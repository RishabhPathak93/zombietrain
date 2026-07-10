#!/usr/bin/env python3
"""Synthesizes all placeholder audio for Zombie Train Escape (original, license-free)."""
import numpy as np, os, subprocess, math

SR = 22050
OUT = os.environ.get("AUDIO_OUT", os.path.join(os.path.dirname(__file__), "..", "assets", "audio"))
os.makedirs(os.path.join(OUT, "music"), exist_ok=True)
os.makedirs(os.path.join(OUT, "sfx"), exist_ok=True)
rng = np.random.default_rng(42)

def t(dur): return np.linspace(0, dur, int(SR*dur), endpoint=False)
def env(n, a, d, sustain=0.0, s_len=0.0, r=0.05):
    total = int(n)
    e = np.zeros(total)
    i = 0
    for seg_len, v0, v1 in [(int(a*SR),0,1),(int(d*SR),1,sustain),(int(s_len*SR),sustain,sustain),(int(r*SR),sustain,0)]:
        if i >= total: break
        L = min(seg_len, total-i)
        if L > 0:
            e[i:i+L] = np.linspace(v0, v1, L)
            i += L
    return e
def sine(f, dur): return np.sin(2*np.pi*f*t(dur))
def saw(f, dur): x = t(dur)*f; return 2*(x-np.floor(x+0.5))
def square(f, dur): return np.sign(sine(f,dur))
def noise(dur): return rng.uniform(-1,1,int(SR*dur))
def lowpass(x, alpha):
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += alpha*(x[i]-acc); y[i] = acc
    return y
def fade(x, ms=8):
    n = int(SR*ms/1000)
    x[:n] *= np.linspace(0,1,n); x[-n:] *= np.linspace(1,0,n)
    return x
def norm(x, level=0.85):
    m = np.max(np.abs(x)) or 1
    return x/m*level
def write(name, x, folder="sfx"):
    x = norm(np.asarray(x, dtype=np.float64))
    pcm = (x*32767).astype(np.int16)
    wav = os.path.join(OUT, folder, name+".wav")
    import wave
    with wave.open(wav, "w") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    ogg = wav[:-4]+".ogg"
    subprocess.run(["ffmpeg","-y","-loglevel","error","-i",wav,"-c:a","libvorbis","-q:a","3",ogg],check=True)
    os.remove(wav)
    print("wrote", os.path.basename(ogg))

def hz(midi): return 440*2**((midi-69)/12)

# ---------------- SFX ----------------
# pistol: sharp noise crack + low thump
n = int(SR*0.22)
x = noise(0.22)*env(n,0.001,0.05,0.2,0.05,0.1) + 0.9*sine(160,0.22)*env(n,0.001,0.12)
write("pistol", x)
# shotgun: bigger boom
n = int(SR*0.5)
x = lowpass(noise(0.5),0.35)*env(n,0.001,0.18,0.25,0.1,0.2)*1.4 + sine(90,0.5)*env(n,0.001,0.3)
write("shotgun", x)
# reload: two clicks + slide
c1 = noise(0.04)*env(int(SR*0.04),0.001,0.03)
gap = np.zeros(int(SR*0.12))
slide = lowpass(noise(0.15),0.5)*env(int(SR*0.15),0.02,0.1)
c2 = noise(0.05)*env(int(SR*0.05),0.001,0.04)*1.2
write("reload", np.concatenate([c1,gap,slide,gap*0.5,c2]))
# ui click
write("ui_click", (sine(880,0.06)+0.5*sine(1320,0.06))*env(int(SR*0.06),0.002,0.05))
# coin
x = np.concatenate([sine(hz(88),0.07)*env(int(SR*0.07),0.002,0.06), sine(hz(93),0.12)*env(int(SR*0.12),0.002,0.1)])
write("pickup_coin", x)
# item pickup (fuel/ammo): chunky confirm
x = np.concatenate([square(hz(60),0.08)*0.4*env(int(SR*0.08),0.002,0.07), square(hz(67),0.14)*0.4*env(int(SR*0.14),0.002,0.12)])
write("pickup_item", lowpass(x,0.4))
# heal
x = sum(sine(hz(m),0.5)*env(int(SR*0.5),0.02+i*0.08,0.35)*0.5 for i,m in enumerate([72,76,79]))
write("heal", x)
# hurt (player): short low grunt-ish
n = int(SR*0.18)
f = np.linspace(220,110,n)
x = np.sin(2*np.pi*np.cumsum(f)/SR)*env(n,0.005,0.15) + 0.3*noise(0.18)*env(n,0.005,0.1)
write("hurt", x)
# zombie growls: filtered noise + wobbly low tone
for i,(f0,dur) in enumerate([(85,0.7),(70,0.9),(95,0.6)]):
    n = int(SR*dur)
    wob = f0*(1+0.15*np.sin(2*np.pi*(3+i)*t(dur)))
    tone = np.sin(2*np.pi*np.cumsum(wob)/SR)
    x = (tone*0.7 + lowpass(noise(dur),0.15)*0.6)*env(n,0.08,dur*0.5,0.4,dur*0.2,0.2)
    write("zombie_growl%d"%(i+1), x)
