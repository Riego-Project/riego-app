import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth.provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController(text: 'admin@riego.pe');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  bool _obscure       = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    ref.read(authProvider).whenData((_) => context.go('/dashboard'));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    ref.listen(authProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0f1a14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / ícono
                const Icon(
                  Icons.water_drop_rounded,
                  size: 72,
                  color: Color(0xFF52b788),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Riego Automatizado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF95d5b2),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Paltos · Ayacucho',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF52b788),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),

                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller:  _passwordCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Contraseña',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF52b788),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2d6a4f),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Ingresar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText:   label,
      labelStyle:  const TextStyle(color: Color(0xFF52b788)),
      prefixIcon:  Icon(icon, color: const Color(0xFF52b788)),
      suffixIcon:  suffix,
      filled:      true,
      fillColor:   const Color(0xFF1a2f20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: Color(0xFF52b788)),
      ),
    );
  }
}