import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lesson_provider.g.dart';

/// Từ vựng theo chủ đề của [course] (`assets/<khoá>/vocabulary.json`).
@Riverpod(keepAlive: true)
Future<List<Topic<Word>>> vocabTopics(Ref ref, Course course) async => [
  for (final t in await _load(course, 'vocabulary'))
    _topic(
      t,
      'words',
      (items, id) => [
        for (final w in items.cast<Map<String, dynamic>>())
          Word.fromJson(w, course, id),
      ],
    ),
];

/// Câu giao tiếp theo tình huống của [course].
@Riverpod(keepAlive: true)
Future<List<Topic<Phrase>>> phraseTopics(Ref ref, Course course) async => [
  for (final t in await _load(course, 'phrases'))
    _topic(
      t,
      'phrases',
      (items, id) => [
        for (final (i, p) in items.cast<Map<String, dynamic>>().indexed)
          Phrase(
            course: course,
            id: '$id.$i',
            text: (p['en'] ?? p['ja']) as String,
            reading: p['r'] as String?,
            meaning: p['vi'] as String,
            note: p['note'] as String?,
            topicId: id,
          ),
      ],
    ),
];

/// Bài ngữ pháp của [course], mỗi bài 10 bài tập.
@Riverpod(keepAlive: true)
Future<List<GrammarLesson>> grammarLessons(Ref ref, Course course) async => [
  for (final g in await _load(course, 'grammar'))
    GrammarLesson.fromJson(g, course),
];

/// Hội thoại của [course], mỗi đoạn 4 câu hỏi hiểu bài.
@Riverpod(keepAlive: true)
Future<List<Dialogue>> dialogues(Ref ref, Course course) async => [
  for (final d in await _load(course, 'dialogues'))
    Dialogue.fromJson(d, course),
];

Future<List<Map<String, dynamic>>> _load(Course course, String name) async =>
    (jsonDecode(
              await rootBundle.loadString(
                'assets/${course.assetDir}/$name.json',
              ),
            )
            as List)
        .cast();

Topic<T> _topic<T>(
  Map<String, dynamic> json,
  String field,
  List<T> Function(List<dynamic> items, String id) items,
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
