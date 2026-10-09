# CLAUDE.md

Guidance for Claude Code and human contributors. **This directory (`tripbybid-flutter/`) is the repo root.**

## Project overview

**TripByBid** is a reverse-auction travel marketplace: a traveler posts one request (flight, train, bus
or hotel), verified travel agents bid on it, the traveler picks a bid and pays, then chats with the agent
until the trip. This repo is the **Flutter mobile client**.

Sibling projects (read-only references — never edit them from here):

- `../tripbybid` — NestJS API (Prisma on Supabase Postgres). It owns all data access. The API contract
  is in `../tripbybid/FRONTEND_API_DOCS.md`; realtime (Ably) in `../tripbybid/ABLY_INTEGRATION.md`.
- `../tripbybid-frontend` — Next.js web client. Use it as the reference for user flows and screens,
  e.g. `../tripbybid-frontend/AUTH_FLOW_DOCUMENTATION.md`.

The app talks only to the NestJS API. Never query Supabase tables directly from Flutter.

## Toolchain

- Flutter 3.35.5 (stable) / Dart 3.9.2
- Dart & Flutter MCP server configured in `.mcp.json` (`dart mcp-server`)

## Commands

```bash
flutter pub get
dart run build_runner build -d               # generate test mocks (test/helpers/mocks.mocks.dart)
flutter analyze                              # must be clean before a task is done
dart format lib test
dart fix --apply                             # mechanical lint fixes
flutter test                                 # unit, bloc, widget and architecture tests
flutter test integration_test                # integration tests

# Run against the local backend (`npm run start:dev` in ../tripbybid, port 3001)
flutter run                                                        # iOS simulator: localhost works
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api    # Android emulator
```

`API_BASE_URL` (see `lib/core/config/app_config.dart`) must include the `/api` prefix. Plain HTTP is
allowed only in Android debug builds and for local networking on iOS.

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
  ├── main.dart                        # configureDependencies() + runApp
  ├── app.dart                         # MaterialApp.router, app-wide AuthBloc
  ├── core/                            # shared across features
  │     ├── config/                    # AppConfig (--dart-define values)
  │     ├── di/                        # get_it setup: injection_container.dart (`sl`)
  │     ├── error/                     # Failure, Result (Ok/Err) — pure Dart; AppException (data layer)
  │     ├── usecase/                   # UseCase<T, Params>, NoParams — pure Dart
  │     ├── network/                   # ApiClient (bearer + token refresh), TokenStorage, AuthTokens
  │     ├── router/                    # go_router routes + auth redirects
  │     └── theme/
  └── features/
        └── <feature>/                 # e.g. auth, booking_requests, bids, bookings, chat, profile
              ├── domain/
              │     ├── entities/          user.dart
              │     ├── repositories/      auth_repository.dart          (abstract interface)
              │     └── usecases/          login_usecase.dart
              ├── data/
              │     ├── datasources/       auth_remote_data_source.dart, auth_local_data_source.dart
              │     ├── models/            user_model.dart               (DTO + JSON)
              │     └── repositories/      auth_repository_impl.dart
              └── presentation/
                    ├── bloc/              auth_bloc.dart (+ part auth_event/auth_state), login_cubit.dart
                    ├── pages/             login_page.dart, splash_page.dart
                    └── widgets/           feature-private widgets (login_form.dart)
