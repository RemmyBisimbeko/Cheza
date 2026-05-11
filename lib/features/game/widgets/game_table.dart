import 'package:flutter/material.dart';
import 'package:cheza_games/core/models/player.dart';
import '../../../core/models/game_state.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/enums.dart';
import 'card_widget.dart';

class GameTable extends StatelessWidget {
  final GameState state;
  final VoidCallback onDraw;
  final void Function(Suit) onSuitSelected;

  const GameTable({
    super.key,
    required this.state,
    required this.onDraw,
    required this.onSuitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Status message ────────────────────────────
        if (state.message != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.message!,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
            ),
          ),

        // ── Deck + Discard ────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Deck pile
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: state.currentPlayer.type == PlayerType.human
                      ? onDraw
                      : null,
                  child: SizedBox(
                    width: 75,
                    height: 100,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 3,
                          left: 2,
                          child: const CardWidget(faceDown: true),
                        ),
                        Positioned(
                          top: 1.5,
                          left: 1,
                          child: const CardWidget(faceDown: true),
                        ),
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: CardWidget(faceDown: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${state.deck.length} left',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),

            // Add this next to the deck pile in the Row:
            if (state.cutCard != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: 1.5708, // 90 degrees — sideways
                      child: SizedBox(
                        width: 65,
                        height: 95,
                        child: CardWidget(card: state.cutCard),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cut card',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),

            const SizedBox(width: 40),

            // Discard pile
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 75,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CardWidget(card: state.topCard),
                      // Declared suit badge
                      if (state.declaredSuit != null)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _suitSymbol(state.declaredSuit!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Discard',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        // ── Suit selector (when Ace played) ──────────
        if (state.phase == GamePhase.awaitingSuit) ...[
          const SizedBox(height: 20),
          const Text(
            'Choose a suit:',
            style: TextStyle(color: AppTheme.textLight, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: Suit.values.map((suit) {
              return GestureDetector(
                onTap: () => onSuitSelected(suit),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _suitSymbol(suit),
                      style: TextStyle(
                        fontSize: 26,
                        color: suit == Suit.hearts || suit == Suit.diamonds
                            ? AppTheme.cardRed
                            : AppTheme.cardBlack,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
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
}
