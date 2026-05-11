import 'package:flutter/material.dart';

enum AppThemeMode { dark, light, tableGreen }

enum CardBackDesign { classic, ugandaFlag, pattern1, pattern2, minimal }

enum AiSpeed { slow, normal, fast }

class AppSettings {
  final AppThemeMode themeMode;
  final CardBackDesign cardBack;
  final bool showHints;
  final bool autoDraw;
  final AiSpeed aiSpeed;
  final bool soundEnabled;
  final double volume;

  const AppSettings({
    this.themeMode = AppThemeMode.tableGreen,
    this.cardBack = CardBackDesign.classic,
    this.showHints = true,
    this.autoDraw = false,
    this.aiSpeed = AiSpeed.normal,
    this.soundEnabled = true,
    this.volume = 0.8,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    CardBackDesign? cardBack,
    bool? showHints,
    bool? autoDraw,
    AiSpeed? aiSpeed,
    bool? soundEnabled,
    double? volume,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    cardBack: cardBack ?? this.cardBack,
    showHints: showHints ?? this.showHints,
    autoDraw: autoDraw ?? this.autoDraw,
    aiSpeed: aiSpeed ?? this.aiSpeed,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    volume: volume ?? this.volume,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'cardBack': cardBack.name,
    'showHints': showHints,
    'autoDraw': autoDraw,
    'aiSpeed': aiSpeed.name,
    'soundEnabled': soundEnabled,
    'volume': volume,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: AppThemeMode.values.byName(json['themeMode'] ?? 'tableGreen'),
    cardBack: CardBackDesign.values.byName(json['cardBack'] ?? 'classic'),
    showHints: json['showHints'] ?? true,
    autoDraw: json['autoDraw'] ?? false,
    aiSpeed: AiSpeed.values.byName(json['aiSpeed'] ?? 'normal'),
    soundEnabled: json['soundEnabled'] ?? true,
    volume: (json['volume'] ?? 0.8).toDouble(),
  );
}
