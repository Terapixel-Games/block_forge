#!/usr/bin/env bash
set -euo pipefail

echo "Running Godot import smoke..."
godot --headless --path /workspace --import --quit

echo "Running scene load smoke..."
godot --headless --path /workspace --script /workspace/backend/ci/godot/stack_smoke.gd
