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
flutter run                                  # run on a connected device / emulator
flutter analyze                              # must be clean before a task is done
dart format .
dart fix --apply                             # mechanical lint fixes
flutter test                                 # unit + widget tests
flutter test integration_test                # integration tests
dart run build_runner build -d               # code generation (mocks, etc.)
```

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
  ├── main.dart
  ├── core/                            # shared across features
  │     ├── di/                        # get_it service locator setup (injection_container.dart)
  │     ├── error/                     # Failure (pure Dart), exceptions thrown by data sources
  │     ├── usecase/                   # UseCase<Type, Params> base (pure Dart)
  │     ├── network/                   # API client, auth-token interceptor, connectivity
  │     ├── router/                    # app routes
  │     ├── theme/
  │     └── utils/
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
                    ├── bloc/              auth_bloc.dart, auth_event.dart, auth_state.dart
                    ├── pages/             login_page.dart
                    └── widgets/           feature-private widgets
test/                                  # mirrors lib/ exactly
```

### Layer rules

**Domain (`features/*/domain/`, plus `core/error` and `core/usecase`)**
- Pure Dart only. No `package:flutter/...`, no `flutter_bloc`, `get_it`, `http`, `dio`, JSON
  annotations or any other third-party package. If an import isn't `dart:` or another pure-Dart
  domain/core file, it doesn't belong here.
- Entities are immutable (`final` fields, `const` constructors) and hold no JSON logic.
- Repository interfaces are `abstract interface class` and return `Future<Result<T>>` (a sealed
  `Success`/`Failure` type in `core/error`), never throw.
- One use case per action, with a single `call(...)` method that depends only on repository interfaces.

**Data (`features/*/data/`)**
- Data sources do the I/O (HTTP to the NestJS API, local storage) and **throw** exceptions from
  `core/error` (`ServerException`, `CacheException`, …).
- Models are DTOs that own `fromJson`/`toJson` and map explicitly with `toEntity()` / `fromEntity()`.
  Entities never leak JSON.
- Repository implementations implement the domain interface, call data sources, catch exceptions and
  convert them into `Failure`s.

**Presentation (`features/*/presentation/`)**
- State management: `flutter_bloc` (Bloc for event-driven flows, Cubit for simple state).
- Blocs/Cubits depend on **use cases only**, never on repositories or data sources.
- States are immutable; prefer a `sealed class` hierarchy and exhaustive `switch` in widgets.
- Widgets contain no business logic; pages obtain their Bloc via `BlocProvider(create: (_) => sl<...>())`.

**Cross-feature:** a feature may import another feature's `domain/` only — never its `data/` or
`presentation/`. Anything needed more widely moves to `core/`.

**Dependency injection:** register everything in `core/di/` with `get_it` (`sl`). Data sources,
repositories and use cases are lazy singletons; Blocs are factories. Only `core/di`, `main.dart` and
pages (via `BlocProvider`) may touch `sl`.

### Adding a feature — order of work

1. Domain: entity → repository interface → use case(s) (+ unit tests).
2. Data: model (+ JSON tests) → data source(s) → repository impl (+ tests with mocked data sources).
3. Presentation: Bloc/Cubit (+ bloc tests with mocked use cases) → page/widgets (+ widget tests).
4. Register in `core/di/`, add the route, run `flutter analyze` and `flutter test`.

## Testing

- `test/` mirrors `lib/` file for file (`login_usecase.dart` → `login_usecase_test.dart`).
- Mock collaborators with `mockito` + `build_runner` (see the `dart-generate-test-mocks` skill);
  test each layer against mocks of the layer beneath it.

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
