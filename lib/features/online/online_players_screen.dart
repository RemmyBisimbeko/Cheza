import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/presence_service.dart';
import '../../services/challenge_service.dart';
import '../../services/online_service.dart';
import '../../providers/online_provider.dart';
import '../../providers/setup_provider.dart';
import '../../services/profile_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/models/game_registry.dart';
import '../profile/profile_screen.dart';

class OnlinePlayersScreen extends ConsumerStatefulWidget {
  const OnlinePlayersScreen({super.key});

  @override
  ConsumerState<OnlinePlayersScreen> createState() =>
      _OnlinePlayersScreenState();
}

class _OnlinePlayersScreenState extends ConsumerState<OnlinePlayersScreen> {
  String? _pendingChallengeId;
  bool _sending = false;
  bool _dialogShowing = false;
  StreamSubscription? _incomingChallengesSub;
  StreamSubscription? _watchChallengeSub;

  late final PresenceService _presenceService;
  late final ChallengeService _challengeService;
  late final OnlineService _onlineService;
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _presenceService = ref.read(presenceServiceProvider);
    _challengeService = ref.read(challengeServiceProvider);
    _onlineService = ref.read(onlineServiceProvider);
    _profileService = ref.read(profileServiceProvider);

    _goOnline();
    _startHeartbeat();
    _listenForIncomingChallenges();
  }

  @override
  void dispose() {
    _incomingChallengesSub?.cancel();
    _watchChallengeSub?.cancel();
    _presenceService.goOffline();
    super.dispose();
  }

  void _goOnline() async {
    try {
      final setup = ref.read(setupProvider);
      final profile = await _profileService.profileStream().first;

      await _profileService.updateProfile(
        displayName: setup.playerName.isNotEmpty
            ? setup.playerName
            : profile.displayName,
      );

      final updatedProfile = await _profileService.profileStream().first;

      await _presenceService.goOnline(
        updatedProfile.displayName,
        updatedProfile.avatarIndex,
      );
    } catch (e) {
      debugPrint('goOnline error: $e');
    }
  }

  void _startHeartbeat() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      try {
        await _presenceService.heartbeat();
      } catch (_) {}
      return mounted;
    });
  }

  void _listenForIncomingChallenges() {
    _incomingChallengesSub = _challengeService
        .incomingChallengesStream()
        .listen((challenges) {
          if (!mounted) return;
          if (challenges.isNotEmpty && !_dialogShowing) {
            _showIncomingChallenge(challenges.first);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(onlinePlayersProvider);
    final setup = ref.watch(setupProvider);

    return Scaffold(
      backgroundColor: AppTheme.tableGreen,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [AppTheme.tableFelt, AppTheme.tableGreen],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textLight,
                        ),
                        onPressed: () => context.go('/'),
                      ),
                      const Expanded(
                        child: Text(
                          'PLAY ONLINE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Game picker ───────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHALLENGE WITH',
                        style: TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: GameRegistry.games.map((game) {
                            final selected = setup.gameType == game.type;
                            return GestureDetector(
                              onTap: () => ref
                                  .read(setupProvider.notifier)
                                  .setGameType(game.type),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? game.primaryColor.withOpacity(0.2)
                                      : Colors.black26,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? game.primaryColor
                                        : Colors.white12,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      game.emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      game.name,
                                      style: TextStyle(
                                        color: selected
                                            ? game.primaryColor
                                            : AppTheme.textDim,
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(color: Colors.white12),
                ),

                // ── Players list ──────────────────
                Expanded(
                  child: playersAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                    data: (players) {
                      if (players.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎮', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              const Text(
                                'No players online',
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Share the app with friends\nto play together!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textDim,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          return _PlayerCard(
                                player: player,
                                gameType: setup.gameType,
                                isSending: _sending,
                                onChallenge: () =>
                                    _challenge(player, setup.gameType),
                              )
                              .animate()
                              .fadeIn(delay: (index * 80).ms, duration: 300.ms)
                              .slideX(begin: 0.1, end: 0);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Challenge ─────────────────────────────────────────

  Future<void> _challenge(OnlinePlayer player, GameType gameType) async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final profile = await _profileService.profileStream().first;

      final challengeId = await _challengeService.sendChallenge(
        toUid: player.uid,
        fromName: profile.displayName,
        fromAvatar: profile.avatarIndex,
        gameType: gameType,
      );

      setState(() {
        _pendingChallengeId = challengeId;
        _sending = false;
      });

      if (!mounted) return;
      _showWaitingDialog(challengeId, player.displayName, gameType);
    } catch (e) {
      setState(() => _sending = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showWaitingDialog(
    String challengeId,
    String playerName,
    GameType gameType,
  ) {
    setState(() => _dialogShowing = true);

    // Cancel any previous watch
    _watchChallengeSub?.cancel();

    // Watch challenge doc directly — no Riverpod needed
    _watchChallengeSub = FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .snapshots()
        .listen((snap) async {
          if (!snap.exists || !mounted) return;
          final data = snap.data()!;
          final status = data['status'] as String?;
          final roomId = data['roomId'] as String?;

          if (status == 'accepted' && roomId != null) {
            _watchChallengeSub?.cancel();

            // ✅ Wait for room to be fully ready before navigating
            try {
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .snapshots()
                  .firstWhere(
                    (snap) =>
                        snap.exists && snap.data()?['status'] == 'playing',
                  )
                  .timeout(const Duration(seconds: 10));
            } catch (_) {}

            if (!mounted) return;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() {
              _dialogShowing = false;
              _pendingChallengeId = null;
            });
            ref.read(roomIdProvider.notifier).state = roomId;
            _navigateToGame(gameType);
          } else if (status == 'declined') {
            _watchChallengeSub?.cancel();
            if (!mounted) return;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() {
              _dialogShowing = false;
              _pendingChallengeId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$playerName declined your challenge'),
                backgroundColor: Colors.red[800],
              ),
            );
          }
        });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WaitingDialog(
        playerName: playerName,
        gameType: gameType,
        onCancel: () async {
          _watchChallengeSub?.cancel();
          await FirebaseFirestore.instance
              .collection('challenges')
              .doc(challengeId)
              .update({'status': 'declined'});
          if (ctx.mounted) Navigator.of(ctx).pop();
          setState(() {
            _dialogShowing = false;
            _pendingChallengeId = null;
          });
        },
      ),
    ).then((_) {
      setState(() => _dialogShowing = false);
    });
  }

  void _showIncomingChallenge(Challenge challenge) {
    setState(() => _dialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IncomingChallengeDialog(
        challenge: challenge,
        onAccept: () async {
          try {
            final roomId = await _challengeService.acceptChallenge(
              challenge,
              _onlineService,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            setState(() => _dialogShowing = false);
            ref.read(roomIdProvider.notifier).state = roomId;
            _navigateToGame(challenge.gameType);
          } catch (e) {
            if (ctx.mounted) Navigator.of(ctx).pop();
            setState(() => _dialogShowing = false);
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        onDecline: () async {
          await _challengeService.declineChallenge(challenge.id);
          if (ctx.mounted) Navigator.of(ctx).pop();
          setState(() => _dialogShowing = false);
        },
      ),
    ).then((_) {
      setState(() => _dialogShowing = false);
    });
  }

  void _navigateToGame(GameType gameType) {
    if (!mounted) return;
    switch (gameType) {
      case GameType.matatu:
        context.go('/online-game');
      case GameType.chess:
        context.go('/online-chess');
      case GameType.checkers:
        context.go('/online-checkers');
      default:
        context.go('/online-game');
    }
  }
}

// ── Player Card ────────────────────────────────────────
class _PlayerCard extends StatelessWidget {
  final OnlinePlayer player;
  final GameType gameType;
  final bool isSending;
  final VoidCallback onChallenge;

  const _PlayerCard({
    required this.player,
    required this.gameType,
    required this.isSending,
    required this.onChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final game = GameRegistry.getGame(gameType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
              border: Border.all(
                color: player.isIdle ? Colors.greenAccent : Colors.orange,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                kAvatars[player.avatarIndex % kAvatars.length],
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: player.isIdle
                            ? Colors.greenAccent
                            : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      player.isIdle ? 'Available' : 'In a game',
                      style: TextStyle(
                        color: player.isIdle
                            ? Colors.greenAccent
                            : Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Challenge button
          if (player.isIdle)
            ElevatedButton(
              onPressed: isSending ? null : onChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: game.primaryColor.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(game.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  const Text('Challenge', style: TextStyle(fontSize: 12)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Busy',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Waiting Dialog ─────────────────────────────────────
class _WaitingDialog extends StatelessWidget {
  final String playerName;
  final GameType gameType;
  final VoidCallback onCancel;

  const _WaitingDialog({
    required this.playerName,
    required this.gameType,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final game = GameRegistry.getGame(gameType);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(game.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Challenge sent to $playerName',
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for response...',
              style: TextStyle(color: AppTheme.textDim, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Incoming Challenge Dialog ──────────────────────────
class _IncomingChallengeDialog extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingChallengeDialog({
    required this.challenge,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final game = GameRegistry.getGame(challenge.gameType);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.accent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kAvatars[challenge.fromAvatar % kAvatars.length],
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 12),
            Text(
              '${challenge.fromName} challenges you!',
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: game.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: game.primaryColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(game.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    game.name,
                    style: TextStyle(
                      color: game.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDim,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.cardBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Accept!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
