import 'package:chess/chess.dart' as ch;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chess_provider.dart';
import '../../providers/setup_provider.dart';
import '../../core/models/chess/chess_state.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/models/player.dart';

class ChessScreen extends ConsumerStatefulWidget {
  const ChessScreen({super.key});

  @override
  ConsumerState<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends ConsumerState<ChessScreen> {
  ChessDifficulty _difficulty = ChessDifficulty.easy;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    if (gameState == null) {
      return DifficultyPicker(
        selected: _difficulty,
        onSelect: (d) => setState(() => _difficulty = d),
        onStart: () {
          final setup = ref.read(setupProvider);
          notifier.startGame([
            Player(
              id: 'white_player',
              name: setup.playerName,
              type: PlayerType.human,
            ),
            Player(
              id: 'black_player',
              name: _difficultyName(_difficulty),
              type: PlayerType.ai,
            ),
          ], _difficulty);
        },
        onBack: () => context.go('/'),
      );
    }

    final isMyTurn =
        gameState.currentPlayer.type == PlayerType.human &&
        gameState.phase == GamePhase.playing;

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C2E),
        body: Stack(
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
                  // ── Top Bar ───────────────────────
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
                            notifier.resetGame();
                            context.go('/');
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'CHESS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor(
                              gameState.difficulty,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _difficultyColor(gameState.difficulty),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _difficultyName(gameState.difficulty),
                            style: TextStyle(
                              color: _difficultyColor(gameState.difficulty),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppTheme.textDim,
                          ),
                          onPressed: () => notifier.resetGame(),
                        ),
                      ],
                    ),
                  ),

                  // ── Black player (top) ────────────
                  PlayerBar(
                    player: gameState.players[1],
                    isActive: gameState.currentPlayerIndex == 1,
                    isWhite: false,
                  ),

                  const SizedBox(height: 4),

                  // ── Board ─────────────────────────
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ChessBoard(
                            state: gameState,
                            flipped: false, // human is always white vs AI
                            onSquareTap: isMyTurn
                                ? notifier.selectSquare
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── White player (bottom) ─────────
                  PlayerBar(
                    player: gameState.players[0],
                    isActive: gameState.currentPlayerIndex == 0,
                    isWhite: true,
                  ),

                  // ── Status message ────────────────
                  if (gameState.message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: gameState.isCheck
                              ? Colors.red.withOpacity(0.2)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                          border: gameState.isCheck
                              ? Border.all(color: Colors.red, width: 1)
                              : null,
                        ),
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
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Game Over ─────────────────────────
            if (gameState.phase == GamePhase.gameOver)
              ChessGameOver(
                state: gameState,
                onPlayAgain: () => notifier.resetGame(),
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

  String _difficultyName(ChessDifficulty d) {
    switch (d) {
      case ChessDifficulty.easy:
        return 'Easy';
      case ChessDifficulty.medium:
        return 'Medium';
      case ChessDifficulty.hard:
        return 'Hard';
    }
  }

  Color _difficultyColor(ChessDifficulty d) {
    switch (d) {
      case ChessDifficulty.easy:
        return Colors.green;
      case ChessDifficulty.medium:
        return Colors.orange;
      case ChessDifficulty.hard:
        return Colors.red;
    }
  }
}

// ── Difficulty Picker ──────────────────────────────────
class DifficultyPicker extends StatelessWidget {
  final ChessDifficulty selected;
  final void Function(ChessDifficulty) onSelect;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const DifficultyPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C2E),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF2D2D44), Color(0xFF1C1C2E)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textLight,
                        ),
                        onPressed: onBack,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('♟️', style: TextStyle(fontSize: 64))
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 16),
                        const Text(
                          'CHESS',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose difficulty',
                          style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),

                        ...[
                          ChessDifficulty.easy,
                          ChessDifficulty.medium,
                          ChessDifficulty.hard,
                        ].map((d) {
                          final isSelected = selected == d;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => onSelect(d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _difficultyColor(d).withOpacity(0.15)
                                      : Colors.black26,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? _difficultyColor(d)
                                        : Colors.white12,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _difficultyEmoji(d),
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _difficultyName(d),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? _difficultyColor(d)
                                                  : AppTheme.textLight,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            _difficultyDesc(d),
                                            style: const TextStyle(
                                              color: AppTheme.textDim,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: _difficultyColor(d),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: AppTheme.cardBlack,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'START GAME',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyName(ChessDifficulty d) {
    switch (d) {
      case ChessDifficulty.easy:
        return 'Easy';
      case ChessDifficulty.medium:
        return 'Stockfish';
      case ChessDifficulty.hard:
        return 'Minimax';
    }
  }

  String _difficultyEmoji(ChessDifficulty d) {
    switch (d) {
      case ChessDifficulty.easy:
        return '🐣';
      case ChessDifficulty.medium:
        return '🤖';
      case ChessDifficulty.hard:
        return '🧠';
    }
  }

  String _difficultyDesc(ChessDifficulty d) {
    switch (d) {
      case ChessDifficulty.easy:
        return 'Random moves — perfect for beginners';
      case ChessDifficulty.medium:
        return 'Powered by Stockfish — strong play';
      case ChessDifficulty.hard:
        return 'Minimax AI — think carefully!';
    }
  }

  Color _difficultyColor(ChessDifficulty d) {
    switch (d) {
      case ChessDifficulty.easy:
        return Colors.green;
      case ChessDifficulty.medium:
        return Colors.orange;
      case ChessDifficulty.hard:
        return Colors.red;
    }
  }
}

// ── Chess Board ────────────────────────────────────────
class ChessBoard extends StatelessWidget {
  final ChessState state;
  final void Function(String square)? onSquareTap;
  final bool flipped;

  const ChessBoard({
    super.key,
    required this.state,
    this.onSquareTap,
    this.flipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: List.generate(8, (rankIdx) {
            final rank = flipped ? rankIdx + 1 : 8 - rankIdx;
            return Expanded(
              child: Row(
                children: List.generate(8, (fileIdx) {
                  final file = flipped ? 7 - fileIdx : fileIdx;
                  const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
                  final square = '${files[file]}$rank';
                  return Expanded(
                    child: ChessSquare(
                      square: square,
                      rank: rank,
                      file: file,
                      state: state,
                      onTap: onSquareTap != null
                          ? () => onSquareTap!(square)
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Chess Square ───────────────────────────────────────
class ChessSquare extends StatelessWidget {
  final String square;
  final int rank;
  final int file;
  final ChessState state;
  final VoidCallback? onTap;

  const ChessSquare({
    super.key,
    required this.square,
    required this.rank,
    required this.file,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = (rank + file) % 2 == 1;
    final isSelected = state.selectedSquare == square;
    final isValidDest = state.validMoves.any(
      (m) => m.length >= 4 && m.substring(2, 4) == square,
    );

    final chess = ch.Chess.fromFEN(state.fen);
    final piece = chess.get(square);

    final isKingInCheck =
        state.isCheck &&
        piece?.type == ch.PieceType.KING &&
        ((state.currentPlayerIndex == 0 && piece?.color == ch.Color.WHITE) ||
            (state.currentPlayerIndex == 1 && piece?.color == ch.Color.BLACK));

    Color squareColor;
    if (isKingInCheck) {
      squareColor = Colors.red.withOpacity(0.6);
    } else if (isSelected) {
      squareColor = AppTheme.accent.withOpacity(0.5);
    } else if (isLight) {
      squareColor = const Color(0xFFF0D9B5);
    } else {
      squareColor = const Color(0xFFB58863);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        child: Stack(
          children: [
            if (isValidDest)
              Center(
                child: Container(
                  width: piece == null ? 20 : double.infinity,
                  height: piece == null ? 20 : double.infinity,
                  margin: piece != null ? const EdgeInsets.all(2) : null,
                  decoration: BoxDecoration(
                    shape: piece == null ? BoxShape.circle : BoxShape.rectangle,
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: piece != null
                        ? BorderRadius.circular(4)
                        : null,
                    border: piece != null
                        ? Border.all(color: Colors.black38, width: 2)
                        : null,
                  ),
                ),
              ),

            if (piece != null)
              Center(
                child: Text(
                  _pieceEmoji(piece),
                  style: TextStyle(
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            if (file == 0)
              Positioned(
                top: 2,
                left: 2,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 9,
                    color: isLight
                        ? const Color(0xFFB58863)
                        : const Color(0xFFF0D9B5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (rank == 1)
              Positioned(
                bottom: 2,
                right: 2,
                child: Text(
                  String.fromCharCode(97 + file),
                  style: TextStyle(
                    fontSize: 9,
                    color: isLight
                        ? const Color(0xFFB58863)
                        : const Color(0xFFF0D9B5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _pieceEmoji(ch.Piece piece) {
    final isWhite = piece.color == ch.Color.WHITE;
    switch (piece.type) {
      case ch.PieceType.PAWN:
        return isWhite ? '♙' : '♟';
      case ch.PieceType.ROOK:
        return isWhite ? '♖' : '♜';
      case ch.PieceType.KNIGHT:
        return isWhite ? '♘' : '♞';
      case ch.PieceType.BISHOP:
        return isWhite ? '♗' : '♝';
      case ch.PieceType.QUEEN:
        return isWhite ? '♕' : '♛';
      case ch.PieceType.KING:
        return isWhite ? '♔' : '♚';
      default:
        return '';
    }
  }
}

// ── Player Bar ─────────────────────────────────────────
class PlayerBar extends StatelessWidget {
  final Player player;
  final bool isActive;
  final bool isWhite;
  final bool isOnline;

  const PlayerBar({
    super.key,
    required this.player,
    required this.isActive,
    required this.isWhite,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withOpacity(0.1) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              isWhite ? '♔' : '♚',
              style: TextStyle(
                fontSize: 24,
                color: isWhite ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.accent : AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isWhite ? 'White' : 'Black',
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Game Over ──────────────────────────────────────────
class ChessGameOver extends StatelessWidget {
  final ChessState state;
  final VoidCallback? onPlayAgain;
  final VoidCallback onHome;

  const ChessGameOver({
    super.key,
    required this.state,
    this.onPlayAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final winner = state.winnerId != null
        ? state.players.firstWhere(
            (p) => p.id == state.winnerId,
            orElse: () => state.players.first,
          )
        : null;
    final isDraw = state.isStalemate || winner == null;
    final isHumanWinner = winner?.type == PlayerType.human;

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
                    isDraw
                        ? '🤝'
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
                  Text(
                    isDraw
                        ? 'Draw!'
                        : isHumanWinner
                        ? 'You Win!'
                        : '${winner?.name} Wins!',
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
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onPlayAgain != null) ...[
                        ElevatedButton(
                          onPressed: onPlayAgain,
                          child: const Text('Play Again'),
                        ),
                        const SizedBox(width: 12),
                      ],
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
