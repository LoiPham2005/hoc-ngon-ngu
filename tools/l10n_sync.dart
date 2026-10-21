// ignore_for_file: avoid_print — script CLI
import 'dart:convert';
import 'dart:io';

/// Đồng bộ các file ARB theo file mẫu (`template-arb-file` trong `l10n.yaml`).
///
///   dart run tools/l10n_sync.dart              xoá key thừa + liệt kê key chưa dịch
///   dart run tools/l10n_sync.dart --translate  + dịch key còn thiếu bằng Google Translate
///   dart run tools/l10n_sync.dart --dry-run    chỉ xem, không ghi file
///
/// - Key chưa dịch KHÔNG chép tiếng Anh vào: gen-l10n tự dùng bản mẫu cho key thiếu.
/// - Chuỗi plural/select (ICU) không tự dịch → dịch tay.
/// - Giữ `@@locale`, metadata `@key` sẵn có; thứ tự key theo file mẫu; thụt 2 dấu cách.
Future<void> main(List<String> args) async {
  final translate = args.contains('--translate');
  final dryRun = args.contains('--dry-run');

  final config = _readL10nYaml();
  final dir = config['arb-dir'] ?? 'lib/l10n';
  final templateName = config['template-arb-file'] ?? 'app_en.arb';
  final template = _readArb(File('$dir/$templateName'));
  final keys = template.keys.where((k) => !k.startsWith('@')).toList();
  final from = template['@@locale'] as String? ?? _localeOf(templateName);

  final files =
      Directory(dir)
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.arb') && !f.path.endsWith('/$templateName'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final original = file.readAsStringSync();
    final arb = jsonDecode(original) as Map<String, dynamic>;
    final to = arb['@@locale'] as String? ?? _localeOf(name);

    final extra = arb.keys
        .where((k) => !k.startsWith('@') && !keys.contains(k))
        .toList();
    final missing = keys.where((k) => !arb.containsKey(k)).toList();
    final added = <String>[];
    if (translate) {
      for (final key in missing) {
        final text = await _translate(
          template[key] as String,
          from: from,
          to: to,
        );
        if (text == null) continue;
        arb[key] = text;
        added.add(key);
        print('  + $key: $text');
      }
    }
    final untranslated = missing.where((k) => !added.contains(k)).toList();

    // @@locale + @@… lên đầu, rồi các key theo thứ tự file mẫu (kèm metadata @key nếu file đã có).
    final output = <String, dynamic>{
      '@@locale': to,
      for (final e in arb.entries)
        if (e.key.startsWith('@@')) e.key: e.value,
      for (final k in keys)
        if (arb.containsKey(k)) ...{
          k: arb[k],
          if (arb.containsKey('@$k')) '@$k': arb['@$k'],
        },
    };
    final json = '${const JsonEncoder.withIndent('  ').convert(output)}\n';
    final changed = json != original;
    if (changed && !dryRun) file.writeAsStringSync(json);

    final notes = [
      if (added.isNotEmpty) 'đã dịch ${added.length}',
      if (extra.isNotEmpty)
        'xoá ${extra.length} key thừa (${extra.join(', ')})',
      if (untranslated.isNotEmpty)
        'chưa dịch ${untranslated.length} (${untranslated.join(', ')})',
    ];
    final status = !changed
        ? ''
        : (dryRun ? ' — dry-run, chưa ghi' : ' — đã ghi');
    print('$name: ${notes.isEmpty ? 'đủ key' : notes.join(' · ')}$status');
  }
}

final _icu = RegExp(r'\{\s*\w+\s*,\s*(plural|select|selectordinal)\s*,');
final _placeholder = RegExp(r'\{\w+\}');

/// `null` = không dịch được (chuỗi ICU, lỗi mạng, hoặc Google làm mất placeholder).
Future<String?> _translate(
  String text, {
  required String from,
  required String to,
}) async {
  if (_icu.hasMatch(text)) return null;
  // {name} → [0], [1]… để Google không dịch tên biến.
  final names = _placeholder.allMatches(text).map((m) => m[0]!).toList();
  var i = 0;
  final masked = text.replaceAllMapped(_placeholder, (_) => '[${i++}]');

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': from.replaceAll('_', '-'),
      'tl': to.replaceAll('_', '-'),
      'dt': 't',
      'q': masked,
    });
    final response = await (await client.getUrl(uri)).close();
    if (response.statusCode != 200) return null;
    final body =
        jsonDecode(await response.transform(utf8.decoder).join()) as List;
    var result = (body[0] as List).map((part) => (part as List)[0]).join();
    for (var j = 0; j < names.length; j++) {
      if (!result.contains('[$j]')) return null;
      result = result.replaceFirst('[$j]', names[j]);
    }
    return result;
  } on Object {
    return null;
  } finally {
    client.close();
  }
}

Map<String, dynamic> _readArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

/// `l10n.yaml` chỉ có dạng `key: value` một dòng → không cần thư viện yaml.
Map<String, String> _readL10nYaml() {
  final file = File('l10n.yaml');
  if (!file.existsSync()) return {};
  return {
    for (final line in file.readAsLinesSync())
      if (line.contains(':') && !line.trimLeft().startsWith('#'))
        line.substring(0, line.indexOf(':')).trim(): line
            .substring(line.indexOf(':') + 1)
            .trim(),
  };
}

/// `app_vi.arb` → `vi`, `app_zh_Hant.arb` → `zh_Hant`.
String _localeOf(String fileName) =>
    RegExp(r'_([a-z]{2,3}(?:_\w+)?)\.arb$').firstMatch(fileName)?[1] ?? 'en';
