import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../core/models/app_settings.dart';
import '../../core/constants/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        [
                              // ── Appearance ────────────────────
                              _SectionHeader('Appearance'),

                              // Theme
                              _SettingsTile(
                                icon: Icons.palette_outlined,
                                title: 'Theme',
                                subtitle: _themeName(settings.themeMode),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: AppThemeMode.values.map((mode) {
                                    final selected = settings.themeMode == mode;
                                    return GestureDetector(
                                      onTap: () => notifier.setThemeMode(mode),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(left: 8),
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _themeColor(mode),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selected
                                                ? AppTheme.accent
                                                : Colors.transparent,
                                            width: 2.5,
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.accent
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Card Back Design
                              _SettingsTile(
                                icon: Icons.style_outlined,
                                title: 'Card Back',
                                subtitle: _cardBackName(settings.cardBack),
                                child: null,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 90,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: CardBackDesign.values.map((design) {
                                    final selected =
                                        settings.cardBack == design;
                                    return GestureDetector(
                                      onTap: () => notifier.setCardBack(design),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        width: 58,
                                        height: 86,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? AppTheme.accent
                                                : Colors.white24,
                                            width: selected ? 2.5 : 1,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: _cardBackColors(design),
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.accent
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Center(
                                          child: Text(
                                            _cardBackEmoji(design),
                                            style: const TextStyle(
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Gameplay ──────────────────────
                              _SectionHeader('Gameplay'),

                              _SwitchTile(
                                icon: Icons.lightbulb_outline,
                                title: 'Show Card Hints',
                                subtitle: 'Highlight cards you can play',
                                value: settings.showHints,
                                onChanged: notifier.setShowHints,
                              ),

                              const SizedBox(height: 8),

                              _SwitchTile(
                                icon: Icons.download_outlined,
                                title: 'Auto Draw',
                                subtitle:
                                    'Automatically draw when no card to play',
                                value: settings.autoDraw,
                                onChanged: notifier.setAutoDraw,
                              ),

                              const SizedBox(height: 8),

                              // AI Speed
                              _SettingsTile(
                                icon: Icons.speed_outlined,
                                title: 'AI Speed',
                                subtitle: _aiSpeedName(settings.aiSpeed),
                                child: SegmentedButton<AiSpeed>(
                                  segments: const [
                                    ButtonSegment(
                                      value: AiSpeed.slow,
                                      label: Text(
                                        'Slow',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: AiSpeed.normal,
                                      label: Text(
                                        'Normal',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: AiSpeed.fast,
                                      label: Text(
                                        'Fast',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                  selected: {settings.aiSpeed},
                                  onSelectionChanged: (val) =>
                                      notifier.setAiSpeed(val.first),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                WidgetState.selected,
                                              )
                                              ? AppTheme.accent.withOpacity(0.3)
                                              : Colors.transparent,
                                        ),
                                    foregroundColor: WidgetStateProperty.all(
                                      AppTheme.textLight,
                                    ),
                                    side: WidgetStateProperty.all(
                                      const BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Sound ─────────────────────────
                              _SectionHeader('Sound'),

                              _SwitchTile(
                                icon: Icons.volume_up_outlined,
                                title: 'Sound Effects',
                                subtitle: 'Card plays, draws and wins',
                                value: settings.soundEnabled,
                                onChanged: notifier.setSoundEnabled,
                              ),

                              const SizedBox(height: 8),

                              // Volume slider
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
                                      children: [
                                        const Icon(
                                          Icons.music_note,
                                          color: AppTheme.textDim,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Volume',
                                            style: TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${(settings.volume * 100).round()}%',
                                          style: const TextStyle(
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppTheme.accent,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: AppTheme.accent,
                                        overlayColor: AppTheme.accent
                                            .withOpacity(0.2),
                                      ),
                                      child: Slider(
                                        value: settings.volume,
                                        onChanged: settings.soundEnabled
                                            ? notifier.setVolume
                                            : null,
                                        min: 0,
                                        max: 1,
                                        divisions: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── About ─────────────────────────
                              _SectionHeader('About'),

                              _InfoTile(
                                icon: Icons.info_outline,
                                title: 'Version',
                                value: '1.0.0',
                              ),

                              const SizedBox(height: 8),

                              _InfoTile(
                                icon: Icons.flag_outlined,
                                title: 'Origin',
                                value: 'Made in Uganda 🇺🇬',
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_outline,
                                      color: AppTheme.accent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Matatu — The Ugandan Card Game',
                                        style: TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),
                            ]
                            .map(
                              (w) => w
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.1, end: 0),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.tableGreen:
        return 'Table Green';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
    }
  }

  Color _themeColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.tableGreen:
        return AppTheme.tableGreen;
      case AppThemeMode.dark:
        return const Color(0xFF121212);
      case AppThemeMode.light:
        return const Color(0xFFF5F5F5);
    }
  }

  String _cardBackName(CardBackDesign design) {
    switch (design) {
      case CardBackDesign.classic:
        return 'Classic Blue';
      case CardBackDesign.ugandaFlag:
        return 'Uganda Flag';
      case CardBackDesign.pattern1:
        return 'Diamonds';
      case CardBackDesign.pattern2:
        return 'Waves';
      case CardBackDesign.minimal:
        return 'Minimal';
    }
  }

  String _cardBackEmoji(CardBackDesign design) {
    switch (design) {
      case CardBackDesign.classic:
        return '🟦';
      case CardBackDesign.ugandaFlag:
        return '🇺🇬';
      case CardBackDesign.pattern1:
        return '💎';
      case CardBackDesign.pattern2:
        return '🌊';
      case CardBackDesign.minimal:
        return '⬛';
    }
  }

  List<Color> _cardBackColors(CardBackDesign design) {
    switch (design) {
      case CardBackDesign.classic:
        return [const Color(0xFF1A237E), const Color(0xFF283593)];
      case CardBackDesign.ugandaFlag:
        return [const Color(0xFF000000), const Color(0xFFFFD600)];
      case CardBackDesign.pattern1:
        return [const Color(0xFF880E4F), const Color(0xFFAD1457)];
      case CardBackDesign.pattern2:
        return [const Color(0xFF006064), const Color(0xFF00838F)];
      case CardBackDesign.minimal:
        return [const Color(0xFF212121), const Color(0xFF424242)];
    }
  }

  String _aiSpeedName(AiSpeed speed) {
    switch (speed) {
      case AiSpeed.slow:
        return 'Slow — 2 seconds';
      case AiSpeed.normal:
        return 'Normal — 0.8 seconds';
      case AiSpeed.fast:
        return 'Fast — 0.3 seconds';
    }
  }
}

// ── Section Header ─────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ── Switch Tile ────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accent.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ──────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textDim, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
