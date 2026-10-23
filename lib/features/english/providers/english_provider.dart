import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lingua/features/english/models/english_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'english_provider.g.dart';

/// 44 chủ đề, ~1.350 từ thông dụng (A1–B1).
@Riverpod(keepAlive: true)
Future<List<Topic<Word>>> vocabTopics(Ref ref) async => [
  for (final t in await _load('assets/english/vocabulary.json'))
    _topic(
      t,
      (items, id) => [
        for (final w in items) Word.fromJson(w as Map<String, dynamic>, id),
      ],
      'words',
    ),
];

/// 15 tình huống × 12 câu giao tiếp.
@Riverpod(keepAlive: true)
Future<List<Topic<Phrase>>> phraseTopics(Ref ref) async => [
  for (final t in await _load('assets/english/phrases.json'))
    _topic(
      t,
      (items, id) => [
        for (final (i, p) in items.indexed)
          Phrase(
            id: '$id.$i',
            text: (p as Map<String, dynamic>)['en'] as String,
            meaning: p['vi'] as String,
            note: p['note'] as String?,
            topicId: id,
          ),
      ],
      'phrases',
    ),
];

/// 24 bài ngữ pháp A1–B1, mỗi bài 10 bài tập.
@Riverpod(keepAlive: true)
Future<List<GrammarLesson>> grammarLessons(Ref ref) async => [
  for (final g in await _load('assets/english/grammar.json'))
    GrammarLesson.fromJson(g),
];

/// 24 đoạn hội thoại A1–B1, mỗi đoạn 4 câu hỏi hiểu bài.
@Riverpod(keepAlive: true)
Future<List<Dialogue>> dialogues(Ref ref) async => [
  for (final d in await _load('assets/english/dialogues.json'))
    Dialogue.fromJson(d),
];

Future<List<Map<String, dynamic>>> _load(String asset) async =>
    (jsonDecode(await rootBundle.loadString(asset)) as List).cast();

Topic<T> _topic<T>(
  Map<String, dynamic> json,
  List<T> Function(List<dynamic> items, String id) items,
  String field,
) {
  final id = json['id'] as String;
  return Topic(
    id: id,
    emoji: json['emoji'] as String,
    nameVi: json['name_vi'] as String,
    nameEn: json['name_en'] as String,
    items: items(json[field] as List, id),
  );
}
