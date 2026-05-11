import 'player.dart';
import '../constants/enums.dart';

/// All game states extend this.
/// Gives online service a consistent interface.
abstract class BaseGameState {
  final List<Player> players;
  final int currentPlayerIndex;
  final GamePhase phase;
  final String? winnerId;
  final String? message;
  final GameType gameType;

  const BaseGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.phase,
    required this.gameType,
    this.winnerId,
    this.message,
  });

  Player get currentPlayer => players[currentPlayerIndex];
  bool get isGameOver => phase == GamePhase.gameOver;

  /// Must be implemented by each game state
  Map<String, dynamic> toJson();
}
