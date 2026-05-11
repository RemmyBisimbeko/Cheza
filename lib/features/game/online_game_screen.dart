import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/online_game_provider.dart';
import '../../providers/online_provider.dart';
import '../../services/online_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../core/engine/game_engine.dart';
import '../../core/models/player.dart';
import '../../core/models/playing_card.dart';
import 'widgets/opponent_row.dart';
import 'widgets/game_table.dart';
import 'widgets/game_over_overlay.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key});

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  PlayingCard? _selected;
  final _engine = GameEngine();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final roomId = ref.watch(roomIdProvider);
    final gameAsync = ref.watch(onlineGameStateProvider);
    final service = ref.read(onlineServiceProvider);
    final myUid = service.currentUid;

    return ExcludeSemantics(
      child: Scaffold(
        backgroundColor: AppTheme.tableGreen,
        body: gameAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppTheme.textLight),
            ),
          ),
          data: (gameState) {
            if (gameState == null || roomId == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              );
            }

            final myPlayer = gameState.players.firstWhere(
              (p) => p.id == myUid,
              orElse: () => gameState.players.first,
            );

            final opponents = gameState.players
                .where((p) => p.id != myUid)
                .toList();

            final isMyTurn =
                gameState.currentPlayer.id == myUid &&
                gameState.phase == GamePhase.playing;

            return Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [AppTheme.tableFelt, AppTheme.tableGreen],
                    ),
                  ),
                ),

                SafeArea(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Top Bar ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.textLight,
                                ),
                                onPressed: () {
                                  ref.read(roomIdProvider.notifier).state =
                                      null;
                                  context.go('/');
                                },
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'MATATU',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  Text(
                                    'ONLINE',
                                    style: TextStyle(
                                      color: AppTheme.accent.withOpacity(0.6),
                                      fontSize: 10,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                              // Matatu button
                              TextButton(
                                onPressed: myPlayer.hand.length == 1
                                    ? () => _callMatatuOnline(roomId, service)
                                    : null,
                                child: Text(
                                  'MATATU!',
                                  style: TextStyle(
                                    color: myPlayer.hand.length == 1
                                        ? AppTheme.accent
                                        : AppTheme.textDim,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Connection indicator ──────────────
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${gameState.players.length} players connected',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Opponents ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: opponents.map((o) {
                              return OpponentRow(
                                player: o,
                                isCurrentTurn:
                                    gameState.currentPlayer.id == o.id,
                              );
                            }).toList(),
                          ),
                        ),

                        // ── Game Table ────────────────────────
                        Expanded(
                          child: Center(
                            child: GameTable(
                              state: gameState,
                              onDraw: isMyTurn
                                  ? () => _drawCard(roomId, service)
                                  : () {},
                              onSuitSelected: (suit) =>
                                  _declareSuit(roomId, suit, service),
                            ),
                          ),
                        ),

                        // ── My Turn indicator ─────────────────
                        Opacity(
                          opacity: isMyTurn ? 1.0 : 0.0,
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Your turn',
                                style: TextStyle(
                                  color: AppTheme.cardBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Play button ───────────────────────
                        if (_selected != null && isMyTurn)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null // 👈 disabled while processing
                                  : () {
                                      _playCard(roomId!, _selected!, service);
                                      setState(() => _selected = null);
                                    },
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.cardBlack,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow, size: 18),
                              label: Text(
                                _isProcessing ? 'Playing...' : 'Play Card',
                              ),
                            ),
                          ),

                        // ── My Hand ───────────────────────────
                        SizedBox(
                          height: 95,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: myPlayer.hand.length,
                            itemBuilder: (context, index) {
                              final card = myPlayer.hand[index];
                              final canPlay =
                                  isMyTurn && _engine.canPlay(card, gameState);
                              final isSelected = _selected == card;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: isMyTurn
                                      ? () => setState(() {
                                          _selected = isSelected ? null : card;
                                        })
                                      : null,
                                  child: Container(
                                    width: 65,
                                    height: 95,
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardWhite,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.accent
                                            : canPlay
                                            ? AppTheme.accent.withOpacity(0.5)
                                            : Colors.black26,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? AppTheme.accent.withOpacity(0.4)
                                              : Colors.black38,
                                          blurRadius: isSelected ? 12 : 4,
                                          offset: const Offset(2, 3),
                                        ),
                                      ],
                                    ),
                                    child: _buildCardFace(card),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Game Over Overlay ─────────────────────
                if (gameState.phase == GamePhase.gameOver)
                  GameOverOverlay(
                    state: gameState,
                    onPlayAgain: () {
                      ref.read(roomIdProvider.notifier).state = null;
                      context.go('/');
                    },
                    onHome: () {
                      ref.read(roomIdProvider.notifier).state = null;
                      context.go('/');
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────

  Future<void> _playCard(
    String roomId,
    PlayingCard card,
    OnlineService service,
  ) async {
    if (_isProcessing) return; // 👈 prevent double tap
    setState(() => _isProcessing = true);

    try {
      await service.playCard(roomId, card);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _drawCard(String roomId, OnlineService service) async {
    if (_isProcessing) return; // 👈 prevent double tap
    setState(() => _isProcessing = true);

    try {
      await service.drawCard(roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _declareSuit(
    String roomId,
    Suit suit,
    OnlineService service,
  ) async {
    try {
      await service.playCard(
        roomId,
        const PlayingCard(suit: Suit.spades, rank: Rank.ace),
        chosenSuit: suit,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _callMatatuOnline(String roomId, OnlineService service) async {
    // Update hasCalledMatatu flag in Firestore
    try {
      final myUid = service.currentUid;
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'players': FieldValue.arrayRemove([]),
        // We update via a transaction instead
      });
    } catch (_) {}
  }

  // ── Card Face Builder ─────────────────────────────────

  Widget _buildCardFace(PlayingCard card) {
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? AppTheme.cardRed : AppTheme.cardBlack;
    final suit = _suitSymbol(card.suit);
    final rank = _rankLabel(card.rank);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rank,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          Text(suit, style: TextStyle(fontSize: 11, color: color, height: 1)),
          Expanded(
            child: Center(
              child: Text(suit, style: TextStyle(fontSize: 26, color: color)),
            ),
          ),
        ],
      ),
    );
  }

  String _suitSymbol(Suit suit) {
    switch (suit) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  String _rankLabel(Rank rank) {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.king:
        return 'K';
      case Rank.queen:
        return 'Q';
      case Rank.jack:
        return 'J';
      case Rank.ten:
        return '10';
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
    }
  }
}
