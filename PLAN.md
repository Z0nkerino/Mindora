# Mindora — Product & Engineering Plan

> Status: **Draft for approval** · Phase 0 (planning)
> Nothing beyond this plan and the brand asset is built yet. Build starts only after approval.

Mindora puts a person's whole life into one calm app: calendar, tasks, projects, notes, ideas, habits, goals, health and finance, connected by a private, on-device AI assistant.

---

## 0. Decisions already made (from the kickoff Q&A)

| Topic | Decision | What it means for the plan |
|---|---|---|
| Launch region | Hosted globally, **main city St. Petersburg** | The backend starts hosted in the EU, close to SPb (Frankfurt). It is **fully self-hostable** so it can move to a Russian data centre if 152-FZ demands it (see §9, risk R1). RU is a first-class language, and RUB is a first-class currency. |
| Build verification | **GitHub Actions CI** | Every push builds and tests Web, Android, iOS, iPadOS, macOS and Windows on CI runners. You test on real devices. |
| Encryption | **E2EE for sensitive data** | Notes, ideas, health, finance, goal reviews and attachments are end-to-end encrypted, with a recovery key. Tasks, calendar, projects and habits are encrypted at rest on the server. That keeps calendar sync and server-side features possible. |
| Business model | **Free for now** | No billing layer. Code keeps a `FeatureFlags`/`Entitlements` seam so billing can be added later without a refactor. |
| Logo | **Provided** (three slanted, rounded bars in `#FF0051` on black) | The three-concept step is skipped. The file is stored at `assets/brand/mindora-logo-2000.png`. Phase 1 adds a hand-built vector (SVG) version and app icons for every platform. |

---

## 1. Tech stack: comparison and recommendation

### 1.1 The options

Scoring follows the brief's priority order: (1) a native-feeling, buttery UI with liquid animations, (2) one shared codebase, (3) native features.

| | **Flutter** | **React Native / Expo (+ RN Web)** | **Compose Multiplatform (KMP)** | **Shared core + native UIs** (Rust/KMP core + SwiftUI + Compose + WinUI + Web) |
|---|---|---|---|---|
| Liquid, custom glass UI that looks the same everywhere | ★★★★★ One renderer (Impeller). Full control of every pixel. Runtime fragment shaders give refraction and morphing. 120 Hz on ProMotion. | ★★★☆☆ Reanimated + Skia are good, but each platform renders differently. Real iOS 26 Liquid Glass only exists on iOS. Web and Windows lag behind. | ★★★★☆ Skia-based, good animation API. iOS is stable, but **Web (Wasm) is still beta**, and Desktop runs on the JVM (slower start). | ★★★★★ per platform, but **four or more UI codebases** |
| One codebase across all 6 targets | ★★★★★ iOS, iPadOS, Android, macOS, Windows and Web are all first-party | ★★★☆☆ Expo doesn't support Windows or macOS. That needs Microsoft's RN forks, which ship on a separate cadence. | ★★★★☆ | ★☆☆☆☆ |
| Native features (widgets, HealthKit, Live Activities, on-device AI) | ★★★★☆ Platform channels, Pigeon and FFI. Widgets are always native code, whatever the stack. | ★★★★☆ Expo Modules are excellent on mobile | ★★★★☆ Kotlin↔Swift interop is good | ★★★★★ |
| Local SQLite + sync ecosystem | Drift, sqlite3 (WASM on web, FTS5), PowerSync SDK (incl. web) | op-sqlite, WatermelonDB, PowerSync | SQLDelight, PowerSync (beta) | depends on the core |
| On-device LLM | llama.cpp via `dart:ffi`, Swift plugin for Apple Foundation Models, WebLLM via JS interop | llama.rn, react-native-executorch, Apple FM modules | llama.cpp via cinterop | best |
| Risk | Web bundle size and blur cost on weak GPUs (mitigated, §3.4) | Maintaining 4 platform renderers. New Architecture churn. | Web maturity. Smaller library ecosystem. | Team size and time |

### 1.2 Recommendation: **Flutter (Dart 3) + small native modules**

Why:

1. **Mindora Glass is a custom design system, not a platform look.** The brief wants the same black/white/`#FF0051` liquid-glass identity on every platform, Windows and Web included. Flutter draws every pixel itself, so the glass, springs and morphs behave the same everywhere. Stacks that wrap native controls fight this.
2. **Real shader-level effects.** Flutter's `FragmentProgram` (GLSL → Impeller/Skia) lets us do refraction, specular rims and goo-style morphing between glass shapes. Opacity and blur alone can't produce these.
3. **All six targets come from one first-party toolchain**, with a single CI matrix.
4. **Native where it matters.** Swift (WidgetKit, ActivityKit, HealthKit, Foundation Models), Kotlin (Glance widgets, Health Connect, Gemini Nano) and C/C++ (llama.cpp) plug in through Pigeon or FFI.

What we give up, honestly:
- **No real Apple Liquid Glass material.** On iOS 26 we *emulate* Apple's material. It will look very close, but it is not the system material. Native-UI stacks get it for free on iOS only.
- **Web.** The first load is about 2–3 MB (Skwasm/CanvasKit), and backdrop blur is GPU-heavy. Mitigations: a glass quality tier system, a service-worker cache, and a lightweight static landing page.
- **Platform-standard text editing and context menus** need care. We use Flutter's native-adaptive text selection and context menu APIs.

### 1.3 Full stack

