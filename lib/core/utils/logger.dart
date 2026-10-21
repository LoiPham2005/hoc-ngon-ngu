import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Logger toàn app — gọi thẳng `talker.info/.warning/.error(msg, e, s)`.
/// Mọi log/error tự đẩy sang Crashlytics + Sentry (đã che PII) qua [_RemoteObserver].
final Talker talker = TalkerFlutter.init(
  settings: TalkerSettings(useConsoleLogs: kDebugMode),
  observer: _RemoteObserver(),
);

/// Gọi 1 lần trong `main()` theo flavor.
void configureTalker({
  required bool enableConsole,
  required bool maskSensitive,
  required bool crashReporting,
  required bool sentryEnabled,
}) {
  _maskSensitive = maskSensitive;
  _crashReporting = crashReporting;
  _sentryEnabled = sentryEnabled;
  talker.configure(settings: TalkerSettings(useConsoleLogs: enableConsole));
}

bool _maskSensitive = !kDebugMode;
bool _crashReporting = kReleaseMode;
bool _sentryEnabled = false;

const _sensitiveKeys =
    'password|token|access_token|refresh_token|authorization|secret|api_key|pin|otp|cvv';
final _bearer = RegExp(r'Bearer\s+[A-Za-z0-9._\-]+', caseSensitive: false);
final _kv = RegExp(
  '(["\']?(?:$_sensitiveKeys)["\']?\\s*[:=]\\s*)("[^"]*"|\'[^\']*\'|[^\\s,&}"\']+)',
  caseSensitive: false,
);

/// Che field nhạy cảm (JSON, `key=value`, `Bearer <token>`) trước khi gửi remote.
String maskPii(String input) {
  if (!_maskSensitive) return input;
  return input
      .replaceAll(_bearer, 'Bearer ******')
      .replaceAllMapped(_kv, (m) => '${m[1]}******');
}

String _truncate(String s, [int max = 1000]) =>
    s.length <= max ? s : '${s.substring(0, max)}…(${s.length})';

class _RemoteObserver extends TalkerObserver {
  @override
  void onLog(TalkerData log) {
    final msg = _truncate(maskPii(log.generateTextMessage()));
    final level = log.logLevel?.name ?? 'info';
    if (_crashReporting) {
      _safe(() => FirebaseCrashlytics.instance.log('[$level] $msg'));
    }
    if (_sentryEnabled) {
      _safe(
        () => Sentry.addBreadcrumb(Breadcrumb(message: msg, category: level)),
      );
    }
  }

  @override
  void onError(TalkerError err) =>
      _capture(err.error, err.stackTrace, err.message);

  @override
  void onException(TalkerException err) =>
      _capture(err.exception, err.stackTrace, err.message);

  void _capture(Object? error, StackTrace? stack, String? message) {
    final reason = maskPii(message ?? error?.toString() ?? 'error');
    final e = error ?? Exception(reason);
    if (_crashReporting) {
      _safe(
        () =>
            FirebaseCrashlytics.instance.recordError(e, stack, reason: reason),
      );
    }
    if (_sentryEnabled) {
      _safe(
        () => Sentry.captureException(
          e,
          stackTrace: stack,
          hint: Hint.withMap({'reason': reason}),
        ),
      );
    }
  }

  /// Firebase/Sentry chưa init → bỏ qua, không để logger tự gây lỗi.
  void _safe(Object? Function() fn) {
    try {
      fn();
    } catch (_) {}
  }
}

/// Màn xem log trên máy (cho QA/dev).
Future<void> openTalkerScreen(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => TalkerScreen(talker: talker)));

/// In bảng key/value gọn (dùng cho thống kê ads).
void talkerAdTable(
  String title, {
  required List<(String, String)> rows,
  String? tag,
  bool isError = false,
}) {
  final b = StringBuffer('📺 ADS${tag != null ? ' [$tag]' : ''} — $title\n');
  for (final (k, v) in rows) {
    b.writeln('  $k: $v');
  }
  isError ? talker.error(b.toString()) : talker.info(b.toString());
}
