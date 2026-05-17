# AGENTS.md
Adaptive Ground Control is a Qt6/QML application that use KDDockWidgets.

## Build System
- **To Lint/Build/Run**: This project use Just (justfile) as command runner. Always use the `just` to build, fromat, and lint. 
- **Package Manager**: Git submodules for third_party dependencies

## Development Workflow
1. Make changes to source files
2. Run `just format` to auto-format code
3. Run `just lint` to check for linting issues
4. Run `just build` to compile
5. Run `just run` to test
> NOTE: DO NOT use cmake/lint/format/etc directly, always use just.

## Code Style
- **C++**: Google style with 4-space tabs (just format)
- **QML**: Qt conventions (just format)
- **Linting**: cppcoreguidelines, google, modernize, performance checks (just lint)

## Dependencies
- Qt6 (Quick, QuickControls2, etc.)
- KDDockWidgets-qt6 (In third_party)
- QMapLibre (Expected to be installed)
