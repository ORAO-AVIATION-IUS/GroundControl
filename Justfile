set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
qmlformat6 := if os() == "linux" { "/usr/lib/qt6/bin/qmlformat" } else { "qmlformat" }

# Configure cmake (run once after clean or when adding dependencies)
[unix]
configure:
    CC=clang CXX=clang++ cmake -B build -S . -G Ninja

# Configure cmake
[windows]
configure:
    cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Build project (incremental — fast for code changes)
[unix]
build:
    cmake --build build

# Build project
[windows]
build:
    cmake --build build

# Rebuild the committed QMapLibre prebuilt under third_party/maplibre-prebuilt/macos.
# The prebuilt artifacts are committed; only run this when the upstream version needs updating.
[macos]
bootstrap-maplibre:
    #!/usr/bin/env bash
    set -euo pipefail
    repo="third_party/maplibre-native-qt"
    out="$PWD/third_party/maplibre-prebuilt/macos"
    if [ ! -d "$repo" ]; then
        git clone --depth 1 --recurse-submodules --shallow-submodules \
            https://github.com/maplibre/maplibre-native-qt.git "$repo"
    fi
    qt-cmake -S "$repo" -B "$repo/build" -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.19 \
        -DMLN_WITH_METAL=ON \
        -DMLN_QT_WITH_RENDERER_DEBUGGING=OFF \
        -DCMAKE_INSTALL_PREFIX="$out"
    cmake --build "$repo/build"
    rm -rf "$out"
    cmake --install "$repo/build"

# Rebuild the committed Ubuntu/Debian QMapLibre prebuilt under
# third_party/maplibre-prebuilt/linux-ubuntu (Qt 6.10.x, glibc 2.35 / Ubuntu 22.04,
# bundled ICU). Build it on the oldest supported Ubuntu so it runs on newer ones.
# Needs CMAKE_PREFIX_PATH pointing at the Qt 6.10 install (e.g. ~/Qt/6.10.3/gcc_64).
[linux]
bootstrap-maplibre:
    #!/usr/bin/env bash
    set -euo pipefail
    repo="third_party/maplibre-native-qt"
    rev="399311ee6389c32240cc8bcaae7ad751749de1bb"
    out="$PWD/third_party/maplibre-prebuilt/linux-ubuntu"
    if [ ! -d "$repo" ]; then
        git init -q "$repo"
        git -C "$repo" fetch --depth 1 https://github.com/maplibre/maplibre-native-qt.git "$rev"
        git -C "$repo" checkout -q FETCH_HEAD
        git -C "$repo" submodule update --init --recursive --depth 1
    fi
    cmake -S "$repo" -B "$repo/build" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.19 \
        -DMLN_WITH_OPENGL=ON \
        -DMLN_QT_WITH_INTERNAL_ICU=ON \
        -DMLN_QT_WITH_RENDERER_DEBUGGING=OFF \
        -DQT_NO_PRIVATE_MODULE_WARNING=ON \
        -DCMAKE_INSTALL_PREFIX="$out"
    cmake --build "$repo/build"
    rm -rf "$out"
    cmake --install "$repo/build"

# Run (paths to the QMapLibre prebuilt and Qt come from build/runtime-env.sh)
[linux]
run BACKEND="xcb":
    cd build && \
    . ./runtime-env.sh && \
    QT_QPA_PLATFORM={{BACKEND}} \
    ./GroundControl

[macos]
run:
    QT_PLUGIN_PATH="$PWD/third_party/maplibre-prebuilt/macos/plugins" \
    QML_IMPORT_PATH="$PWD/third_party/maplibre-prebuilt/macos/qml" \
    ./build/GroundControl

[windows]
run:
    Copy-Item -Force "{{justfile_directory()}}\third_party\maplibre-prebuilt\windows\bin\*.dll" "{{justfile_directory()}}\build\"; $env:QT_PLUGIN_PATH = "{{justfile_directory()}}\third_party\maplibre-prebuilt\windows\plugins"; $env:QML_IMPORT_PATH = "{{justfile_directory()}}\third_party\maplibre-prebuilt\windows\qml"; .\build\GroundControl.exe

# Format code using clang-format and qmlformat
[unix]
format:
	find src/ -path '*/.venv' -prune -o \( -name '*.cpp' -o -name '*.h' \) -exec clang-format -i -style=file {} \;
	find src/ -path '*/.venv' -prune -o -name '*.qml' -exec {{qmlformat6}} -i {} \;

# Format code using clang-format and qmlformat
[windows]
format:
	Get-ChildItem -Path 'src' -Recurse -Filter '*.qml' | Where-Object { $_.FullName -notmatch '\\.venv\\' } | ForEach-Object { qmlformat -i $_.FullName }
	Get-ChildItem -Path 'src\*' -Recurse -Include '*.cpp','*.h' | Where-Object { $_.FullName -notmatch '\\.venv\\' } | ForEach-Object { clang-format -i -style=file $_.FullName }

# Lint code using clang-tidy and CMake qmllint targets
[unix]
lint:
	find src/ -path '*/.venv' -prune -o \( -name '*.cpp' -o -name '*.h' \) -exec clang-tidy -p build {} \;
	cmake --build build --target GroundControl_qmllint AgcStyle_qmllint AgcLog_qmllint AgcComponents_qmllint AgcPanels_qmllint AgcNetwork_qmllint AgcMavlink_qmllint AgcDetection_qmllint AgcCamera_qmllint

# Lint code using clang-tidy and qmllint
[windows]
lint:
	Get-ChildItem -Recurse -Include *.cpp,*.h | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\third_party\\' -and $_.FullName -notmatch '\\.venv\\' } | ForEach-Object { clang-tidy $_.FullName -p build --header-filter=".*" 2>&1 | Out-Null }
	cmake --build build --target GroundControl_qmllint AgcStyle_qmllint AgcLog_qmllint AgcComponents_qmllint AgcPanels_qmllint AgcNetwork_qmllint AgcMavlink_qmllint AgcDetection_qmllint AgcCamera_qmllint

# Clean build directory and LSP files
[unix]
clean:
	rm -rf build
	rm -f compile_commands.json

# Clean build directory and LSP files
[windows]
clean:
	Remove-Item -Path build -Verbose -Recurse -ErrorAction SilentlyContinue -Force
	Remove-Item -Path compile_commands.json -Verbose -ErrorAction SilentlyContinue -Force

# Detection Python runtime managed with uv.
detection_project := "src/Detection"
detection_model := "yolov8n.pt"

# Create/update the uv environment for the detector.
[unix]
detector-setup:
	uv sync --project {{detection_project}}

[windows]
detector-setup:
	uv sync --project {{detection_project}}

# Download YOLO weights into the detection module.
# MODEL can be overridden, e.g. `just detector-download-model yolov8s.pt`.
[unix]
detector-download-model MODEL="yolov8n.pt": detector-setup
	cd {{detection_project}} && uv run --no-sync python -c "from ultralytics import YOLO; YOLO('{{MODEL}}')"

[windows]
detector-download-model MODEL="yolov8n.pt": detector-setup
	cd {{detection_project}}; uv run --no-sync python -c "from ultralytics import YOLO; YOLO('{{MODEL}}')"

# Set up the Python object-detection environment and model, then configure and build.
[unix]
setup: detector-setup detector-download-model configure
    cmake --build build

[windows]
setup: detector-setup detector-download-model configure
    cmake --build build
