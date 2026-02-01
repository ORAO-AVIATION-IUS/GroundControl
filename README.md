# Ground Control

Qt6 QML docking application with KDDockWidgets.

## Quick Start

```bash
git clone --recursive <repo-url>     # Clone with submodules
cd GroundControl
just build-dependencies              # Build KDDockWidgets library
just build                           # Build project
just run                             # Run application
```

## Requirements

- Qt 6.2+
- CMake 3.15+
- Ninja
- C++17 compiler
- Just (`cargo install just`)
- clang-format (formatting)
- clang-tidy (linting)
- **Windows**: PowerShell (required for `just format`)

## All Commands

Run `just --list` to see all available commands.

### Build

```bash
just build-dependencies    # Build KDDockWidgets dependency library
just build                 # Build the project using CMake + Ninja
```

### Run

```bash
just run [BACKEND]         # Run application (BACKEND: xcb|wayland, Unix only)
```

On Unix: Omit BACKEND for default (xcb), or specify `xcb` or `wayland`.
On Windows: BACKEND parameter is ignored (uses native backend).

### Code Quality

```bash
just format [FILE]         # Format C++/QML files (all or specific file, PowerShell on Windows)
just lint [FILE]           # Run clang-tidy/qmllint (all files or specific file)
```

### Clean

```bash
just clean [TARGET]        # Clean build dir, LSP files, or all (TARGET: build|lsp|all, default: all)
```

## Platform Notes

### Unix (Linux/macOS)

Backend selection via `just run [xcb|wayland]`:
- **XCB (default)**: X11 via XWayland. Best docking support.
- **Wayland**: Native protocol. May have dual title bars/docking issues.

### Windows

- `just run` executes natively (no backend parameter)
- `just format` requires PowerShell for file globbing
- All other commands work identically to Unix

## LSP Support

CMake generates `compile_commands.json` for LSP clients. Use `just clean lsp` to remove.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit message guidelines.

## License

KDDockWidgets: GPL 2.0 or GPL 3.0. Contact KDAB for commercial licensing.
