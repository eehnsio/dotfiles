# NVIDIA: pinnad på 610.57.04

Four packages are held back in `/etc/pacman.conf`:

```
IgnorePkg = nvidia-utils lib32-nvidia-utils nvidia-open-dkms nvidia-settings
```

This is deliberate, and it is not a matter of taste. **615.71.09 cannot drive the
main monitor on this machine.** Every `pacman -Syu` will now warn that NVIDIA is
being skipped — that is the reminder working, not a problem.

Hardware: RTX 4070 SUPER, `nvidia-open-dkms`. Monitors on the GPU (`card1`):
VG27AQM1A 2560x1440@240 with VRR on DP-1, VG259 1920x1080@143 portrait on DP-2.

## What 615.71.09 did, 2026-09-17

Two separate faults in one evening. Both are upstream regressions with matching
reports, not local misconfiguration.

**1. DisplayPort output with no signal.** DP-1 reported `connected`, `enabled`
and `dpms=On` in DRM, EDID parsed, and all five 2560x1440 modes were advertised —
but the panel never locked on. DP-2 at 1080p@143 without VRR was unaffected, which
is why it first looked like a resolution or refresh-rate problem. It is not: the
modes are offered and simply produce no output.

The kernel logged this at every modeset:

```
WARNING: nvidia-drm/nvidia-drm-crtc.h:368 at __nv_drm_handle_flip_event+0x1f8/0x210
         [nvidia_drm]  Comm: nvidia-modeset/  Tainted: G OE
```

**2. A driver deadlock that stopped all logins.** Running a second compositor on
another VT while the greeter held the first one wedged the driver outright:

```
nvidia-modeset/:282   blocked 368s on a semaphore held by kworker/2:1
kworker/7:1:168       blocked 368s on a mutex held by the same kworker
systemd-logind:605    blocked on a mutex held by the same kworker
```

A `D`-state kernel thread cannot be killed. With logind wedged **nothing can log
in at all** — SSH authenticates and then hangs in `[postauth]`, because
`pam_systemd` never returns. In that state `2560x1440` also vanished from
`/sys/class/drm/card1-DP-1/modes` entirely, which looked like a separate driver
regression and was not: a clean reboot brought both the mode list and logind back.

The one command that tells these apart from a config problem:

```bash
ps -eo pid,stat,comm | awk '$2 ~ /D/'     # anything here means reboot, not config
```

## Upstream

- [open-gpu-kernel-modules#1357](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1357)
  — *"615.71.09: DisplayPort output produces no signal, 610.57.04 works"*. DSC
  modes advertised, EDID fine, no output; reverting to 610.57.04 fixes it
  immediately. Same two version numbers as here. **This is the one to watch.**
- [open-gpu-kernel-modules#1361](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1361)
  — the `WARN_ON(nv_flip == NULL)` at **`nvidia-drm-crtc.h:368`**, the exact line
  from the log above. A blocking atomic commit waits 3 s per head for a
  flip-complete that never arrives once planes are torn down.
- [Arch forums](https://bbs.archlinux.org/viewtopic.php?pid=2309466#p2309466) —
  615.71.09-1 leaves `plasma-login-manager` and `gdm` unable to load, black screen
  on Wayland while Xorg works. A greeter that will not come up is the same class
  of failure.
- [NVIDIA forums](https://forums.developer.nvidia.com/t/615-71-09-regression-displayport-link-never-re-established-after-monitor-dpms-sleep-connector-marked-zombie-flush-mode-fails-no-signal-until-phy/383236)
  — on 615.71.09 the DP link is never re-established after DPMS sleep.

## Rolling back, if it is ever needed again

The 610 packages came out of `/var/cache/pacman/pkg`, so this only works while
the cache still holds them. `rollback-nvidia.sh` in this directory does it:
installs the four packages, adds the `IgnorePkg` line, prints DKMS status.

```bash
sudo bash reference/nvidia/rollback-nvidia.sh
sudo reboot
```

Verify afterwards:

```bash
cat /sys/module/nvidia/version                     # 610.57.04
ps -eo stat,comm | awk '$1 ~ /D/'                  # empty
journalctl -k -b | grep -i nv_drm_handle_flip      # empty
```

## When to unpin

Watch issue #1357. When it closes, or when a version later than 615.71.09 reaches
`extra`, drop the `IgnorePkg` line and try again — **on an evening when there is
time to debug**, not a quarter of an hour before a game.

One experiment is worth running first if you do. There are
[reports](https://forums.developer.nvidia.com/t/screen-goes-black-for-a-few-seconds-when-alt-tabbing-out-of-games-with-vrr-at-240hz-on-wayland/314590)
that VRR at 240 Hz causes black screens and that turning VRR off resolves them.
DP-1 has `variable-refresh-rate` set in `niri/.config/niri/local.kdl`. Remove that
line before installing the newer driver — if the screen then lights up, the bug
is narrower than "615 is broken" and VRR is the real cost.

## Related

The greeter's config carries the other half of this lesson: a hardcoded `mode`
turns a driver fault into a black screen with no way in, because niri leaves an
output dark rather than falling back. See `reference/greetd/README.md`.
