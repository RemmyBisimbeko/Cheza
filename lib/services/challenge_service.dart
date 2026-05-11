import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/enums.dart';
import 'online_service.dart';
import 'presence_service.dart';

enum ChallengeStatus { pending, accepted, declined }

class Challenge {
  final String id;
  final String fromUid;
  final String fromName;
  final int fromAvatar;
  final String toUid;
  final GameType gameType;
  final ChallengeStatus status;
  final String? roomId;

  const Challenge({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromAvatar,
    required this.toUid,
    required this.gameType,
    required this.status,
    this.roomId,
  });

  factory Challenge.fromJson(String id, Map<String, dynamic> json) => Challenge(
    id: id,
    fromUid: json['fromUid'],
    fromName: json['fromName'],
    fromAvatar: json['fromAvatar'] ?? 0,
    toUid: json['toUid'],
    gameType: GameType.values.byName(json['gameType'] ?? 'matatu'),
    status: ChallengeStatus.values.byName(json['status'] ?? 'pending'),
    roomId: json['roomId'],
  );
}

class ChallengeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ── Send challenge ────────────────────────────────────

  Future<String> sendChallenge({
    required String toUid,
    required String fromName,
    required int fromAvatar,
    required GameType gameType,
  }) async {
    final ref = await _db.collection('challenges').add({
      'fromUid': currentUid,
      'fromName': fromName,
      'fromAvatar': fromAvatar,
      'toUid': toUid,
      'gameType': gameType.name,
      'status': 'pending',
      'roomId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ── Accept challenge ──────────────────────────────────

  Future<String> acceptChallenge(
    Challenge challenge,
    OnlineService onlineService,
  ) async {
    // Create room
    final roomId = await onlineService.createRoom(
      _auth.currentUser?.displayName ?? 'Player',
      2,
      challenge.gameType,
    );

    // Join room as the challenged player
    await onlineService.joinRoomById(roomId, challenge.fromName);

    // Start the game
    await onlineService.startOnlineGame(roomId);

    // ✅ Wait for Firestore to confirm game is 'playing'
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .firstWhere(
          (snap) => snap.exists && snap.data()?['status'] == 'playing',
        )
        .timeout(const Duration(seconds: 10));

    // Update challenge status with roomId
    await _db.collection('challenges').doc(challenge.id).update({
      'status': 'accepted',
      'roomId': roomId,
    });

    return roomId;
  }

  // ── Decline challenge ─────────────────────────────────

  Future<void> declineChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'declined',
    });
  }

  // ── Streams ───────────────────────────────────────────

  // Incoming challenges for current user
  Stream<List<Challenge>> incomingChallengesStream() {
    return _db
        .collection('challenges')
        .where('toUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Challenge.fromJson(d.id, d.data())).toList(),
        );
  }

  // Watch a specific challenge (for challenger to detect acceptance)
  Stream<Challenge?> watchChallenge(String challengeId) {
    return _db
        .collection('challenges')
        .doc(challengeId)
        .snapshots()
        .map(
          (snap) =>
              snap.exists ? Challenge.fromJson(snap.id, snap.data()!) : null,
        );
  }
}

final challengeServiceProvider = Provider<ChallengeService>(
  (_) => ChallengeService(),
);

final incomingChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.watch(challengeServiceProvider).incomingChallengesStream();
});
