// Forces the microphone without echo cancellation, noise suppression or auto gain:
// with them on, Chrome boosts the pre-recorded voice ~13 dB and it sounds distorted.
(() => {
  const raw = {echoCancellation: false, noiseSuppression: false, autoGainControl: false};
  const fix = c => {
    if (c && c.audio) c.audio = Object.assign(typeof c.audio === 'object' ? c.audio : {}, raw);
    return c;
  };
  const md = MediaDevices.prototype, gum = md.getUserMedia;
  md.getUserMedia = function (c) { return gum.call(this, fix(c)); };
  const ac = MediaStreamTrack.prototype.applyConstraints;
  MediaStreamTrack.prototype.applyConstraints = function (c) {
    return ac.call(this, this.kind === 'audio' ? Object.assign(c || {}, raw) : c);
  };
})();
