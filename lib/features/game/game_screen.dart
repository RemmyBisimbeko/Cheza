import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cheza_games/core/models/game_registry.dart';
import 'package:cheza_games/features/chess/chess_screen.dart';
import 'package:cheza_games/features/ludo/ludo_screen.dart';
import 'package:cheza_games/services/sound_service.dart';
import '../../providers/game_provider.dart';
import '../../providers/setup_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/engine/game_engine.dart';
import '../../core/models/player.dart';
import 'widgets/opponent_row.dart';
import 'widgets/game_table.dart';
import 'widgets/player_hand.dart';
import 'widgets/game_over_overlay.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final engine = ref.watch(gameEngineProvider);
    final notifier = ref.read(gameProvider.notifier);
    final setup = ref.watch(setupProvider);

    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final players = ref.read(setupProvider).buildPlayers();
        notifier.startGame(players);
      });
      return const Scaffold(
        backgroundColor: AppTheme.tableGreen,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    // Route to correct game
    if (setup.gameType == GameType.checkers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/checkers');
      });
      return const Scaffold(
        backgroundColor: AppTheme.tableGreen,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (setup.gameType == GameType.ludo) {
      return const LudoScreen();
    }
    if (setup.gameType == GameType.chess) {
      return const ChessScreen();
    }
    if (setup.gameType != GameType.matatu) {
      return Scaffold(
        backgroundColor: AppTheme.tableGreen,
        body: Center(
          child: Text(
            '${GameRegistry.getGame(setup.gameType).name} coming soon!',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 18),
          ),
        ),
      );
    }

    final opponents = gameState.players
        .where((p) => p.type != PlayerType.human)
        .toList();

    final humanPlayer = gameState.players.firstWhere(
      (p) => p.type == PlayerType.human,
      orElse: () => gameState.players.first,
    );

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: AppTheme.tableGreen,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [AppTheme.tableFelt, AppTheme.tableGreen],
                ),
              ),
            ),

            // Main layout — SingleChildScrollView prevents overflow
            SafeArea(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: // Replace the back button row with:
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.textLight,
                              ),
                              onPressed: () {
                                notifier.resetGame();
                                context.go('/');
                              },
                            ),
                            const Text(
                              'MATATU',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mute button
                                Consumer(
                                  builder: (context, ref, _) {
                                    final sound = ref.watch(
                                      soundServiceProvider,
                                    );
                                    return IconButton(
                                      icon: Icon(
                                        sound.isMuted
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                        color: AppTheme.textDim,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(soundServiceProvider)
                                            .toggleMute();
                                        // Trigger rebuild
                                        (ref as WidgetRef).invalidate(
                                          soundServiceProvider,
                                        );
                                      },
                                    );
                                  },
                                ),
                                // Matatu button
                                TextButton(
                                  onPressed: humanPlayer.hand.length == 1
                                      ? notifier.callMatatu
                                      : null,
                                  child: Text(
                                    'MATATU!',
                                    style: TextStyle(
                                      color: humanPlayer.hand.length == 1
                                          ? AppTheme.accent
                                          : AppTheme.textDim,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Opponents
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: opponents
                              .map(
                                (o) => OpponentRow(
                                  player: o,
                                  isCurrentTurn:
                                      gameState.currentPlayer.id == o.id,
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      // Game table — fills remaining space
                      Expanded(
                        child: Center(
                          child: GameTable(
                            state: gameState,
                            onDraw: notifier.drawCard,
                            onSuitSelected: notifier.declareSuit,
                          ),
                        ),
                      ),

                      // Player hand
                      PlayerHand(
                        state: gameState,
                        engine: engine,
                        onCardPlayed: (card) => notifier.playCard(card),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // Game over overlay
            if (gameState.phase == GamePhase.gameOver)
              GameOverOverlay(
                state: gameState,
                onPlayAgain: () {
                  final players = ref.read(setupProvider).buildPlayers();
                  notifier.startGame(players);
                },
                onHome: () {
                  notifier.resetGame();
                  context.go('/');
                },
              ),
          ],
        ),
      ),
    );
  }
}