| Layer | Choice | Notes |
|---|---|---|
| UI | Flutter stable (3.3x), Impeller on all native targets, Skwasm on web | Pinned via FVM |
| State | Riverpod 2 (code-gen) | Testable, compile-safe DI |
| Navigation | go_router | Deep links, web URLs, adaptive shell |
| Local DB | SQLite via **Drift** (+ `sqlite3` WASM on web, OPFS storage) | FTS5 for full-text search on every platform |
| Sync | **PowerSync** (SQLite ↔ Postgres) behind our own `SyncEngine` interface | Self-hostable Open Edition. Fallback: our own sync over the same interface (§5). |
| Backend | **Supabase**: Postgres 15+, Auth, Storage, Edge Functions, RLS | Open source and self-hostable (Docker) → there is a path to a Russian region |
| Crypto | libsodium (`sodium_libs`): XChaCha20-Poly1305, Argon2id, X25519 | Same primitives on every platform, incl. web (WASM) |
| Rich text | AppFlowy Editor (spike vs `super_editor` in Phase 4) | Markdown import/export, `[[backlinks]]` |
| Charts | Our own `GlassChart` painters (line, bar, ring, heatmap) on CustomPainter | Animated, accessible (semantics), same look on every platform |
| Recurrence | RFC 5545 RRULE (`rrule` package), expanded locally | Same format Google, Outlook and CalDAV use |
| i18n | Flutter `gen-l10n` (ARB, ICU plurals; Russian has 4 plural forms) | RTL-ready from day one |
| On-device AI | Apple Foundation Models (Swift) · Gemini Nano (Android ML Kit GenAI) · llama.cpp (FFI) · WebLLM (WebGPU) · rule engine | §6 |
| Speech (ideas) | iOS/macOS `SpeechAnalyzer`/`SFSpeechRecognizer` (on-device) · Android on-device recognizer · whisper.cpp (desktop/web) | Never cloud speech recognition, including the Web Speech API in Chrome, which sends audio to a server |
| Monorepo | Dart pub workspaces + Melos | |
| CI/CD | GitHub Actions (ubuntu, macos, windows runners) | Free for public repos |
| Web hosting | Cloudflare Pages (headers support for COOP/COEP), with a Russia-reachable mirror (see R7) | |
| Crash/analytics | Sentry, self-hostable, **opt-in**, no personal data | No third-party analytics SDKs |

---

## 2. Architecture

### 2.1 Layers

```
┌───────────────────────────────────────────────────────────────┐
│ Presentation: feature screens (built ONLY from mindora_glass) │
├───────────────────────────────────────────────────────────────┤
│ Application: Riverpod controllers, use-cases, Command bus     │  ← AI uses the same commands
│ (create/update/link/delete → undoable, audited ChangeSets)    │
├───────────────────────────────────────────────────────────────┤
│ Domain: pure Dart entities, value objects, RRULE, links,      │
│ smart-list rules, progress math, money math                   │
├───────────────────────────────────────────────────────────────┤
│ Data: Drift repositories · FTS index · crypto envelope ·      │
│ SyncEngine (PowerSync) · attachment store                     │
├───────────────────────────────────────────────────────────────┤
│ Platform: Pigeon/FFI bridges: HealthKit, Health Connect,      │
│ EventKit, widgets, Live Activities, notifications, AI runtimes│
└───────────────────────────────────────────────────────────────┘
```

Key principles:
- **Local-first.** The UI only ever reads and writes the local SQLite database. Network calls never block the UI.
- **One Command bus.** Every mutation (from UI, quick add, AI, import or widget) is a `Command` → `ChangeSet` (list of ops) → applied in one transaction → pushed to the undo stack → queued for sync. That is how the AI gets "show me first, then confirm" for free: the AI produces a `ChangeSet` and does **not** apply it.
- **Universal links.** A single `links` table connects any entity to any other (task↔project↔goal↔note↔event↔habit↔idea). Backlinks are a reverse query on it.
- **Modules are self-contained** packages that depend on `mindora_core` and `mindora_data`, never on each other. Cross-module UI (for example "linked items" chips) goes through a registry of `EntityTypeAdapter`s.

### 2.2 Repository layout

```
mindora/
├─ apps/
│  └─ mindora/                 # The Flutter app (iOS, iPadOS, Android, macOS, Windows, Web)
│     ├─ lib/
│     │  ├─ app/               # bootstrap, router, adaptive shell, theme, l10n wiring
│     │  └─ features/
│     │     ├─ today/  calendar/  tasks/  projects/  notes/  ideas/
│     │     ├─ habits/ goals/     health/ finance/   assistant/
│     │     ├─ search/ (command palette)  settings/  onboarding/  auth/
│     │     └─ <feature>/{data,domain,application,presentation}/
│     ├─ ios/ android/ macos/ windows/ web/
│     ├─ integration_test/
│     └─ test/
├─ packages/
│  ├─ mindora_glass/           # Design system: tokens, glass material, motion, components, charts
│  ├─ mindora_core/            # Entities, IDs (UUIDv7), HLC clock, Command/ChangeSet, links, money
│  ├─ mindora_data/            # Drift schema + migrations, repositories, FTS, SyncEngine
│  ├─ mindora_crypto/          # Key hierarchy, envelope encryption, recovery key
│  ├─ mindora_nlp/             # Rule-based EN/RU parser: dates, times, durations, recurrence, amounts
│  ├─ mindora_ai/              # AI orchestrator, provider interface, tools, prompts, evals
│  ├─ mindora_l10n/            # ARB files (en, ru; ar later)
│  └─ mindora_test_kit/        # Fakes, realistic sample-data generator, golden helpers
├─ native/
│  ├─ apple/                   # Swift: FoundationModels plugin, WidgetKit, ActivityKit, App Intents
│  ├─ android/                 # Kotlin: Glance widgets, Gemini Nano bridge, Health Connect extras
│  └─ llama/                   # llama.cpp submodule + C shim + build scripts per platform
├─ backend/
│  ├─ supabase/
│  │  ├─ migrations/           # SQL schema, RLS policies, functions
│  │  ├─ functions/            # Edge functions: calendar-sync, fx-rates, export, delete-account
│  │  └─ tests/                # pgTAP tests (RLS!)
│  ├─ powersync/sync-rules.yaml
│  └─ selfhost/docker-compose.yml   # Full stack for a self-hosted / Russian region
├─ assets/brand/               # Mindora logo (png now, svg in Phase 1)
├─ assets/brands/              # Official third-party logos + BRANDS.md (source, guideline, date)
├─ docs/                       # ADRs, design specs, privacy docs
├─ .github/workflows/
├─ PLAN.md  PROGRESS.md  README.md
```

### 2.3 Data model

