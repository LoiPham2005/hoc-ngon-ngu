import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lingua/features/japanese/models/kanji_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kanji_provider.g.dart';

/// ~980 Kanji N5–N2, xếp theo cấp rồi theo độ thông dụng.
/// Nghĩa/âm đọc: KANJIDIC (EDRDG, CC BY-SA 4.0) · cấp JLPT: tanos.co.uk · Hán Việt + nghĩa tiếng Việt: soạn riêng.
@Riverpod(keepAlive: true)
Future<List<Kanji>> kanjiList(Ref ref) async {
  final raw =
      jsonDecode(await rootBundle.loadString('assets/japanese/kanji.json'))
          as List;
  return [for (final e in raw) Kanji.fromJson(e as Map<String, dynamic>)];
}
