# WealthLens

[![Built with Claude Code](https://img.shields.io/badge/built%20with-Claude%20Code-D97757?logo=anthropic&logoColor=white)](https://claude.com/claude-code)
[![Flutter](https://img.shields.io/badge/Flutter-iOS%20%2B%20Android-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

A **task-driven** personal-finance app — iOS and Android from a single Flutter codebase.

Instead of logging every expense, WealthLens turns money management into a short list
of monthly tasks: open it, see where you stand, do this month's tasks, move toward your
goals. It **advises — it never moves real money**, so the allocation engine is fully
unit-tested and trustworthy on its own. Honest, never judgmental: no shaming, no nagging
notifications.

## Tech

- **Flutter** — one codebase, iOS + Android
- **Drift** — local SQLite persistence
- **Riverpod** — state management
- Pure-Dart domain layer (enforced by a small custom lint)

## Build & run

```bash
flutter pub get
flutter run
```

Clone it, build it, make it your own.

---

Built solo — product, design system, and implementation by one engineer, paired with
[**Claude Code**](https://claude.com/claude-code), Anthropic's agentic coding tool.
