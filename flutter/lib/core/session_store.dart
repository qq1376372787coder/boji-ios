import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';
import 'api_client.dart';

enum SessionPhase { launching, loggedOut, onboarding, ready }

class SessionStore extends ChangeNotifier {
  SessionStore({ApiClient? api, FlutterSecureStorage? storage})
      : api = api ?? createApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  final ApiClient api;
  final FlutterSecureStorage _storage;

  SessionPhase phase = SessionPhase.launching;
  AppUser? user;
  String? errorMessage;

  Future<void> bootstrap() async {
    phase = SessionPhase.launching;
    notifyListeners();

    final token = await _storage.read(key: 'access_token') ?? '';
    if (token.isEmpty) {
      phase = SessionPhase.loggedOut;
      notifyListeners();
      return;
    }

    api.accessToken = token;
    try {
      final data = await api.get('/api/me');
      user = AppUser.fromJson(data);
      phase = user?.onboarded == true ? SessionPhase.ready : SessionPhase.onboarding;
    } catch (_) {
      await clearSession();
    }
    notifyListeners();
  }

  Future<void> login(String phone, String code) async {
    final data = await api.post(
      '/api/auth/sms/verify',
      body: {'phone': phone, 'code': code},
      authorized: false,
    );
    final auth = AuthResponse.fromJson(data);
    api.accessToken = auth.accessToken;
    await _storage.write(key: 'access_token', value: auth.accessToken);
    await _storage.write(key: 'refresh_token', value: auth.refreshToken);
    user = auth.user;
    phase = auth.user.onboarded ? SessionPhase.ready : SessionPhase.onboarding;
    notifyListeners();
  }

  Future<void> completeOnboarding(OnboardingPayload payload) async {
    final data = await api.post('/api/onboarding', body: payload.toJson());
    user = AppUser.fromJson(data);
    phase = SessionPhase.ready;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (phase == SessionPhase.loggedOut) return;
    try {
      final data = await api.get('/api/me');
      user = AppUser.fromJson(data);
      phase = user?.onboarded == true ? SessionPhase.ready : SessionPhase.onboarding;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout');
    } catch (_) {}
    await clearSession();
  }

  Future<void> clearSession() async {
    api.accessToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    user = null;
    phase = SessionPhase.loggedOut;
    notifyListeners();
  }
}

