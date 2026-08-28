#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Hago"
SOURCE_APP="$ROOT_DIR/outputs/$APP_NAME.app"
TARGET_APP="/Applications/$APP_NAME.app"
LEGACY_APP="/Applications/Worklog.app"
DEFAULT_SIGN_IDENTITY="Worklog Local Code Signing"
SIGN_IDENTITY="${WORKLOG_CODE_SIGN_IDENTITY:-}"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/package-app.sh" release >/dev/null

for process_name in "$APP_NAME" "Worklog"; do
  if pgrep -x "$process_name" >/dev/null; then
    pkill -x "$process_name" || true
    sleep 1
  fi
done

if [[ -z "$SIGN_IDENTITY" ]] && security find-identity -v -p codesigning | grep -q "\"$DEFAULT_SIGN_IDENTITY\""; then
  SIGN_IDENTITY="$DEFAULT_SIGN_IDENTITY"
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
  codesign --force --deep --sign "$SIGN_IDENTITY" "$SOURCE_APP"
else
  codesign --force --deep --sign - "$SOURCE_APP"
fi

rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"
rm -rf "$LEGACY_APP"
open "$TARGET_APP"

echo "$TARGET_APP"
