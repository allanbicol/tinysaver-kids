// Generates simple WAV sound effects for the app.
// Pure Node — no external deps.
const fs = require('fs');
const path = require('path');

const SAMPLE_RATE = 22050;

/**
 * Build a WAV file buffer from PCM samples.
 * samples is an array of Float32 in -1..1 range.
 */
function wav(samples) {
  const buf = Buffer.alloc(44 + samples.length * 2);
  buf.write('RIFF', 0);
  buf.writeUInt32LE(36 + samples.length * 2, 4);
  buf.write('WAVE', 8);
  buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16);            // PCM chunk size
  buf.writeUInt16LE(1, 20);             // PCM format
  buf.writeUInt16LE(1, 22);             // mono
  buf.writeUInt32LE(SAMPLE_RATE, 24);
  buf.writeUInt32LE(SAMPLE_RATE * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write('data', 36);
  buf.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) {
    const v = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  return buf;
}

/** Linear envelope (attack + release) */
function env(i, N, attack = 0.02, release = 0.5) {
  const t = i / N;
  if (t < attack) return t / attack;
  if (t > 1 - release) return (1 - t) / release;
  return 1;
}

function sine(freq, t) { return Math.sin(2 * Math.PI * freq * t); }
function triangle(freq, t) {
  const v = (t * freq) % 1;
  return 4 * Math.abs(v - 0.5) - 1;
}

// ── Coin — two quick ascending blips (ching!) ─────────────────────────────────
function makeCoin() {
  const dur = 0.28;
  const N = Math.floor(dur * SAMPLE_RATE);
  const out = new Array(N);
  for (let i = 0; i < N; i++) {
    const t = i / SAMPLE_RATE;
    const freq = t < 0.1 ? 880 : 1320;    // A5 → E6 jump
    const e = env(i, N, 0.01, 0.6);
    out[i] = 0.4 * sine(freq, t) * e;
  }
  return out;
}

// ── Success — 3-note major chord arpeggio (C-E-G) ────────────────────────────
function makeSuccess() {
  const notes = [523.25, 659.25, 783.99]; // C5, E5, G5
  const noteDur = 0.14;
  const N = Math.floor(notes.length * noteDur * SAMPLE_RATE);
  const out = new Array(N);
  for (let i = 0; i < N; i++) {
    const t = i / SAMPLE_RATE;
    const idx = Math.min(Math.floor(t / noteDur), notes.length - 1);
    const localT = t - idx * noteDur;
    const noteN = Math.floor(noteDur * SAMPLE_RATE);
    const localI = i - idx * noteN;
    const e = env(localI, noteN, 0.01, 0.7);
    out[i] = 0.4 * sine(notes[idx], localT) * e;
  }
  return out;
}

// ── Pop — very short descending blip ─────────────────────────────────────────
function makePop() {
  const dur = 0.08;
  const N = Math.floor(dur * SAMPLE_RATE);
  const out = new Array(N);
  for (let i = 0; i < N; i++) {
    const t = i / SAMPLE_RATE;
    const freq = 700 - (t / dur) * 300;
    const e = env(i, N, 0.01, 0.5);
    out[i] = 0.35 * triangle(freq, t) * e;
  }
  return out;
}

// ── Oink — short low tone pair (not realistic, just friendly) ────────────────
function makeOink() {
  const dur = 0.25;
  const N = Math.floor(dur * SAMPLE_RATE);
  const out = new Array(N);
  for (let i = 0; i < N; i++) {
    const t = i / SAMPLE_RATE;
    const gate = t < 0.12 ? 1 : (t < 0.13 ? 0 : 1);
    const freq = t < 0.12 ? 260 : 220;
    const e = env(i, N, 0.02, 0.3);
    out[i] = 0.35 * triangle(freq, t) * e * gate;
  }
  return out;
}

const outDir = path.join(__dirname, '..', 'assets', 'sounds');
fs.mkdirSync(outDir, { recursive: true });

const files = {
  'coin.wav': makeCoin(),
  'success.wav': makeSuccess(),
  'pop.wav': makePop(),
  'oink.wav': makeOink(),
};

for (const [name, samples] of Object.entries(files)) {
  const full = path.join(outDir, name);
  fs.writeFileSync(full, wav(samples));
  const kb = (fs.statSync(full).size / 1024).toFixed(1);
  console.log(`✓ ${name}  (${kb} KB)`);
}

console.log('\nDone. Update SoundService paths from .mp3 to .wav.');
