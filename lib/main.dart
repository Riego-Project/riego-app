import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';

void main() {
  runApp(const ProviderScope(child: RiegoApp()));
}

class RiegoApp extends ConsumerWidget {
  const RiegoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title:        'Riego Automatizado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:   const Color(0xFF52b788),
          brightness:  Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}