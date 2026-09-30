{
  autoPatchelfHook,
  dbus,
  fetchurl,
  fontconfig,
  freetype,
  lib,
  libGL,
  libdrm,
  libusb1,
  libx11,
  libxcomposite,
  libxcb,
  libxext,
  libxkbcommon,
  libxrender,
  p7zip,
  python3,
  stdenv,
  stdenvNoCC,
  wayland,
}:

let
  version = "2026.2";
  expectedArchiveCount = 25;

  installer = fetchurl {
    url = "https://dl.trikset.com/ts/fresh/installer/trik-studio-installer-linux-${version}.run";
    hash = "sha256-LWW//7bbu7o5MS5LkWGlpqEataGFFYHO096Q6itihBc=";
  };

  icon = fetchurl {
    url = "https://raw.githubusercontent.com/trikset/trik-studio/${version}/installer/images/trik-studio-48x48.png";
    hash = "sha256-jEa/CRqrKt1aFt2l69csKRNRDmwj6Nrh41WUTuEh1J8=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "trik-studio";
  inherit version;

  src = installer;

  nativeBuildInputs = [
    autoPatchelfHook
    p7zip
    python3
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    dbus
    fontconfig
    freetype
    libGL
    libdrm
    libusb1
    libx11
    libxcomposite
    libxcb
    libxext
    libxkbcommon
    libxrender
    wayland
  ];

  unpackPhase = ''
    runHook preUnpack

    # The QtIFW .run file is an ELF executable with embedded 7z archives,
    # so standard unpackers cannot extract it directly. Running the installer
    # in the build sandbox fails because it invokes /bin/bash. The Python
    # helper finds archive boundaries using 7z headers and CRCs; p7zip
    # then extracts each archive.
    python3 ${./extract-installer.py} "$src" archives ${toString expectedArchiveCount}
    mkdir extracted
    for archive in archives/*.7z; do
      7z x -y -oextracted "$archive" > /dev/null
    done
    test -x extracted/bin/trik-studio.bin
    test -f extracted/lib/libQt5Core.so.5
    cd extracted

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    appDir="$out/libexec/trik-studio"
    mkdir -p "$appDir" "$out/bin" "$out/share/applications"
    cp -a {bin,lib,resources,scripts,palettes,trik-studio} "$appDir/"

    # Upstream links omit the python-runtime directory.
    for library in libgfortran-040039e1-0352e75f.so.5.0.0 libquadmath-96973f99-934c22de.so.0.0.0 libscipy_openblas64_-32a4b2a6.so; do
      test -f "$appDir/lib/python-runtime/numpy.libs/$library"
      ln -sfn "python-runtime/numpy.libs/$library" "$appDir/lib/$library"
    done

    # The upstream launcher assumes /bin/bash, which NixOS does not provide.
    sed -i "1c#!${stdenv.shell}" "$appDir/trik-studio"
    addAutoPatchelfSearchPath "$appDir/lib"

    cat > "$out/bin/trik-studio" <<EOF_WRAPPER
    #!${stdenv.shell}
    exec "$appDir/trik-studio" "\$@"
    EOF_WRAPPER
    chmod +x "$out/bin/trik-studio"

    cat > "$out/share/applications/trik-studio.desktop" <<EOF_DESKTOP
    [Desktop Entry]
    Type=Application
    Name=TRIK Studio
    Exec=$out/bin/trik-studio
    Icon=trik-studio
    Categories=Development;Education;
    Terminal=false
    EOF_DESKTOP
    install -Dm644 ${icon} "$out/share/icons/hicolor/48x48/apps/trik-studio.png"

    runHook postInstall
  '';

  meta = {
    description = "Visual programming environment for TRIK and other educational robots";
    homepage = "https://trikset.com/products/trik-studio";
    license = lib.licenses.asl20;
    mainProgram = "trik-studio";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
