import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lingua/core/services/app_version_service.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:lingua/design/l10n/locale_notifier.dart';
import 'package:lingua/features/course/models/course_model.dart';
import 'package:lingua/features/course/providers/learner_notifier.dart';
import 'package:lingua/features/practice/providers/quiz_session_notifier.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_service.g.dart';

/// Ghi dữ liệu sang widget rồi vẽ lại — test thay bằng hàm giả.
typedef HomeWidgetWriter = Future<void> Function(Map<String, Object> data);

/// Widget màn hình chính: iOS `ios/AppWidget` (WidgetKit), Android 3 provider nhỏ / vừa / lớn
/// (`android/app/src/main/kotlin/.../widget`). Gửi dữ liệu THÔ — native tự tính lại khi sang ngày
/// mới (app không cần chạy). Khoá phải khớp `AppWidget.swift` và `WidgetData.kt`.
class HomeWidgetService {
  HomeWidgetService(this._ref, {HomeWidgetWriter? writer})
    : _write = writer ?? _writeToPlatform;

  static const iOSKind = 'AppWidget';
  static const _androidPackage = 'com.loipham.lingua.widget';
  static const androidProviders = [
    'SmallWidgetProvider',
    'MediumWidgetProvider',
    'LargeWidgetProvider',
  ];

  final Ref _ref;
  final HomeWidgetWriter _write;
  Timer? _debounce;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<Uri?>? _clicks;

  Future<void> initialize() async {
    final info = await _ref.read(packageInfoProvider.future);
    await HomeWidget.setAppGroupId('group.${info.packageName}');
    _ref
      ..listen(learnerProvider, (_, _) => _schedule())
      ..listen(localeProvider, (_, _) => _schedule());
    _lifecycle = AppLifecycleListener(onResume: push);
    _clicks = HomeWidget.widgetClicked.listen(_open);
    unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(_open));
    await push();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), push);
  }

  Future<void> push() async {
    try {
      final learner = _ref.read(learnerProvider);
      final notifier = _ref.read(learnerProvider.notifier);
      await _write(
        buildHomeWidgetData(
          learner: learner,
          now: notifier.now(),
          dueCount: notifier.dueKeys(learner.course ?? Course.ja).length,
          l10n: lookupAppLocalizations(_ref.read(localeProvider)),
        ),
      );
    } catch (e, s) {
      talker.error('[HOME_WIDGET] push failed', e, s);
    }
  }

  static Future<void> _writeToPlatform(Map<String, Object> data) async {
    await Future.wait([
      for (final MapEntry(:key, :value) in data.entries)
        HomeWidget.saveWidgetData<Object>(key, value),
    ]);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.updateWidget(iOSName: iOSKind);
      return;
    }
    for (final provider in androidProviders) {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: '$_androidPackage.$provider',
      );
    }
  }

  /// `lingua://widget/home` → tab Trang chủ; `lingua://widget/review` → ôn tập (nếu có mục tới hạn).
  Future<void> _open(Uri? uri) async {
    if (uri == null || uri.host != 'widget') return;
    final learner = _ref.read(learnerProvider);
    final course = learner.course;
    if (course == null || !await _mainReady()) return; // chưa qua onboarding
    talker.info('[HOME_WIDGET] open $uri');
    final due = _ref.read(learnerProvider.notifier).dueKeys(course).length;
    if (uri.path == '/review' && due > 0) {
      await appRouter.push(QuizRoute(topic: QuizTopic.review(course)));
    } else {
      await appRouter.navigate(const MainRoute(children: [HomeRoute()]));
    }
  }

  /// Mở app nguội từ widget: chờ Splash chuyển sang khung tab rồi mới điều hướng.
  Future<bool> _mainReady() async {
    bool ready() => appRouter.isRouteActive(MainRoute.name);
    if (ready()) return true;
    final done = Completer<bool>();
    void check() {
      if (ready() && !done.isCompleted) done.complete(true);
    }

    appRouter.addListener(check);
    final ok = await done.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
    appRouter.removeListener(check);
    return ok;
  }

  void dispose() {
    _debounce?.cancel();
    _lifecycle?.dispose();
    unawaited(_clicks?.cancel());
  }
}

@Riverpod(keepAlive: true)
HomeWidgetService homeWidgetService(Ref ref) {
  final service = HomeWidgetService(ref);
  ref.onDispose(service.dispose);
  return service;
}

/// Dữ liệu cho widget. Chuỗi ngày / lượt hôm nay là số đã lưu kèm [Learner.lastActiveDay] —
/// native tự về 0 khi ngày đó không phải hôm nay (lượt) hoặc cũ hơn hôm qua (chuỗi).
/// `last7` = lượt học 7 ngày kết thúc ở `last7End` (cũ → mới).
Map<String, Object> buildHomeWidgetData({
  required Learner learner,
  required DateTime now,
  required int dueCount,
  required AppLocalizations l10n,
}) {
  final course = learner.course ?? Course.ja;
  final module = learner.lastModule?.course == course
      ? learner.lastModule!
      : course.modules.first;
  return {
    'streak': learner.streak,
    'lastActiveDay': learner.lastActiveDay ?? '',
    'todayCount': learner.todayCount,
    'dailyGoal': learner.dailyGoal,
    'dueCount': dueCount,
    'courseFlag': course.flag,
    'continueTitle': module.titleIn(l10n),
    'last7': [
      for (var i = 6; i >= 0; i--)
        learner
                .history[_dayKey(DateTime(now.year, now.month, now.day - i))]
                ?.total ??
            0,
    ].join(','),
    'last7End': _dayKey(now),
    'labelStreak': l10n.widget_streakLabel,
    'labelToday': l10n.widget_today,
    'labelDue': l10n.widget_due(dueCount),
    'labelContinue': l10n.widget_continue,
    'labelWeekdays': l10n.widget_weekdays,
  };
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
