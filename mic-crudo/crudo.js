// Fuerza el micrófono sin cancelación de eco, supresión de ruido ni ganancia automática.
(() => {
  const crudo = {echoCancellation: false, noiseSuppression: false, autoGainControl: false};
  const fix = c => {
    if (c && c.audio) c.audio = Object.assign(typeof c.audio === 'object' ? c.audio : {}, crudo);
    return c;
  };
  const md = MediaDevices.prototype, gum = md.getUserMedia;
  md.getUserMedia = function (c) { return gum.call(this, fix(c)); };
  const ac = MediaStreamTrack.prototype.applyConstraints;
  MediaStreamTrack.prototype.applyConstraints = function (c) {
    return ac.call(this, this.kind === 'audio' ? Object.assign(c || {}, crudo) : c);
  };
})();
