import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mindora_glass/mindora_glass.dart';

import '../../l10n/generated/app_localizations.dart';

/// Today dashboard (v0). Shows the real date and greeting, and the widget
/// grid the later phases will fill. Each card has a designed empty state.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime? now;

  static String greeting(AppLocalizations l, DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return l.greetingMorning;
    if (h >= 12 && h < 18) return l.greetingAfternoon;
    if (h >= 18 && h < 23) return l.greetingEvening;
    return l.greetingNight;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = now ?? DateTime.now();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = toBeginningOfSentenceCase(
      DateFormat.MMMMEEEEd(locale).format(t),
      locale,
    );

    final cards = <_TodayCardData>[
      _TodayCardData(
        Icons.calendar_today_rounded,
        l.todayAgenda,
        l.todayAgendaEmpty,
      ),
      _TodayCardData(
        Icons.check_circle_outline_rounded,
        l.todayTasks,
        l.todayTasksEmpty,
      ),
      _TodayCardData(Icons.repeat_rounded, l.todayHabits, l.todayHabitsEmpty),
      _TodayCardData(
        Icons.favorite_outline_rounded,
        l.todayHealth,
        l.todayHealthEmpty,
      ),
      _TodayCardData(
        Icons.account_balance_wallet_outlined,
        l.todayBudget,
        l.todayBudgetEmpty,
      ),
    ];

    return GlassPage(
      title: greeting(l, t),
      subtitle: date,
      slivers: [
        SliverLayoutBuilder(
          builder: (context, c) {
            final cols = c.crossAxisExtent >= 860
                ? 3
                : c.crossAxisExtent >= 560
                ? 2
                : 1;
            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: Space.m,
                crossAxisSpacing: Space.m,
                mainAxisExtent: 148,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => GlassEntrance(
                  index: i,
                  child: _TodayCard(data: cards[i]),
                ),
                childCount: cards.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TodayCardData {
  const _TodayCardData(this.icon, this.title, this.empty);
  final IconData icon;
  final String title;
  final String empty;
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.data});
  final _TodayCardData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCardHeader(title: data.title, icon: data.icon),
          const Spacer(),
          Text(
            data.empty,
            style: context.type.callout.copyWith(color: palette.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
