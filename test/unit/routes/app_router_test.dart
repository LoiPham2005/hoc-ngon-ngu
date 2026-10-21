import 'package:flutter_test/flutter_test.dart';
import 'package:lingua/routes/app_router.dart';

void main() {
  // Mở app, hệ điều hành gửi '/'. Phải vào Splash (kiểm tra phiên bản + onboarding),
  // '/' mà trỏ thẳng Main là bỏ qua bước khởi động.
  test("'/' (cold start) → SplashRoute", () {
    final match = AppRouter().matcher.match('/');
    expect(match?.last.name, SplashRoute.name);
  });

  test('Main có đủ 4 tab', () {
    final main = AppRouter().matcher.match('/main/profile')!;
    expect(main.first.name, MainRoute.name);
    expect(main.first.children?.last.name, ProfileRoute.name);
  });
}
