"""Makes the boss fight music of the boss hall: a heavy rock loop (drums, distorted power chords,
bass) in E minor, 168 BPM, 16 bars, as a 16 bit mono WAV that loops without a gap.

    py assets/_reference/music/make_boss_rock.py

Writes res://assets/audio/music/boss_rock_01.wav (data/audio.json music "boss_rock").
Plain Python (no numpy), takes about half a minute. A real recorded track can replace it at any
time: just point "boss_rock" in data/audio.json to another file.
"""

import math
import os
import random
import struct
import wave

RATE = 32000
BPM = 168
BEAT = 60.0 / BPM
STEP = BEAT / 4.0          # one 16th note
BARS = 16
STEPS = BARS * 16
LENGTH = int(STEPS * STEP * RATE)

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "audio", "music", "boss_rock_01.wav")

random.seed(7)
mix = [0.0] * LENGTH


def note_hz(semitones_from_e2: int) -> float:
    return 82.41 * 2.0 ** (semitones_from_e2 / 12.0)


def add(start: float, samples: list[float], gain: float) -> None:
    first = int(start * RATE)
    for i, value in enumerate(samples):
        j = first + i
        if j >= LENGTH:
            j -= LENGTH  # wraps around: the loop stays seamless
        mix[j] += value * gain


# --- Drums -------------------------------------------------------------------------------

def kick() -> list[float]:
    out, phase = [], 0.0
    n = int(0.22 * RATE)
    for i in range(n):
        t = i / RATE
        freq = 48.0 + 110.0 * math.exp(-t * 32.0)
        phase += freq / RATE
        click = (random.uniform(-1, 1) * math.exp(-t * 300.0)) * 0.4
        out.append(math.sin(phase * math.tau) * math.exp(-t * 14.0) + click)
    return out


def snare() -> list[float]:
    out, phase, low = [], 0.0, 0.0
    n = int(0.2 * RATE)
    for i in range(n):
        t = i / RATE
        phase += 190.0 / RATE
        noise = random.uniform(-1, 1)
        low += (noise - low) * 0.45
        body = math.sin(phase * math.tau) * math.exp(-t * 30.0) * 0.6
        out.append(body + low * math.exp(-t * 16.0) * 0.9)
    return out


def hat(open_hat: bool) -> list[float]:
    out, last = [], 0.0
    n = int((0.16 if open_hat else 0.05) * RATE)
    for i in range(n):
        t = i / RATE
        noise = random.uniform(-1, 1)
        high = noise - last  # crude high pass: only the hiss
        last = noise
        out.append(high * math.exp(-t * (18.0 if open_hat else 70.0)))
    return out


def crash() -> list[float]:
    out, last = [], 0.0
    n = int(1.6 * RATE)
    for i in range(n):
        t = i / RATE
        noise = random.uniform(-1, 1)
        high = noise - last * 0.6
        last = noise
        out.append(high * math.exp(-t * 2.6))
    return out


KICK, SNARE, HAT, OPEN_HAT, CRASH = kick(), snare(), hat(False), hat(True), crash()


# --- Guitar and bass -----------------------------------------------------------------------

def power_chord(root: int, length: float, muted: bool) -> list[float]:
    """Root, fifth and octave from detuned saws, driven hard into a soft clipper."""
    freqs = [note_hz(root), note_hz(root + 7), note_hz(root + 12)]
    detune = [1.0, 1.006, 0.995]
    phases = [random.random() for _ in range(len(freqs) * len(detune))]
    n = int(length * RATE)
    out, low = [], 0.0
    decay = 26.0 if muted else 1.3
    cut = 0.22 if muted else 0.5
    for i in range(n):
        t = i / RATE
        value, k = 0.0, 0
        for f in freqs:
            for d in detune:
                phases[k] = (phases[k] + f * d / RATE) % 1.0
                value += phases[k] * 2.0 - 1.0
                k += 1
        value /= len(phases)
        driven = math.tanh(value * 9.0)
        low += (driven - low) * cut  # one-pole low pass takes off the fizz
        env = math.exp(-t * decay) if muted else min(1.0, t * 200.0) * (0.55 + 0.45 * math.exp(-t * decay))
        if i > n - 200:
            env *= (n - i) / 200.0
        out.append(low * env)
    return out


