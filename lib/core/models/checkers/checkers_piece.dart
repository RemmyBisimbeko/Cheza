enum PieceColor { red, black }

enum PieceType { normal, king }

class CheckersPiece {
  final PieceColor color;
  final PieceType type;
  final int row;
  final int col;

  const CheckersPiece({
    required this.color,
    required this.type,
    required this.row,
    required this.col,
  });

  bool get isKing => type == PieceType.king;

  CheckersPiece copyWith({
    PieceColor? color,
    PieceType? type,
    int? row,
    int? col,
  }) => CheckersPiece(
    color: color ?? this.color,
    type: type ?? this.type,
    row: row ?? this.row,
    col: col ?? this.col,
  );

  Map<String, dynamic> toJson() => {
    'color': color.name,
    'type': type.name,
    'row': row,
    'col': col,
  };

  factory CheckersPiece.fromJson(Map<String, dynamic> json) => CheckersPiece(
    color: PieceColor.values.byName(json['color']),
    type: PieceType.values.byName(json['type']),
    row: json['row'],
    col: json['col'],
  );
}
