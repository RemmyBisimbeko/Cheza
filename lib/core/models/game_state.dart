import 'playing_card.dart';
import 'player.dart';
import '../constants/enums.dart';

class GameState {
  final List<Player> players;
  final List<PlayingCard> deck;
  final List<PlayingCard> discardPile;
  final int currentPlayerIndex;
  final Suit? declaredSuit; // active when Ace is played
  final int pendingPickUp; // accumulated pick-2 stacking
  final bool isClockwise;
  final GamePhase phase;
  final String? winnerId;
  final String? message; // e.g. "Player 2 picks 2!"
  final String? chopperPlayerId; // who played the 7
  final Map<String, int> scores; // uid → hand point total
  final PlayingCard? cutCard; // the base card placed under deck at start


  const GameState({
    required this.players,
    required this.deck,
    required this.discardPile,
    required this.currentPlayerIndex,
    this.declaredSuit,
    this.pendingPickUp = 0,
    this.isClockwise = true,
    this.phase = GamePhase.waiting,
    this.winnerId,
    this.message,
    this.chopperPlayerId,
    this.cutCard,
    this.scores = const {},
  });

  Map<String, dynamic> toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'discardPile': discardPile.map((c) => c.toJson()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'declaredSuit': declaredSuit?.name,
    'pendingPickUp': pendingPickUp,
    'isClockwise': isClockwise,
    'phase': phase.name,
    'winnerId': winnerId,
    'message': message,
    // Note: deck is NOT shared — stored separately
  };

  PlayingCard get topCard => discardPile.last;
  Player get currentPlayer => players[currentPlayerIndex];

  GameState copyWith({
    List<Player>? players,
    List<PlayingCard>? deck,
    List<PlayingCard>? discardPile,
    int? currentPlayerIndex,
    Suit? declaredSuit,
    bool clearDeclaredSuit = false,
    int? pendingPickUp,
    bool? isClockwise,
    GamePhase? phase,
    String? winnerId,
    String? message,
    String? chopperPlayerId,
    PlayingCard? cutCard,
    Map<String, int>? scores,
  }) {
    return GameState(
      players: players ?? this.players,
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      declaredSuit: clearDeclaredSuit
          ? null
          : (declaredSuit ?? this.declaredSuit),
      pendingPickUp: pendingPickUp ?? this.pendingPickUp,
      isClockwise: isClockwise ?? this.isClockwise,
      phase: phase ?? this.phase,
      winnerId: winnerId ?? this.winnerId,
      message: message ?? this.message,
      chopperPlayerId: chopperPlayerId ?? this.chopperPlayerId,
      cutCard: cutCard ?? this.cutCard,
      scores: scores ?? this.scores,
    );
  }

  static int cardPoints(PlayingCard card) {
    switch (card.rank) {
      case Rank.ace:
        return 15;
      case Rank.two:
        return 25;
      case Rank.king:
        return 13;
      case Rank.queen:
        return 12;
      case Rank.jack:
        return 11;
      case Rank.ten:
        return 10;
      case Rank.nine:
        return 9;
      case Rank.eight:
        return 8;
      case Rank.seven:
        return 7;
      case Rank.six:
        return 6;
      case Rank.five:
        return 5;
      case Rank.four:
        return 4;
      case Rank.three:
        return 3;
    }
  }

  static int handPoints(List<PlayingCard> hand) =>
      hand.fold(0, (sum, card) => sum + cardPoints(card));

  factory GameState.fromJson(
    Map<String, dynamic> json, {
    List<PlayingCard> deck = const [],
  }) {
    return GameState(
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      deck: deck,
      discardPile: (json['discardPile'] as List)
          .map((c) => PlayingCard.fromJson(c))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex'] ?? 0,
      declaredSuit: json['declaredSuit'] != null
          ? Suit.values.byName(json['declaredSuit'])
          : null,
      pendingPickUp: json['pendingPickUp'] ?? 0,
      isClockwise: json['isClockwise'] ?? true,
      phase: GamePhase.values.byName(json['phase'] ?? 'playing'),
      winnerId: json['winnerId'],
      message: json['message'],
    );
  }
}