def bass(root: int, length: float) -> list[float]:
    f = note_hz(root) / 2.0
    n = int(length * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        phase = (phase + f / RATE) % 1.0
        tone = math.sin(phase * math.tau) * 0.8 + (1.0 if phase < 0.5 else -1.0) * 0.25
        env = min(1.0, t * 300.0) * math.exp(-t * 3.0)
        if i > n - 150:
            env *= (n - i) / 150.0
        out.append(tone * env)
    return out


# Riff: per bar 16 steps. A number = chord on that root (semitones over E2), "m" = palm muted chug
# on E, "." = rest. Long chords ring until the next hit.
RIFF_A = ["m", "m", ".", "m", "m", ".", "m", ".", 3, ".", "m", "m", 5, ".", 6, 5]
RIFF_B = ["m", "m", ".", "m", "m", ".", "m", ".", 3, ".", "m", "m", 10, ".", 8, 7]
RIFF_C = [8, ".", ".", "m", "m", ".", 8, ".", 10, ".", ".", "m", "m", ".", 10, "."]
RIFF_D = [12, ".", ".", "m", "m", ".", 12, ".", 10, ".", 8, ".", 7, ".", 5, 3]
SONG = [RIFF_A, RIFF_B, RIFF_A, RIFF_B, RIFF_C, RIFF_D, RIFF_C, RIFF_D,
        RIFF_A, RIFF_B, RIFF_A, RIFF_B, RIFF_C, RIFF_D, RIFF_C, RIFF_D]


def ring_length(bar: list, step: int) -> int:
    length = 1
    while step + length < 16 and bar[step + length] == ".":
        length += 1
    return length


for bar_index, bar in enumerate(SONG):
    bar_start = bar_index * 16 * STEP
    for step, hit in enumerate(bar):
        if hit == ".":
            continue
        start = bar_start + step * STEP
        if hit == "m":
            add(start, power_chord(0, STEP * 0.95, True), 0.55)
            add(start, bass(0, STEP * 0.9), 0.5)
        else:
            steps = ring_length(bar, step)
            add(start, power_chord(int(hit), steps * STEP * 0.98, False), 0.5)
            add(start, bass(int(hit), steps * STEP * 0.95), 0.5)

# Drums: kick on 1 and 3 (and the gallop in the second half), snare on 2 and 4, hats in 8ths,
# a crash every 4 bars, a snare fill at the end of every 8 bars.
for bar_index in range(BARS):
    bar_start = bar_index * 16 * STEP
    heavy = (bar_index // 4) % 2 == 1
    for step in range(16):
        start = bar_start + step * STEP
        if heavy and step % 2 == 0:
            add(start, KICK, 0.9)
        elif not heavy and step in (0, 3, 8, 10):
            add(start, KICK, 0.95)
        if step in (4, 12):
            add(start, SNARE, 0.85)
        if step % 2 == 0:
            add(start, OPEN_HAT if step == 14 and heavy else HAT, 0.22)
    if bar_index % 4 == 0:
        add(bar_start, CRASH, 0.3)
    if bar_index % 8 == 7:
        for step in (13, 14, 15):
            add(bar_start + step * STEP, SNARE, 0.6 + step * 0.02)

peak = max(abs(v) for v in mix) or 1.0
with wave.open(OUT, "wb") as file:
    file.setnchannels(1)
    file.setsampwidth(2)
    file.setframerate(RATE)
    frames = bytearray()
    for v in mix:
        # Soft limit, then 90 % of full scale.
        s = math.tanh(v / peak * 1.4) / math.tanh(1.4) * 0.9
        frames += struct.pack("<h", int(s * 32767))
    file.writeframes(bytes(frames))
print("written", os.path.normpath(OUT), "%.1f s" % (LENGTH / RATE))
