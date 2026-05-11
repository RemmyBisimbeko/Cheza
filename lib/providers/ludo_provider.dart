import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/engine/ludo_engine.dart';
import '../core/models/ludo/ludo_state.dart';
import '../core/models/player.dart';
import '../core/constants/enums.dart';
import '../core/models/app_settings.dart';
import 'settings_provider.dart';

final ludoEngineProvider = Provider<LudoEngine>((_) => LudoEngine());

class LudoNotifier extends StateNotifier<LudoState?> {
  final LudoEngine _engine;
  final AppSettings _settings;

  LudoNotifier(this._engine, this._settings) : super(null);

  Duration get _aiDelay {
    if (_settings.aiSpeed == AiSpeed.slow) {
      return const Duration(milliseconds: 2000);
    } else if (_settings.aiSpeed == AiSpeed.fast) {
      return const Duration(milliseconds: 400);
    }
    return const Duration(milliseconds: 900);
  }

  void startGame(List<Player> players) {
    state = _engine.initGame(players);
  }

  void rollDice() {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.playing) return;
    if (current.diceRolled) return;

    // Only human can call this
    if (current.currentPlayer.type != PlayerType.human) return;

    state = _engine.rollDice(current);

    // Check if turn was skipped (no moves)
    _checkAiTurn();
  }

  void moveToken(int tokenId) {
    final current = state;
    if (current == null) return;
    if (!current.diceRolled) return;
    if (current.currentPlayer.type != PlayerType.human) return;

    state = _engine.moveToken(current, current.currentPlayerIndex, tokenId);

    _checkAiTurn();
  }

  void _checkAiTurn() {
    Future.delayed(_aiDelay, () {
      final current = state;
      if (current == null) return;
      if (current.phase == GamePhase.gameOver) return;
      if (current.currentPlayer.type != PlayerType.ai) return;

      state = _engine.takeAiTurn(current);

      // Chain AI turns
      if (state?.phase != GamePhase.gameOver) {
        if (state?.currentPlayer.type == PlayerType.ai) {
          _checkAiTurn();
        }
      }
    });
  }

  void resetGame() => state = null;
}

final ludoProvider = StateNotifierProvider<LudoNotifier, LudoState?>(
  (ref) =>
      LudoNotifier(ref.watch(ludoEngineProvider), ref.watch(settingsProvider)),
);
