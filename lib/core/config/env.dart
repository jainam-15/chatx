enum AppEnvironment {
  development,
  staging,
  production,
}

class Env {
  Env._();

  static const String appName = 'ChatX';
  static const AppEnvironment environment = AppEnvironment.development;

  static const bool isDebug = true;
  static const bool enablePushNotifications = true;

  // Global settings
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration messageCacheDuration = Duration(days: 7);
}
