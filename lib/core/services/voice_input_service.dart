import 'dart:async';
import 'dart:io';

import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

part 'voice_input_service.g.dart';

/// Lý do 1 lượt nghe kết thúc mà không có kết quả.
enum VoiceInputError {
  /// Không nghe thấy / không khớp từ nào (im lặng, nói quá nhỏ).
  noSpeech,

  /// Cần mạng (bộ nhận dạng chạy trên máy chủ, chưa có gói ngôn ngữ ngoại tuyến).
  network,

  /// Máy chưa hỗ trợ nhận giọng ngôn ngữ này.
  language,

  /// Micro / bộ nhận dạng đang bận.
  busy,

  /// Chưa có quyền micro / nhận giọng nói (hoặc bị tắt trong Cài đặt).
  permission,
  other;

  /// Mã lỗi của speech_to_text (`error_network`, `error_no_match`…) → loại lỗi.
  static VoiceInputError of(String code) => switch (code) {
    'error_no_match' || 'error_speech_timeout' || 'error_retry' => noSpeech,
    'error_busy' || 'error_client' => busy,
    'error_insufficient_permissions' ||
    'error_speech_recognizer_disabled' => permission,
    _ when code.contains('language') => language,
    _
        when code.contains('network') ||
            code.contains('server') ||
            code.contains('too_many_requests') =>
      network,
    _ => other,
  };
}

/// Cách mở bộ nhận giọng trên Android (thử lần lượt khi cách trước hỏng).
enum _Recognizer {
  /// Bộ nhận giọng mặc định của máy.
  system,

  /// Bộ nhận giọng chạy ngay trên máy (Android 12+), thường là của Google.
  onDevice,

  /// Tự tìm dịch vụ nhận giọng đã cài (thường là Google) — dùng khi bộ mặc định của hãng
  /// không đọc chính tả được (vd trợ lý Vivo Copilot chỉ nghe lệnh, tắt ngay khi bấm).
  lookup,
}

/// Nhận giọng nói (luyện nói): bộ nhận dạng có sẵn của máy — iOS / Google trên Android.
///
/// Một số máy (Vivo, Xiaomi…) đặt bộ nhận giọng mặc định là trợ lý của hãng, mở ra là tắt ngay.
/// Lượt nghe nào tắt ngay (< 1 giây, chưa nghe được chữ nào) → tự thử cách mở kế tiếp,
/// nhớ cách chạy được cho các lượt sau. Người dùng không thấy gì ngoài việc micro vẫn nghe.
class VoiceInputService {
  final _stt = SpeechToText();

  /// Lượt nghe tắt trước mốc này (tính từ lúc bắt đầu nghe) mà chưa có chữ = bộ nhận giọng hỏng.
  static const _instantFail = Duration(milliseconds: 1000);

  /// Gọi đúng 1 lần khi lượt nghe hiện tại kết thúc (tự dừng, bấm dừng, lỗi) — kể cả khi
  /// không có kết quả cuối, để màn hình không kẹt ở trạng thái "đang nghe".
  void Function(VoiceInputError? error)? _onDone;
  void Function(String words, bool isFinal)? _onResult;
  String _localeId = 'en_US';

  /// Lượt nghe hiện tại đã thật sự bắt đầu (nhận trạng thái `listening`). Trạng thái
  /// "ngừng nghe" đến TRƯỚC đó là của lần khởi tạo / lượt cũ → bỏ qua, không kết thúc nhầm.
  bool _started = false;
  DateTime? _startedAt;
  bool _gotWords = false;

  /// Đang chờ chuyển sang bộ nhận giọng khác → bỏ qua sự kiện còn sót của lượt hỏng.
  bool _switching = false;

  /// Các cách mở còn lại để thử trong lượt này.
  List<_Recognizer> _pending = const [];
  _Recognizer _current = _Recognizer.system;

  /// Cách mở đã chạy được trên máy này (thử trước ở lượt sau).
  _Recognizer? _working;
  bool _lookupEnabled = false;

  /// Đếm lượt nghe — bỏ các hẹn giờ của lượt cũ.
  int _session = 0;

  bool get isListening => _stt.isListening;

  /// Xin quyền micro + khởi tạo. `false` = máy không hỗ trợ hoặc chưa cấp quyền.
  /// Không nhớ kết quả `false` → cấp quyền xong bấm lại là dùng được.
  Future<bool> ensureReady() async {
    if (_stt.isAvailable) return true;
    try {
      return await _stt.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
    } on Object catch (e, s) {
      talker.error('[STT] init failed', e, s);
      return false;
    }
  }

