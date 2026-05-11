import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/profile_service.dart';
import '../../core/constants/app_theme.dart';

// Emoji avatars to pick from
const kAvatars = [
  '😎',
  '🦁',
  '🐯',
  '🦊',
  '🐺',
  '🦝',
  '🐸',
  '🐲',
  '👑',
  '🎭',
  '🃏',
  '⚡',
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0; // 0 = profile, 1 = leaderboard

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Scaffold(
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
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                        const Spacer(),
                        // Tab switcher
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TabButton(
                                label: 'Profile',
                                icon: Icons.person,
                                selected: _tab == 0,
                                onTap: () => setState(() => _tab = 0),
                              ),
                              _TabButton(
                                label: 'Leaderboard',
                                icon: Icons.leaderboard,
                                selected: _tab == 1,
                                onTap: () => setState(() => _tab = 1),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _tab == 0
                        ? const _ProfileTab()
                        : const _LeaderboardTab(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Button ─────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppTheme.cardBlack : AppTheme.textDim,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.cardBlack : AppTheme.textDim,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Tab ────────────────────────────────────────
class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  bool _editingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: Colors.red)),
      ),
      data: (profile) {
        _nameController.text = profile.displayName;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textDim),
                onPressed: () => ref.invalidate(profileStreamProvider),
              ),

              const SizedBox(height: 20),

              // ── Avatar ────────────────────────────────
              Text(
                kAvatars[profile.avatarIndex % kAvatars.length],
                style: const TextStyle(fontSize: 80),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 8),

              // Avatar picker
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kAvatars.length,
                  itemBuilder: (context, i) {
                    final selected = i == profile.avatarIndex;
                    return GestureDetector(
                      onTap: () => ref
                          .read(profileServiceProvider)
                          .updateProfile(avatarIndex: i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.accent.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppTheme.accent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            kAvatars[i],
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Name ─────────────────────────────────
              if (_editingName)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        maxLength: 12,
                        style: const TextStyle(color: AppTheme.textLight),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppTheme.accent),
                      onPressed: () {
                        ref
                            .read(profileServiceProvider)
                            .updateProfile(
                              displayName: _nameController.text.trim(),
                            );
                        setState(() => _editingName = false);
                      },
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: AppTheme.textDim,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _editingName = true),
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // ── Stats Grid ────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    label: 'Games Played',
                    value: '${profile.gamesPlayed}',
                    icon: '🎮',
                  ),
                  _StatCard(
                    label: 'Games Won',
                    value: '${profile.gamesWon}',
                    icon: '🏆',
                  ),
                  _StatCard(
                    label: 'Win Rate',
                    value: '${profile.winRate.toStringAsFixed(1)}%',
                    icon: '📊',
                  ),
                  _StatCard(
                    label: 'Best Streak',
                    value: '${profile.bestStreak}',
                    icon: '🔥',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Win streak bar ────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Streak',
                          style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '🔥 ${profile.winStreak}',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: profile.bestStreak == 0
                            ? 0
                            : profile.winStreak / profile.bestStreak,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat Card ──────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

// ── Leaderboard Tab ────────────────────────────────────
class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardStreamProvider);
    final myUid = ref.read(profileServiceProvider).currentUid;

    return boardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: Colors.red)),
      ),
      data: (players) {
        if (players.isEmpty) {
          return const Center(
            child: Text(
              'No players yet.\nPlay some games to appear here!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDim, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final isMe = player.uid == myUid;
            final rank = index + 1;

            return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.accent.withOpacity(0.15)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMe ? AppTheme.accent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 36,
                        child: Text(
                          rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                          style: TextStyle(
                            fontSize: rank <= 3 ? 22 : 14,
                            color: AppTheme.textDim,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Avatar
                      Text(
                        kAvatars[player.avatarIndex % kAvatars.length],
                        style: const TextStyle(fontSize: 28),
                      ),

                      const SizedBox(width: 12),

                      // Name + stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  player.displayName,
                                  style: TextStyle(
                                    color: isMe
                                        ? AppTheme.accent
                                        : AppTheme.textLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${player.gamesWon}W · ${player.gamesLost}L · ${player.winRate.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Win count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${player.gamesWon} wins',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                .slideX(begin: 0.1, end: 0);
          },
        );
      },
    );
  }
}