**Common columns on every synced table:**
`id uuid (v7, client-generated)`, `user_id uuid`, `created_at`, `updated_at`, `deleted_at` (tombstone), `hlc text` (hybrid logical clock of last write), `field_hlc jsonb` (per-field clocks for field-level merging; plaintext tables only), `device_id`.

**Encrypted tables** keep only what the server needs to route and sync in plaintext (`id`, `user_id`, timestamps, `hlc`, `kind`). Everything else goes in `enc bytea` (an XChaCha20-Poly1305 envelope) + `key_id`. Money amounts are integers in minor units (kopecks, fils, cents). Dates with times store `timestamptz` + an IANA `tz` string.

| Module | Tables (★ = E2EE `enc` payload) |
|---|---|
| Accounts | `profiles` (locale, base_currency, week_start, tz), `devices`, `user_keys` (wrapped master keys), `settings` (synced prefs), `dashboard_layouts` |
| Cross-module | `links (from_type, from_id, to_type, to_id, kind)`, `tags`, `entity_tags`, `attachments`★ (blob in Storage, encrypted client-side for E2EE owners) |
| Tasks | `tasks` (title, notes, status, priority 0–3, due_at, due_tz, all_day, scheduled_start, duration_min, rrule, parent_id, project_id, section_id, sort_key, completed_at), `task_occurrences` (completion/override per recurrence instance) |
| Projects | `projects` (name, icon, status, start_on, target_on, default_view), `project_sections` (board columns), `milestones` (owner project **or** goal, due_on, done_at) |
| Calendar | `calendar_accounts` (provider; **OAuth tokens live server-side only** in `private.provider_tokens`, never synced to clients), `calendars` (source, external_id, color, visible), `events` (calendar_id, title, start_at, end_at, tz, all_day, rrule, exdates, recurring_event_id + original_start for exceptions, location, notes, external_id, etag, linked task for time-blocks) |
| Notes | `note_folders`, `notes`★ (title, AppFlowy document JSON, plaintext excerpt for local FTS) |
| Ideas | `ideas`★ (kind text/voice/photo, content, transcript, attachment, status inbox/converted/archived, converted_to type+id) |
| Habits | `habits` (name, icon, schedule JSON: daily / weekdays / N per week / every N days, target, unit, reminder times, archived), `habit_logs` (habit_id, local_date, value, status done/skipped/rest) |
| Goals | `goals` (title, why, horizon, target_on, progress_mode auto/manual, metric), `goal_reviews`★ (period, answers, AI summary) |
| Health | `health_samples`★ (type, value, unit, start/end, source app, external_id for dedupe), `mood_entries`★ |
| Finance | `fin_accounts`★, `fin_categories`, `transactions`★ (amount_minor, currency, account, category, occurred_on, payee, note, import_batch), `budgets`★, `subscriptions`★ (service key for logo, amount, cycle, next_charge_on), `savings_goals`★, `import_batches`, `fx_rates` (public, not user data) |

Notes on the model:
- **Why are finance categories plaintext?** They are reusable labels with no amounts. They can still be E2EE if you prefer, at a tiny cost.
- **Recurring items** store one master row with an RRULE. Instances are expanded locally on demand. Edits to "this occurrence only" create an override row, the same model Google and Outlook use, so two-way sync maps 1:1.
- **Ordering** uses fractional-index `sort_key` strings, so two devices reordering at once never conflict on renumbering.
- **Smart lists** (Today, Upcoming, Overdue) are queries, not stored data.
- **Search**: a local FTS5 index over plaintext *after decryption*, built on device. The server can't search E2EE content, by design.

### 2.4 Key screens and components

The adaptive shell has three layouts:
- **Phone:** a floating glass bottom tab bar (Today · Calendar · Tasks · Notes · More), a central quick-add button, and swipe gestures.
- **Tablet:** a collapsible glass sidebar with a two-pane layout.
- **Desktop/Web:** a sidebar, three-pane layouts, keyboard shortcuts (`⌘/Ctrl K` palette, `N` new, `G T` go to Today, …), hover states and right-click menus.

| Screen | Main components |
|---|---|
| Onboarding | Language, sign-in (Apple / Google / email), recovery-key setup, permissions primer (notifications, calendars, health), optional sample data |
| Today | Greeting + date, **widget grid** (drag to rearrange): agenda timeline, top tasks, habits row, health snapshot rings, budget meter, focus block "now", AI daily plan card |
| Calendar | Day / 3-day / week / month / agenda; time grid with drag-to-create, drag-resize and drag-to-move; unscheduled-tasks tray to time-block; mini-month; calendar layers toggle; TZ switcher |
| Tasks | Inbox, Today, Upcoming, Overdue, tags, custom smart lists; task row (swipe complete/defer); **task detail glass sheet** (subtasks, links, recurrence editor, reminders) |
| Projects | Project list with progress rings; project view switcher **List · Board (kanban) · Timeline (Gantt-lite)**; milestones; notes and files tab |
| Notes | Folder tree, note list, editor (markdown shortcuts, checklists, images, `[[link]]` autocomplete), backlinks panel |
| Ideas | One-tap capture bar (text / voice / photo); idea board (masonry); **convert** action → task / project / note with preview |
| Habits | Today checklist, habit detail with streak, **heatmap**, gentle "rest day" and missed-day handling, reminder editor |
| Goals | Goal cards with auto progress; goal detail (milestones → linked tasks and habits); weekly/monthly **review flow** |
| Health | Metric tiles (sleep, steps, water, workouts, mood, weight, …), trend charts, manual entry, source connections (Apple Health / Health Connect logos), "not medical advice" note |
| Finance | Overview (spent vs budget, by category), transactions list + filters, add transaction (calculator keypad), budgets, subscriptions calendar, savings goals, accounts, **CSV import wizard** (column mapping, dedupe preview), currency settings |
| Assistant | Chat-style panel/sheet, suggestion chips, **ChangeSet preview cards** (diff-style, confirm / edit / discard), model status and download manager |
| Search / Palette | `⌘K` overlay: fuzzy commands + full-text results grouped by module, recent items, natural-language quick add inline |
| Settings | Account, devices, security (recovery key, E2EE status), integrations (calendar accounts, health), AI (model, download, on-device only), appearance (glass quality, reduce motion), language, notifications, export, delete account |

