import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/engine/checkers_engine.dart';
import '../core/models/checkers/checkers_state.dart';
import '../core/models/checkers/checkers_move.dart';
import '../core/models/checkers/checkers_piece.dart';
import '../core/models/player.dart';
import '../core/constants/enums.dart';
import '../providers/settings_provider.dart';
import '../core/models/app_settings.dart';

final checkersEngineProvider = Provider<CheckersEngine>(
  (_) => CheckersEngine(),
);

class CheckersNotifier extends StateNotifier<CheckersState?> {
  final CheckersEngine _engine;
  final AppSettings _settings;

  CheckersNotifier(this._engine, this._settings) : super(null);

  Duration get _aiDelay {
    if (_settings.aiSpeed == AiSpeed.slow) {
      return const Duration(milliseconds: 2000);
    } else if (_settings.aiSpeed == AiSpeed.fast) {
      return const Duration(milliseconds: 300);
    }
    return const Duration(milliseconds: 800);
  }

  void startGame(List<Player> players) {
    state = _engine.initGame(players);
  }

  void selectPiece(int row, int col) {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.playing) return;

    final piece = current.board[row][col];

    // Tapping an empty square or opponent piece
    if (piece == null || piece.color != current.currentColor) {
      // Check if it's a valid move destination
      if (current.selectedPiece != null) {
        final move = current.validMoves.firstWhere(
          (m) =>
              m.toRow == row &&
              m.toCol == col &&
              m.fromRow == current.selectedPiece!.row &&
              m.fromCol == current.selectedPiece!.col,
          orElse: () =>
              CheckersMove(fromRow: -1, fromCol: -1, toRow: -1, toCol: -1),
        );

        if (move.fromRow != -1) {
          _applyMove(move);
          return;
        }
      }

      state = current.copyWith(clearSelected: true, validMoves: []);
      return;
    }

    // Select this piece
    final moves = _engine.getMovesForPiece(current, row, col);
    state = current.copyWith(selectedPiece: piece, validMoves: moves);
  }

  void _applyMove(CheckersMove move) {
    final current = state;
    if (current == null) return;

    state = _engine.applyMove(move, current);

    if (state?.phase == GamePhase.gameOver) return;

    // Trigger AI turn
    _runAiTurn();
  }

  void _runAiTurn() {
    Future.delayed(_aiDelay, () {
      final current = state;
      if (current == null) return;
      if (current.phase == GamePhase.gameOver) return;

      // Check if current player is AI
      final currentPlayer = current.players[current.currentPlayerIndex];
      if (currentPlayer.type != PlayerType.ai) return;

      final move = _engine.getBestAiMove(current);
      if (move == null) return;

      state = _engine.applyMove(move, current);

      // Chain AI turns if multiple AI players
      if (state?.phase != GamePhase.gameOver) {
        final next = state?.players[state!.currentPlayerIndex];
        if (next?.type == PlayerType.ai) {
          _runAiTurn();
        }
      }
    });
  }

  void resetGame() => state = null;
}

final checkersProvider =
    StateNotifierProvider<CheckersNotifier, CheckersState?>(
      (ref) => CheckersNotifier(
        ref.watch(checkersEngineProvider),
        ref.watch(settingsProvider),
      ),
    );
