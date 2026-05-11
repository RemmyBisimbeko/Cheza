import 'dart:math';
import 'package:chess/chess.dart' as ch;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chess/chess_state.dart';
import '../models/player.dart';
import '../constants/enums.dart';

class ChessEngine {
  final Random _random = Random();

  // ── Init ──────────────────────────────────────────────

  ChessState initGame(List<Player> players, ChessDifficulty difficulty) {
    final chess = ch.Chess();

    return ChessState(
      players: players,
      currentPlayerIndex: 0,
      phase: GamePhase.playing,
      gameType: GameType.chess,
      fen: chess.fen,
      difficulty: difficulty,
      message: '${players[0].name}\'s turn (White)',
    );
  }

  // ── Select Square ─────────────────────────────────────

  ChessState selectSquare(ChessState state, String square) {
    final chess = ch.Chess.fromFEN(state.fen);

    // If a piece is already selected, try to move
    if (state.selectedSquare != null) {
      final moveStr = '${state.selectedSquare}$square';

      // Check if this is a valid move
      final validMove = state.validMoves.firstWhere(
        (m) => m.startsWith(moveStr),
        orElse: () => '',
      );

      if (validMove.isNotEmpty) {
        return _applyMove(state, validMove, chess);
      }

      // If clicking same square — deselect
      if (state.selectedSquare == square) {
        return state.copyWith(clearSelected: true, validMoves: []);
      }
    }

    // Select new square
    final piece = chess.get(square);
    if (piece == null) {
      return state.copyWith(clearSelected: true, validMoves: []);
    }

    // Must select own color
    final isWhiteTurn = state.currentPlayerIndex == 0;
    final isWhitePiece = piece.color == ch.Color.WHITE;
    if (isWhiteTurn != isWhitePiece) {
      return state.copyWith(clearSelected: true, validMoves: []);
    }

    // Get valid moves for this piece
    final moves = chess
        .generate_moves()
        .where((m) => m.fromAlgebraic == square)
        .map(
          (m) =>
              '${m.fromAlgebraic}${m.toAlgebraic}'
              '${_promotionSuffix(m)}',
        )
        .toList();

    if (moves.isEmpty) {
      return state.copyWith(clearSelected: true, validMoves: []);
    }

    return state.copyWith(selectedSquare: square, validMoves: moves);
  }

  // ── Apply Move ────────────────────────────────────────

  ChessState _applyMove(ChessState state, String moveStr, ch.Chess chess) {
    // Handle promotion — default to queen
    final from = moveStr.substring(0, 2);
    final to = moveStr.substring(2, 4);
    final promotion = moveStr.length > 4 ? moveStr[4] : null;

    final moveMap = {
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    };

    chess.move(moveMap);

    final newHistory = [...state.moveHistory, moveStr];
    final nextPlayerIdx = state.currentPlayerIndex == 0 ? 1 : 0;
    final nextPlayer = state.players[nextPlayerIdx];

    // Check game status
    final inCheck = chess.in_check;
    final inCheckmate = chess.in_checkmate;
    final inStalemate =
        chess.in_stalemate || chess.in_draw || chess.insufficient_material;

    GamePhase newPhase = GamePhase.playing;
    String? winnerId;
    String message;

    if (inCheckmate) {
      newPhase = GamePhase.gameOver;
      winnerId = state.players[state.currentPlayerIndex].id;
      message =
          '♟ Checkmate! '
          '${state.players[state.currentPlayerIndex].name} wins!';
    } else if (inStalemate) {
      newPhase = GamePhase.gameOver;
      message = '🤝 Draw!';
    } else if (inCheck) {
      message = '⚠️ ${nextPlayer.name} is in check!';
    } else {
      message =
          '${nextPlayer.name}\'s turn '
          '(${nextPlayerIdx == 0 ? 'White' : 'Black'})';
    }

    return state.copyWith(
      fen: chess.fen,
      currentPlayerIndex: nextPlayerIdx,
      phase: newPhase,
      moveHistory: newHistory,
      isCheck: inCheck,
      isCheckmate: inCheckmate,
      isStalemate: inStalemate,
      clearSelected: true,
      validMoves: [],
      winnerId: winnerId,
      message: message,
    );
  }

  // ── AI Moves ──────────────────────────────────────────

  // Easy: random valid move
  ChessState easyAiMove(ChessState state) {
    final chess = ch.Chess.fromFEN(state.fen);
    final moves = chess.generate_moves();
    if (moves.isEmpty) return state;

    final move = moves[_random.nextInt(moves.length)];
    final moveStr =
        '${move.fromAlgebraic}${move.toAlgebraic}'
        '${_promotionSuffix(move)}';

    return _applyMove(state, moveStr, chess);
  }

