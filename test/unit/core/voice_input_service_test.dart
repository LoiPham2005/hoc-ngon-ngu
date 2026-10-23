import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/services/voice_input_service.dart';

void main() {
  test(
    'speech_to_text error codes map to a reason the learner understands',
    () {
      expect(VoiceInputError.of('error_no_match'), VoiceInputError.noSpeech);
      expect(
        VoiceInputError.of('error_speech_timeout'),
        VoiceInputError.noSpeech,
      );
      expect(VoiceInputError.of('error_network'), VoiceInputError.network);
      expect(
        VoiceInputError.of('error_network_timeout'),
        VoiceInputError.network,
      );
      expect(
        VoiceInputError.of('error_server_disconnected'),
        VoiceInputError.network,
      );
      expect(
        VoiceInputError.of('error_language_not_supported'),
        VoiceInputError.language,
      );
      expect(VoiceInputError.of('error_busy'), VoiceInputError.busy);
      expect(
        VoiceInputError.of('error_insufficient_permissions'),
        VoiceInputError.permission,
      );
      expect(VoiceInputError.of('error_something_new'), VoiceInputError.other);
    },
  );
}
