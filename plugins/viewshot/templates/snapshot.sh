#!/bin/bash
# Builds the viewshot and draws frames into ./out next to this script.
#
# Run:  ./snapshot.sh
# Open: open out

set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
# Path to the project's sources directory — adjust to your layout
SOURCES="$HERE/../../YourProject/YourProject"
OUT="$HERE/out"

# Project files the view needs. Add to this list as required:
# an unknown-symbol error from swiftc means a file is missing here
NEEDED=(
    "$SOURCES/ViewUnderTest.swift"
)

mkdir -p "$OUT"
rm -f "$OUT"/*.png

# Warnings are silenced: they belong to the project's own code and show up in Xcode.
# Only errors matter here — with one, the viewshot simply won't build
swiftc -suppress-warnings -o "$HERE/snap" "${NEEDED[@]}" "$HERE/main.swift"
"$HERE/snap" "$OUT"

echo
echo "Frames in $OUT"
