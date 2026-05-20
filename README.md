# test_sentry

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Sentry

Sentry is initialised in [`lib/main.dart`](lib/main.dart) using the
`SENTRY_DSN` and `APP_ENV` values from `env-<flavor>.json` (passed via
`--dart-define-from-file`). The home page has a **Throw test exception**
button that sends a captured `StateError` to Sentry — use it to confirm the
DSN is wired correctly for each flavor.

### Symbol & source upload

Builds are **not obfuscated**, so Dart stack traces are already readable
in Sentry without uploading a symbol map.
[`sentry_dart_plugin`](https://docs.sentry.io/platforms/dart/guides/flutter/debug-symbols/dart-plugin/)
is still run after each build to upload **sources** (source context in
stack frames) and any **native debug symbols** the Flutter Android build
produced. Configuration lives under the `sentry:` block in `pubspec.yaml`.

Locally:

```sh
flutter build apk --release --flavor prod --dart-define-from-file=env-prod.json
SENTRY_AUTH_TOKEN=... dart run sentry_dart_plugin
```

CI does both steps automatically in each Android workflow.

## Releasing the application

Builds are produced by [Codemagic](https://codemagic.io) using `codemagic.yaml`
at the repo root.

### Flavors

The CI assumes four Flutter flavors — `dev`, `staging`, `preprod`, `prod` —
plus a `store` Android variant for the Play Store AAB. Each flavor has a
matching `env-<flavor>.json` at the repo root.

> Flavor configuration in `android/app/build.gradle.kts` is **not** wired up
> yet. Add `productFlavors` matching the names above before running the CI
> workflows.

### Workflows

- `build_android_dev` — builds an APK on every push (manual trigger)
- `build_android_{staging,preprod,prod}` — tag-triggered APK
- `build_android_store_prod` — tag-triggered AAB for the Play Store

Each workflow uploads sources + native symbols to Sentry after the build.
APKs/AABs are published as Codemagic build artifacts.

Tag pattern: `test_sentry-v*` (configurable in `codemagic.yaml`).

### Required Codemagic credentials

Configure these groups in the Codemagic UI before running the workflows:

- `keystore_reference` — Android upload keystore (alias, password, key)
- `sentry_group` — `SENTRY_AUTH_TOKEN` (auth token with `project:releases`
  scope). Optionally `SENTRY_ORG` / `SENTRY_PROJECT` if you prefer
  overriding `pubspec.yaml`.
