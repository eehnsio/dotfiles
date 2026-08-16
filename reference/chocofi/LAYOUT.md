# Chocofi Keymap

## Layer 0 — Base (QWERTY)

```
┌─────┬─────┬─────┬─────┬─────┐       ┌─────┬─────┬─────┬─────┬─────┐
│  Q  │  W  │  E  │  R  │  T  │       │  Y  │  U  │  I  │  O  │  P  │
├─────┼─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┼─────┤
│  A  │  S  │  D  │  F  │  G  │       │  H  │  J  │  K  │  L  │  ;  │
├─────┼─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┼─────┤
│  Z  │  X  │  C  │  V  │  B  │       │  N  │  M  │  ,  │  .  │  /  │
└─────┴─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┴─────┘
            │BSPC │ TAB │ SPC │       │ ENT │ ESC │ DEL │
            └─────┴─────┴─────┘       └─────┴─────┴─────┘
```

Planned home row mods (not yet configured):

```
A = LGUI_T(KC_A)    — hold = Cmd      tap = A
S = LALT_T(KC_S)    — hold = Alt      tap = S
D = LCTL_T(KC_D)    — hold = Ctrl     tap = D
F = LSFT_T(KC_F)    — hold = Shift    tap = F

J = RSFT_T(KC_J)    — hold = Shift    tap = J
K = RCTL_T(KC_K)    — hold = Ctrl     tap = K
L = RALT_T(KC_L)    — hold = Alt      tap = L
; = RGUI_T(KC_SCLN) — hold = Cmd      tap = ;
```

Thumb keys (planned):

```
Left:  BSPC, LT(1, KC_TAB), SPC     — TAB held = activate Layer 1
Right: ENT, LT(2, KC_ESC), DEL      — ESC held = activate Layer 2
```

## Layer 1 — Numbers & Navigation (hold left thumb middle)

```
┌─────┬─────┬─────┬─────┬─────┐       ┌─────┬─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │  5  │       │  6  │  7  │  8  │  9  │  0  │
├─────┼─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┼─────┤
│HOME │     │ UP  │ END │PgUp │       │  -  │  =  │  [  │  ]  │  '  │
├─────┼─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┼─────┤
│     │LEFT │DOWN │RGHT │PgDn │       │  _  │  +  │  {  │  }  │  \  │
└─────┴─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┴─────┘
            │     │ === │     │       │     │     │     │
            └─────┴─────┴─────┘       └─────┴─────┴─────┘
```

`===` = layer activation key (held)

## Layer 2 — Symbols & F-keys (hold right thumb middle)

```
┌─────┬─────┬─────┬─────┬─────┐       ┌─────┬─────┬─────┬─────┬─────┐
│ F1  │ F2  │ F3  │ F4  │ F5  │       │ F6  │ F7  │ F8  │ F9  │ F10 │
├─────┼─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┼─────┤
│  !  │  @  │  #  │  $  │  %  │       │  ^  │  &  │  *  │  (  │  )  │
├─────┼─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┼─────┤
│ F11 │ F12 │     │     │     │       │  ~  │  `  │     │     │     │
└─────┴─────┼─────┼─────┼─────┤       ├─────┼─────┼─────┼─────┴─────┘
            │     │     │     │       │     │ === │     │
            └─────┴─────┴─────┘       └─────┴─────┴─────┘
```

## Configuration notes

- Tapping term: start at ~200ms, adjust based on feel
- Enable Permissive Hold for reliable Cmd+Tab combos
- Swedish ÅÄÖ: use macOS hold-to-accent (hold A → Å/Ä, hold O → Ö)
- Cmd+Tab: hold A (=Cmd via home row mod) + tap TAB thumb key
- Cmd+Tilde (window switch): hold A (=Cmd) + Shift+` on Layer 2
