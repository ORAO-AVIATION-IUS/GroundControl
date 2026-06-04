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

# Configure + build from scratch (first time or after adding dependencies)
[unix]
prebuild: configure
    cmake --build build

# Configure + build from scratch
[windows]
prebuild: configure
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

# Run
[linux]
run BACKEND="xcb":
    cd build && \
    set -a && source {{justfile_directory()}}/.env && set +a && \
    QT_QPA_PLATFORM={{BACKEND}} \
    LD_LIBRARY_PATH="{{justfile_directory()}}/third_party/maplibre-prebuilt/linux/lib" \
    QT_PLUGIN_PATH="{{justfile_directory()}}/third_party/maplibre-prebuilt/linux/plugins" \
    QML_IMPORT_PATH="{{justfile_directory()}}/third_party/maplibre-prebuilt/linux/qml" \
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
	find src/ \( -name '*.cpp' -o -name '*.h' \) -exec clang-format -i -style=file {} \;
	find src/ -name '*.qml' -exec {{qmlformat6}} -i {} \;

# Format code using clang-format and qmlformat
[windows]
format:
	Get-ChildItem -Path 'src' -Recurse -Filter '*.qml' | ForEach-Object { qmlformat -i $_.FullName }
	Get-ChildItem -Path 'src\*' -Recurse -Include '*.cpp','*.h' | ForEach-Object { clang-format -i -style=file $_.FullName }

# Lint code using clang-tidy and CMake qmllint targets
[unix]
lint:
	find src/ \( -name '*.cpp' -o -name '*.h' \) -exec clang-tidy -p build {} \;
	cmake --build build --target GroundControl_qmllint AgcStyle_qmllint AgcLog_qmllint AgcComponents_qmllint AgcPanels_qmllint AgcNetwork_qmllint AgcMavlink_qmllint AgcCamera_qmllint

# Lint code using clang-tidy and qmllint
[windows]
lint:
	Get-ChildItem -Recurse -Include *.cpp,*.h | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\third_party\\' } | ForEach-Object { clang-tidy $_.FullName -p build --header-filter=".*" 2>&1 | Out-Null }
	cmake --build build --target GroundControl_qmllint AgcStyle_qmllint AgcLog_qmllint AgcComponents_qmllint AgcPanels_qmllint AgcNetwork_qmllint AgcMavlink_qmllint AgcCamera_qmllint

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

# stuff necessary for the object detection should be set up in a way that it will just install
# the dependencies and everything
# putting this here cuz i dont want to clog up the preexisting justfile above

# Path to the venv used by the Python detector
detector_venv := ".venv"
detector_python := if os() == "windows" { detector_venv + "/Scripts/python.exe" } else { detector_venv + "/bin/python3" }

# Create venv and install detector dependencies
[unix]
detector-setup:
    python3 -m venv {{detector_venv}}
    {{detector_python}} -m pip install --upgrade pip
    {{detector_python}} -m pip install \
        sahi ultralytics opencv-python-headless numpy \
        google-genai
    {{detector_python}} -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

[windows]
detector-setup:
    python3 -m venv {{detector_venv}}
    {{detector_python}} -m pip install --upgrade pip
    {{detector_python}} -m pip install \
        sahi ultralytics opencv-python-headless numpy \
    {{detector_python}} -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

# Download YOLOv8n weights into src/Camera/
[unix]
detector-download-model:
    {{detector_python}} -c "from ultralytics import YOLO; m=YOLO('yolov8n.pt'); import shutil; shutil.move('yolov8n.pt', 'src/Camera/yolov8n.pt')" 2>/dev/null || true

[windows]
detector-download-model:
    {{detector_python}} -c "from ultralytics import YOLO; m=YOLO('yolov8n.pt'); import shutil; shutil.move('yolov8n.pt', 'src/Camera/yolov8n.pt')"

# First-time setup: venv + model + build
[unix]
setup: detector-setup detector-download-model prebuild

[windows]
setup: detector-setup detector-download-model prebuild
