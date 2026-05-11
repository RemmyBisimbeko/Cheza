import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/game_state.dart';
import '../core/models/player.dart';
import '../core/models/playing_card.dart';
import '../core/constants/enums.dart';
import '../services/online_service.dart';
import 'online_provider.dart';

// Reconstructs GameState from Firestore data
GameState? gameStateFromRoom(
  Map<String, dynamic> room,
  List<PlayingCard> myHand,
  String myUid,
) {
  if (room.isEmpty) return null;
  if (room['status'] != 'playing') return null;

  final rawPlayers = room['players'] as List? ?? [];

  final players = rawPlayers.map((p) {
    final isMe = p['id'] == myUid;
    final handCount = (p['handCount'] as int?) ?? 0;

    return Player(
      id: p['id'],
      name: p['name'],
      type: isMe ? PlayerType.human : PlayerType.remote,
      // My real hand; opponents get placeholder cards for count display
      hand: isMe
          ? myHand
          : List.generate(
              handCount,
              (_) => const PlayingCard(suit: Suit.spades, rank: Rank.ace),
            ),
      hasCalledMatatu: p['hasCalledMatatu'] ?? false,
    );
  }).toList();

  final discard = (room['discardPile'] as List? ?? [])
      .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
      .toList();

  if (discard.isEmpty) return null;

  return GameState(
    players: players,
    deck: [],
    discardPile: discard,
    currentPlayerIndex: room['currentPlayerIndex'] ?? 0,
    declaredSuit: room['declaredSuit'] != null
        ? Suit.values.byName(room['declaredSuit'] as String)
        : null,
    pendingPickUp: room['pendingPickUp'] ?? 0,
    isClockwise: room['isClockwise'] ?? true,
    phase: GamePhase.values.byName((room['phase'] as String?) ?? 'playing'),
    winnerId: room['winnerId'] as String?,
    message: room['message'] as String?,
  );
}

// Watches room doc + fetches hand on every room update
final onlineGameStateProvider = StreamProvider.autoDispose<GameState?>((ref) {
  final roomId = ref.watch(roomIdProvider);
  if (roomId == null) return Stream.value(null);

  final service = ref.read(onlineServiceProvider);
  final myUid = service.currentUid;

  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .snapshots()
      .asyncMap((snap) async {
        if (!snap.exists) return null;
        final room = snap.data()!;

        // Fetch this player's private hand
        try {
          final handSnap = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(roomId)
              .collection('hands')
              .doc(myUid)
              .get();

          final hand = handSnap.exists
              ? (handSnap.data()!['cards'] as List)
                    .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
                    .toList()
              : <PlayingCard>[];

          return gameStateFromRoom(room, hand, myUid);
        } catch (e) {
          return gameStateFromRoom(room, [], myUid);
        }
      });
});
