import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/goal_setting_screen.dart';
import '../screens/add_food_screen.dart';
import '../screens/bin_screen.dart';
import '../screens/recipe_list_screen.dart';
import '../screens/recipe_builder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userData = ref.watch(userProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = authState.value;
      final onAuthPage = state.matchedLocation == '/auth';
      final onForgotPassword = state.matchedLocation == '/forgot-password';
      final onGoalSetting = state.matchedLocation == '/goal-setting';

      if (user == null) {
        if (onAuthPage || onForgotPassword) return null;
        return '/auth';
      }

      if (onAuthPage) {
        return '/';
      }

      if (userData != null && userData.needsSetup && !onGoalSetting) {
        return '/goal-setting';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/goal-setting',
        builder: (context, state) => const GoalSettingScreen(),
      ),
      GoRoute(
        path: '/add-food',
        builder: (context, state) => const AddFoodScreenWrapper(),
      ),
      GoRoute(
        path: '/bin',
        builder: (context, state) => const BinScreen(),
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const RecipeListScreen(),
      ),
      GoRoute(
        path: '/recipe-builder',
        builder: (context, state) => const RecipeBuilderScreen(),
      ),
    ],
  );
});
