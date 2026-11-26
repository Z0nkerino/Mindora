import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';

import '../glass/glass_surface.dart';
import '../motion/motion.dart';
import '../theme/mindora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Single- or multi-line text input on inset glass, with an optional label
/// above, helper/error text below and an accent focus ring.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
    this.textStyle,
    this.height,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? placeholder;
  final String? helper;
  final String? error;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final Iterable<String>? autofillHints;
  final TextStyle? textStyle;
  final double? height;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _ownsFocus = true;

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(GlassTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      _focus.removeListener(_onFocus);
      if (_ownsFocus) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
      _ownsFocus = widget.focusNode == null;
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final hasError = widget.error != null;
    final ringColor = hasError
        ? palette.accentInk
        : (_focus.hasFocus ? palette.accent : Colors.transparent);

    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      autofillHints: widget.autofillHints,
      style: (widget.textStyle ?? type.body).copyWith(
        color: palette.textPrimary,
      ),
      cursorColor: palette.accent,
      decoration: InputDecoration.collapsed(
        hintText: widget.placeholder,
        hintStyle: (widget.textStyle ?? type.body).copyWith(
          color: palette.textTertiary,
        ),
      ).copyWith(semanticCounterText: ''),
    );

    final box = AnimatedContainer(
      duration: MindoraDurations.fade,
      curve: Curves.easeOut,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: Radii.small,
          side: BorderSide(
            color: ringColor,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
      child: GlassSurface(
        depth: GlassDepth.inset,
        borderRadius: Radii.small,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.height ?? 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.m + 2,
              vertical: Space.m,
            ),
            child: Row(
              crossAxisAlignment: widget.maxLines == 1
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (widget.leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: palette.textTertiary, size: 20),
                    child: widget.leading!,
                  ),
                  const SizedBox(width: Space.s + 2),
                ],
                Expanded(child: field),
                if (widget.trailing != null) ...[
                  const SizedBox(width: Space.s),
                  IconTheme.merge(
                    data: IconThemeData(color: palette.textTertiary, size: 20),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final below = widget.error ?? widget.helper;
    return Semantics(
      textField: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(left: Space.xs, bottom: Space.s),
              child: Text(
                widget.label!,
                style: type.subhead.copyWith(color: palette.textSecondary),
              ),
            ),
          box,
          if (below != null)
            Padding(
              padding: const EdgeInsets.only(left: Space.xs, top: Space.s),
              child: Text(
                below,
                style: type.footnote.copyWith(
                  color: hasError ? palette.accentInk : palette.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Search field with a magnifier and an optional keyboard-shortcut hint
/// (⌘K on Apple platforms, Ctrl K elsewhere).
class GlassSearchField extends StatelessWidget {
  const GlassSearchField({
    super.key,
    this.controller,
    this.focusNode,
    required this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.showShortcut = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showShortcut;
  final bool autofocus;

  static String shortcutLabel([TargetPlatform? platform]) {
    final p = platform ?? defaultTargetPlatform;
    return (p == TargetPlatform.macOS || p == TargetPlatform.iOS)
        ? '⌘K'
        : 'Ctrl K';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      leading: const Icon(Icons.search_rounded),
      trailing: showShortcut
          ? DecoratedBox(
              decoration: ShapeDecoration(
                color: palette.insetFill,
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  shortcutLabel(Theme.of(context).platform),
                  style: context.type.caption.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
