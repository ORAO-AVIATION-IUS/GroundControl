set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
qmlformat6 := if os() == "linux" { "/usr/lib/qt6/bin/qmlformat" } else { "qmlformat" }

# Build project
build:
    cmake -B build -S . -G Ninja
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
    cd build && QT_QPA_PLATFORM={{BACKEND}} ./GroundControl

[macos]
run:
    QT_PLUGIN_PATH="$PWD/third_party/maplibre-prebuilt/macos/plugins" \
    QML_IMPORT_PATH="$PWD/third_party/maplibre-prebuilt/macos/qml" \
    ./build/GroundControl

[windows]
run:
    ./build/GroundControl.exe

# Format code using clang-format and qmlformat
[unix]
format:
	find src/ -name '*.cpp' -o -name '*.h' -exec clang-format -i -style=file {} \;
	find src/ -name '*.qml' -exec {{qmlformat6}} -i {} \;

# Format code using clang-format and qmlformat
[windows]
format:
	Get-ChildItem -Path 'src' -Recurse -Filter '*.qml' | ForEach-Object { qmlformat -i $_.FullName }
	Get-ChildItem -Path 'src\*' -Recurse -Include '*.cpp','*.h' | ForEach-Object { clang-format -i -style=file $_.FullName }

# Lint code using clang-tidy and CMake qmllint targets
[unix]
lint:
	find src/ -name '*.cpp' -o -name '*.h' -exec clang-tidy -p build {} \;
	cmake --build build --target GroundControl_qmllint AgcStyle_qmllint AgcComponents_qmllint AgcPanels_qmllint AgcNetwork_qmllint AgcMavlink_qmllint AgcCamera_qmllint

# Lint code using clang-tidy and qmllint
[windows]
lint:
	Get-ChildItem -Recurse -Include *.cpp,*.h | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\third_party\\' } | ForEach-Object { clang-tidy $_.FullName -p build --header-filter=".*" 2>&1 | Out-Null }
	cmake --build build --target GroundControl_qmllint AgcStyle_qmllint AgcComponents_qmllint AgcPanels_qmllint AgcNetwork_qmllint AgcMavlink_qmllint AgcCamera_qmllint

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
