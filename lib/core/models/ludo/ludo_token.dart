enum TokenState { home, active, finished }

enum LudoColor { red, blue, green, yellow }

class LudoToken {
  final LudoColor color;
  final int id; // 0-3 per player
  final TokenState state;
  final int position; // 0-51 on main track, -1 = home base, 52-57 = home column

  const LudoToken({
    required this.color,
    required this.id,
    required this.state,
    this.position = -1,
  });

  bool get isHome => state == TokenState.home;
  bool get isFinished => state == TokenState.finished;
  bool get isActive => state == TokenState.active;

  LudoToken copyWith({TokenState? state, int? position}) => LudoToken(
    color: color,
    id: id,
    state: state ?? this.state,
    position: position ?? this.position,
  );

  Map<String, dynamic> toJson() => {
    'color': color.name,
    'id': id,
    'state': state.name,
    'position': position,
  };

  factory LudoToken.fromJson(Map<String, dynamic> json) => LudoToken(
    color: LudoColor.values.byName(json['color']),
    id: json['id'],
    state: TokenState.values.byName(json['state']),
    position: json['position'],
  );
}
