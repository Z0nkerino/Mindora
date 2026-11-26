import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../app/settings.dart';
import '../l10n/generated/app_localizations.dart';

/// Living catalogue of every Mindora Glass component. Used for design
/// review and as the subject of golden tests.
///
/// The sample content is realistic on purpose (no lorem ipsum).
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: [
          GlassPage(
            title: l.galleryTitle,
            subtitle: 'Mindora Glass',
            actions: [
              GlassIconButton(
                icon: Icons.contrast_rounded,
                label: l.paletteToggleTheme,
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .toggleBrightness(Theme.of(context).brightness),
              ),
              const SizedBox(width: Space.s),
              GlassIconButton(
                icon: Icons.close_rounded,
                label: l.close,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
            slivers: const [SliverToBoxAdapter(child: GalleryContent())],
          ),
        ],
      ),
    );
  }
}

/// The gallery body on its own, so tests can pump it directly.
class GalleryContent extends StatefulWidget {
  const GalleryContent({super.key});

  @override
  State<GalleryContent> createState() => _GalleryContentState();
}

class _GalleryContentState extends State<GalleryContent> {
  String _view = 'week';
  bool _focusMode = true;
  bool _water = false;
  bool _stretch = true;
  final Set<String> _tags = {'work'};
  int _tab = 0;
  double _progress = 0.64;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;

