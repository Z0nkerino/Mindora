import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../glass/glass_surface.dart';
import '../motion/motion.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// A scrolling page with a large title that hands over to a compact
/// floating glass header as you scroll — content visibly flows under the
/// glass.
///
/// Bottom padding includes `MediaQuery.padding.bottom`, which the app shell
/// enlarges to make room for the floating tab bar.
class GlassPage extends StatefulWidget {
  const GlassPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.slivers,
    this.maxContentWidth = 920,
    this.controller,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> slivers;
  final double maxContentWidth;
  final ScrollController? controller;

  @override
  State<GlassPage> createState() => _GlassPageState();
}

class _GlassPageState extends State<GlassPage> {
  late ScrollController _controller = widget.controller ?? ScrollController();
  final ValueNotifier<double> _collapse = ValueNotifier(0);

  static const double _threshold = 56;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(GlassPage old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _controller.removeListener(_onScroll);
      if (old.controller == null) _controller.dispose();
      _controller = widget.controller ?? ScrollController();
      _controller.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final offset = _controller.hasClients ? _controller.offset : 0.0;
    _collapse.value = ((offset - 8) / _threshold).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (widget.controller == null) _controller.dispose();
    _collapse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, palette, type, media, top, constraints.maxWidth),
    );
  }

  Widget _build(
    BuildContext context,
    MindoraPalette palette,
    MindoraTypography type,
    MediaQueryData media,
    double top,
    double width,
  ) {
    final gutter = width >= Breakpoints.tablet ? Space.xxxl : Space.gutter;

    Widget constrain(Widget sliver) => SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: width > widget.maxContentWidth + gutter * 2
            ? (width - widget.maxContentWidth) / 2
            : gutter,
      ),
      sliver: sliver,
    );

    final header = SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: top + Space.xl, bottom: Space.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: type.subhead.copyWith(color: palette.accentInk),
                    ),
                  Semantics(
                    header: true,
                    child: Text(widget.title, style: type.display),
                  ),
                ],
              ),
            ),
            ...widget.actions,
          ],
        ),
      ),
    );

    return Stack(
      children: [
        Scrollbar(
          controller: _controller,
          child: CustomScrollView(
            controller: _controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              constrain(header),
              for (final s in widget.slivers) constrain(s),
              SliverToBoxAdapter(
                child: SizedBox(height: media.padding.bottom + Space.xxxl),
              ),
            ],
          ),
        ),
        // Compact floating header.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _collapse,
            builder: (context, t, child) => IgnorePointer(
              ignoring: t < 0.5,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * -8),
                  child: child,
                ),
              ),
            ),
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Space.s,
                  top + Space.xs,
                  Space.s,
                  0,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GlassSurface(
                    depth: GlassDepth.floating,
                    borderRadius: Radii.pill,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.xl,
                      vertical: Space.s + 2,
                    ),
                    child: Text(widget.title, style: type.headline),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Page section heading inside a [GlassPage].
class GlassSectionHeader extends StatelessWidget {
  const GlassSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.m),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.type.title2),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Wraps a child so its entrance glides up and fades in once, staggered by
/// [index]. Becomes a no-op under Reduce Motion.
class GlassEntrance extends StatefulWidget {
  const GlassEntrance({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<GlassEntrance> createState() => _GlassEntranceState();
}

class _GlassEntranceState extends State<GlassEntrance>
    with SingleTickerProviderStateMixin {
  late final SpringValue _t = SpringValue(
    vsync: this,
    spring: MindoraSprings.gentle,
  );
  bool _started = false;
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotionOf(context)) {
      _t.jumpTo(1);
    } else {
      _delay = Timer(
        Duration(milliseconds: 40 * widget.index.clamp(0, 12)),
        () => _t.animateTo(1),
      );
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * 16),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
