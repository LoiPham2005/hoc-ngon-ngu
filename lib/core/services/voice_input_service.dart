import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'voice_input_service.g.dart';

/// Nhận giọng nói (luyện nói): bộ nhận dạng có sẵn của máy — iOS / Google trên Android.
class VoiceInputService {
  final _stt = SpeechToText();

  bool get isListening => _stt.isListening;

  /// Xin quyền micro + khởi tạo. `false` = máy không hỗ trợ hoặc chưa cấp quyền.
  /// Không nhớ kết quả `false` → cấp quyền xong bấm lại là dùng được.
  Future<bool> ensureReady() async {
    if (_stt.isAvailable) return true;
    try {
      return await _stt.initialize(
        onError: (e) => talker.warning('[STT] ${e.errorMsg}'),
      );
    } on Object catch (e, s) {
      talker.error('[STT] init failed', e, s);
      return false;
    }
  }

  /// Nghe 1 câu: [onResult] nhận chữ đang nhận dạng (liên tục) và `isFinal` khi xong.
  /// Ngừng nói ~2,5 giây hoặc quá 20 giây thì tự dừng.
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
  }) => _stt.listen(
    onResult: (r) => onResult(r.recognizedWords, r.finalResult),
    listenOptions: SpeechListenOptions(
      localeId: localeId,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(milliseconds: 2500),
      partialResults: true,
      cancelOnError: true,
    ),
  );

  Future<void> stop() => _stt.stop();
}

@Riverpod(keepAlive: true)
VoiceInputService voiceInput(Ref ref) => VoiceInputService();
