# Mindora — Progress

## Phase 1 — Foundation · ✅ complete, awaiting your review

Branch: `claude/phase-1-foundation`

### Done

**Project and tooling**
- Pub-workspace monorepo: `apps/mindora` (iOS, iPadOS, Android, macOS, Windows, Web) and `packages/mindora_glass`. Flutter 3.50.1 is pinned in `.fvmrc`.
- Strict lints (`--fatal-infos` in CI), formatting check, generated localisations checked in CI.
- GitHub Actions on every push: analyze and test, then builds for **Web, Android, iOS (device + simulator), macOS and Windows**, each uploaded as an artifact.

**Mindora Glass design system** (`packages/mindora_glass`)
- Tokens: pure black/white base, one accent `#FF0051`, contrast-safe accent-ink (`#CC0041` light / `#FF3374` dark), a type scale with Dynamic Type support, a 4-pt spacing grid, superellipse radii, breakpoints.
- The glass material has three tiers. **Liquid** = blur + saturation + tint + specular rim + shader-driven liquid indicators. **Frosted** = no shaders. **Solid** = opaque, used automatically for Reduce Transparency and High Contrast.
- `LiquidIndicator`: the selection pill flows between items like a droplet. A spring-driven head and tail are merged by a fragment shader (`shaders/liquid_pill.frag`), with a CPU fallback. Used by the tab bar, sidebar and segmented control.
- Motion: five spring tokens and a velocity-preserving `SpringValue`. Every animation honours Reduce Motion.
- `GlassPressable` gives every tappable element a press spring, hover, a visible keyboard focus ring, Enter/Space activation, screen-reader semantics and a 44 pt minimum target.
- Components: button (primary/secondary/ghost/destructive × 3 sizes), icon button, card, text field, search field, segmented control, switch, checkbox, chip, floating tab bar, sidebar/rail, list section/row, sheet (spring, rubber-band, drag-to-dismiss, centred panel on wide screens), dialog, toast (announced to screen readers), progress ring, skeleton, empty state, large-title page with floating glass header, entrance animation.
- Charts: line, bar, heatmap and sparkline. All animate in, and each has a spoken summary for screen readers.
- Brand: the Mindora mark as vector geometry traced from your artwork (0.16 % pixel difference from the master PNG).

**App shell** (`apps/mindora`)
- Adaptive layout: a floating glass tab bar on phones (Today · Calendar · Tasks · Notes · More), an icon rail on tablets, and a full sidebar with the logo, groups and shortcut hints on desktop and web.
- go_router with state-preserving branches and a soft cross-fade between modules.
- Keyboard: `⌘/Ctrl K` opens the command palette (fuzzy match, EN + RU, arrow keys and Enter), `⌘/Ctrl 1–9` jumps to a module, `⌘/Ctrl ,` opens Settings.
- Screens: Today v0 (real date and greeting, widget grid with designed empty states), designed empty states for all ten modules, a "More" hub on phones, Settings (theme, glass tier, reduce motion, reduce transparency, language, version) and the Component gallery.
- Settings persist on the device. Synced settings come with accounts in Phase 2.
- **English and Russian** throughout, with Russian plural rules supported by ICU. The layout uses directional insets, ready for Arabic RTL later.
- App icons and display name "Mindora" on every platform, with an Android adaptive and monochrome icon and web maskable icons. `tool/generate_icons.py` regenerates them all from the same geometry.
- Web: Inter is bundled, subset to Latin + Cyrillic. The build uses `--no-web-resources-cdn`, so **the web app makes no requests to Google's CDNs**, which matters for privacy and reachability from Russia. A black page shows while loading, so there's no white flash.

