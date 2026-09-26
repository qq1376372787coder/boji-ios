import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'core/session_store.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'services/purchase_service.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = SessionStore();
  final purchase = PurchaseService(api: session.api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: purchase),
      ],
      child: const BojiApp(),
    ),
  );

  try {
    await PushService.instance.initialize();
  } catch (_) {
    // Some platforms do not provide a local notifications implementation.
  }
  await session.bootstrap();
  try {
    await purchase.initialize();
  } catch (error) {
    purchase.showMessage(error.toString());
  }
}

class BojiApp extends StatelessWidget {
  const BojiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6FED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE2EC)),
          ),
        ),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<SessionStore, SessionPhase>(
      (session) => session.phase,
    );

    switch (phase) {
      case SessionPhase.launching:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case SessionPhase.loggedOut:
        return const LoginPage();
      case SessionPhase.onboarding:
        return const OnboardingPage();
      case SessionPhase.ready:
        return const HomePage();
    }
  }
}


