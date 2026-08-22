#!/bin/bash
# Собирает рисовальщик иконки.
# Запуск:  ./build.sh && ./bin/icon
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HERE/bin" "$HERE/out"
swiftc -suppress-warnings -o "$HERE/bin/icon" "$HERE/src/main.swift"
echo "готово: bin/icon"