  // Medium: Stockfish API
  Future<ChessState> stockfishMove(ChessState state) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://stockfish.online/api/s/v2.php'
              '?fen=${Uri.encodeComponent(state.fen)}'
              '&depth=10',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bestMove = data['bestmove'] as String?;

        if (bestMove != null && bestMove.isNotEmpty) {
          // Stockfish returns "bestmove e2e4" or "bestmove e7e8q"
          final parts = bestMove.split(' ');
          final moveStr = parts.length > 1 ? parts[1] : parts[0];

          if (moveStr != '(none)' && moveStr.length >= 4) {
            final chess = ch.Chess.fromFEN(state.fen);
            return _applyMove(state, moveStr, chess);
          }
        }
      }
    } catch (e) {
      // Stockfish API failed — fall back to easy
    }

    // Fallback to easy if API fails
    return easyAiMove(state);
  }

  // Hard: Minimax with alpha-beta pruning (depth 4)
  ChessState minimaxMove(ChessState state) {
    final chess = ch.Chess.fromFEN(state.fen);
    final moves = chess.generate_moves();
    if (moves.isEmpty) return state;

    ch.Move? bestMove;
    int bestScore = -99999;
    const depth = 4;

    for (final move in moves) {
      chess.move({
        'from': move.fromAlgebraic,
        'to': move.toAlgebraic,
        if (move.promotion != null)
          'promotion': move.promotion.toString().toLowerCase(),
      });

      final score = -_minimax(chess, depth - 1, -99999, 99999, false);

      chess.undo_move();

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    if (bestMove == null) return easyAiMove(state);

    final moveStr =
        '${bestMove.fromAlgebraic}${bestMove.toAlgebraic}'
        '${_promotionSuffix(bestMove)}';

    final freshChess = ch.Chess.fromFEN(state.fen);
    return _applyMove(state, moveStr, freshChess);
  }

  int _minimax(
    ch.Chess chess,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
  ) {
    if (depth == 0 || chess.game_over) {
      return _evaluateBoard(chess);
    }

    final moves = chess.generate_moves();

    if (isMaximizing) {
      int maxEval = -99999;
      for (final move in moves) {
        chess.move({
          'from': move.fromAlgebraic,
          'to': move.toAlgebraic,
          if (move.promotion != null)
            'promotion': move.promotion.toString().toLowerCase(),
        });
        final eval = _minimax(chess, depth - 1, alpha, beta, false);
        chess.undo_move();
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // Alpha-beta pruning
      }
      return maxEval;
    } else {
      int minEval = 99999;
      for (final move in moves) {
        chess.move({
          'from': move.fromAlgebraic,
          'to': move.toAlgebraic,
          if (move.promotion != null)
            'promotion': move.promotion.toString().toLowerCase(),
        });
        final eval = _minimax(chess, depth - 1, alpha, beta, true);
        chess.undo_move();
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  // Board evaluation — positive = good for white
  int _evaluateBoard(ch.Chess chess) {
    if (chess.in_checkmate) {
      return chess.turn == ch.Color.WHITE ? -99000 : 99000;
    }
    if (chess.in_draw || chess.in_stalemate) return 0;

    int score = 0;
    final pieceValues = {
      ch.PieceType.PAWN: 100,
      ch.PieceType.KNIGHT: 320,
      ch.PieceType.BISHOP: 330,
      ch.PieceType.ROOK: 500,
      ch.PieceType.QUEEN: 900,
      ch.PieceType.KING: 20000,
    };

    // Sum piece values
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final sq = _rankFileToSquare(rank, file);
        final piece = chess.get(sq);
        if (piece == null) continue;
        final value = pieceValues[piece.type] ?? 0;
        score += piece.color == ch.Color.WHITE ? value : -value;
      }
    }

    // Bonus for mobility
    final mobilityBonus = chess.generate_moves().length * 10;
    score += chess.turn == ch.Color.WHITE ? mobilityBonus : -mobilityBonus;

    return score;
  }

  // ── Helpers ───────────────────────────────────────────

  String _rankFileToSquare(int rank, int file) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return '${files[file]}${rank + 1}';
  }

  String _promotionSuffix(ch.Move move) {
    if (move.promotion == null) return '';
    return move.promotion.toString().toLowerCase();
  }

  // Parse FEN to get piece at square
  ch.Piece? getPieceAt(String fen, String square) {
    final chess = ch.Chess.fromFEN(fen);
    return chess.get(square);
  }

  // Get all valid destination squares for selected piece
  List<String> getValidDestinations(String fen, String fromSquare) {
    final chess = ch.Chess.fromFEN(fen);
    return chess
        .generate_moves()
        .where((m) => m.fromAlgebraic == fromSquare)
        .map((m) => m.toAlgebraic)
        .toList();
  }
}
