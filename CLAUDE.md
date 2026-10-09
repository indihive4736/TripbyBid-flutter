# CLAUDE.md

Guidance for Claude Code and human contributors. **This directory (`tripbybid-flutter/`) is the repo root.**

## Project overview

**TripByBid** is a reverse-auction travel marketplace: a traveler posts one request (flight, train or
hotel), verified travel agents bid on it, the traveler accepts a bid and pays, then chats with the agent
until the trip. This repo is the **Flutter mobile client for travelers only** — no agent or admin
flows. Agent/admin accounts are refused at sign-in ("use the web dashboard").

Sibling projects (read-only references — never edit them from here):

- `../tripbybid` — NestJS API (Prisma on Supabase Postgres). It owns all data access.
- `../tripbybid-frontend` — Next.js web client; the reference for traveler flows, copy and status labels.

The UI follows the claude.ai/design project "TripByBid landing redesign", file `TripByBid App.dc.html`
(16 traveler screens: getting started, core app, booking detail).

## Toolchain

- Flutter 3.35.5 (stable) / Dart 3.9.2
- Dart & Flutter MCP server configured in `.mcp.json` (`dart mcp-server`)

## Commands

```bash
flutter pub get
flutter analyze                              # must be clean before a task is done
dart format lib test
flutter test                                 # unit, bloc, widget and architecture tests

# Run (config from env/dev.json — gitignored; copy env/example.json)
flutter run --dart-define-from-file=env/dev.json
```

`env/*.json` holds `API_BASE_URL` (with the `/api` prefix), `SUPABASE_URL`, `SUPABASE_ANON_KEY` and
`CASHFREE_ENV` (`sandbox`|`production`). Without them the app shows a "missing configuration" screen.
Plain HTTP is allowed only in Android debug builds and for local networking on iOS.

## Backend facts that shape the app

