set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
qmlformat6 := if os() == "linux" { "/usr/lib/qt6/bin/qmlformat" } else { "qmlformat" }
qmllint6 := if os() == "linux" { "/usr/lib/qt6/bin/qmllint" } else { "qmllint" }

# Build project
build:
    cmake -B build -S . -G Ninja
    cmake --build build

# Run
[linux]
run BACKEND="xcb":
    cd build && QT_QPA_PLATFORM={{BACKEND}} QML_IMPORT_PATH=./com ./GroundControl

[macos]
run:
    cd build && ./GroundControl

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

# Lint code using clang-tidy and qmllint
[unix]
lint:
	find src/ -name '*.cpp' -o -name '*.h' -exec clang-tidy -p build {} \;
	find src/ -name '*.qml' -exec {{qmllint6}} -I build -I src {} \;

# Lint code using clang-tidy (C++/headers) and qmllint (QML)
[windows]
lint:
    Get-ChildItem -Recurse -Filter *.qml | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\third_party\\' } | ForEach-Object { qmllint $_.FullName }
    Get-ChildItem -Recurse -Include *.cpp,*.h | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\third_party\\' } | ForEach-Object { clang-tidy $_.FullName -p build --header-filter=".*" 2>&1 | Out-Null }

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
