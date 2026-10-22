import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_service.g.dart';

/// Đọc phát âm:
/// - Kana: phát file ghi sẵn `assets/japanese/audio/<mã Hiragana>.m4a` (VOICEVOX:No.7) —
///   nghe được trên MỌI máy, không cần cài gì. Katakana dùng chung file với Hiragana.
/// - Còn lại (âm On/Kun của Kanji, từ/câu tiếng Anh…): giọng có sẵn trên máy (Text-to-Speech).
class SpeechService {
  final _tts = FlutterTts();
  AudioPlayer? _player;
  bool _audioReady = false;

  /// Giọng đang đặt (đổi khi chuyển qua lại Nhật ↔ Anh).
  String? _language;

  /// `false` = máy chưa có giọng đọc [language] (chỉ xảy ra với nội dung không phải Kana).
  Future<bool> speak(String text, {String language = 'ja-JP'}) async {
    final clip = kanaClip(text);
    if (clip != null && await _play(clip)) return true;
    try {
      if (!await _useLanguage(language)) return false;
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } on Object catch (e, s) {
      talker.error('[TTS] speak failed', e, s);
      return false;
    }
  }

  /// Mở cài đặt giọng nói của máy (Android). iOS không mở thẳng được → `false`.
  Future<bool> openVoiceSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      await const AndroidIntent(
        action: 'com.android.settings.TTS_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ).launch();
      return true;
    } on Object catch (e, s) {
      talker.error('[TTS] open settings failed', e, s);
      return false;
    }
  }

  /// File ghi sẵn cho 1 chữ Kana (đường dẫn trong `assets/`); không phải Kana → `null`.
  static String? kanaClip(String text) {
    if (text.runes.length != 1) return null;
    var code = text.runes.first;
    if (code >= 0x30A1 && code <= 0x30F6) code -= 0x60; // Katakana → Hiragana
    if (code < 0x3041 || code > 0x3096) return null;
    return 'japanese/audio/${code.toRadixString(16)}.m4a';
  }

  Future<bool> _play(String asset) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(asset));
      return true;
    } on Object catch (e, s) {
      talker.error('[TTS] play $asset failed → dùng giọng máy', e, s);
      return false;
    }
  }

  /// Đặt giọng [language]; `false` = máy chưa có giọng này. Không nhớ kết quả "chưa có"
  /// → cài giọng xong bấm lại là dùng được, không cần mở lại app.
  Future<bool> _useLanguage(String language) async {
    if (_language == language) return true;
    if (await _tts.isLanguageAvailable(language) != true) return false;
    if (!_audioReady) {
      await _tts.setSpeechRate(0.4); // chậm hơn mặc định cho người học
      // iOS: vẫn kêu khi gạt công tắc im lặng.
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ]);
      _audioReady = true;
    }
    await _tts.setLanguage(language);
    _language = language;
    return true;
  }
}

@Riverpod(keepAlive: true)
SpeechService speech(Ref ref) => SpeechService();
