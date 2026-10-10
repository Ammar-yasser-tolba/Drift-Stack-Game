"""Generates the three SFX files the game needs. Run from the project root:
    python3 tools/generate_sounds.py
Output: assets/sounds/tap.wav, perfect.wav, over.wav  (mono, 16-bit, 44.1 kHz)
"""
import math
import os
import struct
import wave

RATE = 44100


def tone(freq_fn, duration, volume=0.5, attack=0.005):
    n = int(RATE * duration)
    phase = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        p = t / duration
        phase += 2 * math.pi * freq_fn(p) / RATE
        env = min(1.0, t / attack) * math.exp(-4.0 * p)
        out.append(volume * env * (math.sin(phase) + 0.3 * math.sin(2 * phase)))
    return out


def write(name, samples):
    os.makedirs("assets/sounds", exist_ok=True)
    with wave.open(f"assets/sounds/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples
            )
        )


write("tap", tone(lambda p: 520.0, 0.08, 0.55))
write("perfect", tone(lambda p: 660.0 + 660.0 * p, 0.22, 0.5))
write("over", tone(lambda p: 300.0 - 200.0 * p, 0.45, 0.6))
print("Done: assets/sounds/tap.wav, perfect.wav, over.wav")
