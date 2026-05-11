class CheckersMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final List<CheckersCapture> captures; // pieces captured along the way

  const CheckersMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.captures = const [],
  });

  bool get isCapture => captures.isNotEmpty;

Map<String, dynamic> toJson() => {
    'fromRow': fromRow,
    'fromCol': fromCol,
    'toRow': toRow,
    'toCol': toCol,
    'captures': captures.map((c) => c.toJson()).toList(),
  };

  factory CheckersMove.fromJson(Map<String, dynamic> json) => CheckersMove(
    fromRow: json['fromRow'],
    fromCol: json['fromCol'],
    toRow: json['toRow'],
    toCol: json['toCol'],
    captures: (json['captures'] as List? ?? [])
        .map(
          (c) => CheckersCapture.fromJson(Map<String, dynamic>.from(c as Map)),
        )
        .toList(),
  );
}

class CheckersCapture {
  final int row;
  final int col;

  const CheckersCapture({required this.row, required this.col});

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  factory CheckersCapture.fromJson(Map<String, dynamic> json) =>
      CheckersCapture(row: json['row'], col: json['col']);
}