# zombie hit: wet thud
n = int(SR*0.12)
write("zombie_hit", lowpass(noise(0.12),0.25)*env(n,0.001,0.1) + 0.6*sine(140,0.12)*env(n,0.001,0.09))
# zombie die: descending groan
n = int(SR*0.6)
f = np.linspace(120,45,n)
x = np.sin(2*np.pi*np.cumsum(f)/SR)*env(n,0.01,0.5,0.2,0.05) + 0.4*lowpass(noise(0.6),0.2)*env(n,0.01,0.4)
write("zombie_die", x)
# boss roar: big layered
n = int(SR*1.2)
f = np.linspace(70,50,n)
base = np.sin(2*np.pi*np.cumsum(f)/SR)
x = (base + 0.5*np.sin(2*np.pi*np.cumsum(f*1.98)/SR) + 0.8*lowpass(noise(1.2),0.12))*env(n,0.05,0.7,0.5,0.3,0.2)
write("boss_roar", x)
# slam: deep impact
n = int(SR*0.5)
f = np.linspace(120,35,n)
write("slam", np.sin(2*np.pi*np.cumsum(f)/SR)*env(n,0.001,0.4) + 0.5*lowpass(noise(0.5),0.3)*env(n,0.001,0.15))
# dash whoosh
n = int(SR*0.3)
write("dash", lowpass(noise(0.3),0.6)*env(n,0.08,0.2))
# crate break
n = int(SR*0.3)
write("crate", lowpass(noise(0.3),0.55)*env(n,0.002,0.25)*np.sin(2*np.pi*8*t(0.3)+1))
# cage open: metal creak + clang
n1 = int(SR*0.5)
f = 400*(1+0.3*np.sin(2*np.pi*2*t(0.5)))
creak = np.sin(2*np.pi*np.cumsum(f)/SR)*env(n1,0.05,0.4)*0.4
clang = (sine(520,0.4)+sine(780,0.4)*0.6+sine(1240,0.4)*0.3)*env(int(SR*0.4),0.002,0.35)
write("cage_open", np.concatenate([creak, clang]))
# train horn: two-tone chord
dur = 1.4; n = int(SR*dur)
x = (saw(hz(58),dur)*0.5+saw(hz(63),dur)*0.5)
write("train_horn", lowpass(x,0.25)*env(n,0.08,0.4,0.7,0.7,0.25))
# radio static + blip
dur = 1.2; n = int(SR*dur)
st = noise(dur)*0.35*env(n,0.05,0.3,0.5,0.6,0.25)
blip = np.zeros(n)
for st_i,f0 in [(0.25,900),(0.55,760),(0.85,1050)]:
    i0 = int(st_i*SR); seg = sine(f0,0.08)*env(int(SR*0.08),0.005,0.07)
    blip[i0:i0+len(seg)] += seg*0.6
