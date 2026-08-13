# Domain model:
# - Register a dictionary source (`dictionaryPath`, `ensure_dictionary_path`).
# - Resolve dictionary identities from their files (`managedGroup.dictionaries`,
#   `compute_dictionary_id`).
# - Reconcile one default group while preserving other groups (`managedGroup`,
#   `replace_managed_group`).
# - Select that group for main and popup lookups (`select_managed_group`).
# - Disable background full-text indexing (`disable_full_text_search`).
# - Start the autostarted GUI in the system tray without opening the main
#   window (`configure_tray_startup`).
# - Preserve unmanaged state and commit only changed XML atomically (the final
#   pipeline and temporary-file subshell).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    # Keep GoldenDict's stateful XML writable; activation owns only the
    # dictionary path, default group, and FTS flag instead of replacing the
    # whole config with a read-only Nix store file.
    activation.goldendictDictionaries =
      let
        dictionaryPath = "${config.home.homeDirectory}/.local/share/goldendict/dictionaries/GoldenDict_Dicts";
        managedGroup = {
          id = "1";
          minimumNextId = "2";
          name = "Lingvo Universal";
          dictionaries = {
            enRu = {
              name = "LingvoUniversal (En-Ru)";
              files = [
                "${dictionaryPath}/En-Ru/LingvoUniversalEnRu/LingvoUniversalEnRu.dsl.dz"
                "${dictionaryPath}/En-Ru/LingvoUniversalEnRu/LingvoUniversalEnRu_abrv.dsl"
              ];
            };
            ruEn = {
              name = "LingvoUniversal (Ru-En)";
              files = [
                "${dictionaryPath}/Ru-En/LingvoUniversalRuEn/LingvoUniversalRuEn.dsl.dz"
              ];
            };
          };
        };
        commands = {
          cmp = lib.getExe' pkgs.diffutils "cmp";
          cut = lib.getExe' pkgs.coreutils "cut";
          md5sum = lib.getExe' pkgs.coreutils "md5sum";
          sort = lib.getExe' pkgs.coreutils "sort";
          xmlstarlet = lib.getExe pkgs.xmlstarlet;
        };
        emptyConfig = pkgs.writeText "goldendict-config.xml" "<config/>";
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config_file="${config.xdg.configHome}/goldendict/config"

        if [[ ! -e "$config_file" ]]; then
          install -Dm600 ${emptyConfig} "$config_file"
        fi

        # GoldenDict IDs are MD5 hashes of sorted, NUL-terminated absolute paths.
        compute_dictionary_id() {
          printf '%s\0' "$@" \
            | LC_ALL=C ${commands.sort} --zero-terminated \
            | ${commands.md5sum} \
            | ${commands.cut} --delimiter=" " --fields=1
        }

        # Preserve user-owned paths and replace only the path managed here.
        ensure_dictionary_path() {
          ${commands.xmlstarlet} ed \
            --subnode "/config[not(paths)]" --type elem --name paths \
            --delete "/config/paths/path[.='${dictionaryPath}']" \
            --subnode "/config/paths" --type elem --name path --value "${dictionaryPath}" \
            --insert "/config/paths/path[last()]" \
              --type attr --name recursive --value 1 \
            "$1"
        }

        # Read XML from stdin, preserve other groups, and replace only the
        # Home Manager-owned group.
        replace_managed_group() {
          local en_ru_id="$1"
          local ru_en_id="$2"

          ${commands.xmlstarlet} ed \
            --subnode "/config[not(groups)]" --type elem --name groups \
            --insert "/config/groups[not(@nextId)]" \
              --type attr --name nextId --value "${managedGroup.minimumNextId}" \
            --update "/config/groups/@nextId[. < ${managedGroup.minimumNextId}]" \
              --value "${managedGroup.minimumNextId}" \
            --delete "/config/groups/group[@id='${managedGroup.id}' or @name='${managedGroup.name}']" \
            --subnode "/config/groups" --type elem --name group \
            --insert "/config/groups/group[last()]" \
              --type attr --name id --value "${managedGroup.id}" \
            --insert "/config/groups/group[last()]" \
              --type attr --name name --value "${managedGroup.name}" \
            --subnode "/config/groups/group[last()]" \
              --type elem --name dictionary --value "$en_ru_id" \
            --insert "/config/groups/group[last()]/dictionary[last()]" \
              --type attr --name name --value "${managedGroup.dictionaries.enRu.name}" \
            --subnode "/config/groups/group[last()]" \
              --type elem --name dictionary --value "$ru_en_id" \
            --insert "/config/groups/group[last()]/dictionary[last()]" \
              --type attr --name name --value "${managedGroup.dictionaries.ruEn.name}" \
            --subnode "/config/groups/group[last()]" \
              --type elem --name mutedDictionaries
        }

        # FTS is unnecessary here: it searches article bodies, for example by
        # phrase fragments or words from definitions, and its background
        # indexing loads the CPU at application startup.
        disable_full_text_search() {
          ${commands.xmlstarlet} ed \
            --subnode "/config[not(preferences)]" \
              --type elem --name preferences \
            --subnode "/config/preferences[not(fullTextSearch)]" \
              --type elem --name fullTextSearch \
            --subnode "/config/preferences/fullTextSearch[not(enabled)]" \
              --type elem --name enabled --value 0 \
            --update "/config/preferences/fullTextSearch/enabled" --value 0
        }

        configure_tray_startup() {
          ${commands.xmlstarlet} ed \
            --subnode "/config[not(preferences)]" \
              --type elem --name preferences \
            --subnode "/config/preferences[not(enableTrayIcon)]" \
              --type elem --name enableTrayIcon --value 1 \
            --update "/config/preferences/enableTrayIcon" --value 1 \
            --subnode "/config/preferences[not(startToTray)]" \
              --type elem --name startToTray --value 1 \
            --update "/config/preferences/startToTray" --value 1
        }

        # Read XML from stdin and select the managed group for both interfaces.
        select_managed_group() {
          ${commands.xmlstarlet} ed \
            --delete "/config/lastMainGroupId" \
            --subnode "/config" \
              --type elem --name lastMainGroupId --value "${managedGroup.id}" \
            --delete "/config/lastPopupGroupId" \
            --subnode "/config" \
              --type elem --name lastPopupGroupId --value "${managedGroup.id}"
        }

        en_ru_id="$(
          compute_dictionary_id ${lib.escapeShellArgs managedGroup.dictionaries.enRu.files}
        )"
        ru_en_id="$(
          compute_dictionary_id ${lib.escapeShellArgs managedGroup.dictionaries.ruEn.files}
        )"

        # Scope the temporary-file trap so it cannot replace Home Manager's
        # own EXIT trap.
        (
          temporary_file="$(mktemp "$config_file.XXXXXX")"
          trap 'rm -f "$temporary_file"' EXIT

          ensure_dictionary_path "$config_file" \
            | replace_managed_group "$en_ru_id" "$ru_en_id" \
            | disable_full_text_search \
            | configure_tray_startup \
            | select_managed_group \
            > "$temporary_file"

          # Replace the writable config atomically only when managed fields
          # changed.
          if ! ${commands.cmp} --silent "$config_file" "$temporary_file"; then
            chmod --reference="$config_file" "$temporary_file"
            mv "$temporary_file" "$config_file"
          fi
        )
      '';

    packages = [ pkgs.goldendict-ng ];
  };

  programs.plasma.window-rules = [
    {
      description = "Keep GoldenDict-ng above other windows";
      match.window-class = {
        value = "goldendict";
        type = "substring";
        match-whole = false;
      };
      apply.above = {
        value = true;
        apply = "force";
      };
    }
  ];

  xdg.configFile."autostart/io.github.xiaoyifang.goldendict_ng.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Terminal=false
    Categories=Office;Dictionary;Education;Qt;
    Name=GoldenDict-ng
    GenericName=Multiformat Dictionary
    GenericName[ru]=Многоформатный словарь
    Comment=A feature-rich dictionary lookup program
    Comment[ru]=Многофункциональная словарная оболочка
    Keywords=dict;dictionary;
    Keywords[ru]=dict;dictionary;словарь;
    Icon=goldendict
    Exec=${pkgs.goldendict-ng}/bin/goldendict
    MimeType=x-scheme-handler/goldendict;x-scheme-handler/dict;
    StartupWMClass=GoldenDict-ng
  '';
}
