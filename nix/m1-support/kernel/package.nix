{ pkgs, _4KBuild ? false, kernelPatches ? [ ] }: let
  localPkgs =
    # we do this so the config can be read on any system and not affect
    # the output hash
    if builtins ? currentSystem then import (pkgs.path) { system = builtins.currentSystem; }
    else pkgs;

  lib = localPkgs.lib;

  parseExtraConfig = cfg: let
    lines = builtins.filter (s: s != "") (lib.strings.splitString "\n" cfg);
    perLine = line: let
      kv = lib.strings.splitString " " line;
    in assert (builtins.length kv == 2);
       "CONFIG_${builtins.elemAt kv 0}=${builtins.elemAt kv 1}";
    in lib.strings.concatMapStringsSep "\n" perLine lines;

  readConfig = configfile: import (localPkgs.runCommand "config.nix" { } ''
    echo "{ } // " > "$out"
    while IFS='=' read key val; do
      [ "x''${key#CONFIG_}" != "x$key" ] || continue
      no_firstquote="''${val#\"}";
      echo '{  "'"$key"'" = "'"''${no_firstquote%\"}"'"; } //' >> "$out"
    done < "${configfile}"
    echo "{ }" >> $out
  '').outPath;

  linux_asahi_pkg = { stdenv, lib, fetchFromGitHub, fetchpatch, linuxKernel, extraMakeFlags, ... } @ args:
    let
      configfile = if kernelPatches == [ ] then ./config else
      pkgs.writeText "config" ''
        ${builtins.readFile ./config}

        # Patches
        ${lib.strings.concatMapStringsSep "\n" ({extraConfig ? "", ...}: parseExtraConfig extraConfig) kernelPatches}
      '';

      _kernelPatches = kernelPatches;
    in
    linuxKernel.manualConfig rec {
      inherit stdenv lib extraMakeFlags;

      version = "6.2.0-rc2-asahi";
      modDirVersion = version;

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        rev = "asahi-6.2-rc2-1";
        hash = "sha256-bfpxvTnyV3AKu74eAwWI6S6U0OurJ2suUwXk+ZlHN20=";
      };

      kernelPatches = [
      ] ++ lib.optionals _4KBuild [
        # thanks to Sven Peter
        # https://lore.kernel.org/linux-iommu/20211019163737.46269-1-sven@svenpeter.dev/
        { name = "sven-iommu-4k";
          patch = ./sven-iommu-4k.patch;
        }
      ] ++ lib.optionals (!_4KBuild) [
        # patch the kernel to set the default size to 16k instead of modifying
        # the config so we don't need to convert our config to the nixos
        # infrastructure or patch it and thus introduce a dependency on the host
        # system architecture
        { name = "default-pagesize-16k";
          patch = ./default-pagesize-16k.patch;
        }
      ] ++ _kernelPatches;

      inherit configfile;
      config = readConfig configfile;

      extraMeta.branch = "6.2";
    } // (args.argsOverride or {});

  inherit (pkgs.rustPlatform.rust) rustc;
  inherit (pkgs.rustPlatform) rustLibSrc;
  inherit (pkgs) rust-bindgen;

  extraMakeFlags = [
    "RUSTC=${rustc}/bin/rustc"
    "BINDGEN=${rust-bindgen}/bin/bindgen"
    "RUST_LIB_SRC=${rustLibSrc}"
  ];

  linux_asahi = (pkgs.callPackage linux_asahi_pkg { inherit extraMakeFlags; }).overrideAttrs(prior: {
    nativeBuildInputs =
      prior.nativeBuildInputs ++ [ rustc rust-bindgen rustLibSrc ];
  });
in pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_asahi)

