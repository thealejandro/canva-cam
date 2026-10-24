#!/bin/zsh
# Turns a video into the fake camera (media/cam.mjpeg) and fake microphone (media/mic.wav).
# Usage: ./prepare.sh video.mov [crop_y]
#   crop_y: pixels from the top where the square crop starts (default 100).
#   Raise it if the face sits too high in the circle, lower it if too low.
#   MARGIN=8 ./prepare.sh video.mov  changes the lead-in (default 5 s).
set -e
cd "${0:A:h}"
VIDEO=${1:?Usage: ./prepare.sh video.mov [crop_y]}
[[ -f $VIDEO ]] || { echo "File not found: $VIDEO"; exit 1; }
Y=${2:-100}
MARGIN=${MARGIN:-5}  # still image + silence at the start (Canva counts down 3 s before recording)

FF=$(command -v ffmpeg || echo bin/ffmpeg)
[[ -x $FF ]] || { echo "ffmpeg not found. Install it with 'brew install ffmpeg' or put a static build at bin/ffmpeg (https://evermeet.cx/ffmpeg/)."; exit 1; }

mkdir -p media
echo "Encoding video…"
"$FF" -hide_banner -loglevel error -stats -y -i "$VIDEO" -map 0:v:0 -an \
  -vf "crop='min(iw,ih)':'min(iw,ih)':'(iw-min(iw,ih))/2':'min($Y,ih-min(iw,ih))',scale=640:640,tpad=start_duration=${MARGIN}:start_mode=clone,fps=30,format=yuvj420p" \
  -q:v 3 media/cam.mjpeg
# 44.1 kHz stereo: at 48 kHz mono Chrome delivers it choppy.
echo "Encoding audio…"
"$FF" -hide_banner -loglevel error -y -i "$VIDEO" -map 0:a:0 \
  -af "adelay=${MARGIN}s:all=1" -ac 2 -ar 44100 -c:a pcm_s16le media/mic.wav
# Framing preview with Canva's circle.
"$FF" -hide_banner -loglevel error -y -ss $((MARGIN + 10)) -i media/cam.mjpeg -frames:v 1 \
  -vf "format=rgb24,geq=r='r(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)':g='g(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)':b='b(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)'" \
  media/preview.png
echo "Done. Check media/preview.png, then open record.command"
open media/preview.png
