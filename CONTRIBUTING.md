# Contributing to Atari

## Development workflow

1. Create a focused branch from the default branch.
2. Keep changes small enough to review and test independently.
3. Add or update tests for behavior changes.
4. Update documentation when setup, behavior, or architecture changes.
5. Open a pull request describing what changed and how it was verified.

Suggested branch prefixes:

- `feat/` for new capabilities
- `fix/` for bug fixes
- `docs/` for documentation
- `test/` for test-only changes
- `chore/` for maintenance and tooling

## Code organization

- Group `src/` code by product feature or domain once the implementation begins.
- Keep shared code intentionally small and name it by responsibility.
- Place configuration in `config/`; do not commit credentials or local secrets.
- Make scripts safe to run repeatedly and document their inputs.
- Keep tests deterministic and independent of developer-specific state.

## Commit and pull request guidance

Use short, imperative commit subjects, for example:

```text
Add session validation
Fix duplicate device registration
Document local development setup
```

Before requesting review, confirm that formatting, static checks, and automated
tests pass for the selected implementation stack.

