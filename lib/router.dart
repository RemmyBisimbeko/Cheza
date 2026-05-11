import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheza_games/features/checkers/checkers_screen.dart';
import 'package:cheza_games/features/profile/profile_screen.dart';
import 'package:cheza_games/features/settings/settings_screen.dart';
import 'features/home/home_screen.dart';
import 'features/game/game_screen.dart';
import 'features/lobby/lobby_screen.dart';
import 'features/lobby/waiting_screen.dart';
import 'features/game/online_game_screen.dart';
import 'features/timer/timer_screen.dart';
import 'features/chess/online_chess_screen.dart';
import 'features/checkers/online_checkers_screen.dart';
import 'features/online/online_players_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      name: 'matatu',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/lobby',
      name: 'lobby',
      builder: (context, state) => const LobbyScreen(isHost: false),
    ),
    GoRoute(
      path: '/lobby/waiting',
      name: 'waiting',
      builder: (context, state) => const WaitingScreen(),
    ),
    GoRoute(
      path: '/online-game',
      name: 'online-game',
      builder: (context, state) => const OnlineGameScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/game',
      name: 'game',
      builder: (context, state) {
        // Router reads game type from setup provider
        return const GameScreen(); // GameScreen handles routing internally
      },
    ),
    GoRoute(
      path: '/checkers',
      name: 'checkers',
      builder: (context, state) => const CheckersScreen(),
    ),
    GoRoute(
      path: '/timer',
      name: 'timer',
      builder: (context, state) => const TimerScreen(),
    ),
    GoRoute(
      path: '/online-chess',
      name: 'online-chess',
      builder: (context, state) => const OnlineChessScreen(),
    ),
    GoRoute(
      path: '/online-checkers',
      name: 'online-checkers',
      builder: (context, state) => const OnlineCheckersScreen(),
    ),
    GoRoute(
      path: '/online',
      name: 'online',
      builder: (context, state) => const OnlinePlayersScreen(),
    ),
  ],
);
