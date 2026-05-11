import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerProfile {
  final String uid;
  final String displayName;
  final int avatarIndex;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int winStreak;
  final int bestStreak;
  final String favouriteMode;

  const PlayerProfile({
    required this.uid,
    required this.displayName,
    this.avatarIndex = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.winStreak = 0,
    this.bestStreak = 0,
    this.favouriteMode = 'vsAI',
  });

  double get winRate => gamesPlayed == 0 ? 0 : (gamesWon / gamesPlayed * 100);

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'avatarIndex': avatarIndex,
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'gamesLost': gamesLost,
    'winStreak': winStreak,
    'bestStreak': bestStreak,
    'favouriteMode': favouriteMode,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    uid: json['uid'] ?? '',
    displayName: json['displayName'] ?? 'Player',
    avatarIndex: json['avatarIndex'] ?? 0,
    gamesPlayed: json['gamesPlayed'] ?? 0,
    gamesWon: json['gamesWon'] ?? 0,
    gamesLost: json['gamesLost'] ?? 0,
    winStreak: json['winStreak'] ?? 0,
    bestStreak: json['bestStreak'] ?? 0,
    favouriteMode: json['favouriteMode'] ?? 'vsAI',
  );

  PlayerProfile copyWith({
    String? displayName,
    int? avatarIndex,
    int? gamesPlayed,
    int? gamesWon,
    int? gamesLost,
    int? winStreak,
    int? bestStreak,
    String? favouriteMode,
  }) => PlayerProfile(
    uid: uid,
    displayName: displayName ?? this.displayName,
    avatarIndex: avatarIndex ?? this.avatarIndex,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    gamesWon: gamesWon ?? this.gamesWon,
    gamesLost: gamesLost ?? this.gamesLost,
    winStreak: winStreak ?? this.winStreak,
    bestStreak: bestStreak ?? this.bestStreak,
    favouriteMode: favouriteMode ?? this.favouriteMode,
  );
}

class ProfileService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser?.uid ?? '';

    // ── Update display name + avatar ──────────────────────

  Future<void> updateProfile({String? displayName, int? avatarIndex}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (avatarIndex != null) updates['avatarIndex'] = avatarIndex;
    if (updates.isEmpty) return;

    // ✅ set with merge creates doc if missing, updates if exists
    await _db
        .collection('users')
        .doc(currentUid)
        .set(updates, SetOptions(merge: true));
  }

// ── Ensure profile exists ─────────────────────────────
  Future<void> ensureProfile(String displayName) async {
    final ref = _db.collection('users').doc(currentUid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': currentUid,
        'displayName': displayName.isEmpty ? 'Player' : displayName,
        'avatarIndex': 0,
        'gamesPlayed': 0,
        'gamesWon': 0,
        'gamesLost': 0,
        'winStreak': 0,
        'bestStreak': 0,
        'favouriteMode': 'vsAI',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Record game result ────────────────────────────────
  Future<void> recordResult({
    required bool won,
    required String mode,
    required String displayName,
  }) async {
    final ref = _db.collection('users').doc(currentUid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) {
        // Create profile on first result
        tx.set(ref, {
          'uid': currentUid,
          'displayName': displayName.isEmpty ? 'Player' : displayName,
          'avatarIndex': 0,
          'gamesPlayed': 1,
          'gamesWon': won ? 1 : 0,
          'gamesLost': won ? 0 : 1,
          'winStreak': won ? 1 : 0,
          'bestStreak': won ? 1 : 0,
          'favouriteMode': mode,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = snap.data()!;
      final currentStreak = (data['winStreak'] as int?) ?? 0;
      final bestStreak = (data['bestStreak'] as int?) ?? 0;
      final newStreak = won ? currentStreak + 1 : 0;
      final newBest = newStreak > bestStreak ? newStreak : bestStreak;

      tx.update(ref, {
        'gamesPlayed': FieldValue.increment(1),
        'gamesWon': FieldValue.increment(won ? 1 : 0),
        'gamesLost': FieldValue.increment(won ? 0 : 1),
        'winStreak': newStreak,
        'bestStreak': newBest,
        'favouriteMode': mode,
      });
    });
  }
  
  // ── Streams ───────────────────────────────────────────

  Stream<PlayerProfile> profileStream() {
    return _db
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .map(
          (snap) => snap.exists
              ? PlayerProfile.fromJson(snap.data()!)
              : PlayerProfile(uid: currentUid, displayName: 'Player'),
        );
  }

  Stream<List<PlayerProfile>> leaderboardStream({int limit = 20}) {
    return _db
        .collection('users')
        .orderBy('gamesWon', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => PlayerProfile.fromJson(d.data())).toList(),
        );
  }
}

final profileServiceProvider = Provider<ProfileService>(
  (_) => ProfileService(),
);

final profileStreamProvider = StreamProvider<PlayerProfile>((ref) {
  return ref.watch(profileServiceProvider).profileStream();
});

final leaderboardStreamProvider = StreamProvider<List<PlayerProfile>>((ref) {
  return ref.watch(profileServiceProvider).leaderboardStream();
});
