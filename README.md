# Ground Control

Qt6 QML docking application with KDDockWidgets.

## Quick Start

```bash
git clone --recursive <repo-url>     # Clone with submodules
cd GroundControl
just configure                       # Configure once after cloning
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
- GStreamer 1.x
- **Windows**: PowerShell (required for `just format`)

### GStreamer

GStreamer is required for camera/video streaming support.

| Platform | Install |
|---|---|
| **Linux (Debian/Ubuntu)** | `sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-tools` |
| **Linux (Fedora)** | `sudo dnf install gstreamer1-devel gstreamer1-plugins-base-devel gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-libav gstreamer1-tools` |
| **macOS** | `brew install gstreamer` |
| **Windows** | Download from [GStreamer downloads](https://gstreamer.freedesktop.org/download/) — install both runtime and dev packages. Set `GSTREAMER_ROOT_X86_64` env var to the install path (e.g. `C:\gstreamer\1.0\mingw_x86_64`). |

Runtime plugins are also needed for stream decoding: `gst-plugins-good` (RTSP), `gst-plugins-bad` (hardware decode), `gst-libav` (H.264/H.265).

## All Commands

Run `just --list` to see all available commands.

### Build

```bash
just configure             # Configure once after cloning or cleaning
just build                 # Incrementally build the project using CMake + Ninja
```

### Object Detection Setup

`just setup` is only needed to set up the Python object-detection feature. It creates the `uv` environment, downloads the YOLO model, configures the project, and builds it.

```bash
just setup
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

Copyright © 2026 Adaptive Ground Control System (AGCS) contributors.

GroundControl is licensed under the [GNU Affero General Public License version 3](LICENSE) (`AGPL-3.0-only`).

Third-party components remain under their respective licenses. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and the [`LICENSES`](LICENSES) directory.
