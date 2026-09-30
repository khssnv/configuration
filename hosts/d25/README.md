# d25

## UPS

At 50% UPS charge, UPower powers the host off, or puts it into hybrid sleep
once hibernation works. Where losing work matters, keep autosave intervals
under 25 min.

## Monitor brightness control slider

The GNOME brightness slider controls external monitors over DDC/CI. The boot
waits for monitors listed in `hardware.ddcciBacklight.monitors` in
[configuration.nix](configuration.nix). Other monitors have no slider unless
they answer at once. Add a new monitor to the list so the boot waits for it
too, the option description in
[modules/ddcci-backlight](modules/ddcci-backlight/default.nix) shows how to
print its name.
