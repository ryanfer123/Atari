# Atari

Atari is organized as a maintainable, technology-neutral project repository. The
current structure separates product code, tests, documentation, configuration,
automation, and static assets so each area has a clear owner and purpose.

## Repository structure

```text
Atari/
├── .github/        GitHub collaboration templates
├── assets/         Static project assets
├── config/         Version-controlled configuration
├── docs/           Architecture and development documentation
├── scripts/        Development, build, and release automation
├── src/            Application and library source code
├── tests/          Automated tests and test support files
├── .editorconfig   Shared editor defaults
├── .gitignore      Files intentionally excluded from Git
├── CONTRIBUTING.md Contribution workflow
└── README.md       Project overview
```

## Getting started

The implementation stack has not been committed yet. Once it is selected:

1. Add its dependency manifest and lockfile at the repository root.
2. Organize implementation code by feature inside `src/`.
3. Mirror important source boundaries in `tests/`.
4. Put repeatable developer commands in `scripts/`.
5. Record setup instructions and architectural decisions in `docs/`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the working conventions.

