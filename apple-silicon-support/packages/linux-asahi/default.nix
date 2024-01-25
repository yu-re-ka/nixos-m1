{ lib
, callPackage
, linuxPackagesFor
, _kernelPatches ? [ ]
}:

let
  linux-asahi-pkg = { stdenv, lib, fetchFromGitHub, fetchpatch, buildLinux, ... } @ args:
    buildLinux rec {
      inherit stdenv lib;

      version = "6.6.0-asahi";
      modDirVersion = version;
      extraMeta.branch = "6.6";

      src = fetchFromGitHub {
        # tracking: https://github.com/AsahiLinux/linux/tree/asahi-wip (w/ fedora verification)
        owner = "AsahiLinux";
        repo = "linux";
        rev = "asahi-6.6-15";
        hash = "sha256-Jm7wTKWuwd/6ZN0g5F4CNNETiOyGQL31hfSyTDYH85k=";
      };

      kernelPatches = [
        {
          name = "Asahi config";
          patch = null;
          extraStructuredConfig = with lib.kernel; {
            ARCH_APPLE = yes;
            APPLE_WATCHDOG = yes;
            APPLE_PMGR_PWRSTATE = yes;
            APPLE_AIC = yes;
            APPLE_M1_CPU_PMU = yes;
            APPLE_MBOX = yes;
            APPLE_PLATFORMS = yes;
            APPLE_PMGR_MISC = yes;
            APPLE_RTKIT = yes;
            ARM_APPLE_CPUIDLE = yes;
            DRM_VGEM = no;
            DRM_SCHED = yes;
            DRM_GEM_SHMEM_HELPER = yes;
            SUSPEND = yes;
          };
          features.rust = true;
        }
        # speaker enablement; we assert on the relevant lsp-plugins patch
        # before installing speakersafetyd to let the speakers work
        { name = "speakers-1";
          patch = fetchpatch {
            url = "https://github.com/AsahiLinux/linux/commit/385ea7b5023486aba7919cec8b6b3f6a843a1013.patch";
            hash = "sha256-u7IzhJbUgBPfhJXAcpHw1I6OPzPHc1UKYjH91Ep3QHQ=";
          };
        }
        { name = "speakers-2";
          patch = fetchpatch {
            url = "https://github.com/AsahiLinux/linux/commit/6a24102c06c95951ab992e2d41336cc6d4bfdf23.patch";
            hash = "sha256-wn5x2hN42/kCp/XHBvLWeNLfwlOBB+T6UeeMt2tSg3o=";
          };
        }
        { name = "rustc-1.75.0";
          patch = ./0001-check-in-new-alloc-for-1.75.0.patch;
        }
      ] ++ _kernelPatches;
    };

  linux-asahi = (callPackage linux-asahi-pkg { });
in lib.recurseIntoAttrs (linuxPackagesFor linux-asahi)

