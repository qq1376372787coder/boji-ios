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
