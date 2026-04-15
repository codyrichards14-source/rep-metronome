#!/usr/bin/env python3
"""
Generates all Rep Metro audio cues using OpenAI TTS.
Run once: python3 generate_cues.py YOUR_OPENAI_API_KEY
Then drag the AudioCues/ folder into your Xcode project.
"""

import requests
import os
import sys
import time

API_KEY  = sys.argv[1] if len(sys.argv) > 1 else input("OpenAI API Key: ").strip()
MODEL    = "tts-1-hd"
VOICE    = "onyx"       # deep, authoritative — good for coaching
OUT_DIR  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "AudioCues")

os.makedirs(OUT_DIR, exist_ok=True)
generated = 0
skipped   = 0

def generate(filename, text):
    global generated, skipped
    path = os.path.join(OUT_DIR, f"{filename}.mp3")
    if os.path.exists(path):
        print(f"  skip  {filename}")
        skipped += 1
        return
    r = requests.post(
        "https://api.openai.com/v1/audio/speech",
        headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
        json={"model": MODEL, "input": text, "voice": VOICE, "response_format": "mp3"},
        timeout=15
    )
    if r.status_code == 200:
        with open(path, "wb") as f:
            f.write(r.content)
        print(f"  ✓  {filename}  →  {text}")
        generated += 1
    else:
        print(f"  ✗  {filename}  →  {r.status_code}: {r.text[:120]}")
    time.sleep(0.1)

print("\n── Down / Up cues ──")
generate("down", "Down.")
generate("up", "Up.")

print("\n── Rep complete number cues ──")
for i in range(1, 31):
    generate(f"rep_{i}", f"{i}.")

print("\n── Set start cues ──")
for i in range(1, 21):
    generate(f"set_go_{i}", f"Set {i}. Let's go.")

print("\n── Set done cues ──")
for i in range(1, 20):
    generate(f"set_done_{i}", f"Set {i} done. Take your rest.")

print("\n── Workout complete cues ──")
for i in range(1, 21):
    sets_word = "set" if i == 1 else "sets"
    generate(f"complete_{i}", f"That's a wrap. {i} {sets_word} done. Great work today.")

print("\n── Fixed cues ──")
generate("ten_seconds", "Ten seconds remaining.")
generate("countdown",   "Three. Two. One.")

print("\n── Rest cues ──")
for secs in [15, 30, 45, 60, 75, 90, 120, 150, 180, 240, 300]:
    generate(f"rest_{secs}", f"Good work. Rest for {secs} seconds.")

print(f"\n✓ Done — {generated} generated, {skipped} skipped")
print(f"Files saved to: {OUT_DIR}")
print("\nNext: drag the AudioCues/ folder into Xcode (add to target).")
