#!/bin/zsh
# Double-click to prepare a video and open Chrome, with macOS dialogs instead of the terminal.
D="${0:A:h}"
cd "$D"
STEP=60  # crop pixels per click

# Shows a dialog; prints the button clicked, or fails if the window is closed.
ask() {  # ask "message" "Button 1" "Button 2" ... (the last one is the default)
  local msg=$1; shift
  local b quoted=()
  for b; do quoted+=("\"$b\""); done
  osascript -e "button returned of (display dialog \"$msg\" with title \"canva-cam\" buttons {${(j:, :)quoted}} default button \"${argv[-1]}\")"
}
alert() { osascript -e "display alert \"canva-cam\" message \"$1\" as critical" >/dev/null }

if ! command -v ffmpeg >/dev/null && [[ ! -x bin/ffmpeg ]]; then
  alert "ffmpeg is missing. Install it with: brew install ffmpeg, or put a static build at bin/ffmpeg (on Intel Macs Homebrew may compile it for a long time; evermeet.cx has a ready one). Then double-click canva-cam again."
  exit 1
fi

if [[ -f media/cam.mjpeg && -f media/mic.wav ]]; then
  [[ $(ask "A video is already prepared. Record with it or choose a new one?" "New video" "Record") == Record ]] && exec ./record.command
fi

VIDEO=$(osascript -e 'POSIX path of (choose file with prompt "Choose the video to use as your camera and microphone" of type {"public.movie"})') || exit 0

# Framing: show the circle preview and move the face until it's centered.
Y=100
while true; do
  PREVIEW_ONLY=1 NO_OPEN=1 ./prepare.sh "$VIDEO" $Y >/dev/null || { alert "Could not read that video."; exit 1; }
  qlmanage -p media/preview.png >/dev/null 2>&1 &
  QL=$!
  CHOICE=$(ask "Is the face centered in the circle? The preview is in the other window." "Face up" "Face down" "Centered")
  kill $QL 2>/dev/null
  case $CHOICE in
    "Face up") Y=$((Y + STEP)) ;;
    "Face down") Y=$((Y > STEP ? Y - STEP : 0)) ;;
    Centered) break ;;
    *) exit 0 ;;
  esac
done

NO_OPEN=1 ./prepare.sh "$VIDEO" $Y || { alert "Preparing the video failed. See the Terminal window for details."; exit 1; }

if [[ ! -d chrome-profile ]]; then
  ask "First time only: in the Chrome window that opens, go to chrome://extensions, turn on Developer mode, click Load unpacked and pick the raw-mic folder (shown in Finder). Then sign in to Canva." "Open Chrome" >/dev/null || exit 0
  open -R raw-mic
fi
exec ./record.command
