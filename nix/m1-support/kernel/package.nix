{ pkgs, _4KBuild ? false }: let
  localPkgs =
    # we do this so the config can be read on any system and not affect
    # the output hash
    if builtins ? currentSystem then import (pkgs.path) { system = builtins.currentSystem; }
    else pkgs;

  readConfig = configfile: import (localPkgs.runCommand "config.nix" {} ''
    echo "{" > "$out"
    while IFS='=' read key val; do
      [ "x''${key#CONFIG_}" != "x$key" ] || continue
      no_firstquote="''${val#\"}";
      echo '  "'"$key"'" = "'"''${no_firstquote%\"}"'";' >> "$out"
    done < "${configfile}"
    echo "}" >> $out
  '').outPath;

  linux_asahi_pkg = { stdenv, lib, fetchFromGitHub, fetchpatch, linuxKernel, extraMakeFlags, ... } @ args:
    linuxKernel.manualConfig rec {
      inherit stdenv lib extraMakeFlags;

      version = "6.1.0-rc6-asahi";
      modDirVersion = version;

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        rev = "bedf1a6cc2186690b9fd5ec5a273769d552cb4f2"; # gpu/rust-wip
        hash = "sha256-zbdIJiSdYw2UztFheDMc0zchAUCpyRsSlA8uDDkFYlc=";
      };

      kernelPatches = [
        # sven says this is okay since our kernel config supports it, and that
        # it will be fixed at some point to not be necessary. but this allows
        # new kernels to get USB up with old device trees
        { name = "0001-drivers-usb-dwc3-remove-apple-dr_mode-check";
          patch = ./0001-drivers-usb-dwc3-remove-apple-dr_mode-check.patch;
        }
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
      ];

      configfile = ./config;
      config = readConfig configfile;

      extraMeta.branch = "6.1";
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
