import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/setup_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/profile_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/models/game_registry.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupProvider);
    final notifier = ref.read(setupProvider.notifier);
    final profileAsync = ref.watch(profileStreamProvider);
    final avatarIndex = profileAsync.maybeWhen(
      data: (p) => p.avatarIndex,
      orElse: () => 0,
    );

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
                // ── Top bar ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppTheme.textDim,
                          size: 24,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.go('/timer'),
                        icon: const Icon(
                          Icons.hourglass_bottom_rounded,
                          color: Color(0xFFFFD600),
                          size: 26,
                        ),
                      ),
                      const Text(
                        'CHEEZA',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.go('/profile'),
                        icon: Text(
                          kAvatars[avatarIndex % kAvatars.length],
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Game picker ───────────────
                        const _SectionLabel('Choose a game'),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: GameRegistry.games.map((game) {
                            final selected = setup.gameType == game.type;
                            return _GameCard(
                              game: game,
                              selected: selected,
                              onTap: () => notifier.setGameType(game.type),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // ── Game Mode ─────────────────
                        const _SectionLabel('Game mode'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ModeButton(
                              label: 'vs AI',
                              icon: Icons.smart_toy_outlined,
                              selected: setup.mode == GameMode.vsAI,
                              onTap: () => notifier.setMode(GameMode.vsAI),
                            ),
                            const SizedBox(width: 10),
                            _ModeButton(
                              label: 'Online',
                              icon: Icons.wifi_outlined,
                              selected:
                                  setup.mode == GameMode.onlineMultiplayer,
                              onTap: () =>
                                  notifier.setMode(GameMode.onlineMultiplayer),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Players (only for AI mode) ─
                        if (setup.mode == GameMode.vsAI) ...[
                          const _SectionLabel('Number of players'),
                          const SizedBox(height: 10),
                          _buildPlayerCount(context, setup, notifier),
                          const SizedBox(height: 24),
                        ],

                        // ── Player Name ───────────────
                        const _SectionLabel('Your name'),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: notifier.setPlayerName,
                          style: const TextStyle(color: AppTheme.textLight),
                          maxLength: 12,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: const TextStyle(color: AppTheme.textDim),
                            counterStyle: const TextStyle(
                              color: AppTheme.textDim,
                            ),
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
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppTheme.textDim,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Play Button ───────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(profileServiceProvider)
                                  .ensureProfile(setup.playerName);
                              if (!context.mounted) return;
                              if (setup.mode == GameMode.onlineMultiplayer) {
                                context.go('/online');
                              } else {
                                context.go('/game');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: AppTheme.cardBlack,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  GameRegistry.getGame(setup.gameType).emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PLAY ${GameRegistry.getGame(setup.gameType).name.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: () =>
                                _showHowToPlay(context, setup.gameType),
                            child: const Text(
                              'How to Play',
                              style: TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.textDim,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCount(
    BuildContext context,
    GameSetup setup,
    SetupNotifier notifier,
  ) {
    final game = GameRegistry.getGame(setup.gameType);
    final counts = List.generate(
      game.maxPlayers - game.minPlayers + 1,
      (i) => i + game.minPlayers,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: counts.map((count) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => notifier.setPlayerCount(count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: setup.playerCount == count
                    ? AppTheme.accent
                    : Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: setup.playerCount == count
                      ? AppTheme.accent
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: setup.playerCount == count
                        ? AppTheme.cardBlack
                        : AppTheme.textDim,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showHowToPlay(BuildContext context, GameType gameType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HowToPlaySheet(gameType: gameType),
    );
  }
}

// ── Game Card ──────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final GameInfo game;
  final bool selected;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected
                  ? game.primaryColor.withOpacity(0.25)
                  : Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? game.primaryColor : Colors.white12,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: game.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Coming soon overlay
                if (!game.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Card content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(game.emoji, style: const TextStyle(fontSize: 32)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: TextStyle(
                              color: selected
                                  ? game.primaryColor
                                  : AppTheme.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            game.description,
                            style: const TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}

// ── Section Label ──────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textDim,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Mode Button ────────────────────────────────────────
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.cardBlack : AppTheme.textDim,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.cardBlack : AppTheme.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── How to Play Sheet ──────────────────────────────────
class _HowToPlaySheet extends StatelessWidget {
  final GameType gameType;
  const _HowToPlaySheet({required this.gameType});

  @override
  Widget build(BuildContext context) {
    final rules = _getRules(gameType);
    final game = GameRegistry.getGame(gameType);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Text(
              '${game.emoji} How to Play ${game.name}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule['icon']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule['title']!,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          rule['desc']!,
                          style: const TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Map<String, String>> _getRules(GameType type) {
    switch (type) {
      case GameType.matatu:
        return _matatuRules;
      case GameType.chess:
        return _chessRules;
      case GameType.checkers:
        return _checkersRules;
      case GameType.ludo:
        return _ludoRules;
    }
  }

  static const _matatuRules = [
    {
      'icon': '🎯',
      'title': 'Goal',
      'desc': 'Empty your hand first, or cut the game with a 7.',
    },
    {
      'icon': '🃏',
      'title': 'Playing',
      'desc': 'Match the suit or rank of the top discard card.',
    },
    {
      'icon': '2️⃣',
      'title': 'Two — Pick 2',
      'desc': 'Next player draws 2. Stack 2s to pass it on!',
    },
    {
      'icon': '7️⃣',
      'title': 'Seven — Chopper',
      'desc': 'Cuts the game. Only the 7 matching the cut card suit works!',
    },
    {
      'icon': '8️⃣',
      'title': 'Eight — Skip',
      'desc': 'Next player loses their turn.',
    },
    {
      'icon': '🃏',
      'title': 'Jack — Reverse',
      'desc': 'Reverses direction. In 2-player, your turn again!',
    },
    {
      'icon': '🅰️',
      'title': 'Ace — Change Suit',
      'desc': 'Play on any card and choose the next suit.',
    },
    {
      'icon': '📢',
      'title': 'Matatu!',
      'desc': 'Say it when you have one card left or face a penalty.',
    },
  ];

  static const _chessRules = [
    {'icon': '🎯', 'title': 'Goal', 'desc': 'Checkmate your opponent\'s king.'},
    {
      'icon': '♟️',
      'title': 'Movement',
      'desc':
          'Each piece moves differently. Pawns forward, rooks straight, bishops diagonal.',
    },
    {
      'icon': '👑',
      'title': 'Check',
      'desc': 'When the king is threatened, the player must escape check.',
    },
    {
      'icon': '🏆',
      'title': 'Checkmate',
      'desc': 'King is in check with no escape — game over!',
    },
    {
      'icon': '🤝',
      'title': 'Draw',
      'desc': 'Stalemate, insufficient material, or threefold repetition.',
    },
  ];

  static const _checkersRules = [
    {
      'icon': '🎯',
      'title': 'Goal',
      'desc': 'Capture all opponent pieces or block them from moving.',
    },
    {
      'icon': '🔴',
      'title': 'Movement',
      'desc': 'Pieces move diagonally forward one square at a time.',
    },
    {
      'icon': '⚡',
      'title': 'Capture',
      'desc':
          'Jump over opponent pieces to capture them. Multiple jumps allowed!',
    },
    {
      'icon': '👑',
      'title': 'King',
      'desc':
          'Reach the opposite end to become a king — moves in all directions.',
    },
    {
      'icon': '🏆',
      'title': 'Win',
      'desc': 'Capture all opponent pieces or leave them with no moves.',
    },
  ];

  static const _ludoRules = [
    {
      'icon': '🎯',
      'title': 'Goal',
      'desc': 'Be first to move all 4 tokens from start to home.',
    },
    {
      'icon': '🎲',
      'title': 'Dice',
      'desc':
          'Roll the dice and move one of your tokens that number of spaces.',
    },
    {
      'icon': '6️⃣',
      'title': 'Roll a 6',
      'desc': 'Enter a token onto the board and roll again!',
    },
    {
      'icon': '💥',
      'title': 'Capture',
      'desc': 'Land on an opponent\'s token to send it back to start.',
    },
    {
      'icon': '🏠',
      'title': 'Safe squares',
      'desc': 'Starred squares are safe — pieces cannot be captured there.',
    },
    {
      'icon': '🏆',
      'title': 'Win',
      'desc': 'Get all 4 tokens to the home triangle first.',
    },
  ];
}
