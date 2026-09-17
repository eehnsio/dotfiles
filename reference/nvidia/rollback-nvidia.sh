#!/usr/bin/env bash
# Rulla tillbaka NVIDIA 615.71.09 -> 610.57.04.
#
# Varfor: 615 gav tva fel pa den har maskinen 2026-09-17.
#   1. 2560x1440 forsvann helt ur /sys/class/drm/card1-DP-1/modes (VG27AQM1A),
#      hogsta laget blev 1920x1080. 1440p@240 kraver DSC over DisplayPort.
#   2. Kernel-deadlock: nvidia-modeset/kthread_q lastes i D-lage pa en semafor,
#      och tog med sig systemd-logind. Da kan ingen logga in alls - SSH hanger i
#      [postauth] for pam_systemd vantar pa logind. Ingen skarm far signal.
#
# Kor med:  sudo bash ~/rollback-nvidia.sh
set -euo pipefail

C=/var/cache/pacman/pkg
P=(
  "$C/nvidia-utils-610.57.04-1-x86_64.pkg.tar.zst"
  "$C/lib32-nvidia-utils-610.57.04-1-x86_64.pkg.tar.zst"
  "$C/nvidia-open-dkms-610.57.04-1-x86_64.pkg.tar.zst"
  "$C/nvidia-settings-610.57.04-1-x86_64.pkg.tar.zst"
)

for f in "${P[@]}"; do
    [ -f "$f" ] || { echo "SAKNAS: $f"; exit 1; }
done

echo "== installerar 610 =="
pacman -U --noconfirm "${P[@]}"

echo "== pinnar dem sa nasta -Syu inte tar tillbaka 615 =="
if grep -q '^IgnorePkg' /etc/pacman.conf; then
    sed -i 's/^IgnorePkg\s*=\s*/IgnorePkg = nvidia-utils lib32-nvidia-utils nvidia-open-dkms nvidia-settings /' /etc/pacman.conf
else
    sed -i '/^\[options\]/a IgnorePkg = nvidia-utils lib32-nvidia-utils nvidia-open-dkms nvidia-settings' /etc/pacman.conf
fi
grep -n '^IgnorePkg' /etc/pacman.conf

echo "== dkms-lage =="
dkms status | grep nvidia || true

echo
echo "Klart. STARTA OM. Efter omstart, kontrollera bada felen:"
echo "    cat /sys/module/nvidia/version                          # ska vara 610.57.04"
echo "    grep -c 2560x1440 /sys/class/drm/card1-DP-1/modes       # ska vara >0"
echo "    ps -eo stat,comm | awk '\$1 ~ /D/'                      # ska vara tomt"
echo
echo "Nar 1440p ar tillbaka kan mode-raderna aterstallas:"
echo "    ~/.config/niri/local.kdl        (backup i scratchpad)"
echo "    /etc/nwg-hello/niri.kdl         (backup: .bak-modefix)"
echo
echo "Ta bort IgnorePkg-raden nar en nyare NVIDIA-version ar provad."
