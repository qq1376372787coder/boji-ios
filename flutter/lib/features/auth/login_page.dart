import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass.dart';

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
    HapticFeedback.mediumImpact();
    SoundService.instance.tick();
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
      setState(() => _countdown = (data['retry_after'] as num?)?.toInt() ?? 60);
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
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    HapticFeedback.mediumImpact();
    SoundService.instance.success();
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
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F7), Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Column(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.blue, Color(0xFF5AC8FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.22),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '薄肌俱乐部',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '从今天开始，练出更强的自己',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                GlassPanel(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x99FFFFFF), Color(0x66DDEAFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x66FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '登录 / 注册',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: '手机号',
                          prefixText: '+86  ',
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ],
                      const SizedBox(height: 20),
                      LiquidButton(
                        label: _verifying ? '正在登录…' : '进入薄肌俱乐部',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _verifying ? null : _verify,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '继续即表示你同意《用户协议》和《隐私政策》',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 22),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassBadge(label: 'AI 训练计划', icon: Icons.auto_awesome, color: AppColors.blue),
                    SizedBox(width: 8),
                    GlassBadge(label: '训练日历', icon: Icons.calendar_month, color: AppColors.orange),
                    SizedBox(width: 8),
                    GlassBadge(label: '趋势记录', icon: Icons.insights, color: AppColors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
