import 'package:api_client/api_client.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua/features/auth/providers/auth_notifier.dart';
import 'package:lingua/routes/app_router.dart';
import 'package:lingua/shared/base/app_scaffold.dart';
import 'package:lingua/shared/states/async_view.dart';

/// Hồ sơ user lấy từ API thật `GET /auth/me` (cần token — interceptor tự gắn + refresh).
@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(authProvider.notifier);
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: notifier.logout,
          ),
        ],
      ),
      body: AsyncView<User?>(
        state: ref.watch(authProvider),
        notifier: notifier,
        onRetry: notifier.refreshMe,
        onRefresh: notifier.refreshMe,
        builder: (context, user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user == null)
              const Text('Chưa đăng nhập')
            else
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    user.fullName ?? user.username ?? user.email ?? user.id,
                  ),
                  subtitle: Text(
                    '${user.email ?? user.phone ?? '-'}\n'
                    'Vai trò: ${user.roles.join(', ')} · ${user.status.name}',
                  ),
                  isThreeLine: true,
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: notifier.refreshMe,
              icon: const Icon(Icons.refresh),
              label: const Text('Gọi lại GET /auth/me'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  context.router.push(const OpenapiUserListRoute()),
              icon: const Icon(Icons.people_outline),
              label: const Text('Danh sách user (cần quyền admin)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.router.push(const AdsDemoRoute()),
              icon: const Icon(Icons.ads_click),
              label: const Text('Ads Demo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.router.push(const JapaneseRoute()),
              icon: const Icon(Icons.translate),
              label: const Text('Học tiếng Nhật (Kana + Kanji)'),
            ),
          ],
        ),
      ),
    );
  }
}
