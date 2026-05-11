import 'package:cheza_games/core/models/checkers/checkers_move.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cheza_games/core/models/checkers/checkers_move.dart';
import 'dart:math';
import '../core/models/playing_card.dart';
import '../core/models/player.dart';
import '../core/models/game_state.dart';
import '../core/models/checkers/checkers_piece.dart';
import '../core/models/checkers/checkers_state.dart';
import '../core/models/chess/chess_state.dart';
import '../core/constants/enums.dart';
import '../core/engine/game_engine.dart';
import '../core/engine/checkers_engine.dart';
import '../core/engine/chess_engine.dart';

class OnlineService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _engine = GameEngine();
  final Random _random = Random.secure();

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ── Auth ──────────────────────────────────────────────

  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ── Room Management ───────────────────────────────────

  Future<String> createRoom(
    String playerName,
    int playerCount,
    GameType gameType,
  ) async {
    await signInAnonymously();
    final code = _generateCode();
    final roomRef = _db.collection('rooms').doc();

    await roomRef.set({
      'code': code,
      'status': 'waiting',
      'hostId': currentUid,
      'playerCount': playerCount,
      'gameType': gameType.name,
      'players': [
        {
          'id': currentUid,
          'name': playerName,
          'type': 'human',
          'handCount': 0,
          'hasCalledMatatu': false,
        },
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return roomRef.id;
  }

  Future<String?> joinRoom(String code, String playerName) async {
    await signInAnonymously();

    final query = await _db
        .collection('rooms')
        .where('code', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final roomRef = query.docs.first.reference;
    final data = query.docs.first.data();
    final players = List<Map>.from(data['players']);

    if (players.length >= data['playerCount']) return null;

    await roomRef.update({
      'players': FieldValue.arrayUnion([
        {
          'id': currentUid,
          'name': playerName,
          'type': 'human',
          'handCount': 0,
          'hasCalledMatatu': false,
        },
      ]),
    });

    return roomRef.id;
  }

  Future<void> joinRoomById(String roomId, String playerName) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    await roomRef.update({
      'players': FieldValue.arrayUnion([
        {
          'id': currentUid,
          'name': playerName,
          'type': 'human',
          'handCount': 0,
          'hasCalledMatatu': false,
        },
      ]),
    });
  }

  Future<String?> getRoomCode(String roomId) async {
    final snap = await _db.collection('rooms').doc(roomId).get();
    return snap.data()?['code'] as String?;
  }

  // ── Start Game ────────────────────────────────────────

  Future<void> startOnlineGame(String roomId) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    final snap = await roomRef.get();
    final data = snap.data()!;
    final gameType = GameType.values.byName(
      (data['gameType'] as String?) ?? 'matatu',
    );

    final rawPlayers = data['players'] as List;
    final players = rawPlayers
        .map(
          (p) => Player(
            id: p['id'],
            name: p['name'],
            type: PlayerType.remote,
            hand: [],
          ),
        )
        .toList();

    final batch = _db.batch();

    switch (gameType) {
      case GameType.matatu:
        final state = _engine.initGame(players);

        // Write each player's hand to private subcollection
        for (final player in state.players) {
          final handRef = roomRef.collection('hands').doc(player.id);
          batch.set(handRef, {
            'cards': player.hand.map((c) => c.toJson()).toList(),
          });
        }

        final publicPlayers = state.players
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'type': p.type.name,
                'handCount': p.hand.length,
                'hasCalledMatatu': false,
              },
            )
            .toList();

        batch.update(roomRef, {
          'status': 'playing',
          'gameType': 'matatu',
          'currentPlayerIndex': state.currentPlayerIndex,
          'discardPile': state.discardPile.map((c) => c.toJson()).toList(),
          'deck': state.deck.map((c) => c.toJson()).toList(),
          'cutCard': state.cutCard?.toJson(),
          'declaredSuit': null,
          'pendingPickUp': 0,
          'isClockwise': true,
          'phase': 'playing',
          'winnerId': null,
          'message': null,
          'scores': {},
          'players': publicPlayers,
        });

      case GameType.chess:
        batch.update(roomRef, {
          'status': 'playing',
          'gameType': 'chess',
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'currentPlayerIndex': 0,
          'moveHistory': [],
          'phase': 'playing',
          'isCheck': false,
          'isCheckmate': false,
          'isStalemate': false,
          'selectedSquare': null,
          'validMoves': [],
          'winnerId': null,
          'message': '${players[0].name}\'s turn (White)',
          'difficulty': 'easy',
          'players': data['players'],
        });

      case GameType.checkers:
        final engine = CheckersEngine();
        final state = engine.initGame(players);

        // Flatten 2D board to 1D for Firestore
        final flatBoard = _flattenBoard(state.board);

        batch.update(roomRef, {
          'status': 'playing',
          'gameType': 'checkers',
          'board': flatBoard,
          'boardSize': 8,
          'currentPlayerIndex': 0,
          'currentColor': 'red',
          'redCount': 12,
          'blackCount': 12,
          'phase': 'playing',
          'winnerId': null,
          'message': '${players[0].name}\'s turn (Red)',
          'players': data['players'],
        });

      case GameType.ludo:
        // Ludo online — coming soon
        break;
    }

    await batch.commit();
  }

  // ── Matatu: Play Card ─────────────────────────────────

  Future<void> playCard(
    String roomId,
    PlayingCard card, {
    Suit? chosenSuit,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(roomRef);
      if (!snap.exists) return;
      final data = snap.data()!;

      final players = List<Map>.from(data['players'] ?? []);
      final currentIdx = data['currentPlayerIndex'] as int;

      final myPlayerIdx = players.indexWhere((p) => p['id'] == currentUid);
      if (myPlayerIdx == -1) return; // not in this game
      if (currentIdx != myPlayerIdx) return; // not my turn

      final handSnap = await tx.get(
        roomRef.collection('hands').doc(currentUid),
      );
      if (!handSnap.exists) return;

      final myHand = (handSnap.data()!['cards'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList();

      final deck = (data['deck'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList();

      final cutCard = data['cutCard'] != null
          ? PlayingCard.fromJson(data['cutCard'] as Map<String, dynamic>)
          : null;

      final allPlayers = players
          .map(
            (p) => Player(
              id: p['id'],
              name: p['name'],
              type: p['id'] == currentUid
                  ? PlayerType.human
                  : PlayerType.remote,
              hand: p['id'] == currentUid ? myHand : [],
            ),
          )
          .toList();

      final state = GameState(
        players: allPlayers,
        deck: deck,
        discardPile: (data['discardPile'] as List)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        currentPlayerIndex: currentIdx,
        declaredSuit: data['declaredSuit'] != null
            ? Suit.values.byName(data['declaredSuit'] as String)
            : null,
        pendingPickUp: data['pendingPickUp'] ?? 0,
        isClockwise: data['isClockwise'] ?? true,
        phase: GamePhase.values.byName((data['phase'] as String?) ?? 'playing'),
        winnerId: data['winnerId'] as String?,
        message: data['message'] as String?,
        cutCard: cutCard,
      );

      final newState = _engine.playCard(card, state, chosenSuit: chosenSuit);

      final myNewHand = newState.players
          .firstWhere((p) => p.id == currentUid)
          .hand;

      tx.set(roomRef.collection('hands').doc(currentUid), {
        'cards': myNewHand.map((c) => c.toJson()).toList(),
      });

      final updatedPlayers = newState.players.map((p) {
        final original = players.firstWhere((x) => x['id'] == p.id);
        return {
          'id': p.id,
          'name': p.name,
          'type': p.type.name,
          'handCount': p.id == currentUid
              ? myNewHand.length
              : (original['handCount'] as int? ?? 0),
          'hasCalledMatatu': p.hasCalledMatatu,
        };
      }).toList();

      tx.update(roomRef, {
        'discardPile': newState.discardPile.map((c) => c.toJson()).toList(),
        'deck': newState.deck.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': newState.currentPlayerIndex,
        'declaredSuit': newState.declaredSuit?.name,
        'pendingPickUp': newState.pendingPickUp,
        'isClockwise': newState.isClockwise,
        'phase': newState.phase.name,
        'winnerId': newState.winnerId,
        'message': newState.message,
        'scores': newState.scores,
        'players': updatedPlayers,
      });
    });
  }

  // ── Matatu: Draw Card ─────────────────────────────────

  Future<void> drawCard(String roomId) async {
    final roomRef = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(roomRef);
      if (!snap.exists) return;
      final data = snap.data()!;

      final players = List<Map>.from(data['players'] ?? []);
      final currentIdx = data['currentPlayerIndex'] as int;
      final currentPlayerId = players[currentIdx]['id'];
      if (currentPlayerId != currentUid) return;

      final handSnap = await tx.get(
        roomRef.collection('hands').doc(currentUid),
      );
      if (!handSnap.exists) return;

      final myHand = (handSnap.data()!['cards'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList();

      final deck = (data['deck'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList();

      final cutCard = data['cutCard'] != null
          ? PlayingCard.fromJson(data['cutCard'] as Map<String, dynamic>)
          : null;

      final allPlayers = players
          .map(
            (p) => Player(
              id: p['id'],
              name: p['name'],
              type: p['id'] == currentUid
                  ? PlayerType.human
                  : PlayerType.remote,
              hand: p['id'] == currentUid ? myHand : [],
            ),
          )
          .toList();

      final state = GameState(
        players: allPlayers,
        deck: deck,
        discardPile: (data['discardPile'] as List)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        currentPlayerIndex: currentIdx,
        declaredSuit: data['declaredSuit'] != null
            ? Suit.values.byName(data['declaredSuit'] as String)
            : null,
        pendingPickUp: data['pendingPickUp'] ?? 0,
        isClockwise: data['isClockwise'] ?? true,
        phase: GamePhase.values.byName((data['phase'] as String?) ?? 'playing'),
        winnerId: data['winnerId'] as String?,
        message: data['message'] as String?,
        cutCard: cutCard,
      );

      final newState = _engine.drawCard(state);

      final myNewHand = newState.players
          .firstWhere((p) => p.id == currentUid)
          .hand;

      tx.set(roomRef.collection('hands').doc(currentUid), {
        'cards': myNewHand.map((c) => c.toJson()).toList(),
      });

      final updatedPlayers = newState.players.map((p) {
        final original = players.firstWhere((x) => x['id'] == p.id);
        return {
          'id': p.id,
          'name': p.name,
          'type': p.type.name,
          'handCount': p.id == currentUid
              ? myNewHand.length
              : (original['handCount'] as int? ?? 0),
          'hasCalledMatatu': p.hasCalledMatatu,
        };
      }).toList();

      tx.update(roomRef, {
        'discardPile': newState.discardPile.map((c) => c.toJson()).toList(),
        'deck': newState.deck.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': newState.currentPlayerIndex,
        'pendingPickUp': newState.pendingPickUp,
        'isClockwise': newState.isClockwise,
        'phase': newState.phase.name,
        'message': newState.message,
        'players': updatedPlayers,
      });
    });
  }

  // ── Chess: Select Square ──────────────────────────────

  Future<void> chessSelectSquare(String roomId, String square) async {
    final roomRef = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(roomRef);
      if (!snap.exists) return;
      final data = snap.data()!;

      final players = List<Map>.from(data['players'] ?? []);
      final currentIdx = data['currentPlayerIndex'] as int;
      if (players[currentIdx]['id'] != currentUid) return;

      final fen = data['fen'] as String;
      final moveHistory = List<String>.from(data['moveHistory'] ?? []);

      final allPlayers = players
          .map(
            (p) => Player(
              id: p['id'],
              name: p['name'],
              type: p['id'] == currentUid
                  ? PlayerType.human
                  : PlayerType.remote,
            ),
          )
          .toList();

      final state = ChessState(
        players: allPlayers,
        currentPlayerIndex: currentIdx,
        phase: GamePhase.playing,
        gameType: GameType.chess,
        fen: fen,
        moveHistory: moveHistory,
        difficulty: ChessDifficulty.easy,
        selectedSquare: data['selectedSquare'] as String?,
        validMoves: List<String>.from(data['validMoves'] ?? []),
      );

      final engine = ChessEngine();
      final newState = engine.selectSquare(state, square);

      // Move made — update full state
      if (newState.moveHistory.length > moveHistory.length) {
        tx.update(roomRef, {
          'fen': newState.fen,
          'currentPlayerIndex': newState.currentPlayerIndex,
          'moveHistory': newState.moveHistory,
          'phase': newState.phase.name,
          'winnerId': newState.winnerId,
          'message': newState.message,
          'isCheck': newState.isCheck,
          'isCheckmate': newState.isCheckmate,
          'isStalemate': newState.isStalemate,
          'selectedSquare': null,
          'validMoves': [],
        });
      } else {
        // Just selection — update selected square
        tx.update(roomRef, {
          'selectedSquare': newState.selectedSquare,
          'validMoves': newState.validMoves,
        });
      }
    });
  }

  // ── Checkers: Select Square ───────────────────────────
  Future<void> checkersSelectSquare(String roomId, int row, int col) async {
    final roomRef = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(roomRef);
      if (!snap.exists) return;
      final data = snap.data()!;

      final players = List<Map>.from(data['players'] ?? []);
      final currentIdx = data['currentPlayerIndex'] as int;
      if (players[currentIdx]['id'] != currentUid) return;

      // Reconstruct board
      final flatBoard = data['board'] as List? ?? [];
      final size = data['boardSize'] as int? ?? 8;
      final board = List.generate(
        size,
        (r) => List.generate(size, (c) {
          final idx = r * size + c;
          if (idx >= flatBoard.length) return null;
          final cell = flatBoard[idx];
          return cell != null
              ? CheckersPiece.fromJson(Map<String, dynamic>.from(cell as Map))
              : null;
        }),
      );

      // Reconstruct selected piece from Firestore if any
      final selectedData = data['selectedPiece'];
      CheckersPiece? selectedPiece;
      if (selectedData != null) {
        selectedPiece = CheckersPiece.fromJson(
          Map<String, dynamic>.from(selectedData as Map),
        );
      }

      // Reconstruct valid moves from Firestore
      final validMovesData = List<Map>.from(data['validMoves'] ?? []);
      final validMoves = validMovesData
          .map((m) => CheckersMove.fromJson(Map<String, dynamic>.from(m)))
          .toList();

      final allPlayers = players
          .map(
            (p) => Player(
              id: p['id'],
              name: p['name'],
              type: p['id'] == currentUid
                  ? PlayerType.human
                  : PlayerType.remote,
            ),
          )
          .toList();

      final state = CheckersState(
        players: allPlayers,
        currentPlayerIndex: currentIdx,
        phase: GamePhase.values.byName((data['phase'] as String?) ?? 'playing'),
        gameType: GameType.checkers,
        board: board,
        currentColor: PieceColor.values.byName(
          (data['currentColor'] as String?) ?? 'red',
        ),
        redCount: data['redCount'] ?? 12,
        blackCount: data['blackCount'] ?? 12,
        selectedPiece: selectedPiece,
        validMoves: validMoves,
        winnerId: data['winnerId'] as String?,
      );

      final engine = CheckersEngine();
      final newState = engine.applyMoveFromTap(state, row, col);

      final newFlatBoard = _flattenBoard(newState.board);

      // Serialize valid moves for Firestore
      final newValidMoves = newState.validMoves.map((m) => m.toJson()).toList();

      tx.update(roomRef, {
        'board': newFlatBoard,
        'boardSize': size,
        'currentPlayerIndex': newState.currentPlayerIndex,
        'currentColor': newState.currentColor.name,
        'redCount': newState.redCount,
        'blackCount': newState.blackCount,
        'phase': newState.phase.name,
        'winnerId': newState.winnerId,
        'message': newState.message,
        // Persist selection state so second tap knows what was selected
        'selectedPiece': newState.selectedPiece?.toJson(),
        'validMoves': newValidMoves,
      });
    });
  }

  // ── Streams ───────────────────────────────────────────

  Stream<Map<String, dynamic>> roomStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  Stream<List<PlayingCard>> myHandStream(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('hands')
        .doc(currentUid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return [];
          return (snap.data()!['cards'] as List)
              .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
              .toList();
        });
  }

  // ── Helpers ───────────────────────────────────────────

  // Flatten 2D board to 1D for Firestore
  List<Map?> _flattenBoard(List<List<CheckersPiece?>> board) {
    final flat = <Map?>[];
    for (final row in board) {
      for (final cell in row) {
        flat.add(cell?.toJson());
      }
    }
    return flat;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}

final onlineServiceProvider = Provider<OnlineService>((_) => OnlineService());
