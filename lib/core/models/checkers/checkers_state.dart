import 'package:cheza_games/core/models/checkers/checkers_move.dart';

import '../base_game_state.dart';
import '../player.dart';
import '../../constants/enums.dart';
import 'checkers_piece.dart';

class CheckersState extends BaseGameState {
  final List<List<CheckersPiece?>> board; // 8x8 grid
  final PieceColor currentColor;
  final CheckersPiece? selectedPiece;
  final List<CheckersMove> validMoves;
  final int redCount;
  final int blackCount;

  const CheckersState({
    required super.players,
    required super.currentPlayerIndex,
    required super.phase,
    required super.gameType,
    required this.board,
    required this.currentColor,
    required this.redCount,
    required this.blackCount,
    this.selectedPiece,
    this.validMoves = const [],
    super.winnerId,
    super.message,
  });

  CheckersState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    GamePhase? phase,
    List<List<CheckersPiece?>>? board,
    PieceColor? currentColor,
    CheckersPiece? selectedPiece,
    bool clearSelected = false,
    List<CheckersMove>? validMoves,
    int? redCount,
    int? blackCount,
    String? winnerId,
    String? message,
    bool clearMessage = false,
  }) => CheckersState(
    players: players ?? this.players,
    currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
    phase: phase ?? this.phase,
    gameType: gameType,
    board: board ?? this.board,
    currentColor: currentColor ?? this.currentColor,
    selectedPiece: clearSelected ? null : (selectedPiece ?? this.selectedPiece),
    validMoves: validMoves ?? this.validMoves,
    redCount: redCount ?? this.redCount,
    blackCount: blackCount ?? this.blackCount,
    winnerId: winnerId ?? this.winnerId,
    message: clearMessage ? null : (message ?? this.message),
  );

  @override
  Map<String, dynamic> toJson() => {
    'currentPlayerIndex': currentPlayerIndex,
    'phase': phase.name,
    'currentColor': currentColor.name,
    'redCount': redCount,
    'blackCount': blackCount,
    'winnerId': winnerId,
    'message': message,
    'board': board.map((row) => row.map((p) => p?.toJson()).toList()).toList(),
  };

  factory CheckersState.fromJson(
    Map<String, dynamic> json,
    List<Player> players,
  ) {
    final boardData = json['board'] as List;
    final board = boardData
        .map(
          (row) => (row as List)
              .map(
                (cell) => cell != null
                    ? CheckersPiece.fromJson(cell as Map<String, dynamic>)
                    : null,
              )
              .toList(),
        )
        .toList();

    return CheckersState(
      players: players,
      currentPlayerIndex: json['currentPlayerIndex'],
      phase: GamePhase.values.byName(json['phase']),
      gameType: GameType.checkers,
      board: board,
      currentColor: PieceColor.values.byName(json['currentColor']),
      redCount: json['redCount'],
      blackCount: json['blackCount'],
      winnerId: json['winnerId'],
      message: json['message'],
    );
  }
}
