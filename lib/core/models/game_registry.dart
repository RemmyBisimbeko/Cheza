import '../constants/enums.dart';
import 'package:flutter/material.dart';

class GameInfo {
  final GameType type;
  final String name;
  final String description;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final int minPlayers;
  final int maxPlayers;
  final bool isAvailable; // false = coming soon

  const GameInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.minPlayers,
    required this.maxPlayers,
    this.isAvailable = true,
  });
}

class GameRegistry {
  static const List<GameInfo> games = [
    GameInfo(
      type: GameType.matatu,
      name: 'Matatu',
      description: 'The Ugandan card game',
      emoji: '🃏',
      primaryColor: Color(0xFFFFD600),
      secondaryColor: Color(0xFF1B5E20),
      minPlayers: 2,
      maxPlayers: 6,
    ),
    GameInfo(
      type: GameType.chess,
      name: 'Chess',
      description: 'Classic strategy game',
      emoji: '♟️',
      primaryColor: Color(0xFFB0BEC5),
      secondaryColor: Color(0xFF263238),
      minPlayers: 2,
      maxPlayers: 2,
    ),
    GameInfo(
      type: GameType.checkers,
      name: 'Checkers',
      description: 'Jump and capture',
      emoji: '🔴',
      primaryColor: Color(0xFFEF5350),
      secondaryColor: Color(0xFF1A237E),
      minPlayers: 2,
      maxPlayers: 2,
    ),
    GameInfo(
      type: GameType.ludo,
      name: 'Ludo',
      description: 'Race your tokens home',
      emoji: '🎲',
      primaryColor: Color(0xFF7C4DFF),
      secondaryColor: Color(0xFFFF6D00),
      minPlayers: 2,
      maxPlayers: 4,
    ),
  ];

  static GameInfo getGame(GameType type) =>
      games.firstWhere((g) => g.type == type);
}