  /// Nghe 1 câu: [onResult] nhận chữ đang nhận dạng (liên tục) và `isFinal` khi xong;
  /// [onDone] luôn được gọi đúng 1 lần khi lượt nghe kết thúc (có lỗi → kèm loại lỗi).
  /// Ngừng nói ~3 giây hoặc quá 20 giây thì tự dừng.
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
    required void Function(VoiceInputError? error) onDone,
  }) async {
    // Lượt cũ còn chạy (bấm liên tục) → dừng hẳn trước, tránh lỗi "bận".
    if (_stt.isListening) await _stt.cancel();
    _onDone = onDone;
    _onResult = onResult;
    _localeId = localeId;
    final all = Platform.isAndroid ? _Recognizer.values : [_Recognizer.system];
    _pending = [?_working, ...all.where((r) => r != _working)];
    await _next();
  }

  /// Mở bằng cách kế tiếp trong [_pending].
  Future<void> _next() async {
    _current = _pending.first;
    _pending = _pending.sublist(1);
    _started = false;
    _startedAt = null;
    _gotWords = false;
    _switching = false;
    _session++;
    talker.debug('[STT] listen via ${_current.name}');
    try {
      if (_current == _Recognizer.lookup && !_lookupEnabled) {
        // Bật chế độ tự tìm dịch vụ (Google…) — áp dụng khi tạo lại bộ nhận dạng.
        await SpeechToTextPlatform.instance.initialize(
          options: [SpeechToText.androidIntentLookup],
        );
        _lookupEnabled = true;
      }
      await _stt.listen(
        onResult: (r) {
          if (r.recognizedWords.isNotEmpty) {
            _gotWords = true;
            _working = _current;
          }
          _onResult?.call(r.recognizedWords, r.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          // Đổi giữa có / không onDevice buộc plugin tạo lại bộ nhận dạng theo cách mới.
          onDevice: _current == _Recognizer.onDevice,
        ),
      );
    } on Object catch (e, s) {
      talker.error('[STT] listen via ${_current.name} failed', e, s);
      _failOrRetry(VoiceInputError.other);
    }
  }

  void _handleStatus(String status) {
    talker.debug('[STT] status $status');
    if (_switching) return;
    if (status == SpeechToText.listeningStatus) {
      _started = true;
      _startedAt ??= DateTime.now();
    } else if (_started &&
        (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus)) {
      _isInstantFailure ? _failOrRetry(VoiceInputError.other) : _finish(null);
    }
  }

  void _handleError(SpeechRecognitionError e) {
    talker.warning('[STT] error ${e.errorMsg} (permanent: ${e.permanent})');
    if (_switching) return;
    final error = VoiceInputError.of(e.errorMsg);
    // Bộ nhận giọng từ chối ngay (bận / lỗi phía client) → thử cách khác.
    if (!_gotWords &&
        (_isInstantFailure ||
            error == VoiceInputError.busy ||
            error == VoiceInputError.language)) {
      _failOrRetry(error);
    } else {
      _finish(error);
    }
  }

  bool get _isInstantFailure =>
      !_gotWords &&
      (_startedAt == null ||
          DateTime.now().difference(_startedAt!) < _instantFail);

  /// Còn cách khác → đợi sự kiện thừa của lượt hỏng qua hết rồi thử; hết cách → báo lỗi.
  void _failOrRetry(VoiceInputError error) {
    if (_pending.isEmpty || _onDone == null) {
      _finish(error);
      return;
    }
    talker.info('[STT] ${_current.name} failed instantly → retry');
    _switching = true;
    final session = _session;
    Timer(const Duration(milliseconds: 400), () async {
      if (session != _session || _onDone == null) return;
      await _stt.cancel();
      await _next();
    });
  }

  void _finish(VoiceInputError? error) {
    final done = _onDone;
    _onDone = null;
    _onResult = null;
    _started = false;
    _switching = false;
    done?.call(error);
  }

  /// Rời màn: huỷ lượt nghe ngay, không báo kết quả.
  Future<void> cancel() async {
    _onDone = null;
    _onResult = null;
    _session++;
    await _stt.cancel();
  }

  /// Bấm "Đọc xong": chờ kết quả cuối (máy gửi sau khi dừng); quá 1,5 giây không có thì
  /// kết thúc với phần đã nghe được.
  Future<void> stop() async {
    final session = _session;
    await _stt.stop();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (session == _session) _finish(null);
  }
}

@Riverpod(keepAlive: true)
VoiceInputService voiceInput(Ref ref) => VoiceInputService();
