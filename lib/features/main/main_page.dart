import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lingua/design/l10n/l10n_extensions.dart';
import 'package:lingua/routes/app_router.dart';

/// Khung 4 tab: Trang chủ · Khoá học · Luyện tập · Hồ sơ.
@RoutePage()
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutoTabsRouter(
      // Đổi tab: mờ dần + phóng nhẹ (fade-through) thay vì nháy cứng.
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (context, child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      routes: const [
        HomeRoute(),
        LearnRoute(),
        PracticeRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabs = AutoTabsRouter.of(context);
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tabs.activeIndex,
            onDestinationSelected: tabs.setActiveIndex,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.nav_home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: l10n.nav_learn,
              ),
              NavigationDestination(
                icon: const Icon(Icons.quiz_outlined),
                selectedIcon: const Icon(Icons.quiz_rounded),
                label: l10n.nav_practice,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: l10n.nav_profile,
              ),
            ],
          ),
        );
      },
    );
  }
}
