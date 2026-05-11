import 'package:flutter/material.dart';
import '../../../core/models/player.dart';
import '../../../core/constants/app_theme.dart';
import 'card_widget.dart';

class OpponentRow extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;

  const OpponentRow({
    super.key,
    required this.player,
    required this.isCurrentTurn,
  });

  @override
  Widget build(BuildContext context) {
    final cardCount = player.hand.length.clamp(0, 7);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player name + turn indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentTurn
                ? AppTheme.accent.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentTurn ? AppTheme.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrentTurn)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              Text(
                player.name,
                style: TextStyle(
                  color: isCurrentTurn ? AppTheme.accent : AppTheme.textDim,
                  fontWeight: isCurrentTurn
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${player.hand.length}',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Face-down cards — using Row instead of Stack+Positioned
        SizedBox(
          width: 65 + (cardCount - 1) * 12.0,
          height: 75,
          child: cardCount == 0
              ? const SizedBox()
              : Stack(
                  children: List.generate(cardCount, (i) {
                    return Positioned(
                      left: i * 12.0,
                      top: 0,
                      child: SizedBox(
                        width: 65,
                        height: 75,
                        child: const CardWidget(faceDown: true),
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }
}
