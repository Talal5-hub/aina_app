# Phase 3 — Core Flutter Architecture

Theme, routing, dependency injection, networking, and localization: the shared skeleton every feature module (Phase 4 onward) plugs into.

---

## 1. A Verification Note (read this first)

Phase 2's SQL was executed against a real local Postgres+PostGIS instance and I could show you actual query output. **I can't do the equivalent for this phase** — this sandbox has no route to the Flutter/Dart SDK binaries (Google's SDK CDN isn't reachable from here), so nothing in this zip has been run through `flutter analyze` or `flutter pub get`.

What I did instead, so this isn't just "looks right to me":
- Wrote every file by hand rather than templating, so I could reason about each import and type as I went.
- Ran an automated pass over all 42 files checking brace/paren balance and scanning for leftover placeholder text.
- Manually re-traced every cross-file reference (every `import 'package:aina/...'` resolves to a file that exists and exports the symbol used).
- Cross-checked version-sensitive APIs (`CardThemeData`, `Color.withValues`, `Geolocator.getCurrentPosition`'s `LocationSettings` parameter, `LocalizationsDelegate.shouldReload`'s covariant override) against what's current in recent stable Flutter/package releases, since these are exactly the kind of thing that silently breaks between versions.

**Please run `flutter pub get && flutter analyze` yourself before building on this** — I'm confident in the logic and structure, but a real compiler is the only way to catch a typo I can't see.

---

## 2. What Changed From the Phase 1 Plan

Phase 1's dependency list included `riverpod_annotation` / `riverpod_generator` (the `@riverpod` code-generation style). I did **not** use them here — every provider in this phase (`injection.dart`, `theme_mode_provider.dart`, `locale_provider.dart`, `goRouterProvider`) is written as a plain `Provider`/`Notifier`/`NotifierProvider` instead.

Why: generated providers require a `.g.dart` part file produced by `build_runner`, and I have no way to run `build_runner` in this environment to produce and verify that file. Shipping code that references a `.g.dart` file I can't generate would mean handing you something guaranteed not to compile until you run codegen yourself, with no way for me to have checked it first. Plain Riverpod providers are fully valid Dart with zero codegen step, and are just as testable — this was a pragmatic call to keep every file in this zip actually correct rather than technically "more modern" but unverifiable.

If you'd rather standardize on `@riverpod` generators for Phase 4 onward (repository/controller providers), say so and I'll switch — it's a bigger deal for data-layer providers where generated `.family`/`.autoDispose` boilerplate saves real repetition; it mattered less for this phase's small, mostly-singleton service graph.

---

## 3. What's In This Phase

```
lib/
├── app.dart                 -- Root MaterialApp.router: theme + routing + localization wiring
├── bootstrap.dart            -- Shared init sequence for all 3 flavors
├── main_development.dart
├── main_staging.dart
├── main_production.dart
└── core/
    ├── config/                -- Env (dart-define), FlavorConfig, AppConfig
    ├── constants/              -- App-wide string/key constants (no magic strings in repos later)
    ├── theme/                  -- Colors, typography, spacing, ThemeData, theme-mode provider
    ├── routing/                -- GoRouter setup, route names, auth-redirect guards, splash screen
    ├── network/                -- Dio client + auth/logging/retry interceptors, custom exceptions
    ├── error/                  -- Failure types + ExceptionMapper (Dio/Supabase -> Failure)
    ├── services/                -- SupabaseService bootstrap, LocationService
    ├── storage/                -- Hive, SharedPreferences, SecureStorage wrappers
    ├── utils/                  -- Logger, Result<T>, Validators, Formatters, extensions
    ├── localization/            -- JSON-file-based i18n (en/ur) + locale provider
    └── di/injection.dart        -- Root Riverpod provider graph
```

---

## 4. Key Architectural Decisions

**Error handling: `Result<T>`, not exceptions, past the data layer.**
`core/utils/result.dart` defines a sealed `Result<T>` (`Success`/`Error`). Repositories in Phase 4+ will catch raw `DioException`/`PostgrestException`/etc., run them through `ExceptionMapper.map()`, and return `Result<T>` — so a `SalonNotifier` in the presentation layer pattern-matches on `.when(success: ..., failure: ...)` instead of wrapping every repository call in try/catch.

