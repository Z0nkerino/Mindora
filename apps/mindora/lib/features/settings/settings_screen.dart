import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../../app/settings.dart';
import '../../l10n/generated/app_localizations.dart';

/// Kept in step with `version:` in pubspec.yaml.
const kAppVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);

    Widget block(Widget w) => Padding(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: w,
    );

    return GlassPage(
      title: l.navSettings,
      maxContentWidth: 640,
      slivers: [
        SliverList.list(
          children: [
            block(
              GlassListSection(
                title: l.settingsAppearance,
                footer: l.settingsGlassFooter,
                children: [
                  _LabeledControl(
                    label: l.settingsTheme,
                    child: GlassSegmented<ThemeMode>(
                      semanticLabel: l.settingsTheme,
                      selected: s.themeMode,
                      onChanged: c.setThemeMode,
                      segments: [
                        GlassSegment(
                          value: ThemeMode.system,
                          label: l.themeSystem,
                        ),
                        GlassSegment(
                          value: ThemeMode.light,
                          label: l.themeLight,
                        ),
                        GlassSegment(value: ThemeMode.dark, label: l.themeDark),
                      ],
                    ),
                  ),
                  _LabeledControl(
                    label: l.settingsGlass,
                    child: GlassSegmented<GlassPreference>(
                      semanticLabel: l.settingsGlass,
                      selected: s.glass,
                      onChanged: c.setGlass,
                      segments: [
                        GlassSegment(
                          value: GlassPreference.auto,
                          label: l.glassAuto,
                        ),
                        GlassSegment(
                          value: GlassPreference.liquid,
                          label: l.glassLiquid,
                        ),
                        GlassSegment(
                          value: GlassPreference.frosted,
                          label: l.glassFrosted,
                        ),
                        GlassSegment(
                          value: GlassPreference.solid,
                          label: l.glassSolid,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            block(
              GlassListSection(
                footer: l.settingsMotionFooter,
                children: [
                  GlassListRow(
                    title: l.settingsReduceMotion,
                    leading: const Icon(Icons.animation_rounded),
                    trailing: GlassSwitch(
                      value: s.reduceMotion,
                      onChanged: c.setReduceMotion,
                      semanticLabel: l.settingsReduceMotion,
                    ),
                  ),
                  GlassListRow(
                    title: l.settingsReduceTransparency,
                    leading: const Icon(Icons.opacity_rounded),
                    trailing: GlassSwitch(
                      value: s.reduceTransparency,
                      onChanged: c.setReduceTransparency,
                      semanticLabel: l.settingsReduceTransparency,
                    ),
                  ),
                ],
              ),
            ),
            block(
              GlassListSection(
                title: l.settingsLanguage,
                children: [
                  _LabeledControl(
                    child: GlassSegmented<LanguagePreference>(
                      semanticLabel: l.settingsLanguage,
                      selected: s.language,
                      onChanged: c.setLanguage,
                      segments: [
                        GlassSegment(
                          value: LanguagePreference.system,
                          label: l.languageSystem,
                        ),
                        const GlassSegment(
                          value: LanguagePreference.en,
                          label: 'English',
                        ),
                        const GlassSegment(
                          value: LanguagePreference.ru,
                          label: 'Русский',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            block(
              GlassListSection(
                title: l.settingsAbout,
                children: [
                  GlassListRow(
                    title: l.settingsVersion,
                    leading: const MindoraLogo(size: 22),
                    trailing: Text(
                      kAppVersion,
                      style: context.type.body.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
                  GlassListRow(
                    title: l.settingsGallery,
                    subtitle: l.settingsGallerySubtitle,
                    leading: const Icon(Icons.widgets_outlined),
                    onTap: () => context.push('/gallery'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({this.label, required this.child});
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(label!, style: context.type.body),
            const SizedBox(height: Space.m),
          ],
          child,
        ],
      ),
    );
  }
}
