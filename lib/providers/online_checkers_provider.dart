import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/checkers/checkers_state.dart';
import '../core/models/checkers/checkers_piece.dart';
import '../core/models/player.dart';
import '../core/constants/enums.dart';
import '../services/online_service.dart';
import 'online_provider.dart';

final onlineCheckersStateProvider = StreamProvider.autoDispose<CheckersState?>((
  ref,
) {
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

        // Reconstruct board from flat 1D list
        final flatBoard = data['board'] as List? ?? [];
        final size = data['boardSize'] as int? ?? 8;

        final board = List.generate(
          size,
          (row) => List.generate(size, (col) {
            final idx = row * size + col;
            if (idx >= flatBoard.length) return null;
            final cell = flatBoard[idx];
            return cell != null
                ? CheckersPiece.fromJson(Map<String, dynamic>.from(cell as Map))
                : null;
          }),
        );

        return CheckersState(
          players: players,
          currentPlayerIndex: data['currentPlayerIndex'] ?? 0,
          phase: GamePhase.values.byName(
            (data['phase'] as String?) ?? 'playing',
          ),
          gameType: GameType.checkers,
          board: board,
          currentColor: PieceColor.values.byName(
            (data['currentColor'] as String?) ?? 'red',
          ),
          redCount: data['redCount'] ?? 12,
          blackCount: data['blackCount'] ?? 12,
          winnerId: data['winnerId'] as String?,
          message: data['message'] as String?,
        );
      });
});
