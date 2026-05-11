import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/online_checkers_provider.dart';
import '../../providers/online_provider.dart';
import '../../services/online_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/models/checkers/checkers_piece.dart';
import 'checkers_screen.dart';

class OnlineCheckersScreen extends ConsumerStatefulWidget {
  const OnlineCheckersScreen({super.key});

  @override
  ConsumerState<OnlineCheckersScreen> createState() =>
      _OnlineCheckersScreenState();
}

class _OnlineCheckersScreenState extends ConsumerState<OnlineCheckersScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final roomId = ref.watch(roomIdProvider);
    final gameAsync = ref.watch(onlineCheckersStateProvider);
    final service = ref.read(onlineServiceProvider);
    final myUid = service.currentUid;

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: const Color(0xFF1B3A2D),
        body: gameAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppTheme.textLight),
            ),
          ),
          data: (gameState) {
            if (gameState == null || roomId == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              );
            }

            // Determine which color I am
            final myPlayerIdx = gameState.players.indexWhere(
              (p) => p.id == myUid,
            );
            final myColor = myPlayerIdx == 0
                ? PieceColor.red
                : PieceColor.black;

            // Flip board for black player
            final shouldFlip = myColor == PieceColor.black;

            final isMyTurn =
                gameState.currentColor == myColor &&
                gameState.phase == GamePhase.playing;

            return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [Color(0xFF2D5A3D), Color(0xFF1B3A2D)],
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // ── Top bar ───────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.textLight,
                              ),
                              onPressed: () {
                                ref.read(roomIdProvider.notifier).state = null;
                                context.go('/');
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'CHECKERS — ONLINE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Score bar ─────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CheckersPieceCounter(
                              color: PieceColor.red,
                              count: gameState.redCount,
                              label: gameState.players[0].name,
                              isActive:
                                  gameState.currentColor == PieceColor.red,
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isMyTurn
                                    ? AppTheme.accent.withOpacity(0.2)
                                    : Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isMyTurn
                                      ? AppTheme.accent
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                isMyTurn ? 'Your turn' : 'Waiting...',
                                style: TextStyle(
                                  color: isMyTurn
                                      ? AppTheme.accent
                                      : AppTheme.textDim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CheckersPieceCounter(
                              color: PieceColor.black,
                              count: gameState.blackCount,
                              label: gameState.players.length > 1
                                  ? gameState.players[1].name
                                  : 'Player 2',
                              isActive:
                                  gameState.currentColor == PieceColor.black,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Board ─────────────────────────
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Transform.rotate(
                                angle: shouldFlip ? 3.14159 : 0,
                                child: CheckersBoard(
                                  state: gameState,
                                  onSquareTap: isMyTurn && !_isProcessing
                                      ? (r, c) {
                                          // Flip coords back when board is rotated
                                          final actualRow = shouldFlip
                                              ? 7 - r
                                              : r;
                                          final actualCol = shouldFlip
                                              ? 7 - c
                                              : c;
                                          _onSquareTap(
                                            roomId,
                                            actualRow,
                                            actualCol,
                                            service,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Message ───────────────────────
                      if (gameState.message != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            gameState.message!,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // ── Game over ─────────────────────────
                if (gameState.phase == GamePhase.gameOver)
                  CheckersGameOver(
                    state: gameState,
                    onPlayAgain: () {
                      ref.read(roomIdProvider.notifier).state = null;
                      context.go('/');
                    },
                    onHome: () {
                      ref.read(roomIdProvider.notifier).state = null;
                      context.go('/');
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSquareTap(
    String roomId,
    int row,
    int col,
    OnlineService service,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await service.checkersSelectSquare(roomId, row, col);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
