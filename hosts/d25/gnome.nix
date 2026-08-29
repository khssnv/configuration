{ lib, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 3600;

    "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-timeout =
      lib.hm.gvariant.mkUint32 5400;
  };

  xdg.configFile."monitors.xml" = {
    force = true;
    text = ''
      <monitors version="2">
        <configuration>
          <layoutmode>logical</layoutmode>
          <logicalmonitor>
            <x>0</x>
            <y>0</y>
            <scale>1.6666666269302368</scale>
            <primary>yes</primary>
            <monitor>
              <monitorspec>
                <connector>DP-3</connector>
                <vendor>BNQ</vendor>
                <product>BenQ RD280UG</product>
                <serial>EM23T00120087</serial>
              </monitorspec>
              <mode>
                <width>3840</width>
                <height>2560</height>
                <rate>119.991</rate>
              </mode>
            </monitor>
          </logicalmonitor>
        </configuration>
      </monitors>
    '';
  };
}
