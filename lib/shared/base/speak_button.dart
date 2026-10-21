import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/shared/dialogs/app_confirmation_dialog.dart';

/// Nút 🔊 đọc [text]. Máy chưa có giọng đọc → hộp thoại hướng dẫn (Android: nút mở thẳng cài đặt).
class SpeakButton extends ConsumerWidget {
  const SpeakButton(this.text, {this.language = 'ja-JP', super.key});

  final String text;
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton.filledTonal(
    tooltip: context.l10n.tts_listen,
    icon: const Icon(Icons.volume_up_rounded),
    onPressed: () async {
      final speech = ref.read(speechProvider);
      if (await speech.speak(text, language: language) || !context.mounted) {
        return;
      }
      final l10n = context.l10n;
      final android = Platform.isAndroid;
      final open = await AppConfirmationDialog.show(
        context,
        title: l10n.tts_missingTitle,
        message: android ? l10n.tts_missingAndroid : l10n.tts_missingIos,
        confirmText: android ? l10n.tts_openSettings : l10n.common_ok,
      );
      if (open && android) await speech.openVoiceSettings();
    },
  );
}
