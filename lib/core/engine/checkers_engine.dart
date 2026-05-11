import '../models/checkers/checkers_piece.dart';
import '../models/checkers/checkers_move.dart';
import '../models/checkers/checkers_state.dart';
import '../models/player.dart';
import '../constants/enums.dart';

class CheckersEngine {
  // ── Init ──────────────────────────────────────────────

  CheckersState initGame(List<Player> players) {
    // Build empty 8x8 board
    final board = List.generate(8, (_) => List<CheckersPiece?>.filled(8, null));

    // Place black pieces on rows 0-2 (top)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[row][col] = CheckersPiece(
            color: PieceColor.black,
            type: PieceType.normal,
            row: row,
            col: col,
          );
        }
      }
    }

    // Place red pieces on rows 5-7 (bottom)
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[row][col] = CheckersPiece(
            color: PieceColor.red,
            type: PieceType.normal,
            row: row,
            col: col,
          );
        }
      }
    }

    final state = CheckersState(
      players: players,
      currentPlayerIndex: 0,
      phase: GamePhase.playing,
      gameType: GameType.checkers,
      board: board,
      currentColor: PieceColor.red, // red always goes first
      redCount: 12,
      blackCount: 12,
    );

    // Pre-compute valid moves
    return state.copyWith(validMoves: _getAllValidMoves(state, PieceColor.red));
  }

  // ── Move Validation ───────────────────────────────────

  List<CheckersMove> getMovesForPiece(CheckersState state, int row, int col) {
    final piece = state.board[row][col];
    if (piece == null || piece.color != state.currentColor) {
      return [];
    }

    final allMoves = _getAllValidMoves(state, state.currentColor);
    final hasMandatoryCapture = allMoves.any((m) => m.isCapture);

    // Filter to this piece's moves
    var pieceMoves = allMoves
        .where((m) => m.fromRow == row && m.fromCol == col)
        .toList();

    // If captures available anywhere, must capture
    if (hasMandatoryCapture) {
      pieceMoves = pieceMoves.where((m) => m.isCapture).toList();
    }

    return pieceMoves;
  }

  List<CheckersMove> _getAllValidMoves(CheckersState state, PieceColor color) {
    final moves = <CheckersMove>[];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = state.board[row][col];
        if (piece == null || piece.color != color) continue;

        // Get capture moves first
        final captures = _getCapturesForPiece(state.board, piece, row, col, []);
        moves.addAll(captures);

        // Simple moves (only if no captures available)
        if (captures.isEmpty) {
          moves.addAll(_getSimpleMovesForPiece(state.board, piece));
        }
      }
    }

    // If any captures exist, only return captures
    if (moves.any((m) => m.isCapture)) {
      return moves.where((m) => m.isCapture).toList();
    }

    return moves;
  }

  List<CheckersMove> _getSimpleMovesForPiece(
    List<List<CheckersPiece?>> board,
    CheckersPiece piece,
  ) {
    final moves = <CheckersMove>[];
    final directions = _getDirections(piece);

    for (final dir in directions) {
      final newRow = piece.row + dir[0];
      final newCol = piece.col + dir[1];

      if (_inBounds(newRow, newCol) && board[newRow][newCol] == null) {
        moves.add(
          CheckersMove(
            fromRow: piece.row,
            fromCol: piece.col,
            toRow: newRow,
            toCol: newCol,
          ),
        );
      }
    }

    return moves;
  }

  List<CheckersMove> _getCapturesForPiece(
    List<List<CheckersPiece?>> board,
    CheckersPiece piece,
    int fromRow,
    int fromCol,
    List<CheckersCapture> alreadyCaptured,
  ) {
    final moves = <CheckersMove>[];
    final directions = _getDirections(piece);

    for (final dir in directions) {
      final midRow = fromRow + dir[0];
      final midCol = fromCol + dir[1];
      final landRow = fromRow + dir[0] * 2;
      final landCol = fromCol + dir[1] * 2;

      if (!_inBounds(landRow, landCol)) continue;

      final midPiece = board[midRow][midCol];
      final landCell = board[landRow][landCol];

      // Must jump over an opponent
      if (midPiece == null || midPiece.color == piece.color) continue;

      // Landing square must be empty
      if (landCell != null &&
          !(landCell.row == piece.row && landCell.col == piece.col))
        continue;

      // Don't capture the same piece twice
      final alreadyHit = alreadyCaptured.any(
        (c) => c.row == midRow && c.col == midCol,
      );
      if (alreadyHit) continue;

      final newCaptures = [
        ...alreadyCaptured,
        CheckersCapture(row: midRow, col: midCol),
      ];

      // Add this capture
      moves.add(
        CheckersMove(
          fromRow: fromRow,
          fromCol: fromCol,
          toRow: landRow,
          toCol: landCol,
          captures: newCaptures,
        ),
      );

      // Check for additional jumps (multi-capture)
      final tempBoard = _boardWithMove(
        board,
        piece,
        fromRow,
        fromCol,
        landRow,
        landCol,
        newCaptures,
      );

      final movedPiece = tempBoard[landRow][landCol]!;

      final furtherCaptures = _getCapturesForPiece(
        tempBoard,
        movedPiece,
        landRow,
        landCol,
        newCaptures,
      );

      // Replace simple jump with extended multi-jump
      for (final further in furtherCaptures) {
        moves.removeWhere(
          (m) =>
              m.toRow == landRow &&
              m.toCol == landCol &&
              m.captures.length < further.captures.length,
        );
        moves.add(further);
      }
    }

    return moves;
  }

  // ── Apply Move ────────────────────────────────────────

  CheckersState applyMove(CheckersMove move, CheckersState state) {
    var board = _copyBoard(state.board);
    final piece = board[move.fromRow][move.fromCol]!;

    // Move piece
    board[move.fromRow][move.fromCol] = null;

    // Check for king promotion
    final isKing =
        piece.isKing ||
        (piece.color == PieceColor.red && move.toRow == 0) ||
        (piece.color == PieceColor.black && move.toRow == 7);

    board[move.toRow][move.toCol] = piece.copyWith(
      row: move.toRow,
      col: move.toCol,
      type: isKing ? PieceType.king : piece.type,
    );

    // Remove captured pieces
    for (final cap in move.captures) {
      board[cap.row][cap.col] = null;
    }

    // Count remaining pieces
    int redCount = 0;
    int blackCount = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell == null) continue;
        if (cell.color == PieceColor.red) redCount++;
        if (cell.color == PieceColor.black) blackCount++;
      }
    }

    // Next player
    final nextColor = state.currentColor == PieceColor.red
        ? PieceColor.black
        : PieceColor.red;
    final nextPlayerIdx = state.currentPlayerIndex == 0 ? 1 : 0;

    // Check win conditions
    if (redCount == 0) {
      return state.copyWith(
        board: board,
        phase: GamePhase.gameOver,
        winnerId: state.players
            .firstWhere(
              (p) => p.id.contains('black') || state.currentPlayerIndex == 1,
            )
            .id,
        message: '⚫ Black wins!',
        redCount: redCount,
        blackCount: blackCount,
      );
    }

    if (blackCount == 0) {
      return state.copyWith(
        board: board,
        phase: GamePhase.gameOver,
        winnerId: state.players
            .firstWhere(
              (p) => p.id.contains('red') || state.currentPlayerIndex == 0,
            )
            .id,
        message: '🔴 Red wins!',
        redCount: redCount,
        blackCount: blackCount,
      );
    }

    final nextState = state.copyWith(
      board: board,
      currentColor: nextColor,
      currentPlayerIndex: nextPlayerIdx,
      redCount: redCount,
      blackCount: blackCount,
      clearSelected: true,
      clearMessage: true,
    );

    final nextMoves = _getAllValidMoves(nextState, nextColor);

    // No moves left — current player loses
    if (nextMoves.isEmpty) {
      final winner = state.players[state.currentPlayerIndex];
      return nextState.copyWith(
        phase: GamePhase.gameOver,
        winnerId: winner.id,
        validMoves: [],
        message: '🏆 ${winner.name} wins — opponent has no moves!',
      );
    }

    return nextState.copyWith(validMoves: nextMoves);
  }

  // Combines selectPiece + applyMove into one atomic operation
  // Used by online service so selection + move happen in one Firestore write
  // Add this method to CheckersEngine class:
  CheckersState applyMoveFromTap(CheckersState state, int row, int col) {
    final piece = state.board[row][col];

    // Case 1: a piece is selected — check if tapping a valid destination
    if (state.selectedPiece != null) {
      final move = state.validMoves.firstWhere(
        (m) =>
            m.toRow == row &&
            m.toCol == col &&
            m.fromRow == state.selectedPiece!.row &&
            m.fromCol == state.selectedPiece!.col,
        orElse: () =>
            CheckersMove(fromRow: -1, fromCol: -1, toRow: -1, toCol: -1),
      );

      if (move.fromRow != -1) {
        // Valid move — apply it
        return applyMove(move, state);
      }

      // Tapped elsewhere — deselect if not own piece
      if (piece == null || piece.color != state.currentColor) {
        return state.copyWith(clearSelected: true, validMoves: []);
      }
    }

    // Case 2: selecting own piece
    if (piece != null && piece.color == state.currentColor) {
      final moves = getMovesForPiece(state, row, col);
      return state.copyWith(selectedPiece: piece, validMoves: moves);
    }

    // Case 3: deselect
    return state.copyWith(clearSelected: true, validMoves: []);
  }

  // ── AI ────────────────────────────────────────────────

  CheckersMove? getBestAiMove(CheckersState state) {
    final moves = _getAllValidMoves(state, state.currentColor);
    if (moves.isEmpty) return null;

    // Priority: multi-capture > capture > king move > normal
    final captures = moves.where((m) => m.isCapture).toList();
    if (captures.isNotEmpty) {
      captures.sort((a, b) => b.captures.length.compareTo(a.captures.length));
      return captures.first;
    }

    // Prefer king moves and forward-advancing moves
    final kingMoves = moves.where((m) {
      final piece = state.board[m.fromRow][m.fromCol];
      return piece?.isKing ?? false;
    }).toList();

    if (kingMoves.isNotEmpty) {
      return kingMoves[DateTime.now().millisecondsSinceEpoch %
          kingMoves.length];
    }

    return moves[DateTime.now().millisecondsSinceEpoch % moves.length];
  }

  // ── Helpers ───────────────────────────────────────────

  List<List<int>> _getDirections(CheckersPiece piece) {
    if (piece.isKing) {
      return [
        [-1, -1],
        [-1, 1],
        [1, -1],
        [1, 1],
      ];
    }
    // Red moves up (decreasing row), black moves down
    return piece.color == PieceColor.red
        ? [
            [-1, -1],
            [-1, 1],
          ]
        : [
            [1, -1],
            [1, 1],
          ];
  }

  bool _inBounds(int row, int col) =>
      row >= 0 && row < 8 && col >= 0 && col < 8;

  List<List<CheckersPiece?>> _copyBoard(List<List<CheckersPiece?>> board) {
    return board.map((row) => List<CheckersPiece?>.from(row)).toList();
  }

  List<List<CheckersPiece?>> _boardWithMove(
    List<List<CheckersPiece?>> board,
    CheckersPiece piece,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    List<CheckersCapture> captures,
  ) {
    final newBoard = _copyBoard(board);
    newBoard[fromRow][fromCol] = null;
    newBoard[toRow][toCol] = piece.copyWith(row: toRow, col: toCol);
    for (final cap in captures) {
      newBoard[cap.row][cap.col] = null;
    }
    return newBoard;
  }
}
