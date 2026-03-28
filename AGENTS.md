# AGENTS.md

## Project Overview

GroundControl is a Qt6/QML application using KDDockWidgets for dockable panels.

## Build System

- **Build Tool**: CMake with Ninja
- **Task Runner**: Just (justfile)
- **Package Manager**: Git submodules for third_party dependencies

## Commands

```bash
# Build dependencies (KDDockWidgets)
just build-dependencies

# Build project
just build

# Run application
just run

# Format code
just format

# Lint code
just lint

# Clean build
just clean
```

## Code Style

- **C++**: Google style with 4-space tabs (configured in .clang-format)
- **QML**: Qt conventions (use qmlformat)
- **Linting**: clang-tidy with cppcoreguidelines, google, modernize, performance checks

## Project Structure

```
.
├── main.cpp              # Application entry point
├── CMakeLists.txt        # CMake configuration
├── Justfile             # Task definitions
├── src/                 # QML source files
│   ├── Main.qml
│   ├── LeftPanel.qml
│   ├── RightPanel.qml
│   └── BottomPanel.qml
├── third_party/         # Git submodules
│   └── KDDockWidgets/
└── build/               # Build output (gitignored)
```

## Dependencies

- Qt6 (Quick, QuickControls2)
- KDDockWidgets-qt6

## Development Workflow

1. Make changes to source files
2. Run `just format` to auto-format code
3. Run `just lint` to check for issues
4. Run `just build` to compile
5. Run `just run` to test