test/                                  # mirrors lib/; shared mocks + fixtures in test/helpers/
```

`features/auth` is the reference implementation — copy its shape for new features. `features/home` is a
placeholder landing page.

### Layer rules

**Domain (`features/*/domain/`, plus `core/error` and `core/usecase`)**
- Pure Dart only. No `package:flutter/...`, no `flutter_bloc`, `get_it`, `http`, `dio`, JSON
  annotations or any other third-party package. If an import isn't `dart:` or another pure-Dart
  domain/core file, it doesn't belong here.
- Entities are immutable (`final` fields, `const` constructors) and hold no JSON logic.
- Repository interfaces are `abstract interface class` and return `Future<Result<T>>` — `Ok(value)` or
  `Err(failure)` from `core/error/result.dart` — and never throw.
- Domain classes implement `==`/`hashCode` by hand (no `equatable` here).
- One use case per action, with a single `call(...)` method that depends only on repository interfaces.

**Data (`features/*/data/`)**
- Remote data sources call the API only through `ApiClient` (never `http` directly). It attaches the
  bearer token, refreshes it before expiry and once on a 401, and maps errors to `AppException`s.
  Refresh is single-flight on purpose: the backend revokes the whole session when a refresh token is
  reused. Pass `authenticated: false` for public endpoints.
- Data sources **throw** `AppException`s (`ServerException`, `NetworkException`,
  `UnauthorizedException`, `CacheException`).
- Models are DTOs that own `fromJson`/`toJson` (parse with Dart 3 map patterns; throw
  `FormatException` on bad payloads) and map explicitly with `toEntity()`. Entities never see JSON.
- Repository implementations implement the domain interface, call data sources, and convert caught
  `AppException`s with `e.toFailure()`.

**Presentation (`features/*/presentation/`)**
- State management: `flutter_bloc` (Bloc for event-driven flows, Cubit for simple state).
- Blocs/Cubits depend on **use cases only**, never on repositories or data sources.
- States are immutable; prefer a `sealed class` hierarchy and exhaustive `switch` in widgets.
- Widgets contain no business logic; pages obtain their Bloc via `BlocProvider(create: (_) => sl<...>())`.

- `AuthBloc` (session status: `AuthUnknown` / `Authenticated` / `Unauthenticated`) is provided once
  in `app.dart`; the router redirects on it. Form submission state lives in page-scoped Cubits such
  as `LoginCubit`.

**Cross-feature:** a feature may import another feature's `domain/` only — never its `data/` or
`presentation/`. Anything needed more widely moves to `core/`. When a page needs something from
another feature's presentation (e.g. the signed-in user, a logout callback), the router passes it in
as constructor arguments — see `HomePage`.

**Composition roots:** `core/di/`, `core/router/` and `app.dart` wire features together, so they are
the only places outside a feature allowed to import that feature's `data/` or `presentation/`.

**Dependency injection:** register everything in `core/di/` with `get_it` (`sl`). Data sources,
repositories and use cases are lazy singletons; Blocs/Cubits are factories. Only `core/di`, `app.dart`
and pages (inside `BlocProvider.create`) may touch `sl`.

**Enforced:** `test/architecture_test.dart` fails if domain (or `core/error`, `core/usecase`) imports
anything but `dart:` and other pure files, if presentation and data import each other, or if a feature
reaches into another feature's non-domain layers.

### Adding a feature — order of work

1. Domain: entity → repository interface → use case(s) (+ unit tests).
2. Data: model (+ JSON tests) → data source(s) → repository impl (+ tests with mocked data sources).
3. Presentation: Bloc/Cubit (+ bloc tests with mocked use cases) → page/widgets (+ widget tests).
4. Register in `core/di/`, add the route, run `flutter analyze` and `flutter test`.

## Testing

- `test/` mirrors `lib/` file for file (`login_usecase.dart` → `login_usecase_test.dart`).
- Mock collaborators with `mockito` + `build_runner` (see the `dart-generate-test-mocks` skill): add a
  `MockSpec` to `test/helpers/mocks.dart`, rerun `build_runner`, and call `setUpAll(provideResultDummies)`
  in tests that stub methods returning `Result` (mockito cannot fake a sealed type — add new
  `provideDummy<Result<X>>` lines there as needed). Shared fixtures live in `test/helpers/fixtures.dart`.
- Test each layer against mocks of the layer beneath it; Blocs/Cubits with `bloc_test`; `ApiClient`
  with `package:http/testing.dart`'s `MockClient`.

## Agent skills (`.claude/skills/`)

Official Flutter/Dart skills, vendored — see `.claude/skills/README.md` for sources and what was left out.
Apply them **inside** the architecture above:

- `flutter-use-http-package`, `flutter-implement-json-serialization` → only in `data/datasources` and
  `data/models`.
- `flutter-setup-declarative-routing` → `core/router/`.
- `flutter-add-widget-test`, `dart-add-unit-test`, `dart-generate-test-mocks`,
  `flutter-add-integration-test`, `dart-collect-coverage` → testing.
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

- Before reporting a task done: `dart format .`, `flutter analyze` with no issues, `flutter test` passing.
- Don't add a package without saying why; keep the domain layer dependency-free.
