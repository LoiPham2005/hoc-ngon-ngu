import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'voice_input_service.g.dart';

/// Nhận giọng nói (luyện nói): bộ nhận dạng có sẵn của máy — iOS / Google trên Android.
class VoiceInputService {
  final _stt = SpeechToText();

  /// Gọi khi lượt nghe hiện tại kết thúc (tự dừng, bấm dừng, lỗi) — kể cả khi
  /// không có kết quả cuối, để màn hình không kẹt ở trạng thái "đang nghe".
  void Function()? _onDone;

  bool get isListening => _stt.isListening;

  /// Xin quyền micro + khởi tạo. `false` = máy không hỗ trợ hoặc chưa cấp quyền.
  /// Không nhớ kết quả `false` → cấp quyền xong bấm lại là dùng được.
  Future<bool> ensureReady() async {
    if (_stt.isAvailable) return true;
    try {
      return await _stt.initialize(
        onError: (e) {
          talker.warning('[STT] ${e.errorMsg}');
          _finish();
        },
        onStatus: (status) {
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            _finish();
          }
        },
      );
    } on Object catch (e, s) {
      talker.error('[STT] init failed', e, s);
      return false;
    }
  }

  /// Nghe 1 câu: [onResult] nhận chữ đang nhận dạng (liên tục) và `isFinal` khi xong;
  /// [onDone] luôn được gọi đúng 1 lần khi lượt nghe kết thúc vì bất kỳ lý do gì.
  /// Ngừng nói ~2,5 giây hoặc quá 20 giây thì tự dừng.
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
    required void Function() onDone,
  }) {
    _onDone = onDone;
    return _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(milliseconds: 2500),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  void _finish() {
    final done = _onDone;
    _onDone = null;
    done?.call();
  }

  Future<void> stop() async {
    await _stt.stop();
    _finish();
  }
}

@Riverpod(keepAlive: true)
VoiceInputService voiceInput(Ref ref) => VoiceInputService();
