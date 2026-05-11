import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cheza_games/core/engine/ludo_engine.dart';
import '../../providers/ludo_provider.dart';
import '../../providers/setup_provider.dart';
import '../../core/models/ludo/ludo_token.dart';
import '../../core/models/ludo/ludo_state.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/models/player.dart';

class LudoScreen extends ConsumerWidget {
  const LudoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(ludoProvider);
    final notifier = ref.read(ludoProvider.notifier);

    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final setup = ref.read(setupProvider);
        final count = setup.playerCount.clamp(2, 4);
        final colors = ['red', 'blue', 'green', 'yellow'];
        final names = [setup.playerName, 'CPU 1', 'CPU 2', 'CPU 3'];
        final players = List.generate(
          count,
          (i) => Player(
            id: '${colors[i]}_player',
            name: names[i],
            type: i == 0 ? PlayerType.human : PlayerType.ai,
          ),
        );
        notifier.startGame(players);
      });
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    final isMyTurn =
        gameState.currentPlayer.type == PlayerType.human &&
        gameState.phase == GamePhase.playing;

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [Color(0xFF16213E), Color(0xFF0F0E17)],
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
                          'LUDO',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppTheme.textDim,
                          ),
                          onPressed: () {
                            final setup = ref.read(setupProvider);
                            final count = setup.playerCount.clamp(2, 4);
                            final colors = ['red', 'blue', 'green', 'yellow'];
                            final names = [
                              setup.playerName,
                              'CPU 1',
                              'CPU 2',
                              'CPU 3',
                            ];
                            notifier.startGame(
                              List.generate(
                                count,
                                (i) => Player(
                                  id: '${colors[i]}_player',
                                  name: names[i],
                                  type: i == 0
                                      ? PlayerType.human
                                      : PlayerType.ai,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Board ─────────────────────────
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _LudoBoard(
                            state: gameState,
                            onTokenTap: isMyTurn ? notifier.moveToken : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Controls ──────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Message
                        if (gameState.message != null)
                          Text(
                            gameState.message!,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 12),

                        // Dice + Roll button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dice face
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: gameState.diceRolled
                                    ? AppTheme.accent.withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.accent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  gameState.diceValue == 0
                                      ? '🎲'
                                      : _diceFace(gameState.diceValue),
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Roll button
                            ElevatedButton(
                              onPressed: isMyTurn && !gameState.diceRolled
                                  ? notifier.rollDice
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: AppTheme.cardBlack,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isMyTurn && !gameState.diceRolled
                                    ? 'Roll Dice!'
                                    : isMyTurn
                                    ? 'Pick a token'
                                    : 'Waiting...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Game Over ─────────────────────────
            if (gameState.phase == GamePhase.gameOver)
              _LudoGameOver(
                state: gameState,
                onPlayAgain: () {
                  final setup = ref.read(setupProvider);
                  final count = setup.playerCount.clamp(2, 4);
                  final colors = ['red', 'blue', 'green', 'yellow'];
                  final names = [setup.playerName, 'CPU 1', 'CPU 2', 'CPU 3'];
                  notifier.startGame(
                    List.generate(
                      count,
                      (i) => Player(
                        id: '${colors[i]}_player',
                        name: names[i],
                        type: i == 0 ? PlayerType.human : PlayerType.ai,
                      ),
                    ),
                  );
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

  String _diceFace(int value) {
    const faces = ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[value];
  }
}

// ── Ludo Board ─────────────────────────────────────────
class _LudoBoard extends StatelessWidget {
  final LudoState state;
  final void Function(int tokenId)? onTokenTap;

  const _LudoBoard({required this.state, this.onTokenTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 15,
          ),
          itemCount: 225,
          itemBuilder: (context, index) {
            final row = index ~/ 15;
            final col = index % 15;
            return _LudoCell(
              row: row,
              col: col,
              state: state,
              onTokenTap: onTokenTap,
            );
          },
        ),
      ),
    );
  }
}

// ── Ludo Cell ──────────────────────────────────────────
class _LudoCell extends StatelessWidget {
  final int row;
  final int col;
  final LudoState state;
  final void Function(int tokenId)? onTokenTap;

  const _LudoCell({
    required this.row,
    required this.col,
    required this.state,
    this.onTokenTap,
  });

  @override
  Widget build(BuildContext context) {
    final cellType = _getCellType(row, col);
    final bgColor = _getCellColor(row, col, cellType);

    // Find tokens on this cell
    final tokensHere = _getTokensOnCell(row, col);

    return GestureDetector(
      onTap: tokensHere.isNotEmpty && onTokenTap != null
          ? () {
              final humanTokens = tokensHere.where(
                (t) => state.tokens[state.currentPlayerIndex].any(
                  (pt) => pt.id == t.id && pt.color == t.color,
                ),
              );
              if (humanTokens.isNotEmpty) {
                onTokenTap!(humanTokens.first.id);
              }
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black12, width: 0.3),
        ),
        child: tokensHere.isNotEmpty
            ? Center(
                child: tokensHere.length == 1
                    ? _TokenDot(token: tokensHere.first)
                    : Stack(
                        children: tokensHere
                            .take(4)
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (e) => Positioned(
                                top: e.key < 2 ? 0 : null,
                                bottom: e.key >= 2 ? 0 : null,
                                left: e.key % 2 == 0 ? 0 : null,
                                right: e.key % 2 == 1 ? 0 : null,
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: _TokenDot(token: e.value),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              )
            : cellType == 'star'
            ? const Center(
                child: Text(
                  '★',
                  style: TextStyle(fontSize: 8, color: Colors.black45),
                ),
              )
            : null,
      ),
    );
  }

  List<LudoToken> _getTokensOnCell(int row, int col) {
    final tokens = <LudoToken>[];
    // Check home bases
    for (int pi = 0; pi < state.tokens.length; pi++) {
      for (final token in state.tokens[pi]) {
        if (_tokenIsOnCell(token, pi, row, col)) {
          tokens.add(token);
        }
      }
    }
    return tokens;
  }

  bool _tokenIsOnCell(LudoToken token, int playerIndex, int row, int col) {
    if (token.isHome) {
      return _isHomeBase(row, col, token.color, token.id);
    }
    if (token.isFinished) {
      return _isCenterCell(row, col);
    }
    if (token.isActive) {
      final trackCell = _trackToCell(token.position, token.color);
      return trackCell != null && trackCell[0] == row && trackCell[1] == col;
    }
    return false;
  }

  bool _isCenterCell(int row, int col) =>
      row >= 6 && row <= 8 && col >= 6 && col <= 8;

  bool _isHomeBase(int row, int col, LudoColor color, int tokenId) {
    // Each color's home base occupies a 6x6 corner
    switch (color) {
      case LudoColor.red:
        return row < 6 && col < 6 && _isTokenSlot(row, col, tokenId, 1, 1);
      case LudoColor.blue:
        return row < 6 && col > 8 && _isTokenSlot(row, col, tokenId, 1, 10);
      case LudoColor.yellow:
        return row > 8 && col < 6 && _isTokenSlot(row, col, tokenId, 10, 1);
      case LudoColor.green:
        return row > 8 && col > 8 && _isTokenSlot(row, col, tokenId, 10, 10);
    }
  }

  bool _isTokenSlot(int row, int col, int tokenId, int baseRow, int baseCol) {
    final slots = [
      [baseRow + 1, baseCol + 1],
      [baseRow + 1, baseCol + 3],
      [baseRow + 3, baseCol + 1],
      [baseRow + 3, baseCol + 3],
    ];
    if (tokenId >= slots.length) return false;
    return row == slots[tokenId][0] && col == slots[tokenId][1];
  }

  List<int>? _trackToCell(int position, LudoColor color) {
    // Map absolute board position to grid cell
    // Main track: 52 squares around the board
    // Home column: 6 squares leading to center
    if (position >= 52) {
      // Home column
      final homeColCells = _getHomeColumnCells(color);
      final idx = position - 52;
      if (idx < homeColCells.length) return homeColCells[idx];
      return null;
    }

    // Adjust position relative to this color's start
    final start = LudoEngine.startPositions[color]!;
    final absPos = (start + position) % 52;
    return _mainTrackCell(absPos);
  }

  List<int> _mainTrackCell(int absPos) {
    // 52-cell main track mapped to 15x15 grid
    // Top row going right (0-5): row=6, col=1-6 (skip home areas)
    // etc. — simplified mapping
    const track = [
      [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], // 0-4
      [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6], // 5-10
      [0, 7], // 11 (top entry)
      [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], // 12-17
      [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14], // 18-23
      [7, 14], // 24 (right entry)
      [8, 14], [8, 13], [8, 12], [8, 11], [8, 10], [8, 9], // 25-30
      [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8], // 31-36
      [14, 7], // 37 (bottom entry)
      [14, 6], [13, 6], [12, 6], [11, 6], [10, 6], [9, 6], // 38-43
      [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0], // 44-49
      [7, 0], // 50 (left entry)
      [6, 0], // 51
    ];
    if (absPos >= track.length) return [7, 7];
    return track[absPos];
  }

  List<List<int>> _getHomeColumnCells(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return [
          [7, 1],
          [7, 2],
          [7, 3],
          [7, 4],
          [7, 5],
          [7, 6],
        ];
      case LudoColor.blue:
        return [
          [1, 7],
          [2, 7],
          [3, 7],
          [4, 7],
          [5, 7],
          [6, 7],
        ];
      case LudoColor.green:
        return [
          [7, 13],
          [7, 12],
          [7, 11],
          [7, 10],
          [7, 9],
          [7, 8],
        ];
      case LudoColor.yellow:
        return [
          [13, 7],
          [12, 7],
          [11, 7],
          [10, 7],
          [9, 7],
          [8, 7],
        ];
    }
  }

  String _getCellType(int row, int col) {
    // Home bases (corners)
    if ((row < 6 && col < 6) ||
        (row < 6 && col > 8) ||
        (row > 8 && col < 6) ||
        (row > 8 && col > 8))
      return 'home';

    // Center finishing area
    if (row >= 6 && row <= 8 && col >= 6 && col <= 8) {
      return 'center';
    }

    // Safe squares
    const safeCoords = [
      [6, 1], [1, 8], [8, 13], [13, 6], // entry squares
      [6, 2], [2, 8], [8, 12], [12, 6], // near entries
    ];
    for (final s in safeCoords) {
      if (s[0] == row && s[1] == col) return 'star';
    }

    // Track squares
    if ((row == 6 || row == 7 || row == 8) ||
        (col == 6 || col == 7 || col == 8)) {
      return 'track';
    }

    return 'empty';
  }

  Color _getCellColor(int row, int col, String type) {
    if (type == 'empty') return Colors.transparent;

    if (type == 'center') {
      // Color quadrants of center
      if (row == 6 && col == 6) return const Color(0xFFEF5350).withOpacity(0.8);
      if (row == 6 && col == 8) return const Color(0xFF42A5F5).withOpacity(0.8);
      if (row == 8 && col == 6) return const Color(0xFFFFCA28).withOpacity(0.8);
      if (row == 8 && col == 8) return const Color(0xFF66BB6A).withOpacity(0.8);
      return Colors.white.withOpacity(0.9);
    }

    if (type == 'home') {
      if (row < 6 && col < 6) return const Color(0xFFEF5350).withOpacity(0.8);
      if (row < 6 && col > 8) return const Color(0xFF42A5F5).withOpacity(0.8);
      if (row > 8 && col < 6) return const Color(0xFFFFCA28).withOpacity(0.8);
      if (row > 8 && col > 8) return const Color(0xFF66BB6A).withOpacity(0.8);
    }

    // Home columns
    if (row == 7 && col > 0 && col < 6) {
      return const Color(0xFFEF5350).withOpacity(0.4);
    }
    if (col == 7 && row > 0 && row < 6) {
      return const Color(0xFF42A5F5).withOpacity(0.4);
    }
    if (row == 7 && col > 8 && col < 14) {
      return const Color(0xFF66BB6A).withOpacity(0.4);
    }
    if (col == 7 && row > 8 && row < 14) {
      return const Color(0xFFFFCA28).withOpacity(0.4);
    }

    if (type == 'star') return Colors.amber.withOpacity(0.3);

    return Colors.white.withOpacity(0.85);
  }
}

// ── Token Dot ──────────────────────────────────────────
class _TokenDot extends StatelessWidget {
  final LudoToken token;

  const _TokenDot({required this.token});

  @override
  Widget build(BuildContext context) {
    final color = _tokenColor(token.color);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black45, width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
      ),
    );
  }

  Color _tokenColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return const Color(0xFFEF5350);
      case LudoColor.blue:
        return const Color(0xFF42A5F5);
      case LudoColor.green:
        return const Color(0xFF66BB6A);
      case LudoColor.yellow:
        return const Color(0xFFFFCA28);
    }
  }
}

// ── Game Over ──────────────────────────────────────────
class _LudoGameOver extends StatelessWidget {
  final LudoState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _LudoGameOver({
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
                  const SizedBox(height: 24),
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
