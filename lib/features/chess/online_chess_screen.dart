import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/online_chess_provider.dart';
import '../../providers/online_provider.dart';
import '../../services/online_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import 'chess_screen.dart'; // reuse ChessBoard widget

class OnlineChessScreen extends ConsumerStatefulWidget {
  const OnlineChessScreen({super.key});

  @override
  ConsumerState<OnlineChessScreen> createState() => _OnlineChessScreenState();
}

class _OnlineChessScreenState extends ConsumerState<OnlineChessScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final roomId = ref.watch(roomIdProvider);
    final gameAsync = ref.watch(onlineChessStateProvider);
    final service = ref.read(onlineServiceProvider);
    final myUid = service.currentUid;

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C2E),
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

            final myPlayerIdx = gameState.players.indexWhere(
              (p) => p.id == myUid,
            );
            final isMyTurn =
                gameState.currentPlayerIndex == myPlayerIdx &&
                gameState.phase == GamePhase.playing;
            final iAmWhite = myPlayerIdx == 0;

            return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [Color(0xFF2D2D44), Color(0xFF1C1C2E)],
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Top bar
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
                                'CHESS — ONLINE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            // Online indicator
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

                      // Opponent info
                      PlayerBar(
                        player: gameState.players[iAmWhite ? 1 : 0],
                        isActive:
                            gameState.currentPlayerIndex == (iAmWhite ? 1 : 0),
                        isWhite: !iAmWhite,
                        isOnline: true,
                      ),

                      const SizedBox(height: 4),

                      // Board — flipped for black player
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ChessBoard(
                                state: gameState,
                                flipped: !iAmWhite,
                                onSquareTap: isMyTurn && !_isProcessing
                                    ? (sq) => _onSquareTap(roomId, sq, service)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // My info
                      PlayerBar(
                        player: gameState.players[iAmWhite ? 0 : 1],
                        isActive:
                            gameState.currentPlayerIndex == (iAmWhite ? 0 : 1),
                        isWhite: iAmWhite,
                        isOnline: true,
                      ),

                      // Status
                      if (gameState.message != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            gameState.message!,
                            style: TextStyle(
                              color: gameState.isCheck
                                  ? Colors.red
                                  : AppTheme.textLight,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (!isMyTurn && gameState.phase == GamePhase.playing)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.textDim,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Waiting for opponent...',
                                style: TextStyle(
                                  color: AppTheme.textDim,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Game over
                if (gameState.phase == GamePhase.gameOver)
                  ChessGameOver(
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
    String square,
    OnlineService service,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await service.chessSelectSquare(roomId, square);
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
