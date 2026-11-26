import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User's glass preference. `auto` picks a sensible tier per platform
/// (a GPU benchmark replaces this heuristic in Phase 9).
enum GlassPreference { auto, liquid, frosted, solid }

enum LanguagePreference { system, en, ru }

/// Device-local UI preferences. (Synced settings arrive with accounts in
/// Phase 2.)
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.glass = GlassPreference.auto,
    this.reduceMotion = false,
    this.reduceTransparency = false,
    this.language = LanguagePreference.system,
  });

  final ThemeMode themeMode;
  final GlassPreference glass;

  /// In-app override; the OS setting is always honoured as well.
  final bool reduceMotion;

  /// In-app switch (Flutter doesn't expose the OS "Reduce Transparency"
  /// flag on every platform).
  final bool reduceTransparency;
  final LanguagePreference language;

  Locale? get locale => switch (language) {
    LanguagePreference.system => null,
    LanguagePreference.en => const Locale('en'),
    LanguagePreference.ru => const Locale('ru'),
  };

  GlassQuality resolveQuality({required bool isWeb}) => switch (glass) {
    GlassPreference.auto => isWeb ? GlassQuality.frosted : GlassQuality.liquid,
    GlassPreference.liquid => GlassQuality.liquid,
    GlassPreference.frosted => GlassQuality.frosted,
    GlassPreference.solid => GlassQuality.solid,
  };

  AppSettings copyWith({
    ThemeMode? themeMode,
    GlassPreference? glass,
    bool? reduceMotion,
    bool? reduceTransparency,
    LanguagePreference? language,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    glass: glass ?? this.glass,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.glass == glass &&
      other.reduceMotion == reduceMotion &&
      other.reduceTransparency == reduceTransparency &&
      other.language == language;

  @override
  int get hashCode =>
      Object.hash(themeMode, glass, reduceMotion, reduceTransparency, language);
}

/// Provided by `main()` after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'settings.themeMode';
  static const _kGlass = 'settings.glass';
  static const _kMotion = 'settings.reduceMotion';
  static const _kTransparency = 'settings.reduceTransparency';
  static const _kLanguage = 'settings.language';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  T _enum<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  @override
  AppSettings build() {
    final p = _prefs;
    return AppSettings(
      themeMode: _enum(
        ThemeMode.values,
        p.getString(_kTheme),
        ThemeMode.system,
      ),
      glass: _enum(
        GlassPreference.values,
        p.getString(_kGlass),
        GlassPreference.auto,
      ),
      reduceMotion: p.getBool(_kMotion) ?? false,
      reduceTransparency: p.getBool(_kTransparency) ?? false,
      language: _enum(
        LanguagePreference.values,
        p.getString(_kLanguage),
        LanguagePreference.system,
      ),
    );
  }

  void setThemeMode(ThemeMode v) {
    state = state.copyWith(themeMode: v);
    _prefs.setString(_kTheme, v.name);
  }

  void setGlass(GlassPreference v) {
    state = state.copyWith(glass: v);
    _prefs.setString(_kGlass, v.name);
  }

  void setReduceMotion(bool v) {
    state = state.copyWith(reduceMotion: v);
    _prefs.setBool(_kMotion, v);
  }

  void setReduceTransparency(bool v) {
    state = state.copyWith(reduceTransparency: v);
    _prefs.setBool(_kTransparency, v);
  }

  void setLanguage(LanguagePreference v) {
    state = state.copyWith(language: v);
    _prefs.setString(_kLanguage, v.name);
  }

  /// Flips between light and dark, resolving "system" against [current].
  void toggleBrightness(Brightness current) {
    setThemeMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
