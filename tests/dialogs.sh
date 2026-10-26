#!/bin/bash
# Walks canva-cam.command through its dialogs with fake osascript/qlmanage/open (no macOS needed).
set -eu
REPO=$(cd "$(dirname "$0")/.." && pwd)
VIDEO=$(mktemp -d)/clip.mp4
ffmpeg -hide_banner -loglevel error -f lavfi -i "testsrc=size=720x1280:rate=30:duration=3" \
  -f lavfi -i "sine=duration=3" -shortest "$VIDEO"

# run <name> <answers...>: copy of the repo with record.command replaced by a marker.
run() {
  name=$1; shift
  W=$(mktemp -d); cp -r "$REPO/." "$W"; rm -rf "$W/media" "$W/chrome-profile"
  printf '#!/bin/sh\necho record >> "$LOG"\n' > "$W/record.command"
  export LOG=$W/log ANSWERS=$W/answers
  : > "$LOG"; printf '%s\n' "$@" > "$ANSWERS"
  echo "== $name"
}
go() { PATH="$REPO/tests/stubs:$PATH" zsh "$W/canva-cam.command" > "$W/out" 2>&1; }
has() { grep -q -- "$1" "$LOG" || { echo "missing in log: $1"; cat "$LOG"; exit 1; }; }
hasnt() { if grep -q -- "$1" "$LOG"; then echo "unexpected in log: $1"; cat "$LOG"; exit 1; fi; }

run "new video, move the face up once, first time" "$VIDEO" "Face up" "Centered" "Open Chrome"
go
test -s "$W/media/cam.mjpeg" && test -s "$W/media/mic.wav" && test -s "$W/media/preview.png"
[ "$(grep -c '^qlmanage' "$LOG")" = 2 ]
has "open -R raw-mic"; has "^record$"

run "already prepared: record right away" "Record"
mkdir -p "$W/media" && touch "$W/media/cam.mjpeg" "$W/media/mic.wav"
go
has "^record$"; hasnt "choose file"

run "cancel the file picker" CANCEL
go
hasnt "^record$"; test ! -e "$W/media/cam.mjpeg"
echo "all dialog flows OK"