---

## 3. Design system: "Mindora Glass"

### 3.1 Tokens

- **Base:** pure black `#000000` / pure white `#FFFFFF`. Neutral ramps derive from these: 12 steps of grey for text and dividers, computed per mode.
- **Accent:** `#FF0051`, used **only** for primary actions, the current selection and progress. Measured contrast:

  | Accent use | on `#000` | on `#FFF` | on dark glass `#1C1C1E` |
  |---|---|---|---|
  | `#FF0051` (brand fill) | 5.37 ✅ | 3.91 ⚠️ large text / UI only | 4.35 ⚠️ large text / UI only |
  | `#CC0041` (**accent-ink, light mode**) | — | 5.76 ✅ (4.69 on the selection tint) | — |
  | `#FF3374` (**accent-ink, dark mode**) | 5.98 ✅ | — | 4.84 ✅ |

  Rule: fills, rings, progress and selection use `#FF0051`. *Small accent-coloured text* uses the accent-ink tokens, which are visually indistinguishable at text size. Labels on accent-filled buttons use bold text ≥ 18.7 px, or black. All of this is enforced by a contrast unit test over every token pair.
- **Type:** the platform system font (SF Pro on Apple, Roboto/Google Sans-style on Android, Segoe UI Variable on Windows; Inter is bundled on web), with Cyrillic coverage checked. A 7-step scale with Dynamic Type / text scale up to 200 % (layouts reflow; nothing gets clipped).
- **Spacing:** a 4-pt grid with generous whitespace. Radii are continuous ("squircle") corners: 12 / 20 / 28 / full.
- **Elevation = glass depth:** 3 levels (base, raised, overlay). Each level sets blur, tint, highlight and shadow.

### 3.2 The glass material

The `GlassSurface` widget is a layered stack:
1. Backdrop blur (σ by depth) + saturation boost, using grouped backdrops (`BackdropGroup`) so many glass panels share one blur pass.
2. A tint layer (white or black at low opacity, per mode).
3. **Refraction and specular rim**: a fragment shader that bends the backdrop at edges and draws a soft, light-responsive highlight. It reacts to scroll and pointer position, and to device tilt on mobile (subtle).
4. Inner and outer soft shadows for depth.
5. Optional noise dither to prevent banding on large dark gradients.

**Quality tiers**, picked automatically from a GPU benchmark at first launch and switchable in settings:
- `liquid`: full shader refraction and morphing.
- `frosted`: blur + tint + static highlight.
- `solid`: opaque layered surfaces, no blur. Used when the OS "Reduce Transparency" setting is on, on low-end devices, and on web when there is no GPU.

### 3.3 Motion

- **Springs everywhere.** One motion token set (`snappy`, `smooth`, `bouncy`, `gentle`) defined as damping/stiffness, with interruptible, velocity-preserving gestures.
- **Liquid morphs.** The tab-bar selection pill flows between items like a droplet (metaball shader). The quick-add button morphs into the capture sheet. Sheets stretch with rubber-banding.
- **Shared-element transitions**: a task row grows into the detail sheet, and a calendar event into the event editor, using custom Hero flight shuttles that interpolate glass depth and corner radius.
- **Reduce motion** (OS setting or in-app switch) replaces morphs and parallax with short crossfades and turns off tilt effects.
- **Performance budget:** 60 fps minimum on a mid-range device (e.g. Pixel 6a / iPhone 12), 120 fps on ProMotion and 120 Hz Android. Frame-timing tests run in CI on profile builds (§8).

### 3.4 Component library (Phase 1, before any feature screen)

`GlassCard`, `GlassSheet` (modal, detents, draggable), `GlassDialog`, `GlassButton` (primary/secondary/ghost/icon/destructive), `GlassTextField`, `GlassSearchField`, `GlassSegmented`, `GlassSwitch`, `GlassCheckbox` (animated tick), `GlassChip`, `GlassTabBar` (mobile), `GlassSidebar` (desktop/tablet), `GlassToolbar`, `GlassList` / `GlassListRow` (swipe actions, reorder), `GlassMenu` / context menu, `GlassTooltip`, `GlassToast`, `GlassDatePicker`, `GlassTimePicker`, `GlassProgressRing`, `GlassChart` (line, bar, ring, heatmap, sparkline), `EmptyState` (illustrated with simple geometric glass shapes, not lorem ipsum), `Skeleton`, `Avatar`, `BrandLogo` (renders official third-party logos from `assets/brands/`, enforcing clear space and minimum size).

There is a **Gallery app** (`apps/mindora/lib/gallery/`, a debug route and a web deploy) showing every component × light/dark × EN/RU × text-scale × quality tier. Golden tests snapshot all of it.

### 3.5 Third-party logos

- Official assets only: Google (Calendar, Sign-in), Apple (Sign in with Apple button, "Works with Apple Health" badge), Microsoft (Outlook), Google Health Connect, currency/bank logos later. Each file's source URL, usage guideline and download date are recorded in `assets/brands/BRANDS.md`.
- Some brands restrict usage. For example, Apple's guidelines **don't allow using the Health app icon** in third-party apps; the approved "Works with Apple Health" badge and terminology are used instead. Sign-in buttons follow each provider's button spec exactly. These limits are respected even where they reduce visual consistency.
- **Subscriptions tracker:** logos for subscription services (Netflix, Spotify, Yandex Plus …) can't be bundled for every service legally and practically. Plan: a curated set of officially sourced logos where guidelines allow; otherwise a neutral monogram. No scraped or redrawn logos.

### 3.6 Accessibility

Screen readers (VoiceOver, TalkBack, Narrator, NVDA/JAWS on web) get a full `Semantics` tree, including chart summaries ("Steps this week: average 8,210, highest Tuesday"). Full keyboard navigation with visible focus rings in accent-ink. Touch targets ≥ 44 pt. Dynamic Type to 200 %. Respects Reduce Motion, Reduce Transparency and Increase Contrast (adds borders, removes translucency). Contrast is unit-tested.

---

## 4. Modules: scope per module

Everything below links through `links`. Each module ships realistic sample data (EN and RU) plus designed empty states.

