import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/profile/providers/reminder_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_service.g.dart';

/// Kết quả lưu file sao lưu.
enum ExportResult { saved, cancelled, failed }

/// Kết quả nhập file sao lưu.
enum RestoreResult { restored, cancelled, invalid, failed }

/// Sao lưu / khôi phục tiến độ học ra 1 file JSON (không cần mạng, không cần tài khoản):
/// đổi máy / cài lại app → nhập lại file là giữ nguyên chuỗi ngày, mục đã thuộc, lịch ôn.
class BackupService {
  BackupService(this._ref);

  final Ref _ref;

  /// Khoá SharedPreferences được sao lưu.
  static const keys = ['learner_v1', 'reminder_v1'];
  static const _app = 'lingua';
  static const _version = 1;

  /// Nội dung file sao lưu (JSON).
  String encode({DateTime? now}) {
    final prefs = _ref.read(sharedPrefsProvider);
    return const JsonEncoder.withIndent(' ').convert({
      'app': _app,
      'version': _version,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'data': {for (final k in keys) k: ?prefs.getString(k)},
    });
  }

  /// Ghi đè tiến độ từ nội dung file; `false` = không phải file sao lưu của Lingua.
  Future<bool> decode(String content) async {
    final Map<String, dynamic> data;
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json['app'] != _app) return false;
      data = json['data'] as Map<String, dynamic>;
      // Kiểm tra trước khi ghi: hồ sơ người học phải đọc được.
      Learner.fromJson(
        jsonDecode(data['learner_v1'] as String) as Map<String, dynamic>,
      );
    } on Object catch (e) {
      talker.warning('[BACKUP] invalid file: $e');
      return false;
    }
    final prefs = _ref.read(sharedPrefsProvider);
    for (final k in keys) {
      if (data[k] case final String v) await prefs.setString(k, v);
    }
    _ref
      ..invalidate(learnerProvider)
      ..invalidate(reminderProvider);
    await _ref.read(reminderProvider.notifier).sync();
    return true;
  }

  /// Chọn chỗ lưu file. Lỗi hệ thống (không mở được trình lưu file…) → [ExportResult.failed].
  Future<ExportResult> export() async {
    final day = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'lingua-backup-$day.json',
        bytes: Uint8List.fromList(utf8.encode(encode())),
        mimeType: 'application/json',
      );
      return uri == null ? ExportResult.cancelled : ExportResult.saved;
    } on Object catch (e, s) {
      talker.error('[BACKUP] export failed', e, s);
      return ExportResult.failed;
    }
  }

  /// Chọn file sao lưu rồi khôi phục.
  Future<RestoreResult> restore() async {
    final String content;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return RestoreResult.cancelled;
      content = await files.first.xFile.readAsString();
    } on Object catch (e, s) {
      talker.error('[BACKUP] restore failed', e, s);
      return RestoreResult.failed;
    }
    return await decode(content)
        ? RestoreResult.restored
        : RestoreResult.invalid;
  }
}

@riverpod
BackupService backup(Ref ref) => BackupService(ref);
