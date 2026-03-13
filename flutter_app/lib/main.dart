import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_lifecycle.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'stores/app_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLifecycle.instance.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ClawithApp()));
}

class ClawithApp extends ConsumerWidget {
  const ClawithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appState = ref.watch(appProvider);
    final isDark = appState.themeMode == 'dark';

    return MaterialApp.router(
      title: 'Soloship',
      debugShowCheckedModeBanner: false,
      theme: isDark
          ? AppTheme.darkTheme(accentHex: appState.accentColor)
          : AppTheme.lightTheme(accentHex: appState.accentColor),
      routerConfig: router,
    );
  }
}
