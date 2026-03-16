import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
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
  runApp(const ProviderScope(child: OhClawApp()));
}

class OhClawApp extends ConsumerWidget {
  const OhClawApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appState = ref.watch(appProvider);

    // Determine effective brightness & sync AppColors
    final ThemeMode themeMode;
    switch (appState.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        AppColors.setDark(false);
        break;
      case 'system':
        themeMode = ThemeMode.system;
        // For AppColors, resolve using platform brightness
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        AppColors.setDark(platformBrightness == Brightness.dark);
        break;
      default: // 'dark'
        themeMode = ThemeMode.dark;
        AppColors.setDark(true);
    }

    return MaterialApp.router(
      title: 'OhClaw',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(accentHex: appState.accentColor),
      darkTheme: AppTheme.darkTheme(accentHex: appState.accentColor),
      themeMode: themeMode,
      routerConfig: router,
      locale: appState.flutterLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
