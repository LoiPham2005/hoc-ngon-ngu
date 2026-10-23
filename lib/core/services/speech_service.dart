import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua/core/services/voice_settings.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_service.g.dart';

/// Đọc phát âm:
/// - Kana: phát file ghi sẵn `assets/japanese/audio/<mã Hiragana>.m4a` (VOICEVOX:No.7) —
///   nghe được trên MỌI máy, không cần cài gì. Katakana dùng chung file với Hiragana.
/// - Còn lại (âm On/Kun của Kanji, từ/câu tiếng Anh…): giọng có sẵn trên máy (Text-to-Speech).
class SpeechService {
  SpeechService({VoicePrefs Function(String language)? prefs})
    : _prefs = prefs ?? ((_) => const VoicePrefs());

  final _tts = FlutterTts();
  AudioPlayer? _player;
  bool _audioReady = false;

  /// Giọng / tốc độ người dùng chọn cho từng ngôn ngữ đọc.
  final VoicePrefs Function(String language) _prefs;

  /// Giọng đang đặt: mã giọng hoặc ngôn ngữ (đổi khi chuyển Nhật ↔ Anh / đổi giọng).
  String? _language;

  /// Danh sách giọng của máy theo ngôn ngữ (đọc 1 lần).
  final _voices = <String, List<TtsVoice>>{};

  /// Tốc độ đọc đang đặt.
  double? _rate;

  /// `false` = máy chưa có giọng đọc [language] (chỉ xảy ra với nội dung không phải Kana).
  /// [slow] = đọc chậm hẳn (nghe – chép).
  Future<bool> speak(
    String text, {
    String language = 'ja-JP',
    bool slow = false,
  }) async {
    final clip = kanaClip(text);
    if (clip != null && await _play(clip)) return true;
    final prefs = _prefs(language);
    return speakWith(
      text,
      language: language,
      voice: prefs.voice,
      rate: slow ? prefs.rate * 0.6 : prefs.rate,
    );
  }

  /// Đọc bằng đúng [voice] / [rate] (nghe thử ở màn cài giọng đọc).
  Future<bool> speakWith(
    String text, {
    required String language,
    TtsVoice? voice,
    double rate = VoicePrefs.defaultRate,
  }) async {
    try {
      if (!await _useLanguage(language, voice: voice)) return false;
      await _useRate(rate);
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } on Object catch (e, s) {
      talker.error('[TTS] speak failed', e, s);
      return false;
    }
  }

  /// Giọng đọc tiếng [language] có trên máy (cùng thứ tiếng, mọi vùng: en-US, en-GB…):
  /// đúng vùng trước, chất lượng cao trước. Bỏ giọng chưa tải (Android) và giọng hiệu ứng (iOS).
  Future<List<TtsVoice>> voices(String language) async {
    final cached = _voices[language];
    if (cached != null) return cached;
    final lang = language.split('-').first.toLowerCase();
    try {
      final all = [
        for (final v in (await _tts.getVoices as List? ?? const []))
          if (v is Map) TtsVoice.fromPlatform(v),
      ];
      final list = [
        for (final v in all)
          if (v.locale.toLowerCase().split(RegExp('[-_]')).first == lang &&
              !(v.identifier ?? '').contains('speech.synthesis') &&
              !(v.identifier ?? '').contains('eloquence'))
            v,
      ];
      list.sort((a, b) {
        int score(TtsVoice v) =>
            (v.locale.replaceAll('_', '-') == language ? 2 : 0) +
            (v.isHighQuality ? 1 : 0);
        final byScore = score(b).compareTo(score(a));
        return byScore != 0 ? byScore : a.name.compareTo(b.name);
      });
      return _voices[language] = list;
    } on Object catch (e, s) {
      talker.error('[TTS] getVoices failed', e, s);
      return const [];
    }
  }

  /// Đọc rồi chờ đọc xong (đọc nối cả đoạn hội thoại). [partner] = người nói thứ 2:
  /// giọng người dùng chọn, không chọn thì tự lấy 1 giọng khác của máy (khác giới nếu biết),
  /// máy chỉ có 1 giọng thì đổi cao độ nhẹ. `false` = không đọc được / bị [stop] giữa chừng.
  Future<bool> speakAndWait(
    String text, {
    String language = 'en-US',
    bool partner = false,
  }) async {
    final prefs = _prefs(language);
    final voice = partner
        ? prefs.partner ?? await _otherVoice(language, prefs.voice)
        : prefs.voice;
    final pitch = partner && voice == null ? 1.15 : 1.0;
    final done = Completer<bool>();
    void finish(bool ok) {
      if (!done.isCompleted) done.complete(ok);
    }

    try {
      if (!await _useLanguage(language, voice: voice)) return false;
      await _useRate(prefs.rate);
      await _tts.stop();
      // Gắn sau stop() để không nhận nhầm sự kiện huỷ của câu trước.
      _tts
        ..setCompletionHandler(() => finish(true))
        ..setCancelHandler(() => finish(false))
        ..setErrorHandler((_) => finish(false));
      await _tts.setPitch(pitch);
      await _tts.speak(text);
      // Phòng máy không báo "đọc xong": tối đa ~0,5 giây / ký tự.
      return await done.future.timeout(
        Duration(milliseconds: 2000 + text.length * 500),
        onTimeout: () => true,
      );
    } on Object catch (e, s) {
      talker.error('[TTS] speakAndWait failed', e, s);
      return false;
    } finally {
      await _tts.setPitch(1);
    }
  }

  /// Giọng thứ 2 cho hội thoại: khác [main], ưu tiên khác giới tính và chất lượng cao.
  Future<TtsVoice?> _otherVoice(String language, TtsVoice? main) async {
    final list = await voices(language);
    final first = main ?? list.firstOrNull;
    final others = list.where((v) => v != first).toList()
      ..sort((a, b) {
        int score(TtsVoice v) =>
            (first?.gender != null &&
                    v.gender != null &&
                    v.gender != first!.gender
                ? 2
                : 0) +
            (v.locale == first?.locale ? 1 : 0);
        return score(b).compareTo(score(a));
      });
    return others.firstOrNull;
  }

  Future<void> _useRate(double rate) async {
    if (_rate == rate) return;
    await _tts.setSpeechRate(rate);
    _rate = rate;
  }

  Future<void> stop() async {
    await _tts.stop();
    await _player?.stop();
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

  /// Đặt giọng [language] (hoặc đúng [voice] nếu có); `false` = máy chưa có giọng này.
  /// Không nhớ kết quả "chưa có" → cài giọng xong bấm lại là dùng được, không cần mở lại app.
  Future<bool> _useLanguage(String language, {TtsVoice? voice}) async {
    final key = voice?.id ?? language;
    if (_language == key) return true;
    await _prepareAudio();
    // Giọng đã chọn không còn trên máy (gỡ / đổi máy) → quay về giọng mặc định của ngôn ngữ.
    if (voice != null && await _tts.setVoice(voice.toPlatform()) == 1) {
      _language = key;
      return true;
    }
    if (await _tts.isLanguageAvailable(language) != true) return false;
    await _tts.setLanguage(language);
    _language = language;
    return true;
  }

  Future<void> _prepareAudio() async {
    if (!_audioReady) {
      // iOS: vẫn kêu khi gạt công tắc im lặng.
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ]);
      _audioReady = true;
    }
  }
}

@Riverpod(keepAlive: true)
SpeechService speech(Ref ref) =>
    SpeechService(prefs: ref.read(voiceSettingsProvider.notifier).of);
