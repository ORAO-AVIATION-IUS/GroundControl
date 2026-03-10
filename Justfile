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
    cd build && ./GroundControl.exe

# Format code using clang-format and qmlformat (all files or specific file)
[unix]
format FILE="":
    #!/usr/bin/env sh
    if [ -z "{{FILE}}" ]; then
        find . \( -name '*.cpp' -o -name '*.h' \) \
            ! -path '*/build/*' \
            ! -path '*/third_party/*' \
            -exec clang-format -i -style=file {} \;
        find . -name '*.qml' \
            ! -path '*/build/*' \
            ! -path '*/third_party/*' \
            -exec {{qmlformat6}} -i {} \;
    else
        if echo "{{FILE}}" | grep -q '\.qml$'; then
            {{qmlformat6}} -i {{FILE}}
        else
            clang-format -i -style=file {{FILE}}
        fi
    fi

[windows]
format FILE="":
    @if "{{FILE}}"=="" ( \
        powershell -Command "Get-ChildItem -Recurse -Filter '*.cpp','*.h' | Where-Object { $_.FullName -notmatch 'third_party|build' } | ForEach-Object { clang-format -i -style=file $_.FullName }" && \
        powershell -Command "Get-ChildItem -Recurse -Filter '*.qml' | Where-Object { $_.FullName -notmatch 'third_party|build' } | ForEach-Object { qmlformat -i $_.FullName }" \
    ) else ( \
        echo {{FILE}} | findstr /I "\.qml$" >nul && (qmlformat -i {{FILE}}) || (clang-format -i -style=file {{FILE}}) \
    )

# Lint code using clang-tidy and qmllint (all files or specific file)
[unix]
lint FILE="":
    #!/usr/bin/env sh
    set -e
    
    # Filter out GCC-specific flags that clang-tidy doesn't understand
    if [ -f build/compile_commands.json ]; then
        sed -i.bak 's/-mno-direct-extern-access//g' build/compile_commands.json
    fi
    
    if [ -z "{{FILE}}" ]; then
        find . \( -name '*.cpp' -o -name '*.h' \) \
            ! -path '*/build/*' \
            ! -path '*/third_party/*' \
            -exec clang-tidy -p build {} --header-filter='^(?!.*(third_party|build/|/usr/)).*' \; 2>&1 | grep -v "^Suppressed" | grep -v "^Use -header-filter" || true
        find . -name '*.qml' \
            ! -path '*/build/*' \
            ! -path '*/third_party/*' \
            -exec {{qmllint6}} {} \;
    else
        if echo "{{FILE}}" | grep -q '\.qml$'; then
            {{qmllint6}} {{FILE}}
        else
            clang-tidy -p build {{FILE}} --header-filter='^(?!.*(third_party|build/|/usr/)).*' 2>&1 | grep -v "^Suppressed" | grep -v "^Use -header-filter" || true
        fi
    fi
    
    # Restore original compile_commands.json
    if [ -f build/compile_commands.json.bak ]; then
        mv build/compile_commands.json.bak build/compile_commands.json
    fi

[windows]
lint FILE="":
    @if "{{FILE}}"=="" ( \
        powershell -Command "Get-ChildItem -Recurse -Filter '*.cpp','*.h' | Where-Object { $_.FullName -notmatch 'third_party|build' } | ForEach-Object { clang-tidy -p build $_.FullName --extra-arg-before=-Wno-unknown-warning-option }" && \
        powershell -Command "Get-ChildItem -Recurse -Filter '*.qml' | Where-Object { $_.FullName -notmatch 'third_party|build' } | ForEach-Object { qmllint $_.FullName }" \
    ) else ( \
        echo {{FILE}} | findstr /I "\.qml$" >nul && (qmllint {{FILE}}) || (clang-tidy -p build {{FILE}} --extra-arg-before=-Wno-unknown-warning-option) \
    )

# Clean build directory and/or LSP files (TARGET: build|lsp|all, default: all)
[unix]
clean TARGET="all":
    #!/usr/bin/env sh
    if [ "{{TARGET}}" = "all" ] || [ "{{TARGET}}" = "build" ]; then
        rm -rf build
    fi
    if [ "{{TARGET}}" = "all" ] || [ "{{TARGET}}" = "lsp" ]; then
        rm -f compile_commands.json
    fi

[windows]
clean TARGET="all":
    @if "{{TARGET}}"=="all" ( \
        if exist build rmdir /s /q build && \
        if exist compile_commands.json del /f compile_commands.json \
    ) else if "{{TARGET}}"=="build" ( \
        if exist build rmdir /s /q build \
    ) else if "{{TARGET}}"=="lsp" ( \
        if exist compile_commands.json del /f compile_commands.json \
    )
