import 'dart:math';
import '../models/playing_card.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import '../constants/enums.dart';

class GameEngine {
  final Random _random = Random();

  // ── Deck ──────────────────────────────────────────────

  List<PlayingCard> buildDeck() {
    return [
      for (final suit in Suit.values)
        for (final rank in Rank.values) PlayingCard(suit: suit, rank: rank),
    ];
  }

  List<PlayingCard> shuffle(List<PlayingCard> deck) {
    final d = List<PlayingCard>.from(deck);
    d.shuffle(_random);
    return d;
  }

  // ── Game Setup ────────────────────────────────────────

  GameState initGame(List<Player> players) {
    var deck = shuffle(buildDeck());

    final dealt = List<Player>.from(
      players.map(
        (p) => Player(id: p.id, name: p.name, type: p.type, hand: []),
      ),
    );

    // Deal 7 cards each
    for (int i = 0; i < 7; i++) {
      for (final player in dealt) {
        player.hand.add(deck.removeAt(0));
      }
    }

    // First discard must not be a special card
    PlayingCard firstCard;
    int attempts = 0;
    do {
      firstCard = deck.removeAt(0);
      if (firstCard.isSpecial) {
        deck.add(firstCard);
      }
      attempts++;
      if (attempts > 52) break; // safety valve
    } while (firstCard.isSpecial);

    // ✅ Cut card — random card placed face-up under deck
    // Must not be a 7 (to avoid confusion) and not the same as firstCard
    PlayingCard cutCard;
    do {
      cutCard = deck.removeAt(0);
      if (cutCard.rank == Rank.seven) deck.add(cutCard);
    } while (cutCard.rank == Rank.seven);

    // Place cut card at bottom of deck (visible but not drawable)
    // We just store it separately — deck stays normal

    return GameState(
      players: dealt,
      deck: deck,
      discardPile: [firstCard],
      currentPlayerIndex: 0,
      phase: GamePhase.playing,
      isClockwise: true,
      cutCard: cutCard, // ✅ store cut card
    );
  }

  // ── Validation ────────────────────────────────────────

  bool canPlay(PlayingCard card, GameState state) {
    final top = state.topCard;
    final effectiveSuit = state.declaredSuit ?? top.suit;

    // During pending pickup, only a 2 can be stacked
    if (state.pendingPickUp > 0) {
      return card.rank == Rank.two;
    }

    // Ace can be played on anything
    if (card.rank == Rank.ace) return true;

    // All other cards (including all 7s) must match suit or rank
    return card.suit == effectiveSuit || card.rank == top.rank;
  }

  bool hasPlayableCard(Player player, GameState state) {
    return player.hand.any((card) => canPlay(card, state));
  }

  // ── Play Card ─────────────────────────────────────────

  GameState playCard(PlayingCard card, GameState state, {Suit? chosenSuit}) {
    final playerIndex = state.currentPlayerIndex;
    final players = state.players
        .map(
          (p) => Player(
            id: p.id,
            name: p.name,
            type: p.type,
            hand: List<PlayingCard>.from(p.hand),
            hasCalledMatatu: p.hasCalledMatatu,
          ),
        )
        .toList();

    final player = players[playerIndex];
    player.hand.removeWhere((c) => c.suit == card.suit && c.rank == card.rank);

    final newDiscard = List<PlayingCard>.from(state.discardPile)..add(card);

    // Check empty hand win
    if (player.hand.isEmpty) {
      return state.copyWith(
        players: players,
        discardPile: newDiscard,
        phase: GamePhase.gameOver,
        winnerId: player.id,
        message: '🎉 ${player.name} wins!',
        clearDeclaredSuit: true,
      );
    }

    final newState = state.copyWith(players: players, discardPile: newDiscard);

    // ✅ Check chopper HERE — only 7 matching cut card suit
    if (card.rank == Rank.seven &&
        state.cutCard != null &&
        card.suit == state.cutCard!.suit) {
      return _applyChopper(card, newState);
    }

    // All other cards including non-matching 7s go through normal effect
    return _applyEffect(card, newState, chosenSuit: chosenSuit);
  }

