import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/home/home_screen.dart';
import 'features/duel/duel_lobby_screen.dart';
import 'features/duel/battle_screen.dart';
import 'features/duel/result_screen.dart';
import 'features/duel/duel_review_screen.dart';

import 'features/friends/friends_screen.dart';
import 'features/friends/other_profile_screen.dart';
import 'features/friends/chat_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/profile/badges_list_screen.dart';

class StudyDuelApp extends StatelessWidget {
  const StudyDuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyDuel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.friends: (_) => const FriendsScreen(),
        AppRoutes.otherProfile: (_) => const OtherProfileScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.badgesList: (_) => const BadgesListScreen(),
        AppRoutes.duelLobby: (_) => const DuelLobbyScreen(),
        AppRoutes.battle: (_) => const BattleScreen(),
        AppRoutes.result: (_) => const ResultScreen(),
        AppRoutes.duelReview: (_) => const DuelReviewScreen(),
        AppRoutes.chat: (_) => const ChatScreen(),
      },
    );
  }
}
