import 'package:cheza_games/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cheza_games/providers/settings_provider.dart';
import 'package:cheza_games/services/notification_service.dart';
import 'core/constants/app_theme.dart';
import 'router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Sign in anonymously and create profile
  await FirebaseAuth.instance.signInAnonymously();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider); // 👈 watch settings

    return MaterialApp.router(
      title: 'Matatu',
      theme: AppTheme.getTheme(settings.themeMode), // 👈 dynamic theme
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
