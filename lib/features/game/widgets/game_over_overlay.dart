import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/enums.dart';

class GameOverOverlay extends StatelessWidget {
  final GameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const GameOverOverlay({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final winner = state.players.firstWhere(
      (p) => p.id == state.winnerId,
      orElse: () => state.players.first,
    );
    final isHumanWinner = winner.type == PlayerType.human;
    final wasChopped = state.chopperPlayerId != null;

    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child:
              Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.3),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Emoji ──────────────────────────────
                        Text(
                          wasChopped
                              ? '✂️'
                              : isHumanWinner
                              ? '🏆'
                              : '😔',
                          style: const TextStyle(fontSize: 56),
                        ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),

                        const SizedBox(height: 12),

                        // ── How game ended ─────────────────────
                        if (wasChopped)
                          Text(
                            'Game Cut by ${state.players.firstWhere((p) => p.id == state.chopperPlayerId, orElse: () => state.players.first).name}!',
                            style: const TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 13,
                            ),
                          ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 6),

                        // ── Winner ─────────────────────────────
                        Text(
                              isHumanWinner
                                  ? 'You Win!'
                                  : '${winner.name} Wins!',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 4),

                        Text(
                          isHumanWinner
                              ? 'Congratulations! 🎉'
                              : 'Better luck next time!',
                          style: const TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 14,
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        // ── Score breakdown (chopper only) ─────
                        if (wasChopped && state.scores.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          const Text(
                            'SCORES',
                            style: TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...state.players.map((p) {
                            final pts = state.scores[p.id] ?? 0;
                            final isWinner = p.id == state.winnerId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isWinner)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6),
                                          child: Text(
                                            '👑',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      Text(
                                        p.name,
                                        style: TextStyle(
                                          color: isWinner
                                              ? AppTheme.accent
                                              : AppTheme.textDim,
                                          fontWeight: isWinner
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isWinner
                                          ? AppTheme.accent.withOpacity(0.15)
                                          : Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$pts pts',
                                      style: TextStyle(
                                        color: isWinner
                                            ? AppTheme.accent
                                            : AppTheme.textDim,
                                        fontWeight: isWinner
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),

                        // ── Buttons ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: onPlayAgain,
                              child: const Text('Play Again'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: onHome,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textLight,
                                side: const BorderSide(color: AppTheme.textDim),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Home'),
                            ),
                          ],
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 300.ms),
        ),
      ),
    );
  }
}