write("radio", st+blip)
# heartbeat
b = sine(55,0.12)*env(int(SR*0.12),0.005,0.1)
gap1, gap2 = np.zeros(int(SR*0.14)), np.zeros(int(SR*0.5))
write("heartbeat", np.concatenate([b, gap1, b*0.7, gap2]))
# alert (wave incoming)
x = np.concatenate([square(hz(76),0.12)*0.4, np.zeros(int(SR*0.05)), square(hz(76),0.12)*0.4])
write("alert", lowpass(x,0.5)*np.concatenate([env(int(SR*0.12),0.005,0.1), np.zeros(int(SR*0.05)), env(int(SR*0.12),0.005,0.1)]))
# victory sting
seq = [(72,0.14),(76,0.14),(79,0.14),(84,0.4)]
x = np.concatenate([ (sine(hz(m),d)+0.4*sine(hz(m+12),d))*env(int(SR*d),0.01,d*0.8) for m,d in seq])
write("victory", x)
# defeat sting
seq = [(64,0.2),(60,0.2),(55,0.5)]
x = np.concatenate([ (saw(hz(m),d)*0.5)*env(int(SR*d),0.01,d*0.85) for m,d in seq])
write("defeat", lowpass(x,0.3))
# footstep
write("step", lowpass(noise(0.07),0.4)*env(int(SR*0.07),0.002,0.06)*0.5)

# ---------------- MUSIC ----------------
def music(name, bpm, bars, prog, lead_pattern, drum=True, tense=False):
    beat = 60/bpm
    total = bars*4*beat
    n = int(SR*total)
    x = np.zeros(n+SR)  # pad
    # pads/bass per bar
    for bar in range(bars):
        root = prog[bar % len(prog)]
        t0 = int(bar*4*beat*SR)
        dur = 4*beat
        nn = int(SR*dur)
        # bass pulse eighth notes
        for e8 in range(8):
            i0 = t0+int(e8*beat/2*SR)
            d8 = beat*0.45
            seg = lowpass(saw(hz(root-24),d8),0.25)*env(int(SR*d8),0.005,d8*0.7)*0.5
            x[i0:i0+len(seg)] += seg
        # pad chord (root, min3, 5th)
        for iv in (0,3,7):
            seg = sine(hz(root+iv),dur)*env(nn,dur*0.2,dur*0.5,0.5,dur*0.25,0.3)*0.12
            x[t0:t0+len(seg)] += seg
    # lead
    for i,(step, m, ln) in enumerate(lead_pattern):
        i0 = int(step*beat*SR)
        d = ln*beat
        if m is None: continue
        seg = (square(hz(m),d)*0.16+sine(hz(m),d)*0.2)*env(int(SR*d),0.01,d*0.7,0.3,d*0.15)
        seg = lowpass(seg, 0.5)
        x[i0:i0+len(seg)] += seg
    # drums
    if drum:
        for beat_i in range(bars*4):
            i0 = int(beat_i*beat*SR)
            kick = np.sin(2*np.pi*np.cumsum(np.linspace(110,40,int(SR*0.12)))/SR)*env(int(SR*0.12),0.002,0.1)*0.8
            x[i0:i0+len(kick)] += kick
            if beat_i % 2 == 1:
                sn = noise(0.08)*env(int(SR*0.08),0.002,0.07)*(0.5 if not tense else 0.65)
                x[i0:i0+len(sn)] += sn
            if tense:
                for h in (0.5,):
                    ih = i0+int(h*beat*SR)
                    hat = noise(0.03)*env(int(SR*0.03),0.001,0.025)*0.25
                    x[ih:ih+len(hat)] += hat
    x = x[:n]
    write(name, x, "music")

Am, C, Dm, Em, F, G = 57, 60, 62, 64, 65, 67
# menu: slow, moody
lead = [(0,69,1.5),(2,72,1),(4,71,1.5),(6,None,0),(8,69,1),(10,67,1),(12,64,3)]
music("music_menu", 72, 8, [Am, F, C, G], lead, drum=False)
# game: tense pulse
lead = [(0,76,0.5),(1,None,0),(2,76,0.5),(3,79,0.5),(4,77,0.5),(6,76,0.5),(8,74,1),(10,76,0.5),(12,72,1.5)]
music("music_game", 118, 8, [Am, Am, F, G], lead, drum=True, tense=True)
# boss: faster, driving
lead = [(0,81,0.5),(1,80,0.5),(2,81,0.5),(3,84,0.5),(4,81,0.5),(5,80,0.5),(6,77,1),(8,81,0.5),(9,80,0.5),(10,81,0.5),(11,84,0.5),(12,86,1.5)]
music("music_boss", 140, 8, [Am, F, Em, G], lead, drum=True, tense=True)
print("ALL AUDIO DONE")
