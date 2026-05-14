import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.model.dart';
import '../repositories/auth.repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo      = ref.read(authRepositoryProvider);
    final loggedIn  = await repo.isLoggedIn();
    return loggedIn ? null : null; // token existe pero no tenemos el objeto user en memoria
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);