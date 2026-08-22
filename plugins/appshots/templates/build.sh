#!/bin/bash
# Собирает рисовальщик скриншотов витрины.
# Запуск:  ./build.sh && ./bin/shots
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HERE/bin"
swiftc -suppress-warnings -o "$HERE/bin/shots" "$HERE/src/main.swift"
echo "готово: bin/shots"
