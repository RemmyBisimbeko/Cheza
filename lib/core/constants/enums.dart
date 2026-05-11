enum GameType { matatu, chess, checkers, ludo }

enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

enum GameMode { vsAI, onlineMultiplayer }

enum GamePhase { waiting, playing, awaitingSuit, gameOver }

enum SpecialEffect {
  skip, // 8, Jack
  pickTwo, // 2
  changeSuit, // Ace
  reverse, // King
  chopper, // 7 — cuts game
  none,
}
