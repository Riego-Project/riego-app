import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth.provider.dart';
import '../screens/auth/login.screen.dart';
import '../screens/dashboard/dashboard.screen.dart';
import '../screens/valves/valves.screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final repo     = ref.read(authRepositoryProvider);
      final loggedIn = await repo.isLoggedIn();
      final onLogin  = state.matchedLocation == '/login';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn  &&  onLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path:    '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path:    '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path:    'valvulas',
            builder: (context, state) => const ValvesScreen(),
          ),
        ],
      ),
    ],
  );
});