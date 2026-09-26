import 'package:boji/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app configuration is available', () {
    expect(AppConfig.appName, '薄肌俱乐部');
  });
}
