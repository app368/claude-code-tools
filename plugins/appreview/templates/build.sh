#!/bin/bash
# Builds the AppReview tool. Run it from the folder holding fit.swift.
#
# The binary is deliberately not shipped: it is machine-specific,
# the source is not.

set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

# Swift allows top-level code only in a file named main.swift
TMP=$(mktemp -d)
cp "$HERE/fit.swift" "$TMP/main.swift"
swiftc -suppress-warnings -o "$HERE/fit" "$TMP/main.swift"
rm -rf "$TMP"

echo "built: $HERE/fit"
echo
echo "  ./fit check clip.mov"
echo "  ./fit fit recording.mov out.mov 1920 1080"
