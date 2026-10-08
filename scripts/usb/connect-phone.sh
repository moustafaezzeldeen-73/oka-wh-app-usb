#!/bin/sh
# OKA WH Dev over USB (Mac / Linux).
#   sh connect-phone.sh                         connect the phone to the dev server
#   sh connect-phone.sh oka-warehouse-dev.apk   install the app first, then connect
# Needs USB debugging on the phone, and the Codespace's port 8081 on this computer
# (VS Code desktop forwards it; or: gh codespace ports forward 8081:8081).
set -e
PORT=8081
LINK='okawhdev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8081'
TOOLS="$HOME/.oka-platform-tools"

if command -v adb >/dev/null 2>&1; then ADB=adb; else
  ADB="$TOOLS/platform-tools/adb"
  if [ ! -x "$ADB" ]; then
    case "$(uname -s)" in Darwin) OS=darwin ;; *) OS=linux ;; esac
    echo "Downloading Android platform-tools (one time)…"
    mkdir -p "$TOOLS"
    curl -fsSL -o "$TOOLS/pt.zip" "https://dl.google.com/android/repository/platform-tools-latest-$OS.zip"
    unzip -qo "$TOOLS/pt.zip" -d "$TOOLS" && rm "$TOOLS/pt.zip"
  fi
fi

"$ADB" start-server >/dev/null 2>&1
echo "Waiting for the phone… plug it in with USB debugging on, and tap Allow on the phone if it asks."
"$ADB" wait-for-device
echo "Phone connected."

if [ -n "$1" ]; then
  echo "Installing $1…"
  "$ADB" install -r "$1"
fi

if ! curl -s -m 3 "http://localhost:$PORT/status" | grep -q packager-status:running; then
  echo
  echo "WARNING: http://localhost:$PORT does not answer here. Start 'npm run dev:usb' in the Codespace and"
  echo "open it in VS Code desktop (forwards port $PORT), or run: gh codespace ports forward $PORT:$PORT"
  echo
fi

"$ADB" reverse "tcp:$PORT" "tcp:$PORT"
"$ADB" shell "am start -a android.intent.action.VIEW -d '$LINK'" >/dev/null
echo "Done: OKA WH Dev is opening on the phone and loading through USB. Every save reloads it."