**Networking: two paths, on purpose.**
Direct table/auth/storage/realtime calls go through `Supabase.instance.client` (via `SupabaseService`) — that SDK already has its own well-tested HTTP handling. The `DioClient` built in this phase is for anything *outside* that SDK: custom Edge Functions, and future third-party REST integrations (JazzCash/Easypaisa gateways, OneSignal). Giving these two paths the same interceptor stack would have meant fighting the Supabase SDK's internals for no benefit.

**Retry policy only covers GET requests.** POST/PATCH/DELETE calls are never auto-retried by `RetryInterceptor` — retrying a booking request or a review submission on a flaky connection risks a duplicate side effect. A failed write surfaces immediately; only idempotent reads get exponential-backoff retries.

**Routing: auth state drives redirects, not screen-level checks.**
`RouteGuards.redirect()` is the single source of truth for "can this navigation proceed." `GoRouterRefreshStream` bridges Supabase's `onAuthStateChange` stream into something GoRouter's `refreshListenable` can consume, so signing out anywhere in the app immediately re-evaluates the current route rather than waiting for the next manual navigation.

**Only the splash route is wired up.** `route_names.dart` declares every path the full app will eventually need (login, home, salon details, search, favorites, profile, settings) as named constants now, so Phase 4 onward can reference `RouteNames.login` without a circular import back into a not-yet-built auth module — but the actual `GoRoute` entries for those paths are added in the phase that builds each screen. Until then, `AppRouter`'s `errorBuilder` shows a plain "this screen is built in a later phase" message rather than a crash if something navigates there early — this is a temporary router-config placeholder for genuinely unbuilt screens, not app content standing in for a feature.

**Localization: JSON, not `.arb` + `gen_l10n`.**
`AppLocalizations` loads `assets/translations/{locale}.json` directly and resolves dot-notation keys (`t('home.greeting', {'name': 'Ali'})`) with a plain string fallback if a key is missing. This was chosen over Flutter's generated `.arb` pipeline for the same reason as the Riverpod decision above — `gen_l10n` also requires a build step I can't run here to verify the generated output compiles. It has a real product upside too: a translator or PM can edit `ur.json` directly without touching Dart or triggering a rebuild step.

**Storage split by sensitivity.** `SharedPrefsService` holds non-sensitive settings (theme, locale, onboarding flag, last-known coordinates). `SecureStorageService` (backed by Keychain/EncryptedSharedPreferences) exists for anything genuinely sensitive beyond what Supabase's own SDK already persists securely. `HiveService` owns the three offline-cache boxes (favorites, search history, cached salon list) that Phase 8 (Favorites) and Phase 12 (Offline support) will read from.

---

## 5. Design System → Code Mapping

Every token from Phase 1's design system has a corresponding constant — no screen in a later phase should ever write a hex color or a raw `EdgeInsets.all(16)` inline:

| Phase 1 spec | Phase 3 implementation |
|---|---|
| Gold `#D4AF37` / Charcoal `#111827` / Purple accent | `AppColors.primary` / `.secondary` / `.accent` |
| Poppins type scale | `AppTextStyles` (loaded via `google_fonts`, no bundled font files needed) |
| 4/8/12/16/24/32/48 spacing scale | `AppSpacing.xs` … `.xxxl` |
| 16-20px card radius / 12px chip radius | `AppSpacing.radiusCard` / `.radiusChip`, applied in `AppTheme`'s `CardThemeData`/button shapes |
| Soft diffused shadows, no Material default hard shadows | `CardThemeData(elevation: 0, side: BorderSide(...))` — a bordered flat card rather than a drop-shadow, matching the "soft, minimal" brief |

---

## 6. What's Deliberately Not Here Yet

- No `GoRoute` for login/home/etc. — added feature-by-feature starting Phase 4.
- No repository classes or Freezed models — those consume `core/network`, `core/error`, and `core/utils/result.dart` starting Phase 4.
- No actual PNG/SVG/Lottie asset files — `AssetPaths` references paths that need real files dropped in before the app will run; only the two JSON translation files are real, populated content in this phase.
- No generated `@riverpod` providers — see Section 2.

---

**End of Phase 3.** Once you've run `flutter pub get` / `flutter analyze` against this and confirmed it's clean (or sent back whatever it flags), I'll move to **Phase 4: Authentication module** — Supabase email/password + Google/Apple sign-in, session persistence, and the first real `GoRoute`s.
