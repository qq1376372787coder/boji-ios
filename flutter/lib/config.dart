class AppConfig {
  static const apiBaseURL = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://123.gongxiang.cloud',
  );
  static const appleProductID = String.fromEnvironment(
    'APPLE_PRODUCT_ID',
    defaultValue: 'cloud.gongxiang.boji.annual12',
  );
  static const appName = '薄肌俱乐部';
}
