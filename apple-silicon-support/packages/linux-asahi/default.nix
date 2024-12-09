{ lib
, callPackage
, linuxPackagesFor
, _kernelPatches ? [ ]
}:

let
  linux-asahi-pkg = { stdenv, lib, fetchFromGitHub, fetchpatch, buildLinux, ... } @ args:
    buildLinux rec {
      inherit stdenv lib;

      version = "6.12.4-asahi";
      modDirVersion = version;
      extraMeta.branch = "6.12";
      extraMeta.broken = false;

      src = fetchFromGitHub {
        # tracking: https://github.com/AsahiLinux/linux/tree/asahi-wip (w/ fedora verification)
        owner = "AsahiLinux";
        repo = "linux";
        rev = "asahi-6.12.4-1";
        hash = "sha256-0JJtJWM0eNKcBMkNRCOA6Vpoi6Ca1QCOlsmSQKRHAUA=";
      };

      kernelPatches = [
        { name = "coreutils-fix";
          patch = ./0001-fs-fcntl-accept-more-values-as-F_DUPFD_CLOEXEC-args.patch;
        }
        {
          name = "Asahi config";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            RUST = yes;
            DRM = yes;
            ARCH_APPLE = yes;
            HID_APPLE = module;
            ARM64_16K_PAGES = yes;
            APPLE_WATCHDOG = yes;
            APPLE_PMGR_PWRSTATE = yes;
            APPLE_AIC = yes;
            APPLE_M1_CPU_PMU = yes;
            APPLE_MAILBOX = yes;
            APPLE_PLATFORMS = yes;
            APPLE_PMGR_MISC = yes;
            APPLE_RTKIT = yes;
            ARM_APPLE_CPUIDLE = yes;
            DRM_VGEM = no;
            DRM_SCHED = yes;
            DRM_GEM_SHMEM_HELPER = yes;
            DRM_APPLE_AUDIO = yes;
          };
          features.rust = true;
        }
      ] ++ _kernelPatches;
    };

  linux-asahi = (callPackage linux-asahi-pkg { });
in lib.recurseIntoAttrs (linuxPackagesFor linux-asahi)

