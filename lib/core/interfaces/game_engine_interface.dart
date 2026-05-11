import 'package:cheza_games/core/models/player.dart';

import '../models/base_game_state.dart';

/// Every game engine must implement this interface.
/// This lets the online service, providers and UI
/// treat all games the same way.
abstract class GameEngineInterface<S extends BaseGameState> {
  /// Initialize a new game with given players
  S initGame(List<Player> players);

  /// Check if a move is valid
  bool isValidMove(dynamic move, S state);

  /// Apply a move and return new state
  S applyMove(dynamic move, S state);

  /// Check if the game is over
  bool isGameOver(S state);

  /// Get the winner ID if game is over
  String? getWinnerId(S state);

  /// Serialize state to Firestore
  Map<String, dynamic> stateToJson(S state);

  /// Deserialize state from Firestore
  S stateFromJson(Map<String, dynamic> json);
}