1. **Calendar**: day/3-day/week/month/agenda views; drag to create, resize and move; time-block a task by dragging it from the tray; RRULE recurrence with "this / this and following / all" edits; per-event time zones and a secondary-TZ column; two-way sync with Google (Calendar API, incremental sync tokens, push channels), Outlook (Microsoft Graph delta + webhooks), Apple Calendar (EventKit on Apple devices) and **Yandex Calendar / any CalDAV** (relevant for St. Petersburg users).
2. **Tasks**: inbox, subtasks (nested), priorities, due date/time, recurrence (incl. "N days after completion"), tags, smart lists (Today, Upcoming, Overdue, custom filters), quick add from anywhere (palette, global hotkey on desktop, widget, share sheet, Siri/App Intents, Android quick-settings tile).
3. **Projects**: tasks, notes and files in one place; List, Board and Timeline views; milestones; progress % = weighted completion of tasks and milestones.
4. **Notes**: rich text + markdown shortcuts, checklists, images, `[[backlinks]]` with autocomplete and a backlinks panel, folders and tags, instant local full-text search (FTS5, EN + RU stemming via the `porter`/`unicode61` tokenizer + Snowball RU stemmer extension).
5. **Ideas**: capture in under 1 s from launch or a widget (text, on-device voice transcription, photo); masonry board; one-tap convert to task / project / note, which keeps the idea linked.
6. **Habits**: daily / specific weekdays / N per week / every N days / counts (e.g. 8 glasses); streaks with **"rest days" and a forgiving streak** (missing one scheduled day in a week doesn't break the streak; wording is neutral, never guilt-tripping); reminders; heatmap.
7. **Goals**: goal → milestones → linked tasks and habits; auto progress (milestones, task completion, habit consistency, or a numeric metric such as savings or weight); weekly and monthly review prompts with an optional AI summary.
8. **Health**: sleep, steps, water, workouts, mood, weight, heart rate, mindful minutes and more; read from Apple Health (iPhone; iPad on iPadOS 17+) and Health Connect (Android) with per-type permissions; manual entry everywhere; E2EE sync so a Mac, PC or web session can view the data; trend charts; a persistent **"not medical advice"** note.
9. **Finance**: income/expenses, categories, budgets (monthly/weekly, rollover), subscriptions with upcoming-charge reminders, savings goals, multi-currency (AED, RUB, USD, EUR + any ISO 4217), base-currency conversion with daily rates (**Central Bank of Russia** for RUB, ECB for EUR crosses; cached for offline use; every transaction stores the rate it was converted at), charts, manual entry, **CSV import** (presets for common Russian and UAE bank export formats + a generic column mapper, with duplicate detection). Bank integrations come later.
10. **AI assistant**: see §6.

**Cross-module features:** Today dashboard with customizable widgets; global search + command palette; local smart reminders; OS widgets and Live Activities; EN + RU at launch, Arabic (RTL) later.

---

## 5. Accounts, sync and security

### 5.1 Backend: Supabase (recommended)

| | Supabase | Firebase |
|---|---|---|
| Data model | Postgres: relational, fits linked entities, SQL, migrations | Document store; joins and aggregates are awkward |
| Security | Row-Level Security in the database, testable with pgTAP | Security Rules (fine, but harder to test) |
| Offline-first sync | Via PowerSync (mature, Flutter + web SDK) | Built-in cache, but last-write-wins per document only |
| Auth | Apple, Google, email/magic link, OTP | Same |
| **Self-hosting** (152-FZ path, R1) | ✅ Open source, Docker | ❌ Google-hosted only |
| Lock-in | Low (plain Postgres) | High |

**Hosting:** Supabase Cloud, `eu-central-1` (Frankfurt, lowest latency to St. Petersburg among the regions on offer) + PowerSync Cloud (EU) for development and beta. `backend/selfhost/` keeps an identical Docker stack (Supabase + PowerSync Open Edition) that we test in CI. It can run in a Russian data centre (for example Selectel or Yandex Cloud in St. Petersburg/Moscow) if needed.

### 5.2 Auth

Sign in with **Apple**, **Google** and **email** (magic link + password). Optional Phase-9 addition worth considering for the SPb audience: **Yandex ID / VK ID** (OIDC). Sessions are stored in the OS keychain (Keychain / Android Keystore / Windows Credential Manager / WebCrypto non-extractable key + IndexedDB on web).

### 5.3 Offline-first sync

```
UI → Command → local SQLite (Drift) ─┬─► upload queue (PowerSync CRUD queue)
                                     │        │  batch of ops with HLC stamps
                                     │        ▼
                                     │   Postgres RPC  apply_changes(ops)   ← RLS: user_id = auth.uid()
                                     │        │  merge: per-field LWW by HLC (plaintext tables)
                                     │        │         per-row LWW + conflict copy (E2EE tables)
                                     │        ▼
                                     └◄── PowerSync service streams checkpoints (bucket per user)
```

- **Clocks:** a hybrid logical clock (HLC) per device, so causality holds even when device clocks are wrong.
- **Plaintext tables** (tasks, events, projects, habits …) merge **per field**. Example: you rename a task on your phone while your laptop sets its due date offline, and both changes survive.
- **E2EE tables** (the server sees only ciphertext) use row-level LWW on the server. For **notes**, the client detects a concurrent edit (both edits based on the same base HLC) and keeps a *conflict copy* linked to the original, with a gentle "two versions" banner. Block-level CRDT merging for notes is a post-launch upgrade, kept in mind in the document format.
- **Deletes** are tombstones and win over older edits. They are garbage-collected after 90 days.
- **Habit logs and health samples** are effectively append-only, with natural keys (`habit_id + local_date`, `source + external_id`) for dedupe.
- **Attachments**: content-addressed and uploaded lazily. E2EE attachments are encrypted before upload.
- `SyncEngine` is an interface. If PowerSync ever stops fitting, a custom implementation over the same ops and RPC can replace it without touching features.

### 5.4 Encryption

- **In transit:** TLS 1.2+ everywhere, with certificate pinning on mobile for our API host.
- **At rest (server):** Postgres and Storage disk encryption (provider-managed).
- **At rest (device):** SQLCipher-encrypted SQLite on native platforms, with the key in the keychain/keystore. On web, the OPFS database is encrypted page by page with a WebCrypto key (verified in a Phase 2 spike; fallback: E2EE-only fields stay encrypted in local storage too).
- **E2EE key hierarchy:**
  - A random 256-bit **Master Key (MK)** is generated on the first device.
  - The MK is wrapped by: (a) a **Recovery Key** (24 words, shown once, Argon2id → KEK), and (b) each device's key (X25519, stored in the keychain/keystore).
  - Adding a new device: approve it from an existing device (QR or code, X25519 key exchange) **or** enter the Recovery Key.
  - Per-table data keys are derived from the MK (HKDF) and versioned for rotation.
  - The server stores only wrapped keys. **Losing every device and the Recovery Key = losing E2EE data.** The UI explains this plainly and nags (kindly) until the key has been saved or printed.
  - Passkey PRF-based unlock is a later improvement.

### 5.5 Privacy and compliance

- **Data export:** full JSON (all entities, decrypted on device) + CSV per module (tasks, transactions, habits logs, health samples) + attachments, as one ZIP.
- **Account deletion:** in-app and on the web (Apple/Google require both), with a 7-day grace period. Then a hard delete of every row, Storage object and wrapped key, and a revoke of calendar tokens. A pgTAP test proves no rows remain.
- **App Store:** privacy nutrition labels; HealthKit data is not used for ads and not stored in iCloud outside our E2EE sync; required purpose strings; Sign in with Apple is offered alongside Google (Guideline 4.8).
- **Google Play:** Data Safety form, Health Connect permissions declaration, prominent disclosure screens.
- **GDPR:** lawful basis = contract; DPA with Supabase/PowerSync; records of processing; DSAR (export/delete) built in; EU hosting.
- **UAE PDPL:** consent for sensitive data (health), cross-border transfer basis (EU adequacy-style safeguards), breach notification process.
- **Russia 152-FZ:** see risk **R1**.
- **AI:** all inference runs on device. There is no AI telemetry. Prompts and outputs never leave the device.

---

## 6. On-device AI

### 6.1 Runtime per platform (best first, with automatic fallback)

| Platform | Tier A (system model) | Tier B (bundled-download model) | Tier C (always available) |
|---|---|---|---|
| **iOS / iPadOS / macOS 26+** | **Apple Foundation Models** (~3B on-device; guided generation `@Generable` = reliable structured output; tool calling). Needs an Apple-Intelligence-capable device (iPhone 15 Pro+, M-series iPad/Mac) with Apple Intelligence on. | llama.cpp (Metal) + **Qwen3-1.7B Q4** (~1.1 GB) on iPhone; **Qwen3-4B Q4** (~2.5 GB) on Mac | Rule engine |
| **Android** | **Gemini Nano** via ML Kit GenAI Prompt API (Pixel 9/10, recent Galaxy flagships, …) | llama.cpp (Vulkan/CPU) + Qwen3-1.7B Q4 or Gemma 3 1B Q4 (~0.7 GB) for 6 GB-RAM devices | Rule engine |
| **Windows** | — (Windows AI Foundry / Phi Silica on Copilot+ PCs: evaluated in Phase 7) | llama.cpp (Vulkan/CUDA/CPU) + Qwen3-4B Q4 (≥ 16 GB RAM) or 1.7B | Rule engine |
| **Web** | Chrome built-in Prompt API (Gemini Nano) where available | **WebLLM** (WebGPU) + Qwen3-1.7B q4f16 (~1 GB, cached in browser storage) | Rule engine |

Model shortlist: **Qwen3** (Apache-2.0, strong Russian, good tool calling) vs **Gemma 3** (good RU, Gemma licence). Final choice comes from our own EN/RU eval set in Phase 7 (accuracy, latency, RAM, battery).

### 6.2 Honest limits

- **Russian on Apple's model:** Apple Intelligence's supported languages and regions **may not include Russian**, or may not be enabled for Russian users. Since the main city is St. Petersburg, many users on new iPhones will still land on **Tier B**. We measure this, but the design assumes Tier B is the main path for RU.
- **Download size:** 0.7–2.5 GB. Never bundled in the app. A lazy, resumable download starts on Wi-Fi only after the user opts in, with a progress UI and a storage display. Models can be deleted any time.
- **Speed:** small models give about 10–30 tokens/s on mid-range phones and faster on desktops and recent iPhones. Answers stay short. Structured output keeps tokens low. Streaming UI throughout.
- **Battery and heat:** inference runs only on user action (no background LLM jobs on mobile). Weekly-review generation runs while charging, or on demand.
- **Small models are bad at arithmetic and recall.** So the model **never computes answers about your data**. It translates a question into a typed **tool call** (e.g. `sum_transactions(category: food, period: this_month)`). The app runs it against SQLite and the model only phrases the result. Numbers are always exact.
- **Weak devices / web without WebGPU:** everything still works through the rule engine and templates. AI-only features (summaries, free-form breakdowns) show a clear "needs a model" state instead of failing.

### 6.3 Capabilities and how they work

| Capability | Mechanism |
|---|---|
| **NL quick add**: "gym tomorrow at 7, then call mum" / "спортзал завтра в 7, потом позвонить маме" | **Rule engine first** (`mindora_nlp`: EN/RU dates, times, durations, recurrence, amounts, tags, `#project`, `!priority`) gives an instant, offline result → the LLM (if present) fixes ambiguous splits and entity types → output is a **ChangeSet** (event + task) |
| Break down a task or goal | LLM with a structured-output schema (`steps[] {title, est_min, order}`) → preview → ChangeSet |
| Auto-plan my day | **A deterministic scheduler** (constraint solver: events, task durations, due dates, priorities, energy windows from settings/habits) builds the plan. The LLM only explains it or adjusts it from a request ("keep my mornings free"). |
| Summarise notes; ideas → action items | LLM over chunked decrypted text (map-reduce for long notes) → summary text / task ChangeSet |
| Ask my data ("how much did I spend on food this month?", "how did I sleep this week?") | Intent → typed tools (finance, health, tasks, habits, calendar queries) → exact numbers → phrased answer + a mini chart |
| Weekly review | Deterministic stats (done tasks, habit consistency, sleep avg, spend vs budget) + LLM narrative |

**Always confirm:** every capability that changes data returns a `ChangeSet` shown as preview cards (what will be created or edited, with field-level diffs). You can confirm, edit inline or discard. Applied changes go through the normal undo stack, and the assistant has no other write path. This is enforced by architecture, not just convention: the AI package has no repository write access.

---

## 7. Platform extras

| Feature | iOS / iPadOS | macOS | Android | Windows | Web |
|---|---|---|---|---|---|
| Widgets | WidgetKit (Today, Tasks, Habits, Next event, Budget), interactive (check off) | WidgetKit | Glance widgets | (Win 11 Widgets Board needs a packaged app + Adaptive Cards; we evaluate it. Fallback: tray menu) | — |
| Lock screen / Live Activities | Lock-screen widgets; **Live Activities + Dynamic Island** for the current time block / focus timer | — | Ongoing notification for the current block | — | — |
| Notifications | Local (scheduled on device, works offline, content stays private) | Local | Local (exact alarms permission handled) | Local toasts | Web Push with a generic payload; content is decrypted on open |
| Quick capture | App Intents / Siri / Shortcuts, share extension, Control Center control | Global hotkey, menu-bar capture | Share target, quick-settings tile, app shortcuts | Global hotkey, tray | PWA install, shortcuts |
| Calendar integration | EventKit + server-side Google/Outlook sync + CalDAV | same | Server-side + CalDAV | Server-side + CalDAV | Server-side + CalDAV |
| Health | HealthKit | (view synced data) | Health Connect | (view synced data) | (view synced data) |

Calendar data is not E2EE (per the encryption decision), so **Google/Outlook sync runs server-side** (Edge Functions + webhooks/push channels). That keeps calendars up to date even when no device is open. OAuth refresh tokens live encrypted in a server-only schema.

---

## 8. Quality and testing

- **Unit:** domain logic (RRULE expansion, smart lists, progress math, money/FX, HLC merge, NLP parser with ~1,000 EN/RU fixtures, scheduler, crypto round-trips).
- **Widget and golden tests:** every design-system component × light/dark × EN/RU × 100/200 % text × quality tier.
- **Integration (sync):** two simulated clients against a local Supabase + PowerSync (Docker in CI): offline edits, conflicts, tombstones, E2EE round-trips, key rotation, device approval.
- **Backend:** pgTAP tests for **every RLS policy** (user A can never read or write user B's data, including through RPCs and Storage).
- **UI / e2e:** `integration_test` flows on Android emulator (Linux runner) and iOS simulator (macOS runner): onboarding, quick add, time-block a task, complete a habit, add a transaction, AI ChangeSet confirm.
- **Performance:** startup-time and frame-timing benchmarks on profile builds in CI, with budgets that fail the build (cold start to interactive Today < 1 s on mid-range; no janky frames in scripted scroll and transition tests).
- **AI evals:** an EN/RU eval set (quick-add parsing, breakdowns, data Q&A tool selection) run per model/runtime. Scores are tracked over time.
- **CI matrix (every push):** analyze + format + test (ubuntu) · web build · Android build · iOS build (no codesign) · macOS build · Windows build · backend tests. Store-signing pipelines are added in Phase 9.
- **Docs:** `README.md` (run/build/deploy per platform), `PROGRESS.md` per phase, ADRs in `docs/adr/` for major decisions.

---

## 9. Risks and trade-offs

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| **R1** | **Russia 152-FZ data localisation.** With St. Petersburg as the main city, collecting Russian citizens' personal data requires *primary* storage on servers in Russia, plus registration with Roskomnadzor as a data operator. EU hosting alone is likely **not compliant** for a Russia-focused launch. | Legal and fines; risk of being blocked | Architecture is self-hostable from day one (§5.1). **Recommend a legal review before the public launch to Russian users.** Likely outcome: a RU region (self-hosted Supabase + PowerSync in a Russian DC), with users routed by region at sign-up. Beta can run on EU hosting with a small invited group. |
| R2 | On-device AI quality and size, esp. Russian on Apple's model | Weaker AI on some devices | Tiered runtimes, rule engine first, tool-based answers, eval-driven model choice, clear UI states |
| R3 | Glass rendering cost (web, low-end Android) | Jank, battery | Quality tiers, grouped backdrops, CI frame budgets, `solid` fallback |
| R4 | E2EE complexity (key loss, multi-device, no server search) | Data loss, support load | Recovery-key flow with strong UX, device approval, extensive tests, E2EE only for sensitive modules |
| R5 | Calendar two-way sync edge cases (recurrence exceptions, TZ, provider quotas) | Duplicate or lost events | Use provider IDs/etags, RRULE override model mirrored 1:1, idempotent sync, large fixture tests |
| R6 | Flutter on Windows and web is less battle-tested than on mobile | Platform bugs | Early CI coverage on all targets from Phase 1; platform QA checklist per phase |
| R7 | **Reachability from Russia**: some foreign CDNs and cloud IPs (Cloudflare, parts of AWS) are periodically throttled in Russia; Google sign-in or APIs may degrade | App or website slow or unreachable for SPb users | Test from Russian networks during beta; keep a Russian mirror/CDN option (e.g. Yandex Cloud CDN) for the web app; email sign-in always available |
| R8 | Scope: 10 modules × 6 platforms is very large | Slow delivery | Strict phase gates, shared components, no module starts until its dependencies are done; cut scope to "beta" per module when needed |
| R9 | Brand-logo guidelines (e.g. Apple Health icon not allowed) | Rejections | Follow official guidelines, `BRANDS.md` audit, approved badges only |
| R10 | Dependency risk: PowerSync, AppFlowy Editor | Lock-in, maintenance | Interfaces around them (`SyncEngine`, editor adapter); spikes before commitment |
| R11 | App Store review: HealthKit, AI model downloads (Guideline 2.5.2: downloaded models are data, not code; that's fine, but must be stated) | Review delays | Prepare review notes, purpose strings and demo account early (Phase 9) |

---

## 10. Phased roadmap

Every phase ends with: all CI platform builds green · tests passing · `PROGRESS.md` updated · a short summary to you · **wait for your OK**. Sizes are relative (S < M < L < XL).

### Phase 1 — Foundation (L)
Monorepo (pub workspaces, Melos, FVM), Flutter app for 6 targets, lints and formatting, CI matrix. Tokens, `GlassSurface` with 3 quality tiers + shaders, motion system, full component library, Gallery. Adaptive shell (bottom bar / sidebar, keyboard shortcuts skeleton), router with transitions, light/dark, EN/RU with plural rules, a11y base. Mindora logo as SVG + app icons and splash screens for all platforms. **Technical spikes:** (a) llama.cpp FFI + Apple Foundation Models plugin compile in CI, (b) SQLite WASM + OPFS + FTS5 on web.
**Done when:** the Gallery and the empty app shell run on all 6 targets via CI artefacts; goldens pass for every component in both modes and both languages; the 60 fps frame-budget test passes for tab and sheet transitions; reduce motion and reduce transparency work; both spikes report findings in `PROGRESS.md`.

### Phase 2 — Accounts and sync (L)
Supabase project + migrations for **the whole schema** (§2.3), RLS + pgTAP, PowerSync sync rules, Drift schema mirroring it, HLC + merge RPC, SyncEngine, E2EE key hierarchy (recovery key, device approval), local DB encryption, auth (Apple, Google, email), onboarding, settings (account, devices, security), export (JSON/CSV) and account deletion, self-host Docker stack tested in CI.
**Done when:** two clients converge after offline conflicting edits (integration tests); RLS tests prove isolation; E2EE round-trip and new-device flows pass; sign-in works on every platform; export and delete are verified end to end.

### Phase 3 — Core planning (XL)
Tasks (all features incl. recurrence and smart lists), Calendar (all views, drag/resize, time-blocking, RRULE edits, time zones; local calendars only, with external sync in Phase 8), Projects (list/board/timeline, milestones, progress), universal links UI, `mindora_nlp` quick add v1 (rule-based EN/RU), Today dashboard v1 (agenda, tasks, widget grid framework), local notifications for tasks and events.
**Done when:** key e2e flows pass (create → schedule → complete → recurring next instance); NLP fixtures ≥ 95 % pass; calendar drag interactions run at 60 fps; realistic sample data and empty states are in place; EN/RU are complete.

### Phase 4 — Thinking (L)
Notes (editor spike → choice, markdown, checklists, images, `[[backlinks]]`, folders/tags, conflict copies), Ideas (text/voice/photo capture, board, convert), global FTS search (EN/RU), **command palette** (`⌘/Ctrl K`) with commands + search + quick add.
**Done when:** search returns results in < 50 ms over 10k items on a mid-range device; on-device voice capture works per platform; backlinks are consistent; palette is fully keyboard-driven.

### Phase 5 — Growth (M)
Habits (schedules, counts, forgiving streaks, rest days, heatmap, reminders), Goals (milestones, linked tasks and habits, auto progress modes, review flow), Today widgets for habits and goals.
**Done when:** streak and progress math are covered by unit tests (incl. TZ/DST edges); review flow e2e passes; the wording has been reviewed as non-judgemental in EN and RU.

### Phase 6 — Life data (L)
Health (HealthKit, Health Connect, manual entry, trends, mood, disclaimer), Finance (accounts, transactions, categories, budgets, subscriptions, savings goals, multi-currency with CBR/ECB rates via an Edge Function cache, CSV import wizard + bank presets, charts), Today widgets for health and budget.
**Done when:** health import dedupes correctly over repeated syncs; money math is exact (integer minor units, rounding tests); CSV import handles the preset formats; FX works offline with cached rates; all data is E2EE-verified.

### Phase 7 — AI assistant (XL)
`mindora_ai` orchestrator + provider interface; Foundation Models plugin, Gemini Nano bridge, llama.cpp runtime (iOS/macOS/Android/Windows), WebLLM (web); model download manager; tool layer for data Q&A; scheduler for auto-plan; all six capabilities; ChangeSet preview/confirm UI; EN/RU eval suite; model selection report.
**Done when:** each platform runs at least Tier B or Tier C end to end; eval thresholds are met (set from baseline in the Phase 7 kickoff); nothing is written without confirmation (tested); no network calls during inference (tested with network disabled).

### Phase 8 — Platform extras (L)
iOS/macOS widgets (interactive), Live Activities + Dynamic Island, Android Glance widgets, App Intents/Siri/Shortcuts, share extensions, global hotkeys, tray/menu-bar capture, Web Push + PWA, **Google Calendar, Outlook, Apple (EventKit) and CalDAV/Yandex two-way sync**, smart reminders.
**Done when:** widgets update within the OS limits after data changes; calendar sync passes the fixture suite (recurrence exceptions, TZ, deletions) against provider sandboxes; Live Activity covers the focus/time-block flow.

### Phase 9 — Polish and release (L)
Performance pass, full a11y audit (VoiceOver, TalkBack, Narrator, NVDA), animation polish, test-coverage gaps, store assets (screenshots EN/RU), privacy labels / Data Safety, signing and release pipelines (TestFlight, Play internal track, Microsoft Store/MSIX, web prod deploy), README deploy docs, legal docs (privacy policy, terms), **RU-region decision executed per R1**.
**Done when:** TestFlight + Play internal + MSIX + web production builds are produced by CI; the a11y checklist is all green; performance budgets are met on mid-range reference devices; store review notes are ready.

---

## 11. What I need from you to start Phase 1

1. **Approve this plan** (or tell me what to change).
2. Confirm the **stack: Flutter + Supabase + PowerSync**.
3. Nothing else is blocking for Phase 1. Accounts needed later: Apple Developer, Google Play Console, Supabase and PowerSync projects (Phase 2), and Google Cloud and Azure app registrations for calendar sync (Phase 8). I'll ask for them when they're needed and never commit secrets. The repo is public, so all secrets go into GitHub Actions secrets.
