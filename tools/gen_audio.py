#!/usr/bin/env python3
"""Generate all sound effects and a looping music track as 16-bit mono WAVs.

Pure standard library (wave/struct/math) - no external deps. Chiptune-ish blips
built from sine/square/triangle/noise oscillators with simple envelopes.

Run:  python3 tools/gen_audio.py
Output: new-game-project/assets/sfx/*.wav  and  assets/music.wav
"""
import os
import wave
import struct
import math
import random

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(HERE, "..", "new-game-project", "assets"))
SFX = os.path.join(ASSETS, "sfx")
os.makedirs(SFX, exist_ok=True)

SR = 22050


def write_wav(path, samples):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s)) * 32000)
            frames += struct.pack("<h", v)
        w.writeframes(frames)


def osc(phase, kind):
    if kind == "sine":
        return math.sin(phase)
    if kind == "square":
        return 1.0 if math.sin(phase) >= 0 else -1.0
    if kind == "tri":
        return 2.0 / math.pi * math.asin(math.sin(phase))
    if kind == "saw":
        t = (phase / (2 * math.pi)) % 1.0
        return 2.0 * t - 1.0
    return 0.0


def tone(freq0, freq1, dur, kind="square", vol=0.5, decay=True, vibrato=0.0):
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq0 + (freq1 - freq0) * t
        if vibrato:
            f *= 1.0 + math.sin(i / SR * vibrato * 2 * math.pi) * 0.02
        phase += 2 * math.pi * f / SR
        env = (1.0 - t) if decay else 1.0
        # short attack to avoid clicks
        if i < 60:
            env *= i / 60.0
        out.append(osc(phase, kind) * vol * env)
    return out


def noise(dur, vol=0.5, decay=True, lp=0.0):
    n = int(dur * SR)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / n
        raw = random.uniform(-1, 1)
        if lp:
            prev += (raw - prev) * lp
            raw = prev
        env = (1.0 - t) if decay else 1.0
        if i < 40:
            env *= i / 40.0
        out.append(raw * vol * env)
    return out


def mix(*layers):
    m = max(len(l) for l in layers)
    out = [0.0] * m
    for l in layers:
        for i, s in enumerate(l):
            out[i] += s
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def note(name, octave):
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
             "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    n = names[name] + (octave - 4) * 12
    return 440.0 * (2 ** ((n - 9) / 12.0))


def build_sfx():
    random.seed(7)
    # shoot: quick descending square blip + tick of noise
    write_wav(os.path.join(SFX, "shoot.wav"),
              mix(tone(660, 220, 0.09, "square", 0.35),
                  noise(0.04, 0.15, lp=0.5)))
    # hit (bullet lands on enemy): tight high noise tick
    write_wav(os.path.join(SFX, "hit.wav"),
              mix(noise(0.06, 0.3, lp=0.7), tone(880, 500, 0.05, "square", 0.15)))
    # hurt (player takes damage): low buzzy hit
    write_wav(os.path.join(SFX, "hurt.wav"),
              mix(tone(300, 90, 0.22, "saw", 0.4), noise(0.12, 0.25, lp=0.3)))
    # enemy die: falling tone + noise burst
    write_wav(os.path.join(SFX, "die.wav"),
              mix(tone(440, 80, 0.25, "square", 0.35), noise(0.18, 0.3, lp=0.4)))
    # coin: two bright ascending sine blips
    write_wav(os.path.join(SFX, "coin.wav"),
              seq(tone(880, 880, 0.05, "sine", 0.35),
                  tone(1320, 1320, 0.08, "sine", 0.35)))
    # heart: gentle rising triad
    write_wav(os.path.join(SFX, "heart.wav"),
              seq(tone(note("C", 5), note("C", 5), 0.06, "tri", 0.3),
                  tone(note("E", 5), note("E", 5), 0.06, "tri", 0.3),
                  tone(note("G", 5), note("G", 5), 0.12, "tri", 0.3)))
    # upgrade: triumphant arpeggio up
    write_wav(os.path.join(SFX, "upgrade.wav"),
              seq(tone(note("C", 5), note("C", 5), 0.06, "square", 0.3),
                  tone(note("E", 5), note("E", 5), 0.06, "square", 0.3),
                  tone(note("G", 5), note("G", 5), 0.06, "square", 0.3),
                  tone(note("C", 6), note("C", 6), 0.16, "square", 0.32)))
    # wave: brassy chord swell
    write_wav(os.path.join(SFX, "wave.wav"),
              mix(tone(note("C", 4), note("C", 4), 0.4, "saw", 0.22),
                  tone(note("G", 4), note("G", 4), 0.4, "saw", 0.18),
                  tone(note("E", 5), note("E", 5), 0.4, "square", 0.16, vibrato=6)))
    # dash: quick whoosh (filtered noise sweep)
    dash = noise(0.18, 0.35, lp=0.15)
    write_wav(os.path.join(SFX, "dash.wav"), dash)
    # game over: sad descending tones
    write_wav(os.path.join(SFX, "gameover.wav"),
              seq(tone(note("G", 4), note("G", 4), 0.18, "tri", 0.3),
                  tone(note("E", 4), note("E", 4), 0.18, "tri", 0.3),
                  tone(note("C", 4), note("C", 4), 0.18, "tri", 0.3),
                  tone(note("G", 3), note("G", 3), 0.45, "tri", 0.32)))
    # click (UI)
    write_wav(os.path.join(SFX, "click.wav"), tone(900, 600, 0.05, "square", 0.25))


def build_music():
    """A short, low, loopable dungeon groove: bass + arp over a i-VI-III-VII minor
    progression in A minor. Kept quiet; the Audio bus lowers it further."""
    random.seed(3)
    bpm = 108
    beat = 60.0 / bpm
    step = beat / 2.0  # eighth notes
    # chord roots for 4 bars (A minor feel)
    roots = ["A", "F", "C", "G"]
    arp_pat = [0, 3, 7, 12, 7, 3, 7, 3]  # semitone offsets from root
    track = []
    for root in roots:
        base = note(root, 2)
        bar = []
        # bass: root note held, plucked each beat
        bass_layer = []
        for b in range(4):
            bass_layer.extend(tone(base, base, beat, "tri", 0.16))
        # arp: eighth notes
        arp_layer = []
        rn = note(root, 4)
        for s in range(8):
            f = rn * (2 ** (arp_pat[s] / 12.0))
            arp_layer.extend(tone(f, f, step, "square", 0.09, decay=True))
        bar = mix(bass_layer, arp_layer)
        track.extend(bar)
    write_wav(os.path.join(ASSETS, "music.wav"), track)


def main():
    build_sfx()
    build_music()
    print("Generated audio in", SFX, "and music.wav")
    for f in sorted(os.listdir(SFX)):
        print("  sfx/" + f)
    print("  music.wav")


if __name__ == "__main__":
    main()
