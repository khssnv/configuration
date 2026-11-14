{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation {
  pname = "rock-pi-x-ap6255-firmware";
  version = "2020-08-18";

  src = fetchurl {
    url = "https://dl.radxa.com/rockpix/drivers/firmware/AP6255_BT_WIFI_Firmware.zip";
    hash = "sha256-G5Q0/N02G3eO/+S1ELhOcX4+znWJz67FXsiUTvmDYAM=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = "BT_WIFI_Firmware";

  installPhase = ''
    runHook preInstall

    install -Dm644 bt/BCM4345C0.hcd \
      "$out/lib/firmware/brcm/BCM4345C0.hcd"
    install -Dm644 wifi/brcmfmac43455c0-sdio.bin \
      "$out/lib/firmware/brcm/brcmfmac43455-sdio.Radxa-ROCK Pi X.bin"
    install -Dm644 "wifi/brcmfmac43455-sdio.ROCK Pi-ROCK Pi X.txt" \
      "$out/lib/firmware/brcm/brcmfmac43455-sdio.Radxa-ROCK Pi X.txt"

    runHook postInstall
  '';

  meta = {
    description = "Wi-Fi and Bluetooth firmware for the ROCK Pi X AP6255 module";
    homepage = "https://wiki.radxa.com/RockpiX";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryFirmware ];
  };
}
