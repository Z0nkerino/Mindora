# Mindora

Your whole life, calmly planned: calendar, tasks, projects, notes, ideas, habits, goals, health and finance in one app, with a private on-device assistant.

One Flutter codebase for **iOS, iPadOS, Android, macOS, Windows and Web**.

- Product and engineering plan: [`PLAN.md`](PLAN.md)
- Status, what's next and known issues: [`PROGRESS.md`](PROGRESS.md)

## Repository layout

```
apps/mindora/            The Flutter app (all six platforms)
packages/mindora_glass/  "Mindora Glass" design system — tokens, glass, motion, components, charts
assets/brand/            Mindora logo (master PNG, SVGs, 1024 px icon)
assets/brands/           Official third-party logos + BRANDS.md register (none needed yet)
tool/generate_icons.py   Regenerates the SVG logo and every platform's app icons
.github/workflows/ci.yml Analyze, test and build all platforms on every push
```

## Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Flutter | **3.50.1** stable (pinned in `.fvmrc`; [FVM](https://fvm.app) recommended) | everything |
| Xcode | 16+ with CocoaPods | iOS, iPadOS, macOS (macOS host only) |
| Android Studio / Android SDK, JDK 17 | latest | Android |
| Visual Studio 2022 with "Desktop development with C++" | latest | Windows (Windows host only) |
| Chrome or Edge | recent | Web |
| Python 3 + Pillow | — | only to regenerate icons |

```bash
flutter pub get
```

Run this at the repository root. It resolves the whole workspace.

## Run

All commands from `apps/mindora/`:

```bash
cd apps/mindora
```

```bash
flutter run -d chrome
```

```bash
flutter run -d macos
```

```bash
flutter run -d windows
```

```bash
flutter run -d ios
```

```bash
flutter run -d android
```

Use `flutter devices` to list simulators, emulators and connected devices. The component gallery is at **Settings → Component gallery** (or `⌘K` / `Ctrl K` → "gallery").

## Test

```bash
(cd packages/mindora_glass && flutter test)
```

```bash
(cd apps/mindora && flutter test)
```

Golden images (`apps/mindora/test/goldens/`) are rendered on Linux, as in CI. After an intentional visual change, update them on Linux:

```bash
(cd apps/mindora && flutter test --tags golden --update-goldens)
```

Static checks, as run by CI:

```bash
dart format --output=none --set-exit-if-changed apps packages
```

```bash
(cd apps/mindora && flutter analyze --fatal-infos)
```

## Build

From `apps/mindora/`:

| Platform | Command | Output |
|---|---|---|
| Web | `flutter build web --release --wasm --no-web-resources-cdn` | `build/web/` (fully self-hosted: no Google CDN) |
| Android | `flutter build apk --release` / `flutter build appbundle` | `build/app/outputs/` |
| iOS / iPadOS | `flutter build ipa` (needs signing) or `flutter build ios --no-codesign` | `build/ios/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/Mindora.app` |
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |

CI builds every one of these on each push and attaches them as workflow artifacts.

## Deploy

Store signing and release pipelines arrive in **Phase 9** (see `PLAN.md`). Until then:

- **Web:** serve `build/web/` from any static host. For the Wasm build's multi-threaded renderer, send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`. Without them it falls back automatically. Serve `index.html` and `flutter_bootstrap.js` with `Cache-Control: no-cache`.
- **iOS / macOS:** archive in Xcode (`ios/Runner.xcworkspace`, `macos/Runner.xcworkspace`) with your team selected → TestFlight.
- **Android:** release signing via a `key.properties` + keystore that is **never committed** → Play Console internal track.
- **Windows:** MSIX packaging is planned for Phase 9.

## Regenerate the logo and icons

```bash
python3 tool/generate_icons.py
```

To check the trace against the master artwork:

```bash
python3 tool/generate_icons.py --overlay /tmp/overlay.png
```

## Privacy and secrets

The repository is public. Never commit keys, keystores, `.env` files or service configs. CI secrets live in GitHub Actions secrets. All AI runs on device (see `PLAN.md` §6).
