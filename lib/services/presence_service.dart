import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/enums.dart';

class OnlinePlayer {
  final String uid;
  final String displayName;
  final int avatarIndex;
  final String status; // idle, in_game
  final String? currentGame;
  final DateTime lastSeen;

  const OnlinePlayer({
    required this.uid,
    required this.displayName,
    required this.avatarIndex,
    required this.status,
    required this.lastSeen,
    this.currentGame,
  });

  bool get isIdle => status == 'idle';

  factory OnlinePlayer.fromJson(String uid, Map<String, dynamic> json) =>
      OnlinePlayer(
        uid: uid,
        displayName: json['displayName'] ?? 'Player',
        avatarIndex: json['avatarIndex'] ?? 0,
        status: json['status'] ?? 'idle',
        currentGame: json['currentGame'],
        lastSeen: (json['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class PresenceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ── Go online ─────────────────────────────────────────

  Future<void> goOnline(String displayName, int avatarIndex) async {
    await _db.collection('presence').doc(currentUid).set({
      'displayName': displayName,
      'avatarIndex': avatarIndex,
      'isOnline': true,
      'status': 'idle',
      'currentGame': null,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Go offline ────────────────────────────────────────

  Future<void> goOffline() async {
    await _db.collection('presence').doc(currentUid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ── Update status ─────────────────────────────────────

  Future<void> setInGame(GameType game) async {
    await _db.collection('presence').doc(currentUid).update({
      'status': 'in_game',
      'currentGame': game.name,
    });
  }

  Future<void> setIdle() async {
    await _db.collection('presence').doc(currentUid).update({
      'status': 'idle',
      'currentGame': null,
    });
  }

  // ── Heartbeat — keep lastSeen fresh ──────────────────

  Future<void> heartbeat() async {
    await _db.collection('presence').doc(currentUid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ── Streams ───────────────────────────────────────────

  Stream<List<OnlinePlayer>> onlinePlayersStream() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 2));

    return _db
        .collection('presence')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => doc.id != currentUid)
              .map((doc) => OnlinePlayer.fromJson(doc.id, doc.data()))
              .where((p) => p.lastSeen.isAfter(cutoff))
              .toList(),
        );
  }
}

final presenceServiceProvider = Provider<PresenceService>(
  (_) => PresenceService(),
);

final onlinePlayersProvider = StreamProvider<List<OnlinePlayer>>((ref) {
  return ref.watch(presenceServiceProvider).onlinePlayersStream();
});
