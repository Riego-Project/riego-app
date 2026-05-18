import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: RiegoApp()));
}

class RiegoApp extends ConsumerWidget {
  const RiegoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title:                      'Riego Automatizado',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.dark,
      routerConfig:               router,
    );
  }
}