#!/bin/zsh
# Convierte un video en la cámara (media/cam.mjpeg) y el micrófono (media/mic.wav) falsos.
# Uso: ./preparar.sh video.mov [desplazamiento_y]
#   desplazamiento_y: píxeles desde arriba donde empieza el recorte cuadrado (por defecto 100).
#   Súbelo si la cara sale muy arriba en el círculo, bájalo si sale muy abajo.
set -e
cd "${0:A:h}"
VIDEO=${1:?Uso: ./preparar.sh video.mov [desplazamiento_y]}
Y=${2:-100}
MARGEN=5  # segundos de imagen quieta y silencio al inicio (Canva cuenta 3 antes de grabar)

FF=$(command -v ffmpeg || echo bin/ffmpeg)
if [[ ! -x $FF ]]; then
  echo "Descargando ffmpeg (evermeet.cx)…"
  mkdir -p bin
  curl -fL https://evermeet.cx/ffmpeg/ffmpeg-9.0.2.zip -o bin/ffmpeg.zip
  unzip -o -q bin/ffmpeg.zip -d bin && rm bin/ffmpeg.zip
fi

mkdir -p media
echo "Generando vídeo…"
"$FF" -hide_banner -loglevel error -stats -y -i "$VIDEO" -map 0:v:0 -an \
  -vf "crop='min(iw,ih)':'min(iw,ih)':'(iw-min(iw,ih))/2':'min($Y,ih-min(iw,ih))',scale=640:640,tpad=start_duration=${MARGEN}:start_mode=clone,fps=30,format=yuvj420p" \
  -q:v 3 media/cam.mjpeg
# 44.1 kHz estéreo: a 48 kHz mono Chrome lo entrega entrecortado.
echo "Generando audio…"
"$FF" -hide_banner -loglevel error -y -i "$VIDEO" -map 0:a:0 \
  -af "adelay=${MARGEN}s:all=1" -ac 2 -ar 44100 -c:a pcm_s16le media/mic.wav
# Vista previa del encuadre con el círculo de Canva.
"$FF" -hide_banner -loglevel error -y -ss $((MARGEN + 10)) -i media/cam.mjpeg -frames:v 1 \
  -vf "format=rgb24,geq=r='r(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)':g='g(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)':b='b(X,Y)*if(lte(hypot(X-W/2,Y-H/2),W/2),1,0.25)'" \
  media/vista-previa.png
echo "Listo. Revisa media/vista-previa.png y luego abre grabar.command"
open media/vista-previa.png