    Widget section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [GlassSectionHeader(title), child],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(
          'Brand',
          Row(
            children: [
              const MindoraLogo(size: 64, background: MindoraColors.black),
              const SizedBox(width: Space.l),
              const MindoraLogo(size: 44),
              const SizedBox(width: Space.l),
              Expanded(
                child: Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    _Swatch('Accent', palette.accent),
                    _Swatch('Accent ink', palette.accentInk),
                    _Swatch('Text', palette.textPrimary),
                    _Swatch('Background', palette.background),
                  ],
                ),
              ),
            ],
          ),
        ),
        section(
          'Typography',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan your week', style: type.display),
              Text('Spring sprint', style: type.title1),
              Text('Morning routine', style: type.title2),
              Text('Call the dentist', style: type.headline),
              Text(
                'Pick up the dry cleaning on the way home.',
                style: type.body,
              ),
              Text(
                'Синхронизировано 2 минуты назад',
                style: type.footnote.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ),
        section(
          'Buttons',
          Wrap(
            spacing: Space.m,
            runSpacing: Space.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GlassButton.primary(
                label: 'Plan my day',
                icon: Icons.auto_awesome_rounded,
                onPressed: () => showGlassToast(
                  context,
                  'Plan ready to review',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
              GlassButton(
                label: 'Add task',
                icon: Icons.add_rounded,
                variant: GlassButtonVariant.primary,
                onPressed: () {},
              ),
              GlassButton(label: 'Reschedule', onPressed: () {}),
              GlassButton(
                label: 'Skip today',
                variant: GlassButtonVariant.ghost,
                onPressed: () {},
              ),
              GlassButton(
                label: 'Delete',
                variant: GlassButtonVariant.destructive,
                size: GlassButtonSize.compact,
                onPressed: () {},
              ),
              const GlassButton(label: 'Disabled', onPressed: null),
              GlassIconButton(
                icon: Icons.add_rounded,
                label: 'Add',
                onPressed: () {},
              ),
              GlassIconButton(
                icon: Icons.mic_rounded,
                label: 'Voice capture',
                selected: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
        section(
          'Inputs',
          const Column(
            children: [
              GlassTextField(
                label: 'Task',
                placeholder: 'Gym tomorrow at 7, then call mum',
                helper: 'Type naturally — Mindora understands dates and times.',
              ),
              SizedBox(height: Space.l),
              GlassTextField(
                label: 'Amount',
                placeholder: '0.00 AED',
                error: 'Enter an amount greater than zero.',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: Space.l),
              GlassSearchField(
                placeholder: 'Search everything',
                showShortcut: true,
              ),
            ],
          ),
        ),
        section(
          'Selection',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassSegmented<String>(
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
                segments: const [
                  GlassSegment(value: 'day', label: 'Day'),
                  GlassSegment(value: 'week', label: 'Week'),
                  GlassSegment(value: 'month', label: 'Month'),
                  GlassSegment(value: 'agenda', label: 'Agenda'),
                ],
              ),
              const SizedBox(height: Space.l),
              Wrap(
                spacing: Space.s,
                children: [
                  for (final t in const ['work', 'home', 'errands', 'health'])
                    GlassChip(
                      label: '#$t',
                      selected: _tags.contains(t),
                      onPressed: () => setState(
                        () =>
                            _tags.contains(t) ? _tags.remove(t) : _tags.add(t),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        section(
          'Lists',
          GlassListSection(
            title: 'Morning routine',
            footer: 'Missing a day never resets your progress.',
            children: [
              GlassListRow(
                title: 'Drink a glass of water',
                subtitle: '7-day streak',
                leading: GlassCheckbox(
                  value: _water,
                  onChanged: (v) => setState(() => _water = v),
                  semanticLabel: 'Drink a glass of water',
                ),
              ),
              GlassListRow(
                title: '10 minutes of stretching',
                subtitle: 'Mon · Wed · Fri',
                leading: GlassCheckbox(
                  value: _stretch,
                  onChanged: (v) => setState(() => _stretch = v),
                  semanticLabel: '10 minutes of stretching',
                ),
              ),
              GlassListRow(
                title: 'Focus mode',
                leading: const Icon(Icons.do_not_disturb_on_outlined),
                trailing: GlassSwitch(
                  value: _focusMode,
                  onChanged: (v) => setState(() => _focusMode = v),
                  semanticLabel: 'Focus mode',
                ),
              ),
              GlassListRow(
                title: 'Reminders',
                subtitle: '07:30',
                leading: const Icon(Icons.notifications_none_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
        section(
          'Cards & progress',
          Wrap(
            spacing: Space.m,
            runSpacing: Space.m,
            children: [
              SizedBox(
                width: 260,
                child: GlassCard(
                  onTap: () => setState(
                    () =>
                        _progress = _progress >= 0.95 ? 0.2 : _progress + 0.18,
                  ),
                  semanticLabel: 'Run a half marathon',
                  child: Row(
                    children: [
                      GlassProgressRing(
                        progress: _progress,
                        semanticLabel: 'Goal progress',
                        center: Text(
                          '${(_progress * 100).round()}%',
                          style: type.caption,
                        ),
                      ),
                      const SizedBox(width: Space.l),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Run a half marathon', style: type.headline),
                            Text(
                              '3 of 5 milestones',
                              style: type.footnote.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlassCardHeader(
                        title: 'Steps',
                        icon: Icons.directions_walk_rounded,
                      ),
                      Row(
                        children: [
                          Text('8 214', style: type.title1),
                          const Spacer(),
                          const GlassSparkline(
                            values: [6200, 7400, 5100, 9800, 8800, 7600, 8214],
                            semanticSummary:
                                'Steps over the last 7 days, trending up',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 260,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassSkeleton(width: 120, height: 16),
                      SizedBox(height: Space.m),
                      GlassSkeleton(height: 12),
                      SizedBox(height: Space.s),
                      GlassSkeleton(width: 180, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        section(
          'Charts',
          Column(
            children: [
              const GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCardHeader(
                      title: 'Sleep · last 14 nights',
                      icon: Icons.bedtime_outlined,
                    ),
                    GlassLineChart(
                      values: [
                        6.8,
                        7.2,
                        6.1,
                        7.9,
                        8.1,
                        7.4,
                        6.9,
                        7.7,
                        8.0,
                        6.5,
                        7.3,
                        7.8,
                        8.2,
                        7.6,
                      ],
                      semanticSummary:
                          'Sleep over 14 nights, average 7.4 hours',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),
              const GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCardHeader(
                      title: 'Spending this week, AED',
                      icon: Icons.bar_chart_rounded,
                    ),
                    GlassBarChart(
                      values: [120, 85, 240, 60, 310, 145, 90],
                      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                      highlightIndex: 4,
                      semanticSummary:
                          'Spending by day, highest on Friday at 310 dirhams',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const GlassCardHeader(
                      title: 'Meditation · 18 weeks',
                      icon: Icons.self_improvement_rounded,
                    ),
                    GlassHeatmap(
                      values: [
                        for (var i = 0; i < 126; i++)
                          (i * 37 % 11) / 10 * (i % 7 == 6 ? 0.3 : 1),
                      ],
                      semanticSummary: 'Meditation consistency over 18 weeks, 71 percent of days',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        section(
          'Navigation',
          Column(
            children: [
              GlassTabBar(
                selectedIndex: _tab,
                onSelected: (i) => setState(() => _tab = i),
                items: const [
                  GlassNavItem(
                    icon: Icons.wb_sunny_outlined,
                    selectedIcon: Icons.wb_sunny_rounded,
                    label: 'Today',
                  ),
                  GlassNavItem(
                    icon: Icons.calendar_today_outlined,
                    selectedIcon: Icons.calendar_today_rounded,
                    label: 'Calendar',
                  ),
                  GlassNavItem(
                    icon: Icons.check_circle_outline_rounded,
                    selectedIcon: Icons.check_circle_rounded,
                    label: 'Tasks',
                  ),
                  GlassNavItem(
                    icon: Icons.sticky_note_2_outlined,
                    selectedIcon: Icons.sticky_note_2_rounded,
                    label: 'Notes',
                  ),
                ],
              ),
            ],
          ),
        ),
        section(
          'Overlays',
          Wrap(
            spacing: Space.m,
            runSpacing: Space.m,
            children: [
              GlassButton(
                label: 'Open sheet',
                icon: Icons.vertical_align_top_rounded,
                onPressed: () => showGlassSheet<void>(
                  context: context,
                  builder: (context) => GlassSheetScaffold(
                    title: 'New event',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const GlassTextField(placeholder: 'Dinner with Lena'),
                        const SizedBox(height: Space.l),
                        GlassButton.primary(
                          label: 'Add to calendar',
                          expand: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GlassButton(
                label: 'Open dialog',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => showGlassDialog(
                  context: context,
                  title: 'Delete this habit?',
                  message: 'Its history will be removed from all your devices.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Keep',
                  destructive: true,
                ),
              ),
              GlassButton(
                label: 'Show toast',
                icon: Icons.notifications_none_rounded,
                onPressed: () => showGlassToast(
                  context,
                  'Synced across your devices',
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
        section(
          'Empty state',
          const GlassCard(
            child: GlassEmptyState(
              icon: Icons.lightbulb_rounded,
              title: 'Catch ideas before they fly away',
              message: 'Capture a thought by text, voice or photo.',
            ),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: name,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: color,
              shape: RoundedSuperellipseBorder(
                borderRadius: Radii.small,
                side: BorderSide(color: palette.hairline),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            name,
            style: context.type.caption.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
