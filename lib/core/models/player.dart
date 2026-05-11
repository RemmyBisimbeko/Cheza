import 'playing_card.dart';

enum PlayerType { human, ai, remote }

class Player {
  final String id;
  final String name;
  final PlayerType type;
  List<PlayingCard> hand;
  bool hasCalledMatatu; // said "Matatu!" with 1 card left

  Player({
    required this.id,
    required this.name,
    required this.type,
    this.hand = const [],
    this.hasCalledMatatu = false,
  });

  bool get hasWon => hand.isEmpty;
  bool get needsToCallMatatu => hand.length == 1 && !hasCalledMatatu;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'handCount': hand.length, // don't expose hand to other players!
    'hasCalledMatatu': hasCalledMatatu,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    type: PlayerType.values.byName(json['type'] ?? 'remote'),
    hand: [], // hands loaded separately from subcollection
    hasCalledMatatu: json['hasCalledMatatu'] ?? false,
  );
}
