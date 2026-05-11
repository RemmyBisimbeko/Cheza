import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cheza_games/core/models/app_settings.dart';
import '../../../core/models/playing_card.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_theme.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceDown;
  final bool isPlayable;
  final bool isSelected;
  final bool isNew; // triggers deal animation
  final VoidCallback? onTap;
  final CardBackDesign cardBack;

  const CardWidget({
    super.key,
    this.card,
    this.faceDown = false,
    this.isPlayable = false,
    this.isSelected = false,
    this.isNew = false,
    this.cardBack = CardBackDesign.classic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardBody = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 95,
        decoration: BoxDecoration(
          color: faceDown ? AppTheme.surface : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent
                : isPlayable
                ? AppTheme.accent.withOpacity(0.6)
                : Colors.black26,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.accent.withOpacity(0.5)
                  : isPlayable
                  ? AppTheme.accent.withOpacity(0.2)
                  : Colors.black38,
              blurRadius: isSelected ? 16 : 4,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: faceDown ? _buildBack(cardBack) : _buildFace(),
      ),
    );

    // Deal animation for new cards
    if (isNew) {
      cardBody = cardBody
          .animate()
          .slideY(begin: -0.5, end: 0, duration: 300.ms, curve: Curves.easeOut)
          .fadeIn(duration: 200.ms);
    }

    // Playable pulse animation
    if (isPlayable && !isSelected) {
      cardBody = cardBody
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .elevation(begin: 0, end: 4, duration: 800.ms);
    }

    return cardBody;
  }

  Widget _buildBack(CardBackDesign design) {
    final colors = switch (design) {
      CardBackDesign.classic => [
        const Color(0xFF1A237E),
        const Color(0xFF283593),
      ],
      CardBackDesign.ugandaFlag => [
        const Color(0xFF000000),
        const Color(0xFFFFD600),
      ],
      CardBackDesign.pattern1 => [
        const Color(0xFF880E4F),
        const Color(0xFFAD1457),
      ],
      CardBackDesign.pattern2 => [
        const Color(0xFF006064),
        const Color(0xFF00838F),
      ],
      CardBackDesign.minimal => [
        const Color(0xFF212121),
        const Color(0xFF424242),
      ],
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Colors.white.withOpacity(0.3),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFace() {
    if (card == null) return const SizedBox();
    final color = _isRed(card!.suit) ? AppTheme.cardRed : AppTheme.cardBlack;
    final label = _rankLabel(card!.rank);
    final suitSymbol = _suitSymbol(card!.suit);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          Text(
            suitSymbol,
            style: TextStyle(fontSize: 11, color: color, height: 1),
          ),
          Expanded(
            child: Center(
              child: Text(
                suitSymbol,
                style: TextStyle(fontSize: 26, color: color),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    suitSymbol,
                    style: TextStyle(fontSize: 11, color: color, height: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRed(Suit suit) => suit == Suit.hearts || suit == Suit.diamonds;

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
