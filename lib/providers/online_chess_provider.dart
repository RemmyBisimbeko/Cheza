import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/chess/chess_state.dart';
import '../core/models/player.dart';
import '../core/constants/enums.dart';
import '../services/online_service.dart';
import 'online_provider.dart';

final onlineChessStateProvider = StreamProvider.autoDispose<ChessState?>((ref) {
  final roomId = ref.watch(roomIdProvider);
  if (roomId == null) return Stream.value(null);

  final service = ref.read(onlineServiceProvider);
  final myUid = service.currentUid;

  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return null;
        final data = snap.data()!;
        if (data['status'] != 'playing') return null;

        final rawPlayers = List<Map>.from(data['players'] ?? []);
        final players = rawPlayers
            .map(
              (p) => Player(
                id: p['id'],
                name: p['name'],
                type: p['id'] == myUid ? PlayerType.human : PlayerType.remote,
              ),
            )
            .toList();

        return ChessState(
          players: players,
          currentPlayerIndex: data['currentPlayerIndex'] ?? 0,
          phase: GamePhase.values.byName(data['phase'] ?? 'playing'),
          gameType: GameType.chess,
          fen:
              data['fen'] ??
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          moveHistory: List<String>.from(data['moveHistory'] ?? []),
          difficulty: () {
            try {
              return ChessDifficulty.values.byName(
                data['difficulty'] ?? 'easy',
              );
            } catch (_) {
              return ChessDifficulty.easy; // fallback for 'online'
            }
          }(),
          selectedSquare: data['selectedSquare'] as String?,
          validMoves: List<String>.from(data['validMoves'] ?? []),
          isCheck: data['isCheck'] ?? false,
          isCheckmate: data['isCheckmate'] ?? false,
          isStalemate: data['isStalemate'] ?? false,
          winnerId: data['winnerId'] as String?,
          message: data['message'] as String?,
        );
      });
});
