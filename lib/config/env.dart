import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static final String cloudEnvId = dotenv.env['CLOUD_ENV_ID']!;
  static final String cloudBaseUrl = dotenv.env['CLOUD_BASE_URL']!;
}