# AGENTS.md

Exercism exercise solutions across 4 language tracks: C, Python, R, x86-64 Assembly.

## Repo structure

- **Root-level track dirs** (`r/`, `x86-64-assembly/`, `python/`, `c/`) — working copies downloaded via `exercism download`. Include tests, scaffolding, `.exercism/` metadata.
- **`solutions/`** — archived submitted solution files only, organized as `solutions/{language}/{exercise}/{iteration}/`. Do not edit; this is archival.

## Submission workflow

Run from inside a root-level exercise dir:
- Bash: `./exercise`
- PowerShell: `. .\exercise.ps1; Exercise`

Both call `exercism submit`, `git add .`, `git commit`, `git push`. Commit message format: `{track}/{exercise}: add {solution|iteration}`.

The script auto-detects "iteration" (existing exercise with tracked README.md) vs "solution" (new exercise).

## Per-language build/test

- **x86-64 Assembly**: `make` in exercise dir. Uses NASM assembler + C test harness (Unity framework in `vendor/`). Build artifacts: `tests` binary, `.o` files (all gitignored).
- **R**: `Rscript test_{exercise}.R` in exercise dir. Uses `testthat` library.
- **C / Python**: No test harness in this repo. Tests run via `exercism test` (requires exercism CLI configured for the track).

## No repo-wide tooling

There is no CI, linter, formatter, typecheck, or shared test runner. Each exercise is self-contained within its directory.

## Do not touch

- `.exercism/` — Exercism CLI metadata (gitignored, but present in working dirs)
- `vendor/` — Unity test framework for x86-64 Assembly (vendored, do not modify)
- `tests` binary, `.o` files — build artifacts (gitignored)
