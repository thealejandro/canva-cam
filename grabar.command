#!/bin/zsh
# Abre Chrome (perfil aparte) con media/cam.mjpeg como cámara y media/mic.wav como micrófono.
D="${0:A:h}"
[[ -f $D/media/cam.mjpeg && -f $D/media/mic.wav ]] || { echo "Primero ejecuta ./preparar.sh video.mov"; exit 1; }
open -na "Google Chrome" --args --user-data-dir="$D/perfil-chrome" --no-first-run \
  --use-fake-ui-for-media-stream --use-fake-device-for-media-stream \
  --disable-features=AudioServiceSandbox \
  --use-file-for-fake-video-capture="$D/media/cam.mjpeg" \
  --use-file-for-fake-audio-capture="$D/media/mic.wav%noloop" \
  "https://www.canva.com"
