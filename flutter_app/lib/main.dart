import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'stores/app_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Clawith',
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
