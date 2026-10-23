import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/core/services/voice_settings.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  late List<MethodCall> calls;
  late bool hasJapanese;
  late List<Map<String, String>> voices;

  setUp(() {
    calls = [];
    hasJapanese = true;
    voices = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'isLanguageAvailable' => hasJapanese,
            'getVoices' => voices,
            _ => 1,
          };
        });
  });

  test(
    'Kana → file ghi sẵn (Katakana dùng chung file Hiragana); khác Kana → null',
    () {
      expect(SpeechService.kanaClip('あ'), 'japanese/audio/3042.m4a');
      expect(SpeechService.kanaClip('ア'), 'japanese/audio/3042.m4a');
      expect(SpeechService.kanaClip('ン'), SpeechService.kanaClip('ん'));
      expect(SpeechService.kanaClip('日'), isNull);
      expect(SpeechService.kanaClip('にち'), isNull);
    },
  );

  test('mọi chữ Kana trong app đều có file âm', () {
    for (final script in KanaScript.values) {
      for (final k in KanaTable.all(script, withDakuten: true)) {
        final clip = SpeechService.kanaClip(k.char)!;
        expect(File('assets/$clip').existsSync(), isTrue, reason: k.char);
      }
    }
  });

  test(
    'Kanji (không phải Kana) → giọng máy: đặt ja-JP, đọc chậm, đọc chuỗi',
    () async {
      expect(await SpeechService().speak('ニチ、ひ'), isTrue);
      final methods = calls.map((c) => c.method).toList();
      expect(
        methods,
        containsAllInOrder([
          'isLanguageAvailable',
          'setLanguage',
          'setSpeechRate',
          'speak',
        ]),
      );
      expect(
        calls.firstWhere((c) => c.method == 'setLanguage').arguments,
        'ja-JP',
      );
      expect(calls.lastWhere((c) => c.method == 'speak').arguments, 'ニチ、ひ');
    },
  );

  test('đổi ngôn ngữ đọc: chỉ đặt lại giọng khi khác lần trước', () async {
    final speech = SpeechService();
    await speech.speak('hello', language: 'en-US');
    await speech.speak('world', language: 'en-US');
    await speech.speak('ニチ');
    expect(
      [
        for (final c in calls)
          if (c.method == 'setLanguage') c.arguments,
      ],
      ['en-US', 'ja-JP'],
    );
  });

  test(
    'máy chưa có giọng → false, không đọc; cài xong bấm lại là đọc được',
    () async {
      hasJapanese = false;
      final speech = SpeechService();
      expect(await speech.speak('ニチ'), isFalse);
      expect(calls.where((c) => c.method == 'speak'), isEmpty);

      hasJapanese = true;
      expect(await speech.speak('ニチ'), isTrue);
    },
  );

  test('Kanji.speech: âm On + Kun, bỏ ký hiệu, không lặp', () {
    const kanji = Kanji(
      char: '一',
      level: JlptLevel.n5,
      hanViet: 'Nhất',
      meaning: 'một',
      meaningEn: 'one',
      onyomi: ['イチ', 'イツ'],
      kunyomi: ['ひと-', 'ひと(つ)'],
    );
    expect(kanji.speech, 'イチ、イツ、ひと、ひとつ');
  });

  test(
    'chosen voice and speed are used; missing voice falls back to language',
    () async {
      const sam = TtsVoice(
        name: 'Samantha',
        locale: 'en-US',
        identifier: 'sam',
      );
      final speech = SpeechService(
        prefs: (_) => const VoicePrefs(voice: sam, rate: 0.6),
      );
      await speech.speak('hello', language: 'en-US');
      expect(calls.firstWhere((c) => c.method == 'setVoice').arguments, {
        'name': 'Samantha',
        'locale': 'en-US',
        'identifier': 'sam',
      });
      expect(
        calls.firstWhere((c) => c.method == 'setSpeechRate').arguments,
        0.6,
      );
      expect(calls.where((c) => c.method == 'setLanguage'), isEmpty);
    },
  );

  test(
    'voices: same language only, exact region + high quality first, no novelty voices',
    () async {
      voices = [
        {
          'name': 'Daniel',
          'locale': 'en-GB',
          'quality': 'default',
          'identifier': 'com.apple.voice.compact.en-GB.Daniel',
        },
        {
          'name': 'Ava',
          'locale': 'en-US',
          'quality': 'premium',
          'identifier': 'com.apple.voice.premium.en-US.Ava',
        },
        {
          'name': 'Fred',
          'locale': 'en-US',
          'quality': 'default',
          'identifier': 'com.apple.speech.synthesis.voice.Fred',
        },
        {
          'name': 'Kyoko',
          'locale': 'ja-JP',
          'quality': 'default',
          'identifier': 'com.apple.voice.compact.ja-JP.Kyoko',
        },
        {
          'name': 'Tom',
          'locale': 'en-US',
          'quality': 'default',
          'identifier': 'com.apple.voice.compact.en-US.Tom',
        },
      ];
      final list = await SpeechService().voices('en-US');
      expect(list.map((v) => v.name), ['Ava', 'Tom', 'Daniel']);
    },
  );

  test('dialogue partner gets a different voice than the main one', () async {
    voices = [
      {
        'name': 'Ava',
        'locale': 'en-US',
        'gender': 'female',
        'identifier': 'ava',
      },
      {
        'name': 'Allison',
        'locale': 'en-US',
        'gender': 'female',
        'identifier': 'allison',
      },
      {'name': 'Tom', 'locale': 'en-US', 'gender': 'male', 'identifier': 'tom'},
    ];
    final speech = SpeechService(
      prefs: (_) => const VoicePrefs(
        voice: TtsVoice(
          name: 'Ava',
          locale: 'en-US',
          identifier: 'ava',
          gender: 'female',
        ),
      ),
    );
    await speech.speakAndWait('Hi!', partner: true);
    final voice =
        calls.lastWhere((c) => c.method == 'setVoice').arguments as Map;
    expect(voice['name'], 'Tom'); // khác giới tính được ưu tiên
  });

  test(
    'Google voices: gender from voice code, flag from region, local preferred over network',
    () async {
      voices = [
        {
          'name': 'en-us-x-iom-network',
          'locale': 'en-US',
          'network_required': '1',
        },
        {'name': 'en-us-x-iom-local', 'locale': 'en-US'},
        {'name': 'en-us-x-sfg-local', 'locale': 'en-US'},
        {'name': 'en-gb-x-gbb-local', 'locale': 'en-GB'},
        {'name': 'en-us-x-zzz-local', 'locale': 'en-US'},
      ];
      final list = await SpeechService().voices('en-US');
      expect(list.map((v) => v.name), isNot(contains('en-us-x-iom-network')));
      final byName = {for (final v in list) v.name: v};
      expect(byName['en-us-x-iom-local']!.genderOrGuess, 'male');
      expect(byName['en-us-x-sfg-local']!.genderOrGuess, 'female');
      expect(byName['en-us-x-zzz-local']!.genderOrGuess, isNull);
      expect(byName['en-gb-x-gbb-local']!.flag, '🇬🇧');
      expect(byName['en-us-x-sfg-local']!.region, 'US');
    },
  );

  test('engine label: known engines get a friendly name', () {
    expect(engineLabel('com.google.android.tts'), 'Google');
    expect(engineLabel('com.samsung.SMT'), 'Samsung');
    expect(engineLabel('com.example.mytts'), 'example');
  });
}
