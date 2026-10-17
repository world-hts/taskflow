#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK was not found. Install Flutter and add it to PATH first.' >&2
  exit 1
fi

flutter create --platforms=android,ios,macos,windows,linux,web --org com.worldhts .
