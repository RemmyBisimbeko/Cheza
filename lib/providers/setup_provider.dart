import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/player.dart';
import '../core/constants/enums.dart';

class GameSetup {
  final int playerCount;
  final GameMode mode;
  final String playerName;
  final GameType gameType;

  const GameSetup({
    this.playerCount = 2,
    this.mode = GameMode.vsAI,
    this.playerName = 'You',
    this.gameType = GameType.matatu,
  });

  GameSetup copyWith({int? playerCount, GameMode? mode, String? playerName, GameType? gameType}) =>
      GameSetup(
        playerCount: playerCount ?? this.playerCount,
        mode: mode ?? this.mode,
        playerName: playerName ?? this.playerName,
        gameType: gameType ?? this.gameType,
      );

  // Build the player list based on setup
  List<Player> buildPlayers() {
    final players = <Player>[];

    // Human player always first
    players.add(
      Player(id: 'human_1', name: playerName, type: PlayerType.human),
    );

    for (int i = 1; i < playerCount; i++) {
      players.add(Player(id: 'ai_$i', name: 'CPU $i', type: PlayerType.ai));
    }

    return players;
  }
}

class SetupNotifier extends StateNotifier<GameSetup> {
  SetupNotifier() : super(const GameSetup());

  void setPlayerCount(int count) => state = state.copyWith(playerCount: count);

  void setMode(GameMode mode) => state = state.copyWith(mode: mode);

  void setPlayerName(String name) => state = state.copyWith(playerName: name);
  void setGameType(GameType type) => state = state.copyWith(gameType: type);
}

final setupProvider = StateNotifierProvider<SetupNotifier, GameSetup>(
  (ref) => SetupNotifier(),
);
