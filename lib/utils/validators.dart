class Validators {
  /// 校验手机号：11位，1开头，第二位3-9
  static bool isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  /// 校验验证码：6位数字
  static bool isValidCode(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  /// 手机号错误提示
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (!isValidPhone(value)) {
      return '请输入正确的手机号';
    }
    return null;
  }

  /// 验证码错误提示
  static String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入验证码';
    }
    if (!isValidCode(value)) {
      return '请输入6位数字验证码';
    }
    return null;
  }
}