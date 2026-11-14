{ ... }:

{
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
                <connector>eDP-1</connector>
                <vendor>SDC</vendor>
                <product>0x4193</product>
                <serial>0x00000000</serial>
              </monitorspec>
              <mode>
                <width>2880</width>
                <height>1800</height>
                <rate>90.001</rate>
              </mode>
            </monitor>
          </logicalmonitor>
        </configuration>
      </monitors>
    '';
  };
}
