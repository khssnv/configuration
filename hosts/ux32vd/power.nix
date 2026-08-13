{
  config,
  userName,
  ...
}:

# Lid and power button behaviour. The three layers below are only meaningful
# together, so they are kept in one module even though one of them is
# user-level (Home Manager) rather than system-level:
#
#   - logind ignores both events, which covers what happens outside of a
#     desktop session (display manager, TTYs);
#   - PowerDevil ignores both events inside a Plasma session, where it may take
#     an inhibitor lock and handle them itself;
#   - acpid then defines what the power button actually does.
#
# Net effect: closing the lid does nothing on any power source, a single press
# of the power button suspends, a double press hibernates.

{
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandlePowerKey = "ignore";
  };

  home-manager.users.${userName} = {
    programs.plasma.powerdevil =
      let
        profile = {
          whenLaptopLidClosed = "doNothing";
          powerButtonAction = "nothing";
        };
      in
      {
        AC = profile;
        battery = profile;
        lowBattery = profile;
      };
  };

  # Neither logind nor desktop power managers know about double presses, so
  # ACPI button events are handled here instead: the first press only arms a
  # short-lived transient timer, and a second press within that window cancels
  # it and hibernates instead. The cost is that a single press suspends with a
  # ~750 ms delay.
  services.acpid = {
    enable = true;

    handlers.powerButton = {
      event = "button/power.*";

      action = ''
        systemctl=${config.systemd.package}/bin/systemctl

        if "$systemctl" is-active --quiet power-button-suspend.timer; then
          "$systemctl" stop power-button-suspend.timer
          exec "$systemctl" hibernate
        fi

        # A previous run that failed would leave the transient units behind
        # and make systemd-run refuse to reuse the name.
        "$systemctl" reset-failed power-button-suspend.timer \
          power-button-suspend.service 2>/dev/null || true

        exec ${config.systemd.package}/bin/systemd-run \
          --unit=power-button-suspend \
          --on-active=750ms \
          --timer-property=AccuracySec=10ms \
          "$systemctl" suspend
      '';
    };
  };
}
