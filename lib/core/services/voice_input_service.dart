import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

/// Nhận giọng nói (luyện nói): bộ nhận dạng có sẵn của máy — iOS / Google trên Android.
class VoiceInputService {
  final _stt = SpeechToText();

  /// Gọi đúng 1 lần khi lượt nghe hiện tại kết thúc (tự dừng, bấm dừng, lỗi) — kể cả khi
  /// không có kết quả cuối, để màn hình không kẹt ở trạng thái "đang nghe".
  void Function(VoiceInputError? error)? _onDone;

  /// Lượt nghe hiện tại đã thật sự bắt đầu (nhận trạng thái `listening`). Trạng thái
  /// "ngừng nghe" đến TRƯỚC đó là của lần khởi tạo / lượt cũ → bỏ qua, không kết thúc nhầm.
  bool _started = false;

  /// Đếm lượt nghe — bỏ các hẹn giờ của lượt cũ.
  int _session = 0;

  bool get isListening => _stt.isListening;

  /// Xin quyền micro + khởi tạo. `false` = máy không hỗ trợ hoặc chưa cấp quyền.
  /// Không nhớ kết quả `false` → cấp quyền xong bấm lại là dùng được.
  Future<bool> ensureReady() async {
    if (_stt.isAvailable) return true;
    try {
      return await _stt.initialize(
        onError: (e) {
          talker.warning(
            '[STT] error ${e.errorMsg} (permanent: ${e.permanent})',
          );
          _finish(VoiceInputError.of(e.errorMsg));
        },
        onStatus: (status) {
          talker.debug('[STT] status $status');
          if (status == SpeechToText.listeningStatus) {
            _started = true;
          } else if (_started &&
              (status == SpeechToText.doneStatus ||
                  status == SpeechToText.notListeningStatus)) {
            _finish(null);
          }
        },
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
    _started = false;
    _onDone = onDone;
    _session++;
    try {
      await _stt.listen(
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } on Object catch (e, s) {
      talker.error('[STT] listen failed', e, s);
      _finish(VoiceInputError.other);
    }
  }

  void _finish(VoiceInputError? error) {
    final done = _onDone;
    _onDone = null;
    _started = false;
    done?.call(error);
  }

  /// Rời màn: huỷ lượt nghe ngay, không báo kết quả.
  Future<void> cancel() async {
    _onDone = null;
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
