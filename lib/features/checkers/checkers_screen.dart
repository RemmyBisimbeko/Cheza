import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/checkers_provider.dart';
import '../../providers/setup_provider.dart';
import '../../core/models/checkers/checkers_piece.dart';
import '../../core/models/checkers/checkers_state.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/models/player.dart';
import '../game/widgets/game_over_overlay.dart';

class CheckersScreen extends ConsumerWidget {
  const CheckersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(checkersProvider);
    final notifier = ref.read(checkersProvider.notifier);

    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final setup = ref.read(setupProvider);
        final players = [
          Player(
            id: 'red_player',
            name: setup.playerName,
            type: PlayerType.human,
          ),
          Player(id: 'black_player', name: 'CPU', type: PlayerType.ai),
        ];
        notifier.startGame(players);
      });
      return const Scaffold(
        backgroundColor: Color(0xFF1B3A2D),
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    final humanPlayer = gameState.players.firstWhere(
      (p) => p.type == PlayerType.human,
      orElse: () => gameState.players.first,
    );
    final isMyTurn =
        gameState.currentPlayer.id == humanPlayer.id &&
        gameState.phase == GamePhase.playing;

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: const Color(0xFF1B3A2D),
        body: Stack(
          children: [
            // Background
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
                  // ── Top Bar ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
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
                          'CHECKERS',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppTheme.textDim,
                          ),
                          onPressed: () {
                            final setup = ref.read(setupProvider);
                            final players = [
                              Player(
                                id: 'red_player',
                                name: setup.playerName,
                                type: PlayerType.human,
                              ),
                              Player(
                                id: 'black_player',
                                name: 'CPU',
                                type: PlayerType.ai,
                              ),
                            ];
                            notifier.startGame(players);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Score Bar ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CheckersPieceCounter(
                          color: PieceColor.red,
                          count: gameState.redCount,
                          label: humanPlayer.name,
                          isActive: gameState.currentColor == PieceColor.red,
                        ),
                        // Turn indicator
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
                            isMyTurn ? 'Your turn' : 'CPU thinking...',
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
                          label: 'CPU',
                          isActive: gameState.currentColor == PieceColor.black,
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
                          child: CheckersBoard(
                            state: gameState,
                            onSquareTap: isMyTurn ? notifier.selectPiece : null,
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
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Game Over ─────────────────────────
            if (gameState.phase == GamePhase.gameOver)
              CheckersGameOver(
                state: gameState,
                onPlayAgain: () {
                  final setup = ref.read(setupProvider);
                  notifier.startGame([
                    Player(
                      id: 'red_player',
                      name: setup.playerName,
                      type: PlayerType.human,
                    ),
                    Player(
                      id: 'black_player',
                      name: 'CPU',
                      type: PlayerType.ai,
                    ),
                  ]);
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

// ── Board Widget ───────────────────────────────────────
class CheckersBoard extends StatelessWidget {
  final CheckersState state;
  final void Function(int row, int col)? onSquareTap;

  const CheckersBoard({required this.state, required this.onSquareTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final col = index % 8;
            return CheckersBoardSquare(
              row: row,
              col: col,
              state: state,
              onTap: onSquareTap != null ? () => onSquareTap!(row, col) : null,
            );
          },
        ),
      ),
    );
  }
}

// ── Board Square ───────────────────────────────────────
class CheckersBoardSquare extends StatelessWidget {
  final int row;
  final int col;
  final CheckersState state;
  final VoidCallback? onTap;

  const CheckersBoardSquare({
    required this.row,
    required this.col,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = (row + col) % 2 == 1;
    final piece = state.board[row][col];

    final isSelected =
        state.selectedPiece?.row == row && state.selectedPiece?.col == col;

    final isValidDest = state.validMoves.any(
      (m) =>
          m.toRow == row &&
          m.toCol == col &&
          (state.selectedPiece == null ||
              (m.fromRow == state.selectedPiece!.row &&
                  m.fromCol == state.selectedPiece!.col)),
    );

    Color squareColor;
    if (isSelected) {
      squareColor = AppTheme.accent.withOpacity(0.5);
    } else if (isValidDest && isDark) {
      squareColor = Colors.green.withOpacity(0.4);
    } else if (isDark) {
      squareColor = const Color(0xFF5D4037);
    } else {
      squareColor = const Color(0xFFD7CCC8);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        child: piece != null
            ? Center(
                child:
                    CheckersPieceWidget(piece: piece, isSelected: isSelected)
                        .animate(key: ValueKey('${row}_$col'))
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1, 1),
                          duration: 200.ms,
                        ),
              )
            : isValidDest && isDark
            ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ── Piece Widget ───────────────────────────────────────
class CheckersPieceWidget extends StatelessWidget {
  final CheckersPiece piece;
  final bool isSelected;

  const CheckersPieceWidget({required this.piece, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isRed = piece.color == PieceColor.red;
    final pieceColor = isRed
        ? const Color(0xFFEF5350)
        : const Color(0xFF212121);
    final borderColor = isRed
        ? const Color(0xFFB71C1C)
        : const Color(0xFF424242);

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pieceColor,
        border: Border.all(
          color: isSelected ? AppTheme.accent : borderColor,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: isSelected ? 8 : 3,
            offset: const Offset(1, 2),
          ),
          if (isSelected)
            BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 10),
        ],
      ),
      child: piece.isKing
          ? Center(
              child: Text(
                '♛',
                style: TextStyle(
                  fontSize: 14,
                  color: isRed ? Colors.white : Colors.amber,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Piece Counter ──────────────────────────────────────
class CheckersPieceCounter extends StatelessWidget {
  final PieceColor color;
  final int count;
  final String label;
  final bool isActive;

  const CheckersPieceCounter({
    required this.color,
    required this.count,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = color == PieceColor.red;
    final pieceColor = isRed
        ? const Color(0xFFEF5350)
        : const Color(0xFF424242);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? pieceColor.withOpacity(0.2) : Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? pieceColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: pieceColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.textLight : AppTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count pieces',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Game Over ──────────────────────────────────────────
class CheckersGameOver extends StatelessWidget {
  final CheckersState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const CheckersGameOver({
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

    return Container(
      color: Colors.black54,
      child: Center(
        child:
            Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accent, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isHumanWinner ? '🏆' : '😔',
                    style: const TextStyle(fontSize: 56),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isHumanWinner ? 'You Win!' : '${winner.name} Wins!',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message ?? '',
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
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
                  ),
                ],
              ),
            ).animate().scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 400.ms,
            ),
      ),
    );
  }
}
