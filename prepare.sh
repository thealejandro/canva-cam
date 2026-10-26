#!/bin/zsh
# Turns a video into the fake camera (media/cam.mjpeg) and fake microphone (media/mic.wav).
# Usage: ./prepare.sh video.mov [crop_y]
#   crop_y: pixels from the top where the square crop starts (default 100).
#   Raise it if the face sits too low in the circle, lower it if too high.
#   MARGIN=8 ./prepare.sh video.mov  changes the lead-in (default 5 s).
#   PREVIEW_ONLY=1 ./prepare.sh video.mov 250  only writes media/preview.png (seconds, not minutes).
#   NO_OPEN=1  doesn't open the preview (used by canva-cam.command).
set -e
cd "${0:A:h}"
VIDEO=${1:?Usage: ./prepare.sh video.mov [crop_y]}
[[ -f $VIDEO ]] || { echo "File not found: $VIDEO"; exit 1; }
Y=${2:-100}
MARGIN=${MARGIN:-5}  # still image + silence at the start (Canva counts down 3 s before recording)

FF=$(command -v ffmpeg || echo bin/ffmpeg)
[[ -x $FF ]] || { echo "ffmpeg not found. Install it with 'brew install ffmpeg' or put a static build at bin/ffmpeg (https://evermeet.cx/ffmpeg/)."; exit 1; }

DUR=$("$FF" -hide_banner -i "$VIDEO" 2>&1 | sed -n 's/.*Duration: \([0-9:.]*\).*/\1/p')
[[ -n $DUR ]] || { echo "Not a video ffmpeg can read: $VIDEO"; exit 1; }
SQUARE="crop='min(iw,ih)':'min(iw,ih)':'(iw-min(iw,ih))/2':'min($Y,ih-min(iw,ih))',scale=640:640"

mkdir -p media
# Framing preview with Canva's circle, taken from the source (fast) at 10 s, or mid-video if shorter.
P=(${(s.:.)DUR}); SECS=$(( P[1] * 3600 + P[2] * 60 + P[3] ))
T=$(( SECS < 20 ? SECS / 2 : 10 ))
rm -f media/preview.png
"$FF" -hide_banner -loglevel error -y -ss $T -i "$VIDEO" -map 0:v:0 -frames:v 1 \
  -vf "$SQUARE,format=rgb24,geq=r='r(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)':g='g(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)':b='b(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)'" \
  media/preview.png
[[ -s media/preview.png ]] || { echo "Could not extract a preview frame at ${T}s."; exit 1; }
show_preview() { if [[ $OSTYPE == darwin* && -z $NO_OPEN ]]; then open media/preview.png; fi }
if [[ -n $PREVIEW_ONLY ]]; then show_preview; exit 0; fi

echo "Encoding video…"
"$FF" -hide_banner -loglevel error -stats -y -i "$VIDEO" -map 0:v:0 -an \
  -vf "$SQUARE,tpad=start_duration=${MARGIN}:start_mode=clone,fps=30,format=yuvj420p" \
  -q:v 3 media/cam.mjpeg
# 44.1 kHz stereo: at 48 kHz mono Chrome delivers it choppy.
echo "Encoding audio…"
if "$FF" -hide_banner -i "$VIDEO" 2>&1 | grep -q 'Audio:'; then
  AUDIO=(-i "$VIDEO" -map 0:a:0)
else
  echo "No audio track, using silence."
  AUDIO=(-f lavfi -t "$DUR" -i anullsrc=r=44100:cl=stereo)
fi
"$FF" -hide_banner -loglevel error -y "${AUDIO[@]}" \
  -af "adelay=${MARGIN}s:all=1" -ac 2 -ar 44100 -c:a pcm_s16le media/mic.wav
echo "Done. Check media/preview.png, then open record.command"
show_preview
