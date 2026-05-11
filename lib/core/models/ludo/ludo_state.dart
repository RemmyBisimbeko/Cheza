import '../base_game_state.dart';
import '../player.dart';
import '../../constants/enums.dart';
import 'ludo_token.dart';

class LudoState extends BaseGameState {
  final List<List<LudoToken>> tokens; // tokens[playerIndex][0-3]
  final int diceValue;
  final bool diceRolled;
  final bool bonusTurn; // got a 6, roll again

  const LudoState({
    required super.players,
    required super.currentPlayerIndex,
    required super.phase,
    required super.gameType,
    required this.tokens,
    required this.diceValue,
    required this.diceRolled,
    this.bonusTurn = false,
    super.winnerId,
    super.message,
  });

  LudoState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    GamePhase? phase,
    List<List<LudoToken>>? tokens,
    int? diceValue,
    bool? diceRolled,
    bool? bonusTurn,
    String? winnerId,
    String? message,
  }) => LudoState(
    players: players ?? this.players,
    currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
    phase: phase ?? this.phase,
    gameType: gameType,
    tokens: tokens ?? this.tokens,
    diceValue: diceValue ?? this.diceValue,
    diceRolled: diceRolled ?? this.diceRolled,
    bonusTurn: bonusTurn ?? this.bonusTurn,
    winnerId: winnerId ?? this.winnerId,
    message: message ?? this.message,
  );

  @override
  Map<String, dynamic> toJson() => {
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.name,
    'diceValue': diceValue,
    'diceRolled': diceRolled,
    'bonusTurn': bonusTurn,
    'winnerId': winnerId,
    'message': message,
    'tokens': tokens
        .map((playerTokens) => playerTokens.map((t) => t.toJson()).toList())
        .toList(),
  };

  factory LudoState.fromJson(Map<String, dynamic> json, List<Player> players) {
    final tokensData = json['tokens'] as List;
    final tokens = tokensData
        .map(
          (playerTokens) => (playerTokens as List)
              .map((t) => LudoToken.fromJson(t as Map<String, dynamic>))
              .toList(),
        )
        .toList();

    return LudoState(
      players: players,
      currentPlayerIndex: json['currentPlayerIndex'],
      phase: GamePhase.values.byName(json['phase']),
      gameType: GameType.ludo,
      tokens: tokens,
      diceValue: json['diceValue'],
      diceRolled: json['diceRolled'],
      bonusTurn: json['bonusTurn'] ?? false,
      winnerId: json['winnerId'],
      message: json['message'],
    );
  }
}
