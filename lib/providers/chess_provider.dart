import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/engine/chess_engine.dart';
import '../core/models/chess/chess_state.dart';
import '../core/models/player.dart';
import '../core/constants/enums.dart';
import '../core/models/app_settings.dart';
import 'settings_provider.dart';

final chessEngineProvider = Provider<ChessEngine>((_) => ChessEngine());

class ChessNotifier extends StateNotifier<ChessState?> {
  final ChessEngine _engine;
  final AppSettings _settings;

  ChessNotifier(this._engine, this._settings) : super(null);

  Duration get _aiDelay {
    if (_settings.aiSpeed == AiSpeed.slow) {
      return const Duration(milliseconds: 2000);
    } else if (_settings.aiSpeed == AiSpeed.fast) {
      return const Duration(milliseconds: 300);
    }
    return const Duration(milliseconds: 800);
  }

  void startGame(List<Player> players, ChessDifficulty difficulty) {
    state = _engine.initGame(players, difficulty);
  }

  void selectSquare(String square) {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.playing) return;
    if (current.currentPlayer.type != PlayerType.human) return;

    state = _engine.selectSquare(current, square);

    // If a move was made (selected piece is now null)
    if (state?.selectedSquare == null &&
        state?.moveHistory.length != current.moveHistory.length) {
      _runAiTurn();
    }
  }

  void _runAiTurn() {
    Future.delayed(_aiDelay, () async {
      final current = state;
      if (current == null) return;
      if (current.phase == GamePhase.gameOver) return;
      if (current.currentPlayer.type != PlayerType.ai) return;

      ChessState newState;

      switch (current.difficulty) {
        case ChessDifficulty.easy:
          newState = _engine.easyAiMove(current);
        case ChessDifficulty.medium:
          newState = await _engine.stockfishMove(current);
        case ChessDifficulty.hard:
          newState = _engine.minimaxMove(current);
      }

      state = newState;
    });
  }

  void resetGame() => state = null;
}

final chessProvider = StateNotifierProvider<ChessNotifier, ChessState?>(
  (ref) => ChessNotifier(
    ref.watch(chessEngineProvider),
    ref.watch(settingsProvider),
  ),
);