  GameState _applyEffect(
    PlayingCard card,
    GameState state, {
    Suit? chosenSuit,
  }) {
    switch (card.effect) {
      // ── Skip (8 or Jack) ──────────────────────────────
      case SpecialEffect.skip:
        final skippedName = _playerAt(state, skip: 1).name;
        return state.copyWith(
          currentPlayerIndex: _nextIndex(state, skip: 1),
          message: '⏭ $skippedName is skipped!',
          clearDeclaredSuit: true,
          pendingPickUp: 0,
        );

      // ── Pick Two (2) ──────────────────────────────────
      case SpecialEffect.pickTwo:
        final newPending = state.pendingPickUp + 2;
        final nextIdx = _nextIndex(state);
        final nextName = state.players[nextIdx].name;
        return state.copyWith(
          currentPlayerIndex: nextIdx,
          pendingPickUp: newPending,
          message: '🃏 $nextName picks up $newPending!',
          clearDeclaredSuit: true,
        );

      // ── Reverse (King) ────────────────────────────────
      case SpecialEffect.reverse:
        final newClockwise = !state.isClockwise;
        final nextIdx = _nextIndexWithDirection(state, clockwise: newClockwise);
        return state.copyWith(
          currentPlayerIndex: nextIdx,
          isClockwise: newClockwise,
          message: '🔄 Direction reversed!',
          clearDeclaredSuit: true,
          pendingPickUp: 0,
        );

      // ── Change Suit (Ace) ─────────────────────────────
      case SpecialEffect.changeSuit:
        if (chosenSuit != null) {
          return state.copyWith(
            currentPlayerIndex: _nextIndex(state),
            declaredSuit: chosenSuit,
            message: '♠ Suit changed to ${chosenSuit.name}!',
            pendingPickUp: 0,
          );
        }
        // Await suit choice from player
        return state.copyWith(phase: GamePhase.awaitingSuit);

      // ── Chopper (7) ───────────────────────────────────
      case SpecialEffect.chopper:
        return _applyChopper(card, state);

      // ── Normal card ───────────────────────────────────
      default:
        return state.copyWith(
          currentPlayerIndex: _nextIndex(state),
          clearDeclaredSuit: true,
          pendingPickUp: 0,
          message: null,
        );
    }
  }

  // ── Chopper Logic ─────────────────────────────────────

  GameState _applyChopper(PlayingCard card, GameState state) {
    // Calculate scores for all players
    final scores = <String, int>{};
    for (final player in state.players) {
      scores[player.id] = GameState.handPoints(player.hand);
    }

    // Find winner — lowest score
    final currentPlayer = state.currentPlayer;
    String winnerId = currentPlayer.id;
    int lowestScore = scores[currentPlayer.id]!;

    for (final entry in scores.entries) {
      if (entry.value < lowestScore) {
        lowestScore = entry.value;
        winnerId = entry.key;
      }
    }

    final winner = state.players.firstWhere((p) => p.id == winnerId);

    // Build score summary message
    final scoreSummary = state.players
        .map((p) => '${p.name}: ${scores[p.id]} pts')
        .join(' · ');

    return state.copyWith(
      phase: GamePhase.gameOver,
      winnerId: winnerId,
      chopperPlayerId: currentPlayer.id,
      scores: scores,
      message:
          '✂️ Game cut by ${currentPlayer.name}!\n'
          '🏆 ${winner.name} wins!\n$scoreSummary',
    );
  }

  // ── Draw Card ─────────────────────────────────────────

  GameState drawCard(GameState state) {
    var deck = List<PlayingCard>.from(state.deck);
    var discard = List<PlayingCard>.from(state.discardPile);
    final players = state.players
        .map(
          (p) => Player(
            id: p.id,
            name: p.name,
            type: p.type,
            hand: List<PlayingCard>.from(p.hand),
            hasCalledMatatu: p.hasCalledMatatu,
          ),
        )
        .toList();

    final player = players[state.currentPlayerIndex];

    // Reshuffle discard into deck if empty
    if (deck.isEmpty) {
      final top = discard.removeLast();
      deck = shuffle(discard);
      discard = [top];
    }

    final drawCount = state.pendingPickUp > 0 ? state.pendingPickUp : 1;
    final safeCount = drawCount.clamp(0, deck.length);
    final drawn = deck.take(safeCount).toList();
    deck.removeRange(0, safeCount);

    player.hand.addAll(drawn);

    return state.copyWith(
      players: players,
      deck: deck,
      discardPile: discard,
      pendingPickUp: 0,
      currentPlayerIndex: _nextIndex(state),
      clearDeclaredSuit: false,
      message:
          '${player.name} draws $safeCount card${safeCount != 1 ? 's' : ''}',
    );
  }

  // ── Index Helpers ─────────────────────────────────────

  int _nextIndex(GameState state, {int skip = 0}) {
    return _nextIndexWithDirection(
      state,
      clockwise: state.isClockwise,
      skip: skip,
    );
  }

  int _nextIndexWithDirection(
    GameState state, {
    required bool clockwise,
    int skip = 0,
  }) {
    final count = state.players.length;
    final step = clockwise ? 1 : -1;
    return ((state.currentPlayerIndex + step * (1 + skip)) % count + count) %
        count;
  }

  Player _playerAt(GameState state, {int skip = 0}) {
    return state.players[_nextIndex(state, skip: skip)];
  }
}
