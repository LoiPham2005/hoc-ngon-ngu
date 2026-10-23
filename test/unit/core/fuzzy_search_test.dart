import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/core/utils/fuzzy_search.dart';

void main() {
  final index = FuzzySearch(const [
    ('rice', 'cơm, gạo'),
    ('price', 'giá'),
    ('friend', 'bạn bè'),
    ('friendly', 'thân thiện'),
    ('Nguyễn Văn An', 'khách hàng'),
    ('食べる', 'ăn'),
  ], fields: (e) => [e.$1, e.$2]);
  List<String> find(String q) => [for (final e in index.search(q)) e.$1];

  test('exact > starts with > word start > contains', () {
    expect(find('rice').first, 'rice');
    expect(find('fri'), ['friend', 'friendly']);
    expect(find('ice'), ['rice', 'price']);
  });

  test('ignores Vietnamese accents and case', () {
    expect(find('GAO'), ['rice']);
    expect(find('nguyen van an'), ['Nguyễn Văn An']);
  });

  test('tolerates typos: swapped, missing, extra letters', () {
    expect(find('rcie').first, 'rice');
    expect(find('freind').first, startsWith('friend'));
    expect(find('nguyn').first, 'Nguyễn Văn An');
    expect(find('gaoo'), contains('rice'));
  });

  test('short words must match exactly (no noise)', () {
    expect(find('xyz'), isEmpty);
    expect(find('ric'), contains('rice'));
    expect(find('rce'), isEmpty);
  });

  test('every word of the query must match', () {
    expect(find('van an'), ['Nguyễn Văn An']);
    expect(find('van rice'), isEmpty);
  });

  test(
    'suggest: closest real word, keeps accents; null when it already matches',
    () {
      expect(index.suggest('gaoo'), 'gạo');
      expect(index.suggest('freind'), 'friend');
      expect(index.suggest('rice'), isNull);
      expect(index.suggest('qwerty'), isNull);
    },
  );
}
