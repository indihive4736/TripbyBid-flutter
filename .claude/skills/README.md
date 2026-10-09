# Vendored agent skills

Copied from the official repositories linked at https://docs.flutter.dev/ai/get-started
(fetched 2026-10-10). Each skill keeps its upstream licence (BSD-3-Clause, see `LICENSE-*`).

| Source | Commit | Skills |
|---|---|---|
| https://github.com/flutter/agent-plugins | `0ef3972` | `flutter-*` |
| https://github.com/dart-lang/skills | `0d9f1c4` | `dart-*` |

## Deliberately not vendored

| Skill | Why |
|---|---|
| `flutter-apply-architecture-best-practices` | Prescribes MVVM + `lib/data`/`lib/ui` by-type layout, which conflicts with this repo's feature-first Clean Architecture (see `CLAUDE.md`). |
| `dart-use-primary-constructors` | Needs Dart ≥ 3.12; the SDK here is 3.9.2. |
| `dart-build-cli-app`, `dart-setup-ffi-assets`, `dart-use-ffigen`, `dart-use-path-package`, `dart-use-doc-examples`, `dart-migrate-to-checks-package` | Not relevant to a Flutter app (CLI tools, native FFI, package docs). |

## Updating

```bash
git clone --depth 1 https://github.com/flutter/agent-plugins
git clone --depth 1 https://github.com/dart-lang/skills
# copy the skill folders listed above over the ones here, then update the commit column
```
