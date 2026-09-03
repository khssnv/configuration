{
  config,
  pkgs,
  ...
}:

let
  wallpaperSourceDir = "/mnt/truenas/shared-hdd/Alisher/Pictures/Wallpaper";
  wallpaperDir = "${config.xdg.dataHome}/backgrounds";
  lightWallpaper = "bliss-4k.jpg";
  darkWallpaper = "black-4k-3840-2160.png";
  wallpaperUri = name: "file://${wallpaperDir}/${name}";

  bootstrapWallpapers = pkgs.writeShellScriptBin "bootstrap-wallpapers" ''
    set -euo pipefail

    readonly source_directory="${wallpaperSourceDir}"
    readonly destination_directory="''${HOME}/.local/share/backgrounds"
    readonly light_wallpaper="${lightWallpaper}"
    readonly dark_wallpaper="${darkWallpaper}"

    if [[ ! -d "$source_directory" ]]; then
      printf 'Wallpaper source is unavailable: %s\n' "$source_directory" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/install -d "$destination_directory"

    for wallpaper in "$light_wallpaper" "$dark_wallpaper"; do
      source_file="$source_directory/$wallpaper"

      if [[ ! -r "$source_file" ]]; then
        printf 'Wallpaper source is not readable: %s\n' "$source_file" >&2
        exit 1
      fi

      ${pkgs.coreutils}/bin/install -m644 "$source_file" "$destination_directory/$wallpaper"
    done

    printf 'Wallpapers copied to %s\n' "$destination_directory"
  '';
in
{
  home.packages = [ bootstrapWallpapers ];

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      picture-uri = wallpaperUri lightWallpaper;
      picture-uri-dark = wallpaperUri darkWallpaper;
    };

    "org/gnome/desktop/screensaver".picture-uri = wallpaperUri darkWallpaper;
  };
}
