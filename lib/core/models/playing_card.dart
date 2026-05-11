import '../constants/enums.dart';

class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard({required this.suit, required this.rank});

  // Special card effects
SpecialEffect get effect {
    switch (rank) {
      case Rank.two:
        return SpecialEffect.pickTwo;
      case Rank.eight:
        return SpecialEffect.skip;
      case Rank.jack:
        return SpecialEffect.reverse; // 👈 swap
      case Rank.king:
        return SpecialEffect.none; // 👈 no effect
      case Rank.ace:
        return SpecialEffect.changeSuit;
      default:
        return SpecialEffect.none; // ✅ 7 is now just normal
    }
  }

  bool get isSpecial => effect != SpecialEffect.none;

  // For Firebase serialization
  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank.name};

  factory PlayingCard.fromJson(Map<String, dynamic> json) => PlayingCard(
    suit: Suit.values.byName(json['suit']),
    rank: Rank.values.byName(json['rank']),
  );

  @override
  String toString() => '${rank.name} of ${suit.name}';
}