**Tests: 92 passing**
- Design system (69): WCAG contrast for every text/surface pairing in both modes; every component rendered in six variants (dark/light × liquid/frosted/solid, reduced motion and transparency, high contrast); a screen-reader label check for every tappable element; keyboard activation; hit-target size; switch, checkbox and segmented behaviour; sheet, dialog and toast flows; the solid tier never blurs; spring physics.
- App (23): phone, tablet and desktop navigation; More hub; `Ctrl+3` and `Ctrl+,` shortcuts; the palette search-and-Enter flow; language switch to Russian and persistence; theme and glass persistence; restoring saved preferences; greeting logic; EN/RU key, placeholder and translation parity; palette fuzzy matching.
- Goldens: the gallery in dark, light, solid tier and **200 % text size**, which also asserts that nothing overflows.

### Changes from the plan
- **Light-mode accent-ink is `#CC0041`**, not `#D90045`. Tests showed `#D90045` reaches only 4.24:1 on the pink selection tint. `PLAN.md` is updated.
- **Tertiary text is a little stronger** (56 % black / 52 % white). The original 45 % failed AA (3.35:1).
- Localisation strings live in the app (`apps/mindora/lib/l10n`) rather than a separate `mindora_l10n` package. They will move to a package once a second package needs strings.
- Riverpod is used without code generation for now; it's small enough. Code generation comes in when the data layer arrives in Phase 2.
- Material and Cupertino are now separate packages in Flutter 3.50 (`material_ui`, `cupertino_ui`), and the code uses them.

### Not done in Phase 1 (honest list)
| Item | Status / plan |
|---|---|
| **Technical spikes** (llama.cpp FFI + Apple Foundation Models compiling in CI; SQLite WASM + OPFS + FTS5 on web) | **Moved to the start of Phase 2.** The SQLite spike belongs with the data layer. The AI spike is the first task of Phase 2's prep week so it still lands long before Phase 7. |
| 60 fps frame-budget check | Widget tests can't measure real GPU frame times. A profile-mode `integration_test` performance harness on a real device or emulator is planned for Phase 3, when the first heavy screen (Calendar) lands. |
| Refraction shader (bending the backdrop at glass edges) | The material is blur + saturation + rim. True refraction needs `ImageFilter.shader`, which works only on Impeller and couldn't be checked visually here. It will be added behind the `liquid` tier once checked on a device. |
| Date/time pickers, context menus, toolbars | Will be built with their first real use: pickers in Phase 3 (tasks/calendar), menus in Phase 3/4. |
| "Auto" glass tier GPU benchmark | Auto currently means Liquid on native and Frosted on web. A benchmark is planned for Phase 9. |
| iOS 18 dark/tinted icon variants | Phase 9 (store polish). |

### Known issues / needs your eyes
- **Check on a real device:** the shader-driven liquid pill and the blur were checked in Chromium (web) and through tests. Impeller on iOS, Android and macOS still needs a look on real hardware. Please try the tab bar and segmented controls, Settings → Glass → Liquid, and the gallery.
- The Russian copy was written carefully but should get a read from a native speaker before launch.
- Android release builds are debug-signed until store signing in Phase 9.
- In the phone layout, the Today cards are mostly empty space until real data arrives in Phase 3.

### How to try it
- **Web:** download the `mindora-web` artifact from the CI run and serve the folder (`python3 -m http.server`).
- **macOS / Windows / Android / iOS Simulator:** download the matching CI artifact, or run `flutter run -d <device>` from `apps/mindora` (see `README.md`).

---

## Next — Phase 2: Accounts and sync

1. Spikes first: SQLite (Drift) on all six targets including web OPFS + FTS5 with Russian text; PowerSync Flutter SDK proof of concept; llama.cpp + Foundation Models plugin compiling in CI.
2. Supabase schema for the whole data model, RLS + pgTAP tests, PowerSync sync rules.
3. Drift schema, HLC clock, merge RPC, `SyncEngine`.
4. E2EE key hierarchy (recovery key, device approval), local database encryption.
5. Sign in with Apple, Google and email; onboarding; account/devices/security settings; export and deletion.

**What I'll need from you for Phase 2** (I'll ask at the right moment; nothing is needed yet):
- A Supabase project (EU, Frankfurt) and a PowerSync instance. Free tiers are fine to start.
- Apple Developer account access for Sign in with Apple, and a Google Cloud OAuth client for Google sign-in.
