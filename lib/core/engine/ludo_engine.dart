import 'dart:math';
import '../models/ludo/ludo_token.dart';
import '../models/ludo/ludo_state.dart';
import '../models/player.dart';
import '../constants/enums.dart';

class LudoEngine {
  final Random _random = Random();

  // ── Board constants ───────────────────────────────────

  // Each player's starting position on the main track
  static const Map<LudoColor, int> startPositions = {
    LudoColor.red: 0,
    LudoColor.blue: 13,
    LudoColor.green: 26,
    LudoColor.yellow: 39,
  };

  // Each player's home column entry point
  static const Map<LudoColor, int> homeEntries = {
    LudoColor.red: 50,
    LudoColor.blue: 11,
    LudoColor.green: 24,
    LudoColor.yellow: 37,
  };

  // Safe squares — cannot be captured here
  static const List<int> safeSquares = [0, 8, 13, 21, 26, 34, 39, 47];

  // Colors in player order
  static const List<LudoColor> playerColors = [
    LudoColor.red,
    LudoColor.blue,
    LudoColor.green,
    LudoColor.yellow,
  ];

  // ── Init ──────────────────────────────────────────────

  LudoState initGame(List<Player> players) {
    final tokens = <List<LudoToken>>[];

    for (int i = 0; i < players.length; i++) {
      final color = playerColors[i];
      tokens.add(
        List.generate(
          4,
          (j) => LudoToken(
            color: color,
            id: j,
            state: TokenState.home,
            position: -1,
          ),
        ),
      );
    }

    return LudoState(
      players: players,
      currentPlayerIndex: 0,
      phase: GamePhase.playing,
      gameType: GameType.ludo,
      tokens: tokens,
      diceValue: 0,
      diceRolled: false,
      message: '${players[0].name}\'s turn — roll the dice!',
    );
  }

  // ── Roll Dice ─────────────────────────────────────────

  LudoState rollDice(LudoState state) {
    if (state.diceRolled) return state;

    final value = _random.nextInt(6) + 1;
    final player = state.players[state.currentPlayerIndex];
    final color = playerColors[state.currentPlayerIndex];
    final playerTokens = state.tokens[state.currentPlayerIndex];

    // Check if player has any valid moves
    final hasMovable = _hasMovableToken(playerTokens, value, color);

    String message;
    if (value == 6) {
      message = '🎲 ${player.name} rolled a 6!';
    } else {
      message = '🎲 ${player.name} rolled $value';
    }

    if (!hasMovable) {
      // No valid moves — skip turn
      return _nextTurn(
        state.copyWith(
          diceValue: value,
          diceRolled: true,
          message: '$message — no valid moves, skip!',
        ),
      );
    }

    return state.copyWith(diceValue: value, diceRolled: true, message: message);
  }

  // ── Move Token ────────────────────────────────────────

  LudoState moveToken(LudoState state, int playerIndex, int tokenId) {
    if (!state.diceRolled) return state;
    if (playerIndex != state.currentPlayerIndex) return state;

    final color = playerColors[playerIndex];
    final token = state.tokens[playerIndex][tokenId];
    final diceValue = state.diceValue;

    // Validate move
    if (!_canMove(token, diceValue, color)) return state;

    // Deep copy tokens
    final newTokens = state.tokens
        .map((pt) => List<LudoToken>.from(pt))
        .toList();

    LudoToken movedToken;
    String message = '';
    bool captured = false;

    if (token.isHome && diceValue == 6) {
      // Enter board
      final startPos = startPositions[color]!;
      movedToken = token.copyWith(state: TokenState.active, position: startPos);
      message = '🚀 ${state.players[playerIndex].name} enters the board!';
    } else if (token.isActive) {
      // Calculate new position
      final newPos = _calculateNewPosition(token, diceValue, color);

      if (newPos == -2) return state; // Invalid move

      if (newPos >= 58) {
        // Reached home!
        movedToken = token.copyWith(state: TokenState.finished, position: 58);
        message = '🏠 Token reached home!';
      } else {
        movedToken = token.copyWith(position: newPos);

        // Check captures (only on main track 0-51)
        if (newPos < 52 && !safeSquares.contains(newPos)) {
          for (int pi = 0; pi < state.players.length; pi++) {
            if (pi == playerIndex) continue;
            for (int ti = 0; ti < newTokens[pi].length; ti++) {
              final enemy = newTokens[pi][ti];
              if (enemy.isActive &&
                  _getAbsolutePosition(enemy.position, playerColors[pi]) ==
                      _getAbsolutePosition(newPos, color)) {
                // Send enemy home!
                newTokens[pi][ti] = enemy.copyWith(
                  state: TokenState.home,
                  position: -1,
                );
                captured = true;
                message =
                    '💥 ${state.players[playerIndex].name} sent ${state.players[pi].name}\'s token home!';
              }
            }
          }
        }
      }
    } else {
      return state; // Can't move finished tokens
    }

    newTokens[playerIndex][tokenId] = movedToken;

    // Check win
    final allFinished = newTokens[playerIndex].every((t) => t.isFinished);
    if (allFinished) {
      return state.copyWith(
        tokens: newTokens,
        phase: GamePhase.gameOver,
        winnerId: state.players[playerIndex].id,
        message: '🏆 ${state.players[playerIndex].name} wins!',
      );
    }

    // Rolled 6 or captured = bonus turn
    final getBonus = diceValue == 6 || captured;

    if (getBonus) {
      return state.copyWith(
        tokens: newTokens,
        diceRolled: false,
        diceValue: 0,
        bonusTurn: true,
        message: message.isEmpty ? '🎲 Roll again!' : '$message Roll again!',
      );
    }

    // Normal — next turn
    return _nextTurn(state.copyWith(tokens: newTokens, message: message));
  }

