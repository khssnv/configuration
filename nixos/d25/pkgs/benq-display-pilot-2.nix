{
  appimageTools,
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

let
  pname = "benq-display-pilot-2";
  version = "1.1.4.0";

  archiveAppimageName = "Display Pilot 2-${version}-release.AppImage";
  appimageName = "${pname}.AppImage";

  appimage = stdenvNoCC.mkDerivation {
    pname = "${pname}-appimage";
    inherit version;

    src = fetchurl {
      url = "https://esupportdownload.benq.com/esupport/VERTICAL%20%26%20PROFESSIONAL%20DISPLAY/Software/Display%20Pilot%202/Display%20Pilot%202_Display%20Pilot%202%20for%20Linux_V1.1.4.0_Linux_260407094616.zip";
      hash = "sha256-IWFIR5VpnZiNP11VQLTWmoezfLbcXKrGB7VWgaf/Fxo=";
    };

    nativeBuildInputs = [ unzip ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      unzip -j "$src" ${lib.escapeShellArg archiveAppimageName} -d "$out"
      mv "$out/${archiveAppimageName}" "$out/${appimageName}"

      runHook postInstall
    '';
  };

  src = "${appimage}/${appimageName}";
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/com.benq.DisplayPilot2.desktop \
      "$out/share/applications/com.benq.DisplayPilot2.desktop"
    substituteInPlace "$out/share/applications/com.benq.DisplayPilot2.desktop" \
      --replace-fail "Exec=Display_Pilot_2" "Exec=${pname}"

    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/scalable/apps/dp2_svg.svg \
      "$out/share/icons/hicolor/scalable/apps/dp2_svg.svg"
  '';

  meta = {
    description = "BenQ Display Pilot 2 monitor control utility";
    homepage = "https://www.benq.com/en-us/monitor/software/display-pilot-2.html";
    license = lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
