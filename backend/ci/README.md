# CI Stack

This stack is used by both local desktop smoke testing and pull request CI.

## Services

- `terapixel-platform`: mock Terapixel platform API backed by SQLite.
- `cockroachdb`: database for Nakama.
- `nakama`: game backend server configured for local CI use.
- `godot-smoke`: headless Godot import + scene load smoke runner.

## Shared command

Run from repo root:

```powershell
./scripts/run-stack-tests.ps1 -Action test
```

On Windows desktops with restricted execution policy, use:

```powershell
./scripts/run-stack-tests.cmd -Action test
```

Useful flags:

- `-Action up` to leave platform, database, and Nakama running.
- `-Action down` to tear everything down.
- `-KeepRunning` with `-Action test` to keep services alive after smoke tests.
