import '../base_game_state.dart';
import '../player.dart';
import '../../constants/enums.dart';

enum ChessDifficulty { easy, medium, hard }

class ChessState extends BaseGameState {
  final String fen; // Chess position in FEN notation
  final String? selectedSquare;
  final List<String> validMoves; // UCI move list e.g. "e2e4"
  final List<String> moveHistory;
  final bool isCheck;
  final bool isCheckmate;
  final bool isStalemate;
  final ChessDifficulty difficulty;

  const ChessState({
    required super.players,
    required super.currentPlayerIndex,
    required super.phase,
    required super.gameType,
    required this.fen,
    required this.difficulty,
    this.selectedSquare,
    this.validMoves = const [],
    this.moveHistory = const [],
    this.isCheck = false,
    this.isCheckmate = false,
    this.isStalemate = false,
    super.winnerId,
    super.message,
  });

  ChessState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    GamePhase? phase,
    String? fen,
    String? selectedSquare,
    bool clearSelected = false,
    List<String>? validMoves,
    List<String>? moveHistory,
    bool? isCheck,
    bool? isCheckmate,
    bool? isStalemate,
    ChessDifficulty? difficulty,
    String? winnerId,
    String? message,
  }) => ChessState(
    players: players ?? this.players,
    currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
    phase: phase ?? this.phase,
    gameType: gameType,
    fen: fen ?? this.fen,
    selectedSquare: clearSelected
        ? null
        : (selectedSquare ?? this.selectedSquare),
    validMoves: validMoves ?? this.validMoves,
    moveHistory: moveHistory ?? this.moveHistory,
    isCheck: isCheck ?? this.isCheck,
    isCheckmate: isCheckmate ?? this.isCheckmate,
    isStalemate: isStalemate ?? this.isStalemate,
    difficulty: difficulty ?? this.difficulty,
    winnerId: winnerId ?? this.winnerId,
    message: message ?? this.message,
  );

  @override
  Map<String, dynamic> toJson() => {
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.name,
    'fen': fen,
    'moveHistory': moveHistory,
    'difficulty': difficulty.name,
    'isCheck': isCheck,
    'isCheckmate': isCheckmate,
    'isStalemate': isStalemate,
    'winnerId': winnerId,
    'message': message,
  };

  factory ChessState.fromJson(
    Map<String, dynamic> json,
    List<Player> players,
  ) => ChessState(
    players: players,
    currentPlayerIndex: json['currentPlayerIndex'],
    phase: GamePhase.values.byName(json['phase']),
    gameType: GameType.chess,
    fen: json['fen'],
    moveHistory: List<String>.from(json['moveHistory'] ?? []),
    difficulty: ChessDifficulty.values.byName(json['difficulty'] ?? 'easy'),
    isCheck: json['isCheck'] ?? false,
    isCheckmate: json['isCheckmate'] ?? false,
    isStalemate: json['isStalemate'] ?? false,
    winnerId: json['winnerId'],
    message: json['message'],
  );
}
