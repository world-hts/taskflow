#!/usr/bin/env bash
set -euo pipefail

flutter pub get
dart format lib test
flutter analyze
flutter test
