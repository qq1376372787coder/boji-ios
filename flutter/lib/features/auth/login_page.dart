import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _timer;
  int _countdown = 0;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('86') ? '+$digits' : '+86$digits';
  }

  bool get _canSend =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '').length == 11 &&
      !_sending &&
      _countdown == 0;

  Future<void> _sendCode() async {
    if (!_canSend) return;
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final session = context.read<SessionStore>();
      final data = await session.api.post(
        '/api/auth/sms/send',
        body: {'phone': _normalizedPhone, 'purpose': 'login'},
        authorized: false,
      );
      setState(() {
        _countdown = (data['retry_after'] as num?)?.toInt() ?? 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown <= 1) {
          timer.cancel();
          setState(() => _countdown = 0);
        } else {
          setState(() => _countdown -= 1);
        }
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await context.read<SessionStore>().login(
            _normalizedPhone,
            _codeController.text.trim(),
          );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 38),
              const Icon(
                Icons.fitness_center,
                size: 64,
                color: Color(0xFF2F6FED),
              ),
              const SizedBox(height: 18),
              Text(
                '登录薄肌俱乐部',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                '使用中国大陆手机号登录，生成你的专属训练计划。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6C778C)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixText: '+86  ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '6 位验证码',
                  suffixIcon: TextButton(
                    onPressed: _canSend ? _sendCode : null,
                    child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _verifying ? null : _verify,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登录 / 注册'),
              ),
              const SizedBox(height: 18),
              const Text(
                '继续即表示你同意《用户协议》和《隐私政策》。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF7A8496)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

