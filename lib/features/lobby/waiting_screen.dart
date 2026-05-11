import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cheza_games/core/constants/enums.dart';
import '../../providers/online_provider.dart';
import '../../services/online_service.dart';
import '../../core/constants/app_theme.dart';

class WaitingScreen extends ConsumerWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(roomIdProvider);
    final code = ref.watch(roomCodeProvider);

    if (roomId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roomAsync = ref.watch(roomStreamProvider(roomId));

    return roomAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.tableGreen,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (room) {
        final players = List<Map>.from(room['players'] ?? []);
        final needed = room['playerCount'] ?? 2;
        final isHost =
            room['hostId'] == ref.read(onlineServiceProvider).currentUid;

        // Auto-navigate when game starts
        if (room['status'] == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final gameType = GameType.values.byName(
              room['gameType'] ?? 'matatu',
            );
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
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.tableGreen,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
              onPressed: () => context.go('/'),
            ),
            title: const Text(
              'Waiting Room',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Room code display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Room Code',
                        style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        code ?? '------',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                          color: AppTheme.textDim,
                        ),
                        label: const Text(
                          'Copy',
                          style: TextStyle(color: AppTheme.textDim),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Players list
                Text(
                  'Players ${players.length}/$needed',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...players.map(
                  (p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          p['name'],
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (room['hostId'] == p['id'])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Host',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Start button (host only)
                if (isHost)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: players.length >= needed
                          ? () async {
                              await ref
                                  .read(onlineServiceProvider)
                                  .startOnlineGame(roomId);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        players.length >= needed
                            ? 'Start Game'
                            : 'Waiting for players...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    'Waiting for host to start...',
                    style: TextStyle(color: AppTheme.textDim),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
