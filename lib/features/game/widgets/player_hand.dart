import 'package:flutter/material.dart';
import '../../../core/models/playing_card.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/enums.dart';
import '../../../core/engine/game_engine.dart';
import 'card_widget.dart';

class PlayerHand extends StatefulWidget {
  final GameState state;
  final GameEngine engine;
  final void Function(PlayingCard) onCardPlayed;

  const PlayerHand({
    super.key,
    required this.state,
    required this.engine,
    required this.onCardPlayed,
  });

  @override
  State<PlayerHand> createState() => _PlayerHandState();
}

class _PlayerHandState extends State<PlayerHand> {
  PlayingCard? _selected;

  @override
  Widget build(BuildContext context) {
    final player = widget.state.players.firstWhere(
      (p) => p.type == PlayerType.human,
      orElse: () => widget.state.players.first,
    );

    final isMyTurn =
        widget.state.currentPlayer.id == player.id &&
        widget.state.phase == GamePhase.playing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Your turn badge
        Opacity(
          opacity: isMyTurn ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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

        // Play button
        if (_selected != null && isMyTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onCardPlayed(_selected!);
                setState(() => _selected = null);
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Play Card'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),

        // Card hand — SizedBox height = card height only, dot drawn inside
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: player.hand.length,
            itemBuilder: (context, index) {
              final card = player.hand[index];
              final canPlay =
                  isMyTurn && widget.engine.canPlay(card, widget.state);
              final isSelected = _selected == card;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CardWidget(
                  card: card,
                  isPlayable: canPlay,
                  isSelected: isSelected,
                  onTap: isMyTurn
                      ? () => setState(() {
                          _selected = isSelected ? null : card;
                        })
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