  // ── Helpers ───────────────────────────────────────────

  LudoState _nextTurn(LudoState state) {
    final nextIdx = (state.currentPlayerIndex + 1) % state.players.length;
    return state.copyWith(
      currentPlayerIndex: nextIdx,
      diceRolled: false,
      diceValue: 0,
      bonusTurn: false,
      message: '${state.players[nextIdx].name}\'s turn — roll the dice!',
    );
  }

  bool _hasMovableToken(
    List<LudoToken> tokens,
    int diceValue,
    LudoColor color,
  ) {
    return tokens.any((t) => _canMove(t, diceValue, color));
  }

  bool _canMove(LudoToken token, int diceValue, LudoColor color) {
    if (token.isFinished) return false;
    if (token.isHome) return diceValue == 6;
    if (token.isActive) {
      final newPos = _calculateNewPosition(token, diceValue, color);
      return newPos != -2;
    }
    return false;
  }

  int _calculateNewPosition(LudoToken token, int diceValue, LudoColor color) {
    final homeEntry = homeEntries[color]!;
    final currentPos = token.position;

    // Check if entering home column
    final distToHomeEntry = (homeEntry - currentPos + 52) % 52;

    if (diceValue <= distToHomeEntry) {
      // Still on main track
      return (currentPos + diceValue) % 52;
    } else {
      // Entering home column (positions 52-57)
      final homeColPos = 52 + (diceValue - distToHomeEntry - 1);
      if (homeColPos > 57) return -2; // Overshot
      return homeColPos;
    }
  }

  // Convert relative position to absolute for capture detection
  int _getAbsolutePosition(int relPos, LudoColor color) {
    if (relPos >= 52) return relPos; // In home column
    final start = startPositions[color]!;
    return (start + relPos) % 52;
  }

  // ── AI ────────────────────────────────────────────────

  LudoState takeAiTurn(LudoState state) {
    // Roll dice
    var newState = rollDice(state);

    if (!newState.diceRolled) return newState;

    final playerIndex = newState.currentPlayerIndex;
    final color = playerColors[playerIndex];
    final tokens = newState.tokens[playerIndex];
    final dice = newState.diceValue;

    // Find best token to move
    int? bestToken;

    // Priority 1: finish a token
    for (int i = 0; i < tokens.length; i++) {
      if (!_canMove(tokens[i], dice, color)) continue;
      if (tokens[i].isActive) {
        final newPos = _calculateNewPosition(tokens[i], dice, color);
        if (newPos >= 58) {
          bestToken = i;
          break;
        }
      }
    }

    // Priority 2: capture an enemy
    if (bestToken == null) {
      for (int i = 0; i < tokens.length; i++) {
        if (!_canMove(tokens[i], dice, color)) continue;
        if (tokens[i].isActive) {
          final newPos = _calculateNewPosition(tokens[i], dice, color);
          if (newPos < 52 && !safeSquares.contains(newPos)) {
            // Check if any enemy is here
            for (int pi = 0; pi < state.players.length; pi++) {
              if (pi == playerIndex) continue;
              final enemyColor = playerColors[pi];
              for (final enemy in state.tokens[pi]) {
                if (enemy.isActive &&
                    _getAbsolutePosition(enemy.position, enemyColor) ==
                        _getAbsolutePosition(newPos, color)) {
                  bestToken = i;
                  break;
                }
              }
              if (bestToken != null) break;
            }
          }
        }
        if (bestToken != null) break;
      }
    }

    // Priority 3: enter board on 6
    if (bestToken == null && dice == 6) {
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].isHome) {
          bestToken = i;
          break;
        }
      }
    }

    // Priority 4: move furthest active token
    if (bestToken == null) {
      int furthest = -1;
      for (int i = 0; i < tokens.length; i++) {
        if (!_canMove(tokens[i], dice, color)) continue;
        if (tokens[i].isActive && tokens[i].position > furthest) {
          furthest = tokens[i].position;
          bestToken = i;
        }
      }
    }

    if (bestToken == null) return _nextTurn(newState);

    return moveToken(newState, playerIndex, bestToken);
  }
}
