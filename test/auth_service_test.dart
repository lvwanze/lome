import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lome/services/auth_service.dart';

void main() {
  // AuthService 用到 shared_preferences，测试环境需先注入 mock
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // 每个用例前清空本地存储并重新初始化（单例状态隔离）
    SharedPreferences.setMockInitialValues({});
    await AuthService.init();
  });

  group('AuthService 假数据流程', () {
    test('初始未登录：isLoggedIn() == false', () {
      expect(AuthService().isLoggedIn(), false);
    });

    test('login() 返回 User 并保存 Token', () async {
      final user = await AuthService().login('13800138000', '1234');

      expect(user.phone, '13800138000');
      expect(user.userId, isNotEmpty);
      expect(user.isBound, false);
      // 登录后已写入 Token
      expect(AuthService().isLoggedIn(), true);
      expect(AuthService().token, isNotNull);
    });

    test('getCurrentUser() 能读回刚登录的用户', () async {
      await AuthService().login('13800138000', '1234');
      final current = await AuthService().getCurrentUser();

      expect(current, isNotNull);
      expect(current!.phone, '13800138000');
    });

    test('generateBindCode() 返回非空绑定码', () async {
      final code = await AuthService().generateBindCode();
      expect(code, isNotEmpty);
    });

    test('useBindCode() 返回伴侣信息且本地用户变为已绑定', () async {
      await AuthService().login('13800138000', '1234');
      final partner = await AuthService().useBindCode('LOVE-ABCD-1234');

      expect(partner['partnerId'], isNotEmpty);
      expect(partner['partnerNickname'], isNotEmpty);

      final current = await AuthService().getCurrentUser();
      expect(current!.isBound, true);
      expect(current.partnerId, isNotNull);
    });

    test('unbind() 后本地用户变回未绑定', () async {
      await AuthService().login('13800138000', '1234');
      await AuthService().useBindCode('LOVE-ABCD-1234');
      await AuthService().unbind();

      final current = await AuthService().getCurrentUser();
      expect(current!.isBound, false);
      expect(current.partnerId, isNull);
    });

    test('logout() 清除登录状态', () async {
      await AuthService().login('13800138000', '1234');
      expect(AuthService().isLoggedIn(), true);

      await AuthService().logout();
      expect(AuthService().isLoggedIn(), false);
      expect(await AuthService().getCurrentUser(), isNull);
    });
  });
}