# Elgato Wave XLR

Not a stow package. The fix that used to live here was replaced by
[openwave](https://github.com/rikkichy/openwave), installed from the AUR as
`openwave`. This file is the reasoning, kept because the failure modes are
expensive to rediscover.

## The device

USB Audio Class 1, `0fd9:007d`, full speed. Firmware 1.34 as of 2026-08-31.
Five interfaces: three standard audio (`snd-usb-audio`), one vendor-specific
(`ff/f0`, what Wave Link talks to), one DFU.

**Capture and playback share a single isochronous clock.** That one fact
explains every symptom below. Anything that tears down or renegotiates the
stream takes both directions with it.

## Two distinct failure modes

**Wedged.** The stream stays open and reports `RUNNING`, but no data flows.
`hw_ptr` stops advancing. The kernel logs nothing at all. Recovered by
recycling the capture stream, or by USB re-enumeration.

**Silent.** The stream runs, bytes arrive at the full rate, every sample is
zero. Nothing looks wrong from outside. Neither recycling nor re-enumeration
clears it — only a power cycle.

They look identical from the application's side: the microphone is dead. They
are not the same fault and do not have the same remedy.

## The diagnostic

Resolve the card by USB id rather than number — the number moves on
re-enumeration:

```sh
card=$(for f in /proc/asound/card*/usbid; do
    [ "$(cat "$f")" = "0fd9:007d" ] && dirname "$f"
done)

grep hw_ptr "$card/pcm0c/sub0/status"; sleep 2
grep hw_ptr "$card/pcm0c/sub0/status"
```

A healthy capture advances 96000 per second at 48 kHz mono. Two identical
readings while `state:` says `RUNNING` is the wedged state.

Compare against playback (`pcm0p`) in the same moment. Playback advancing while
capture is frozen is what rules out the whole Linux audio stack: nothing above
the device can stop one direction and not the other.

## Measured 2026-08-31

Capture opened 18 s after boot, ran 28 hours, then froze. `hw_ptr` stuck at
4882443120 across repeated reads. Playback on the same device advanced 96096
samples in 2 s. No kernel messages. `usbreset 0fd9:007d` recovered it without a
reboot.

Ruled out in the process: USB autosuspend (`power/control` was `on`,
`runtime_suspended_time` 0), application start order, and the WirePlumber fix
releasing the stream (state stayed `RUNNING` throughout).

## Why the old fix was replaced

The previous approach came from
[jmansar/wavexlr-on-linux-cfg](https://github.com/jmansar/wavexlr-on-linux-cfg):
disable the auto-created sink, rename the source, and run a Lua script that
links the microphone to a hidden null sink so capture always starts before
playback. It treated the fault as an **ordering** problem.

openwave treats it as a **renegotiation** problem, which is the better model —
it explains both failure modes with one mechanism. It touches no nodes at all
and instead sets three properties on the ones already there:

```
session.suspend-timeout-seconds = 0   # never auto-suspend on idle
node.pause-on-idle              = false
audio.rate                      = 48000   # the device never changes rate
```

`audio.rate` was missing from the old fix entirely. An application opening the
device at another rate forces the shared clock to renegotiate, which is one of
the documented triggers for the wedged state.

A daemon then holds a `pw-cat --record` pin and watches its byte flow. No bytes
for 3 s means wedged, and it recycles the stream — recovery in under 4 seconds,
without re-enumerating, so client nodes survive.

An interim local change to the old script set `pause-on-idle = true` and
`suspend-timeout = 5` on the theory that holding playback open fed the device
hours of silence. It was active when the device hung on 2026-08-31, so the
theory is disproven — and it was the exact opposite of what openwave prescribes.

## Still open

Firmware 1.34 with a DFU interface exposed. Whether Elgato has published
anything newer, and whether it can be flashed from Linux with `dfu-util`, is the
only remaining path to a real fix rather than a workaround.
