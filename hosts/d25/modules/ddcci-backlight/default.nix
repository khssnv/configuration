# Exposes external monitor brightness as a sysfs backlight via ddcci-driver so
# the GNOME brightness slider controls it over DDC/CI.
# Notes:
# - Mutter uses a raw backlight for an external monitor only when the backlight
#   is a descendant of the monitor's DRM connector. i915 DP AUX I2C adapters are
#   children of their connectors, so a ddcci backlight on them matches.
# - DRM I2C adapters no longer have I2C_CLASS_DDC (Linux 6.8+), so ddcci does
#   not autodetect monitors and has to be attached through new_device.
# - Mutter creates backlights with monitors and ignores backlight add events, so
#   the driver must be attached before the GNOME session starts. Attaching
#   before the display manager also avoids its mode set, during which the
#   monitor does not answer DDC/CI and the driver probe fails.
# - ddcci-backlight does not poll the monitor, so brightness changed elsewhere
#   (e.g. Display Pilot 2 or the OSD) is announced to Mutter by a sync service.
{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.ddcciBacklight;

  # i915 names DP AUX adapters like "AUX USBC4/DDI TC4/PHY TC4".
  adapterNamePattern = "AUX *";
  syncIntervalSeconds = 5;
in

{
  options.hardware.ddcciBacklight = {
    enable = lib.mkEnableOption "external monitor brightness control via ddcci-driver";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
      kernelModules = [ "ddcci_backlight" ];
    };

    # AUX adapters are added once at boot and stay while monitors are plugged in
    # or out, so the driver is attached only to monitors connected at boot. A
    # monitor connected later to another port, or a different monitor on the
    # same port, is handled after a reboot.
    services.udev.extraRules = ''
      SUBSYSTEM=="i2c", ACTION=="add", ATTR{name}=="${adapterNamePattern}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci-attach@$kernel.service"
    '';

    systemd.services."ddcci-attach@" = {
      description = "Attach ddcci driver to %I";
      before = [ "display-manager.service" ];
      scriptArgs = "%i";
      script = ''
        adapter=/sys/bus/i2c/devices/$1
        client=''${1#i2c-}-0037

        # Skip AUX adapters of connectors without a monitor.
        [ "$(cat "$adapter/../status")" = connected ] || exit 0

        [ -e "$adapter/$client" ] || echo ddcci 0x37 > "$adapter/new_device"

        # The driver probe fails while the monitor does not answer DDC/CI.
        for _ in {1..5}; do
          [ ! -e "$adapter/$client/driver" ] || exit 0
          sleep 1
          echo "$client" 2>/dev/null > /sys/bus/i2c/drivers/ddcci/bind || true
        done
        [ ! -e "$adapter/$client/driver" ] || exit 0

        echo "ddcci driver did not bind to $client" >&2
        exit 1
      '';
      serviceConfig.Type = "oneshot";
    };

    systemd.services.ddcci-backlight-sync = {
      description = "Announce ddcci backlight changes made outside sysfs";
      wantedBy = [ "multi-user.target" ];
      script = ''
        shopt -s nullglob

        while sleep ${toString syncIntervalSeconds}; do
          for device in /sys/class/backlight/ddcci*; do
            # Reading actual_brightness queries the monitor and updates the
            # cached brightness value that Mutter reads on change events.
            cached=$(cat "$device/brightness") || continue
            actual=$(cat "$device/actual_brightness" 2>/dev/null) || continue
            [ "$actual" = "$cached" ] || echo change > "$device/uevent"
          done
        done
      '';
      serviceConfig.Restart = "on-failure";
    };
  };
}
