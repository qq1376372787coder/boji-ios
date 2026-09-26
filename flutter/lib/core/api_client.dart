import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

ApiClient createApiClient() {
  return AppConfig.useMockApi ? MockApiClient() : ApiClient();
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? accessToken;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseURL}$path');

  Future<Map<String, dynamic>> get(
    String path, {
    bool authorized = true,
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: _headers(authorized: authorized),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = true,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(authorized: authorized),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    return _decode(response);
  }

  Map<String, String> _headers({required bool authorized}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Client-Platform': 'flutter',
    };
    if (authorized && accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));

    if (body is! Map<String, dynamic>) {
      throw const ApiException('服务器返回格式不正确。');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] ?? body['message'] ?? '请求失败，请稍后重试。';
      throw ApiException(
        message.toString(),
        statusCode: response.statusCode,
      );
    }
    return body;
  }
}


class MockApiClient extends ApiClient {
  MockUserState? _state;
  final List<Map<String, dynamic>> _records = [];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    bool authorized = true,
  }) async {
    if (path == '/api/me') {
      return _userResponse();
    }
    if (path == '/api/checkins') {
      return {'records': _records};
    }
    throw const ApiException('Mock endpoint not implemented.');
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authorized = true,
  }) async {
    switch (path) {
      case '/api/auth/sms/send':
        return {'ok': true, 'retry_after': 60, 'debug_code': '123456'};
      case '/api/auth/sms/verify':
        final phone = body?['phone']?.toString() ?? '';
        _state = MockUserState.fromPhone(phone);
        return {
          'access_token': 'mock-access-token',
          'refresh_token': 'mock-refresh-token',
          'user': _state!.asJson(),
        };
      case '/api/onboarding':
        _state?.onboarded = true;
        return _userResponse();
      case '/api/checkin':
        _records.insert(0, {
          'id': _records.length + 1,
          'created_at': DateTime.now().toIso8601String(),
          'kind': body?['kind'] ?? 'workout',
          'payload': body?['payload'] ?? const {},
        });
        return {'ok': true};
      case '/api/auth/logout':
        _state = null;
        return {'ok': true};
      case '/api/plan/generate':
      case '/api/plan/import':
        return _mockPlan();
      case '/api/plan/version':
        return {
          'version': {'id': 1, 'version': 1, 'member': 'me'}
        };
      case '/api/billing/apple/verify':
        _state?.membershipActive = true;
        return {
          'ok': true,
          'membership': _membership(),
        };
      default:
        throw const ApiException('Mock endpoint not implemented.');
    }
  }

  Map<String, dynamic> _userResponse() {
    final state = _state;
    if (state == null) throw const ApiException('请先登录。');
    return state.asJson();
  }

  Map<String, dynamic> _membership() {
    return {
      'active': _state?.membershipActive == true,
      'status': _state?.membershipActive == true ? 'active' : 'none',
      'expires_at': _state?.membershipActive == true
          ? DateTime.now().add(const Duration(days: 365)).toIso8601String()
          : null,
    };
  }

  Map<String, dynamic> _mockPlan() {
    return {
      'summary': '根据你的目标和训练条件，安排一份循序渐进的训练计划。',
      'plans': [
        {
          'name': '第 1 天 · 上肢推',
          'note': '控制动作节奏，最后一组保留 1–2 次余力。',
          'exercises': [
            ['哑铃卧推', 4, '8–12', 'weight'],
            ['哑铃肩推', 3, '8–12', 'weight'],
            ['俯卧撑', 3, '10–15', 'bodyweight'],
          ],
        },
        {
          'name': '第 2 天 · 下肢',
          'note': '注意膝盖和脚尖方向一致。',
          'exercises': [
            ['高脚杯深蹲', 4, '8–12', 'weight'],
            ['哑铃硬拉', 3, '8–12', 'weight'],
            ['臀桥', 3, '12–15', 'bodyweight'],
          ],
        },
      ],
    };
  }
}

class MockUserState {
  MockUserState({
    required this.phone,
    required this.onboarded,
    required this.membershipActive,
  });

  factory MockUserState.fromPhone(String phone) {
    final isVipTestAccount = phone == '+8613800138000';
    return MockUserState(
      phone: phone,
      onboarded: isVipTestAccount,
      membershipActive: isVipTestAccount,
    );
  }

  String phone;
  bool onboarded;
  bool membershipActive;

  Map<String, dynamic> asJson() {
    return {
      'id': phone.endsWith('138000') ? 1001 : 1002,
      'phone': phone,
      'display_name': phone.endsWith('138000') ? 'VIP 测试账号' : '新用户测试账号',
      'onboarded': onboarded,
      'membership': {
        'active': membershipActive,
        'status': membershipActive ? 'active' : 'none',
        'expires_at': membershipActive
            ? DateTime.now().add(const Duration(days: 365)).toIso8601String()
            : null,
      },
    };
  }
}


