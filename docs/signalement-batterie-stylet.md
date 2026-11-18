# Signalement à envoyer à linux-surface (batterie du stylet à 1 %)

À coller dans une nouvelle issue sur https://github.com/linux-surface/linux-surface/issues
Avant d'envoyer, remplace `<uname -r>` par la sortie de `uname -r` sur la Surface.

---

**Title:** Surface Go 2: bogus stylus battery (stuck at 1%) shown again with third-party MPP pen

**Device:** Surface Go 2, touchscreen `ELAN9038:00 04F3:2A1C`
**Kernel:** `<uname -r>` (linux-surface), Arch Linux, KDE Plasma 6 (Wayland)
**Pen:** Milikilo F97, third-party MPP pen (no Bluetooth)

**Problem**

As soon as the pen is used, UPower shows a stylus battery stuck at 1% with warning level `action`, whatever the real charge of the pen:

```
Device: /org/freedesktop/UPower/devices/battery_hid_0018o04F3o2A1Cx0001_battery_7
  native-path:          hid-0018:04F3:2A1C.0001-battery-7
  model:                ELAN9038:00 04F3:2A1C Stylus
  power supply:         no
  tablet
    warning-level:       action
    percentage:          1%
    icon-name:          'battery-caution-symbolic'
```

**Likely cause**

This digitizer used to have a dedicated `HID_BATTERY_QUIRK_IGNORE` entry in `drivers/hid/hid-input.c` (`I2C_DEVICE_ID_SURFACE_GO2_TOUCHSCREEN`, added in 2022 because it "mistakenly reports the battery of the stylus"). In current mainline that entry is gone: all ELAN I2C/USB devices now get `HID_BATTERY_QUIRK_DYNAMIC` (battery reported present only after life signs). So the bogus battery is hidden at boot but comes back as soon as the pen touches the screen.

Checked in the linux-surface kernel too: branches `v7.1-surface`, `v7.2-surface` and `v7.3-surface` have no `SURFACE_GO2` entry left, only the generic ELAN `HID_BATTERY_QUIRK_DYNAMIC` rule.

**Expected**

No stylus battery for this digitizer (restore `HID_BATTERY_QUIRK_IGNORE` for `04F3:2A1C`), or a correct value if the pen actually reports one.
