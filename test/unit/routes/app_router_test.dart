import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/routes/app_router.dart';

void main() {
  // Mở app, hệ điều hành gửi '/'. Phải vào Splash (check version + vân tay/Face ID),
  // nếu '/' trỏ thẳng Main là bỏ qua hết bước khởi động.
  test("'/' (cold start) → SplashRoute", () {
    final match = AppRouter().matcher.match('/');
    expect(match?.last.name, SplashRoute.name);
  });

  test('Main is behind AuthGuard', () {
    final main = AppRouter().matcher.match('/main')!.first;
    expect(main.name, MainRoute.name);
    expect(main.guards, isNotEmpty);
  });
}
