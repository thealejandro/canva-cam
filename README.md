# canva-cam

Graba una presentación con **Canva → Presentar y grabar** usando un video ya grabado: el video sale en la burbuja de la cámara y su audio como micrófono. Tú solo pasas las diapositivas al ritmo del audio.

Funciona con Google Chrome en macOS, sin OBS ni cámaras virtuales. Usa los dispositivos falsos de Chrome, que leen la cámara y el micrófono desde archivos.

## Uso

1. **Preparar el video** (una vez por video, tarda ~1 min):

   ```bash
   ./preparar.sh ~/Downloads/video.mov
   ```

   Genera `media/cam.mjpeg` y `media/mic.wav` con 5 s de margen al inicio. Al terminar, abre `media/vista-previa.png` con el círculo de Canva. Si la cara no queda centrada, repite el comando con un número al final: los píxeles desde arriba donde empieza el recorte (por defecto 100).

   ```bash
   ./preparar.sh ~/Downloads/video.mov 250
   ```

   Si no tienes ffmpeg, el script descarga uno en `bin/`.

2. **Abrir Chrome:** doble clic en `grabar.command`. La primera vez macOS puede bloquearlo: clic derecho → **Abrir**. Se abre una ventana de Chrome con un perfil aparte (`perfil-chrome/`), sin tocar tu Chrome normal.

3. **Solo la primera vez, en esa ventana:**
   - Ve a `chrome://extensions`, activa **Modo de desarrollador** → **Cargar descomprimida** → elige la carpeta `mic-crudo` de este proyecto.
   - Inicia sesión en Canva.

4. **Grabar:** abre la presentación → **Presentar y grabar**. Elige la cámara y el micrófono `fake…` y **pulsa grabar enseguida**. El video empieza en cuanto Canva abre la cámara, no cuando empieza a grabar. Los 5 s de margen cubren la cuenta atrás de 3 s de Canva.

5. **Si algo sale mal:** el audio suena una sola vez. Cierra esa ventana con Cmd+Q y vuelve a abrir `grabar.command`.

## Por qué está hecho así

- **`mic-crudo/`**: extensión que pide el micrófono sin cancelación de eco, supresión de ruido ni volumen automático. Con esos filtros, Chrome sube la voz unos 13 dB y suena distorsionada. Chrome 137+ ya no permite cargar extensiones por línea de comandos, por eso se carga a mano en el paso 3.
- **Audio a 44.1 kHz estéreo**: a 48 kHz mono, Chrome lo entrega entrecortado.
- **`--disable-features=AudioServiceSandbox`**: sin esto, Chrome no puede leer el WAV.
- **Brave no sirve**: casi no lee el vídeo MJPEG (sale congelado), y con Y4M el vídeo va ~0.9 s detrás del audio.
