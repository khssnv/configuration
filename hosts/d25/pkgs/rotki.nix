{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "rotki";
  version = "1.44.0";
  tag = "v${version}";

  src = fetchurl {
    url = "https://github.com/rotki/rotki/releases/download/${tag}/rotki-linux_x86_64-${tag}.AppImage";
    hash = "sha256-Se6x9qXqSYk4AlhS2Q8009J2FR8pJFnu1M0/Ua20WGs=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/rotki.desktop \
      "$out/share/applications/rotki.desktop"
    substituteInPlace "$out/share/applications/rotki.desktop" \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=${pname} --no-sandbox %U"

    install -Dm444 ${appimageContents}/rotki.png \
      "$out/share/pixmaps/rotki.png"
  '';

  meta = {
    description = "Portfolio tracking, analytics, accounting and tax reporting tool";
    homepage = "https://rotki.com/";
    license = lib.licenses.agpl3Only;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
