{
  lib,
  pkgs,
  userName,
  ...
}:

let
  # Use scalable fonts and apply resources at launch, including under XWayland.
  xtermConfigured = pkgs.symlinkJoin {
    name = "xterm-configured";
    paths = [ pkgs.xterm ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/xterm" --add-flags ${lib.escapeShellArg (lib.escapeShellArgs [
        "-fa" "JetBrains Mono"
        "-fs" "11"
        "-bg" "#1e1e1e"
        "-fg" "#dedede"
        "-xrm" (lib.concatStringsSep "\\n" [
          "XTerm*VT100.translations: #override"
          "Ctrl <Key>plus: larger-vt-font()"
          "Ctrl <Key>equal: larger-vt-font()"
          "Ctrl <Key>minus: smaller-vt-font()"
          "Ctrl <Key>0: set-vt-font(d)"
        ])
      ])}
    '';
  };
in
{
  # GNS3 runs its local server as the desktop user, without libvirt.
  home-manager.users.${userName} = { config, lib, ... }: {
    home.packages = with pkgs; [
      (gns3-gui.overrideAttrs (oldAttrs: {
        # Qt's native GTK file chooser needs GTK's GSettings schemas.
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ wrapGAppsHook3 ];
        # See https://nixos.org/manual/nixpkgs/unstable/#ssec-gnome-common-issues-double-wrapped.
        dontWrapGApps = true;
        preFixup = (oldAttrs.preFixup or "") + ''
          makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
        '';
      }))
      gns3-server
      dynamips # GNS3's built-in Ethernet switch and hub.
      qemu
      vpcs
      inetutils # telnet for GNS3 device consoles.
      xtermConfigured
    ];

    # Seed a writable configuration once; GNS3 owns subsequent GUI changes.
    home.activation.initializeGns3Paths =
      let
        initialConfig = (pkgs.formats.ini { }).generate "gns3-server-initial.conf" {
          Server = lib.genAttrs [
            "projects_path"
            "images_path"
            "appliances_path"
            "symbols_path"
            "configs_path"
          ] (name: "${config.home.homeDirectory}/Workspace/GNS3/${lib.removeSuffix "_path" name}");
        };
        configFile = "${config.xdg.configHome}/GNS3/2.2/gns3_server.conf";
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ ! -e ${lib.escapeShellArg configFile} && ! -L ${lib.escapeShellArg configFile} ]]; then
          run ${lib.getExe' pkgs.coreutils "install"} -Dm600 ${initialConfig} ${lib.escapeShellArg configFile}
        fi
      '';
  };

  users.users.${userName}.extraGroups = [
    "kvm"
    "ubridge"
  ];
  users.groups.ubridge = { };
  security.wrappers.ubridge = {
    source = lib.getExe pkgs.ubridge;
    capabilities = "cap_net_raw,cap_net_admin=eip";
    owner = "root";
    group = "ubridge";
    permissions = "u=rwx,g=rx,o=r";
  };
}
