# Meletrix Zoom75 (wireless)

75% wireless/tri-mode board, configured with [VIA](https://usevia.app).

## Files

- `zoom75_wireless_rgb-via-v33.json` — VIA definition. Required: the wireless
  model is **not** in VIA's built-in list.

## Why the JSON is needed

The board reports `1EA7:CED3`, but the public definitions in
[the-via/keyboards](https://github.com/the-via/keyboards) are for other models:

| Definition | vendorId | productId |
|---|---|---|
| `meletrix/zoom75` | `0x806D` | `0x0006` |
| `ubest/vn` | `0x6D66` | `0x0868` |
| **this board** | **`0x1EA7`** | **`0xCED3`** |

So VIA sits on "Searching for devices" forever until the definition is loaded
by hand. Source: <https://meletrix.com/pages/firmwares>.

## Loading it

1. VIA → gear icon → enable **Show Design tab**
2. **Design** tab → load `zoom75_wireless_rgb-via-v33.json`
3. Back to **Configure** — the board appears

## Notes

- **Vial does not work.** The firmware answers `0xff` (unsupported) to Vial's
  keyboard-id command. It speaks plain VIA, protocol version 11.
- VIA reaches the board **over the 2.4 GHz dongle** — no cable needed. It
  exposes three HID interfaces; `usage page 0xFF60` is the VIA one.
- Linux needs hidraw access. See `/etc/udev/rules.d/92-viakeyboard.rules`:
  `SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1ea7", ATTRS{idProduct}=="ced3", TAG+="uaccess", MODE="0660", GROUP="input"`
- The key next to the knob toggles RGB but shows as unbound in VIA — that
  function lives in the wireless MCU, outside the QMK keymap.
