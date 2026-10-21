import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/services/speech_service.dart';
import 'package:lingua/features/japanese/models/kana_model.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  late List<MethodCall> calls;
  late bool hasJapanese;

  setUp(() {
    calls = [];
    hasJapanese = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'isLanguageAvailable' ? hasJapanese : 1;
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
}
