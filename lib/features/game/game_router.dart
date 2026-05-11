// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../providers/setup_provider.dart';
// import '../../core/constants/enums.dart';
// import 'game_screen.dart';
// import '../checkers/checkers_screen.dart';

// class GameRouter extends ConsumerWidget {
//   const GameRouter({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final setup = ref.watch(setupProvider);

//     switch (setup.gameType) {
//       case GameType.checkers:
//         return const CheckersScreen();
//       case GameType.chess:
//       case GameType.ludo:
//         return _ComingSoon(gameType: setup.gameType);
//       case GameType.matatu:
//       default:
//         return const GameScreen();
//     }
//   }
// }

// class _ComingSoon extends StatelessWidget {
//   final GameType gameType;
//   const _ComingSoon({required this.gameType});

//   @override
//   Widget build(BuildContext context) {
//     // ... coming soon screen
//   }
// }