- **Auth is Supabase Auth**, like the web client: sign-up (`signUp` with `role:'user'`), a 6-digit
  email code (`verifyOTP`, type signup), `signInWithPassword`. The Supabase access token is the API
  bearer token (the backend's AuthGuard accepts it). The backend's own `/auth/login` cannot be used yet:
  it only knows accounts backfilled into `user_credentials`, never new signups. There is no phone OTP,
  social login or password reset.
- `GET /bids/request/:id` lists only **active** bids; the accepted/selected bid is in
  `GET /booking-requests/:id`'s `bids`. `TripDetail.comparableBids` merges them.
- Paying: `POST /payments/initiate {bidId}` → Cashfree checkout (`payment_session_id`) →
  `POST /payments/verify/:paymentId` → `PATCH /bids/:id/select {paymentId}` creates the booking.
  Verify alone does not book. `PayForBidUseCase` runs the sequence.
- Routes use the **request** id; chat, cancellation, tickets and reviews need the **booking** id
  (`TripRequest.booking?.id`). Chat exists only after payment (one thread per booking).
- No realtime for bids/notifications/status today (Ably publishes chat messages only) — screens poll
  or refresh on pull/resume.
- Reviews: `POST /reviews` (rating 1–5, optional comment), only for `completed` bookings, once.

## Architecture — Clean Architecture, feature-first

**This section is binding.** Where a skill's guidance on structure conflicts with it, this section wins.

```
┌────────────────────────────────────────────────────────┐
│                  Presentation Layer                    │
│        (Widgets, Pages, BLoC / Cubit)                  │
└───────────────────────────┬────────────────────────────┘
                            │ depends on
                            ▼
┌────────────────────────────────────────────────────────┐
│                     Domain Layer                       │
│    (Entities, Use Cases, Repository Interfaces)        │
│          ★ Pure Dart — zero frameworks ★               │
└───────────────────────────▲────────────────────────────┘
                            │ depends on
┌───────────────────────────┴────────────────────────────┐
│                      Data Layer                        │
│   (Models/DTOs, Data Sources, Repository Impls)        │
└────────────────────────────────────────────────────────┘
```

**Dependency rule:** dependencies always point inward. Domain knows nothing about Data or Presentation.
Presentation never imports from `data/`, and Data never imports from `presentation/`.

### Folder structure

```
lib/
  ├── main.dart                        # Supabase.initialize, configureDependencies, runApp
  ├── app.dart                         # MaterialApp.router, app-wide AuthBloc
  ├── core/
  │     ├── config/                    # AppConfig (--dart-define values)
  │     ├── di/                        # get_it setup: injection_container.dart (`sl`)
  │     ├── error/                     # Failure, Result (Ok/Err), guard() — pure Dart; AppException
  │     ├── usecase/                   # UseCase<T, Params>, NoParams — pure Dart
  │     ├── utils/                     # pure-Dart helpers the domain may use (IndianPhone)
  │     ├── network/                   # ApiClient, AccessTokenProvider (Supabase), JsonReader
  │     ├── format/                    # Fmt: INR, dates, relative times, class labels (intl)
  │     ├── router/                    # app_routes.dart (paths), app_router.dart (routes, shell)
  │     ├── theme/                     # AppColors, AppTypography, AppTheme — design tokens
  │     └── widgets/                   # design-system widgets (AppButton, AppCard, InkPanel, …)
  └── features/
        ├── onboarding/                # splash, intro slides, welcome; "intro seen" flag
        ├── auth/                      # login, signup, email code; AuthBloc
        ├── trips/                     # home, my trips, new request, booking detail (bids, pay,
        │                              #   cancel, ticket, rate) — requests/bids/bookings
        ├── payments/                  # checkout (Cashfree gateway), payment history
        ├── chat/                      # inbox + booking chat
        ├── notifications/             # notification list, unread count
        └── profile/                   # profile, edit, notification settings, payments, help
test/                                  # mirrors lib/; shared fakes + fixtures in test/helpers/
```

Each feature has `domain/{entities,repositories,usecases}`, `data/{datasources,models,repositories}`
and `presentation/{bloc,pages,widgets}`.

### Layer rules

**Domain (`features/*/domain/`, plus `core/error`, `core/usecase`, `core/utils`)**
- Pure Dart only. No `package:flutter/...`, no `flutter_bloc`, `get_it`, `http`, `intl`, JSON
  annotations or any other third-party package.
- Entities are immutable (`final` fields, `const` constructors) and hold no JSON logic. Value objects
  implement `==`/`hashCode` by hand (no `equatable`); large aggregates (`TripRequest`, `Booking`)
  compare by identity.
- Repository interfaces are `abstract interface class` and return `Future<Result<T>>` — `Ok(value)` or
  `Err(failure)` — and never throw.
- One use case per action with a single `call(...)`; related use cases may share a file. Business
  rules (validation, stage derivation, payment sequencing) live here and are unit-tested.

**Data (`features/*/data/`)**
- Remote data sources call the API only through `ApiClient` (never `http` directly). It attaches the
  bearer token from `AccessTokenProvider`, retries once after a single-flight refresh on a 401, and
  maps errors (`{message}` or `{error:{message}}`) to `AppException`s.
- Data sources **throw** `AppException`s; wrap parsing in `parseResponse(...)` so malformed payloads
  become `ServerException`. Repository methods are usually `guard(() => ...)`.
- Read-only payloads are parsed with `JsonReader` into entities by parser classes in `data/models/`
  (e.g. `TripJson`), which also build request bodies. Entities never see JSON.

**Presentation (`features/*/presentation/`)**
- State management: `flutter_bloc` (Bloc for event-driven flows, Cubit for simple state).
- Blocs/Cubits depend on **use cases only**, never on repositories or data sources.
- States are immutable; prefer a `sealed class` hierarchy and exhaustive `switch` in widgets.
- Widgets contain no business logic; pages obtain their Bloc via `BlocProvider(create: (_) => sl<...>())`.
- Build screens from `core/theme` tokens and `core/widgets` — never hard-code colours or font families.
  Icons come from `material_symbols_icons` (`Symbols.xxx_rounded`). Success/info feedback uses
  `showAppToast`; destructive or multi-step actions use bottom sheets.
- `AuthBloc` is provided once in `app.dart`; the router redirects on it. Pages that need the signed-in
  user get it as a constructor argument from the router.

**Cross-feature:** a feature may import another feature's `domain/` only — never its `data/` or
`presentation/`. Navigate with `AppRoutes` paths (`context.push(AppRoutes.trip(id))`), never by
importing another feature's page.

**Composition roots:** `core/di/`, `core/router/app_router.dart` and `app.dart` wire features together,
so they are the only places outside a feature allowed to import that feature's `data/` or
`presentation/`.

**Dependency injection:** register everything in `core/di/` with `get_it` (`sl`). Data sources,
repositories and use cases are lazy singletons; Blocs/Cubits are factories. Only `core/di`, `app.dart`
and pages (inside `BlocProvider.create`) may touch `sl`.

**Enforced:** `test/architecture_test.dart` fails if domain (or the pure core folders) imports anything
but `dart:` and other pure files, if presentation and data import each other, or if a feature reaches
into another feature's non-domain layers.

### Adding a feature — order of work

1. Domain: entity → repository interface → use case(s) (+ unit tests).
2. Data: parser/model (+ JSON tests) → data source(s) → repository impl.
3. Presentation: Bloc/Cubit (+ bloc tests against fakes) → page/widgets (+ widget tests).
4. Register in `core/di/`, add the route in `core/router/`, run `flutter analyze` and `flutter test`.

## Testing

- `test/` mirrors `lib/`. Use **hand-written fakes** that implement repository interfaces (see
  `test/helpers/fakes.dart`, `test/features/trips/trips_fakes.dart`) and run the real use cases on top —
  no mockito/codegen. Blocs/Cubits with `bloc_test`; `ApiClient` with `package:http/testing.dart`.
- Widget tests pump a page's inner view with its Cubit provided directly (not via `sl`).

## Agent skills (`.claude/skills/`)

Official Flutter/Dart skills, vendored — see `.claude/skills/README.md` for sources and what was left out.
Apply them **inside** the architecture above:

- `flutter-use-http-package`, `flutter-implement-json-serialization` → only in `data/`.
- `flutter-setup-declarative-routing` → `core/router/`.
- `flutter-add-widget-test`, `dart-add-unit-test`, `flutter-add-integration-test`,
  `dart-collect-coverage` → testing (`dart-generate-test-mocks` is superseded by the fakes rule).
- `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-add-widget-preview` → UI.
- `dart-run-static-analysis`, `dart-fix-runtime-errors`, `dart-resolve-package-conflicts`,
  `dart-use-pattern-matching`, `dart-write-documentation` → general.

## Rules

### Proactive hot reload (from flutter/agent-plugins `rules/flutter-hot-reload.md`)

Whenever you edit a `.dart` file under `lib/`:

1. **Skip** for files outside `lib/` (`test/`, `integration_test/`, …) and for comment/whitespace-only edits.
2. **Discover & connect** to running app instances with the Dart MCP server (`dtd` / `list_running_apps`).
3. Run `hot_reload` after changes to widgets (including `build` methods) or simple methods; run
   `hot_restart` after changes to `initState`, global/static state, DI registration or `main()`.

### General

- Before reporting a task done: `dart format lib test`, `flutter analyze` with no issues,
  `flutter test` passing.
- Don't add a package without saying why; keep the domain layer dependency-free.
