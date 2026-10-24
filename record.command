#!/bin/zsh
# Opens Chrome (separate profile) with media/cam.mjpeg as the camera and media/mic.wav as the microphone.
D="${0:A:h}"
[[ -f $D/media/cam.mjpeg && -f $D/media/mic.wav ]] || { echo "Run ./prepare.sh video.mov first"; exit 1; }
open -na "Google Chrome" --args --user-data-dir="$D/chrome-profile" --no-first-run \
  --use-fake-ui-for-media-stream --use-fake-device-for-media-stream \
  --disable-features=AudioServiceSandbox \
  --use-file-for-fake-video-capture="$D/media/cam.mjpeg" \
  --use-file-for-fake-audio-capture="$D/media/mic.wav%noloop" \
  "https://www.canva.com"
