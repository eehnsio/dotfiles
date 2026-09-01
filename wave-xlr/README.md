# wave-xlr

Elgato Wave XLR: the daemon unit, plus a watchdog for the failure mode that
openwave cannot see.

## The failure

The Wave XLR is a UAC1 device whose capture and playback endpoints share one
isochronous clock. When playback is opened before capture, the microphone stops
converting — but it keeps *sending*, at full rate, nothing but zeros.

Every signal on the OS side stays green. The stream is `RUNNING`, the byte flow
is perfect, nothing is logged. You find out when someone tells you they cannot
hear you.

`openwave` holds a permanent capture stream open to prevent this, and watches it
for a stall. That watchdog looks for **absent byte flow** — it logs `wedged (3.0s
without data)` and recycles the stream. It is structurally blind to this one:
the flow never stops.

## The watchdog

`wave-xlr-watchdog` measures **amplitude** instead. An analog input never
produces exact zeros; even a silent room has a noise floor on every sample. An
unbroken run of zeros means the device stopped converting, not that the room
went quiet. Measured on a healthy device: 97–99 % of samples are non-zero.

The one legitimate source of exact zeros is the mute plate — and it does **not**
show up in ALSA. `numid=5` (`Mic Capture Switch`) stays `on` while the plate is
held down; measured, not assumed. The mute state is therefore read from firmware
over the same libusb path openwave uses, which `99-openwave.rules` already
grants access to.

So the rule is: zeros for 15 s **and** not muted → the device has quit.

## Recovery

A ladder, measuring after each step, stopping as soon as sound returns:

1. **Restart openwave.** Its keepalive recycles the capture stream. Inaudible.
2. **Bounce the card profile** — `off`, then capture-only, then open the capture
   stream, and only then restore the duplex profile. This is the boot ordering
   reproduced by hand: capture before playback.
3. **Restart the whole PipeWire graph**, in that same order.

Step 3 silences every application for a few seconds, which is why it is last.
It is also the only step proven to clear the worst case: a **leaked PipeWire
device** holding both PCMs open. The tell is a playback PCM that is `RUNNING`
while the card sits in a profile that has no sink at all:

```bash
cat /proc/asound/card4/pcm0p/sub0/status   # state: RUNNING
pactl list cards | grep 'Active Profile'   # input:mono-fallback
```

`owner_pid` then points at `pipewire` itself. Neither profile changes nor
`systemctl --user restart wireplumber` reach an object wireplumber no longer
manages — and a `usbreset` does not stick either, because the leak reopens the
device before anything can record from it.

Set `WAVE_XLR_MAX_LEVEL=2` in the unit to stop before step 3.

## Enable

```bash
systemctl --user daemon-reload
systemctl --user enable --now openwave.service wave-xlr-watchdog.service
```

`--dry-run` logs the ladder without touching anything, which is the way to watch
it think:

```bash
systemctl --user stop wave-xlr-watchdog
~/.local/bin/wave-xlr-watchdog --dry-run --verbose
```

## Measuring by hand

Target the node **id**, never the name. After profile switches and USB resets
several nodes can carry the same name, and a recording aimed at the name may
bind to a stale one that emits zeros far faster than realtime — a perfect
disguise for the very fault you are looking for. Compare the sample count
against the wall clock before calling anything silent.

```bash
id=$(pactl list sources short | grep -i 'Elgato.*Wave' | grep -v monitor | tail -1 | cut -f1)
pw-record --target "$id" --rate 48000 --channels 1 --format s16 - > /tmp/m.raw
```

## Not a replacement for openwave

openwave keeps the capture stream pinned and syncs the firmware controls; this
package only watches for the silent failure and repairs it. They do different
jobs. The device background is in [reference/wave-xlr](../reference/wave-xlr/).
