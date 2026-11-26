import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'settings.dart';

class MindoraApp extends ConsumerWidget {
  const MindoraApp({super.key});

  /// Web bundles Inter (never fetched from a CDN); native uses the system
  /// font. Fallbacks cover Cyrillic on every platform.
  static const String? _fontFamily = kIsWeb ? 'Inter' : null;
  static const _fallback = ['Inter', 'Segoe UI', 'Roboto', 'Helvetica Neue'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    ThemeData theme(Brightness b, {bool hc = false}) => buildMindoraTheme(
      brightness: b,
      highContrast: hc,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fallback,
    );

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: settings.themeMode,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      highContrastTheme: theme(Brightness.light, hc: true),
      highContrastDarkTheme: theme(Brightness.dark, hc: true),
      themeAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 360),
        curve: Curves.easeInOut,
      ),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return GlassConfig(
          data: GlassConfigData(
            quality: settings.resolveQuality(isWeb: kIsWeb),
            reduceMotion: settings.reduceMotion || media.disableAnimations,
            reduceTransparency: settings.reduceTransparency,
            highContrast: media.highContrast,
          ),
          // Gives every route a themed default text style and an ink layer
          // without painting a background.
          child: Material(
            type: MaterialType.transparency,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyLarge!,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
