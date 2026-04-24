# TASKS - block_forge

## Baseline
- [x] Project boots headless and unit tests are wired.


## Fun Scale Excellence Plan (2026-02-27)
- [x] Baseline fun-scale gap audit completed (points 1-9).
- [x] [P1] Add explicit objective copy in HUD/onboarding and clear fail/win conditions visible during play.
- [x] [P1] Add a fair challenge curve with adaptive ramp guardrails and tests against difficulty spikes.
- [x] [P2] Add social/emotional hook: leaderboard season, async challenge card, or shareable rival target.

<!-- BEGIN CODEX REVIEW 2026-04-24 -->

## Automated Review - 2026-04-24

Review commands used:
- `audit_repo.ps1 -TargetRepo <game>`
- `verify_repo.ps1 -TargetRepo <game> -Suite unit -GodotBin C:\code\bin\godot.exe`
- `verify-visual-smoke.ps1 -TargetRepo <game> -GodotBin C:\code\bin\godot.exe`

Current state:
- [x] Unit verification is clean via `verify_repo.ps1 -Suite unit` (files=3 tests=9 failures=0).
- [x] 180-frame visual smoke is clean via `generic_playthrough`.
- [x] Required ArcadeCore autoload and display contracts are satisfied.
- [x] ArcadeCore addon drift is reconciled against the canonical `ArcadeCore` source.
- [ ] Adopt premium ArcadeCore UI primitives and update menu/HUD/results screens to use them.

Completed in this pass:
- [x] Hardened shared `run-tests.ps1` so compile/parse errors and nonzero Godot exits fail honestly.
- [x] Updated shared `TestRunner.gd` to register ordered project autoloads, support Node-based tests, handle gdUnit suites, dispose gdUnit runtime state, and avoid duplicate existing autoloads.
- [x] Added shared generic scenario-driver visual smoke coverage where no product-specific scenario existed.
- [x] Hardened `verify-visual-smoke.ps1` so script/parse/compile errors fail classification.
- [x] Fixed strict typing in `BlockForgeGame.gd` exposed by visual smoke.
- [x] Re-ran the full 22-game unit and visual-smoke verification sweeps after fixes.

Next implementation tasks:
- [ ] Do a product-specific polish pass: menu/game HUD/results, input feel, and mobile layout.
- [ ] Investigate remaining Godot shutdown RID/resource leak warnings from visual-smoke runs where present.
- [ ] Re-run unit and visual-smoke verification after each fix and update this section with the result.

<!-- END CODEX REVIEW 2026-04-24 -->



