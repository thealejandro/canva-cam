#!/bin/zsh
# Opens Chrome (separate profile) with media/cam.mjpeg as the camera and media/mic.wav as the microphone.
# Usage: ./record.command [url]   (default https://www.canva.com)
D="${0:A:h}"
[[ -f $D/media/cam.mjpeg && -f $D/media/mic.wav ]] || { echo "Run ./prepare.sh video.mov first"; exit 1; }
FLAGS=(--user-data-dir="$D/chrome-profile" --no-first-run
  --use-fake-ui-for-media-stream --use-fake-device-for-media-stream
  --disable-features=AudioServiceSandbox
  --use-file-for-fake-video-capture="$D/media/cam.mjpeg"
  --use-file-for-fake-audio-capture="$D/media/mic.wav%noloop"
  "${1:-https://www.canva.com}")
if [[ $OSTYPE == darwin* ]]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  [[ -x $CHROME ]] && "$CHROME" --version  # handy when reporting issues: Chrome flags change between versions
  open -na "Google Chrome" --args $FLAGS
else
  for CHROME in google-chrome google-chrome-stable chromium chromium-browser ""; do
    (( $+commands[$CHROME] )) && break
  done
  [[ -n $CHROME ]] || { echo "Google Chrome or Chromium not found"; exit 1; }
  $CHROME --version
  $CHROME $FLAGS >/dev/null 2>&1 &!
fi
