# Contributing

This repository is a portfolio project. Small, focused pull requests are welcome.

## Before you open a pull request

1. Fork the repository and create a branch from `main`.
2. Keep the change limited to one behavior or one bug.
3. Run the same checks as CI:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

4. Update the README if setup, architecture, or limitations change.
5. Do not add API keys, keystores, or machine-local paths.

## Commit messages

Use a short conventional prefix: `feat`, `fix`, `docs`, `test`, or `refactor`.

Example: `fix: keep the ledger when a save fails`
