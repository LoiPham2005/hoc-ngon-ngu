import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/lessons/models/lesson_model.dart';

/// Dữ liệu `grammar.json` của mọi khoá: parse được, id không trùng, bài tập làm được.
void main() {
  for (final course in Course.values) {
    final file = File('assets/${course.assetDir}/grammar.json');
    if (!file.existsSync()) continue;
    final lessons = [
      for (final json
          in (jsonDecode(file.readAsStringSync()) as List)
              .cast<Map<String, dynamic>>())
        GrammarLesson.fromJson(json, course),
    ];

    test('${course.name}: lesson ids are unique', () {
      final ids = lessons.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    for (final lesson in lessons) {
      test('${course.name}/${lesson.id}: has content and valid exercises', () {
        expect(lesson.formulas, isNotEmpty);
        expect(lesson.points, isNotEmpty);
        expect(lesson.examples, isNotEmpty);
        expect(lesson.exercises, hasLength(10));
        for (final e in lesson.exercises) {
          switch (e) {
            case ChoiceExercise():
              expect(e.prompt, contains('___'), reason: e.prompt);
              expect(e.options, hasLength(4), reason: e.prompt);
              expect(e.options.toSet(), hasLength(4), reason: e.prompt);
              expect(e.answer, inInclusiveRange(0, 3), reason: e.prompt);
            case OrderExercise():
              expect(
                e.answer.split(' ').where((c) => c.isNotEmpty).length,
                greaterThanOrEqualTo(3),
                reason: e.answer,
              );
          }
        }
      });
    }
  }
}
