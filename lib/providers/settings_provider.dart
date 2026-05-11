import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const _key = 'app_settings';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        state = AppSettings.fromJson(jsonDecode(json));
      } catch (_) {
        state = const AppSettings();
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setCardBack(CardBackDesign design) {
    state = state.copyWith(cardBack: design);
    _save();
  }

  void setShowHints(bool value) {
    state = state.copyWith(showHints: value);
    _save();
  }

  void setAutoDraw(bool value) {
    state = state.copyWith(autoDraw: value);
    _save();
  }

  void setAiSpeed(AiSpeed speed) {
    state = state.copyWith(aiSpeed: speed);
    _save();
  }

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
    _save();
  }

  void setVolume(double value) {
    state = state.copyWith(volume: value);
    _save();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (_) => SettingsNotifier(),
);
