{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "netinstall-cli";
  version = "7.25.1";

  src = fetchurl {
    url = "https://download.mikrotik.com/routeros/${finalAttrs.version}/netinstall-${finalAttrs.version}.tar.gz";
    hash = "sha256-WDeYR/ITJ5L+FV64kjY/H4oM1Z50yGjpGbYFkIPXlS8=";
  };

  sourceRoot = ".";
  # Preserve the vendor's statically linked binary and embedded boot images.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 netinstall-cli "$out/bin/netinstall-cli"
    install -Dm644 LICENSE.txt "$out/share/licenses/netinstall-cli/LICENSE.txt"
    runHook postInstall
  '';

  meta = {
    description = "Command-line utility for installing RouterOS on MikroTik devices";
    homepage = "https://mikrotik.com/download/tools";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "netinstall-cli";
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
})
