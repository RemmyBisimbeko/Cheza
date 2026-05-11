import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cheza_games/core/models/app_settings.dart';
import 'package:cheza_games/providers/settings_provider.dart';
import 'package:cheza_games/services/profile_service.dart';
import 'package:cheza_games/services/sound_service.dart';
import '../core/engine/game_engine.dart';
import '../core/models/game_state.dart';
import '../core/models/player.dart';
import '../core/models/playing_card.dart';
import '../core/constants/enums.dart';

// ── Engine provider ───────────────────────────────────
final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

// ── Game Notifier ─────────────────────────────────────
class GameNotifier extends StateNotifier<GameState?> {
  final GameEngine _engine;
  final SoundService _sound;
  final ProfileService _profileService;
  final AppSettings _settings;

  GameNotifier(this._engine, this._sound, this._profileService, this._settings)
    : super(null);

  // ── AI delay based on settings ────────────────────────
  Duration get _aiDelay {
    if (_settings.aiSpeed == AiSpeed.slow) {
      return const Duration(milliseconds: 2000);
    } else if (_settings.aiSpeed == AiSpeed.fast) {
      return const Duration(milliseconds: 300);
    }
    return const Duration(milliseconds: 800);
  }

  // ── Start game ────────────────────────────────────────
  void startGame(List<Player> players) {
    _sound.playShuffle();
    state = _engine.initGame(players);
  }

  // ── Play card ─────────────────────────────────────────
  void playCard(PlayingCard card, {Suit? chosenSuit}) {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.playing &&
        current.phase != GamePhase.awaitingSuit)
      return;
    if (current.currentPlayer.type != PlayerType.human) return;
    if (!_engine.canPlay(card, current)) return;

    _sound.playCardPlay();
    state = _engine.playCard(card, current, chosenSuit: chosenSuit);

    _checkGameOver();
    _runAiTurns();
  }

  // ── Draw card ─────────────────────────────────────────
  void drawCard() {
    final current = state;
    if (current == null) return;
    if (current.currentPlayer.type != PlayerType.human) return;

    _sound.playCardDraw();
    state = _engine.drawCard(current);

    _checkGameOver();
    _runAiTurns();
  }

  // ── Declare suit after Ace ────────────────────────────
  void declareSuit(Suit suit) {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.awaitingSuit) return;

    state = _engine.playCard(
      current.topCard,
      current.copyWith(phase: GamePhase.playing),
      chosenSuit: suit,
    );

    _runAiTurns();
  }

  // ── Call Matatu ───────────────────────────────────────
  void callMatatu() {
    final current = state;
    if (current == null) return;

    final players = List<Player>.from(current.players);
    final idx = current.currentPlayerIndex;

    if (players[idx].hand.length == 1) {
      players[idx].hasCalledMatatu = true;
      state = current.copyWith(
        players: players,
        message: '🎉 ${players[idx].name} calls Matatu!',
      );
    }
  }

  // ── Reset ─────────────────────────────────────────────
  void resetGame() => state = null;

  // ── Check game over and record result ─────────────────
  void _checkGameOver() {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.gameOver) return;

    final humanPlayer = current.players.firstWhere(
      (p) => p.type == PlayerType.human,
      orElse: () => current.players.first,
    );

    final won = current.winnerId == humanPlayer.id;

    // Determine game mode
    final hasRemote = current.players.any((p) => p.type == PlayerType.remote);
    final humanCount = current.players
        .where((p) => p.type == PlayerType.human)
        .length;
    final mode = current.players.any((p) => p.type == PlayerType.remote)
        ? 'online'
        : 'vsAI';

    // Record result — single call, no duplicates
    _profileService.recordResult(
      won: won,
      mode: mode,
      displayName: humanPlayer.name,
    );

    // Play win/lose sound
    if (won) {
      _sound.playWin();
    } else {
      _sound.playLose();
    }
  }

  // ── AI Logic ──────────────────────────────────────────

  void _runAiTurns() {
    Future.doWhile(() async {
      await Future.delayed(_aiDelay);

      final current = state;
      if (current == null) return false;
      if (current.phase == GamePhase.gameOver) return false;

      // ✅ Only auto-declare suit if it's the AI's turn
      if (current.phase == GamePhase.awaitingSuit) {
        if (current.currentPlayer.type != PlayerType.human) {
          _aiDeclareSuit();
        }
        return false; // always stop loop — human or AI, wait for input
      }

      if (current.currentPlayer.type == PlayerType.human) return false;

      _takeAiTurn();
      return true;
    });
  }

  void _takeAiTurn() {
    final current = state;
    if (current == null) return;

    final ai = current.currentPlayer;

    final playable = ai.hand
        .where((card) => _engine.canPlay(card, current))
        .toList();

    if (playable.isEmpty) {
      state = _engine.drawCard(current);
      _checkGameOver();
      return;
    }

    final card = _chooseBestCard(playable, current);

    Suit? chosenSuit;
    if (card.rank == Rank.ace) {
      chosenSuit = _mostCommonSuit(ai.hand);
    }

    state = _engine.playCard(card, current, chosenSuit: chosenSuit);
    _checkGameOver();

    // AI calls Matatu when 1 card left
    final newState = state;
    if (newState != null && newState.phase != GamePhase.gameOver) {
      final aiInNew = newState.players.firstWhere(
        (p) => p.id == ai.id,
        orElse: () => ai,
      );
      if (aiInNew.hand.length == 1 && !aiInNew.hasCalledMatatu) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final s = state;
          if (s == null) return;
          final players = List<Player>.from(s.players);
          final aiIdx = players.indexWhere((p) => p.id == ai.id);
          if (aiIdx != -1 && players[aiIdx].hand.length == 1) {
            players[aiIdx].hasCalledMatatu = true;
            state = s.copyWith(
              players: players,
              message: '🤖 ${ai.name} calls Matatu!',
            );
          }
        });
      }
    }
  }

  void _aiDeclareSuit() {
    final current = state;
    if (current == null) return;
    final suit = _mostCommonSuit(current.currentPlayer.hand);
    state = _engine.playCard(
      current.topCard,
      current.copyWith(phase: GamePhase.playing),
      chosenSuit: suit,
    );
  }

  PlayingCard _chooseBestCard(List<PlayingCard> playable, GameState state) {
    if (state.pendingPickUp > 0) {
      return playable.firstWhere(
        (c) => c.rank == Rank.two,
        orElse: () => playable.first,
      );
    }
    return playable.firstWhere(
      (c) => c.isSpecial,
      orElse: () => playable.first,
    );
  }

  Suit _mostCommonSuit(List<PlayingCard> hand) {
    final counts = <Suit, int>{};
    for (final card in hand) {
      counts[card.suit] = (counts[card.suit] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

// ── Provider ──────────────────────────────────────────
final gameProvider = StateNotifierProvider<GameNotifier, GameState?>(
  (ref) => GameNotifier(
    ref.watch(gameEngineProvider),
    ref.watch(soundServiceProvider),
    ref.watch(profileServiceProvider),
    ref.watch(settingsProvider),
  ),
);
