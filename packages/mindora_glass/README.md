# mindora_glass

**Mindora Glass**, the Mindora design system. Every app screen is built only from what `package:mindora_glass/mindora_glass.dart` exports.

| Area | What's inside |
|---|---|
| Tokens | `MindoraColors`, `MindoraPalette` (light/dark/high-contrast), `MindoraTypography`, `Space`, `Radii`, `Breakpoints`, `kMinTarget` |
| Theme | `buildMindoraTheme`, `MindoraTheme` (ThemeExtension), `GlassConfig` (quality tier, reduce motion/transparency, high contrast) |
| Material | `GlassSurface` (blur + saturation + tint + specular rim; `liquid` / `frosted` / `solid`), `LiquidIndicator` (fragment shader `shaders/liquid_pill.frag` with CPU fallback) |
| Motion | `MindoraSprings` (snappy, smooth, bouncy, gentle, trailing), `SpringValue` (velocity-preserving, interruptible), `GlassEntrance` |
| Interaction | `GlassPressable`: press spring, hover, focus ring, Enter/Space, semantics, 44 pt target |
| Components | `GlassButton`, `GlassIconButton`, `GlassCard`, `GlassTextField`, `GlassSearchField`, `GlassSegmented`, `GlassSwitch`, `GlassCheckbox`, `GlassChip`, `GlassTabBar`, `GlassSidebar`, `GlassListSection`/`GlassListRow`, `showGlassSheet`, `showGlassDialog`, `showGlassToast`, `GlassProgressRing`, `GlassSkeleton`, `GlassEmptyState`, `GlassPage` |
| Charts | `GlassLineChart`, `GlassBarChart`, `GlassHeatmap`, `GlassSparkline`. Each takes a `semanticSummary` for screen readers. |
| Brand | `MindoraMark` geometry, `MindoraLogo`, `MindoraBarsIllustration` |

Rules:

- **Accent sparingly.** `palette.accent` is for fills, rings, progress and selection. Small accent *text* uses `palette.accentInk`. Contrast is enforced by `test/contrast_test.dart`.
- **Blur only where it shows.** Only floating surfaces blur by default.
- **Motion respects the user.** Everything reads `GlassConfig.reduceMotion`.
