# wireplumber

One thing only: the Elgato Wave XLR microphone fix. Linux only.

Files are taken from [jmansar/wavexlr-on-linux-cfg](https://github.com/jmansar/wavexlr-on-linux-cfg),
which also covers Wave 1, Wave 3 and the XLR Dock. They are vendored here rather
than linked so the fix survives without network access.

## The bug

**The Wave XLR stops sending microphone audio over USB if playback starts before
recording.** Start recording first and it works. It is a device-level fault,
reproducible from raw ALSA with neither PipeWire nor PulseAudio running, and it
has nothing to do with how Linux is configured.

Since Spotify, a game or a call will almost always start playing before you
speak, in practice the microphone is dead every session.

## Why it costs hours to find

Every signal points away from the real cause:

- **You hear yourself perfectly.** The Wave XLR monitors the mic to the headphone
  jack in hardware, never touching the computer. So the mic, the XLR cable and
  the preamp all demonstrably work.
- **Every OS-side value reads correct.** Right card, right profile, right port,
  gain up, nothing muted, stream `RUNNING`, no kernel errors, correct routing to
  the app.
- **`arecord -D hw:4,0` is not the bypass it looks like.** Going "direct to
  hardware" still fails, because PipeWire is holding the *playback* half of the
  same USB device — which is the exact condition that triggers the bug. That test
  reproduces the fault while appearing to rule it out.
- **It works intermittently.** Whenever the ordering happens to come out right,
  it works for a while, which sends you looking for something that changed.

## The one diagnostic that settles it

```bash
arecord -vv -f cd /dev/null
```

A meter that stays at `00%` **while you can hear yourself in the headphones**
means the device is not sending audio over USB. Nothing in the Linux audio stack
can cause that combination, so stop tuning gain and volumes — they are all
downstream of the problem.

## How the fix works

The config disables the auto-created Wave XLR playback sink. The Lua script then
links the microphone source to a hidden null sink — which keeps capture running
permanently — and only afterwards creates the playback sink. The device therefore
never sees playback start first.

Two consequences worth knowing:

- The sink is renamed to **`WaveXLR Sink`**. Any app storing a device name will
  need it re-selected once; Dota 2 lost its output and needed a restart.
- `Null Sink For WaveXLR Source - do not use` appears in the sink list. Ignore it.

## Sanity check

```bash
head -2 /proc/asound/card4/pcm0c/sub0/status   # should say RUNNING with nothing recording
```

Capture running while no app is recording is the fix doing its job. If it says
`Stop`, the script is not loaded.
