import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/modules/app_config/app_config.dart';

void main() {
  test('missing fields fall back to safe defaults', () {
    final cfg = AppConfig.fromJson(const {});
    expect(cfg.maintenance, isFalse);
    expect(cfg.mustUpdate('1.0.0'), isFalse);
    expect(cfg.hasNotice, isFalse);
  });

  test('mustUpdate only when running version is below min_version', () {
    final cfg = AppConfig.fromJson(const {'min_version': '1.2.0'});
    expect(cfg.mustUpdate('1.1.9'), isTrue);
    expect(cfg.mustUpdate('1.2.0'), isFalse);
    expect(cfg.mustUpdate('1.10.0'), isFalse);
    expect(cfg.mustUpdate('1.2.0+45'), isFalse);
  });

  test('noticeId changes when notice content changes', () {
    const a = AppConfig(noticeTitle: 'Sale', noticeBody: '50%');
    expect(
      a.noticeId,
      const AppConfig(noticeTitle: 'Sale', noticeBody: '50%').noticeId,
    );
    expect(
      a.noticeId,
      isNot(const AppConfig(noticeTitle: 'Sale', noticeBody: '30%').noticeId),
    );
  });
}
