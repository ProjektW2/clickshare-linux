#!/bin/sh
# Builds the DXGI Desktop Duplication shim (csdup.dll) and the injector
# (inject.exe) as 32-bit Windows binaries.
#
# Uses i686-w64-mingw32-gcc if installed, otherwise downloads a pinned Zig
# toolchain into .toolchain/ (no root needed).
#
# Usage: sh scripts/build.sh
set -e

DIR=$(cd "$(dirname "$0")/.." && pwd)
OUT="$DIR/build"
SRC="$DIR/shim"
ZIG_VERSION=0.14.1
# From https://ziglang.org/download/index.json
ZIG_SHA256=24aeeec8af16c381934a6cd7d95c807a8cb2cf7df9fa40d359aa884195c4716c
mkdir -p "$OUT"

if command -v i686-w64-mingw32-gcc >/dev/null 2>&1; then
    echo "Building with MinGW-w64"
    i686-w64-mingw32-gcc -O2 -shared -o "$OUT/csdup.dll" "$SRC/csdup.c" \
        -ld3d11 -ldxgi -lgdi32 -luser32 -static-libgcc
    i686-w64-mingw32-gcc -O2 -municode -o "$OUT/inject.exe" "$SRC/inject.c" -static-libgcc
else
    ZIG="$DIR/.toolchain/zig-x86_64-linux-$ZIG_VERSION/zig"
    if [ ! -x "$ZIG" ]; then
        if command -v zig >/dev/null 2>&1; then
            ZIG=$(command -v zig)
        else
            echo "Downloading Zig $ZIG_VERSION into .toolchain/"
            mkdir -p "$DIR/.toolchain"
            curl -fL -o "$DIR/.toolchain/zig.tar.xz" \
                "https://ziglang.org/download/$ZIG_VERSION/zig-x86_64-linux-$ZIG_VERSION.tar.xz"
            if ! echo "$ZIG_SHA256  $DIR/.toolchain/zig.tar.xz" | sha256sum -c --status; then
                rm -f "$DIR/.toolchain/zig.tar.xz"
                echo "Zig download failed the SHA-256 check." >&2
                exit 1
            fi
            tar -C "$DIR/.toolchain" -xf "$DIR/.toolchain/zig.tar.xz"
            rm "$DIR/.toolchain/zig.tar.xz"
        fi
    fi
    echo "Building with $("$ZIG" version | sed 's/^/Zig /')"
    "$ZIG" cc -target x86-windows-gnu -O2 -shared -o "$OUT/csdup.dll" "$SRC/csdup.c" \
        -ld3d11 -ldxgi -lgdi32 -luser32
    "$ZIG" cc -target x86-windows-gnu -O2 -municode -o "$OUT/inject.exe" "$SRC/inject.c"
    rm -f "$OUT"/*.pdb "$OUT"/*.lib
fi

ls -l "$OUT/csdup.dll" "$OUT/inject.exe"
