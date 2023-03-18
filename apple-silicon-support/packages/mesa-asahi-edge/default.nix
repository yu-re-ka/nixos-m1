{ lib
, fetchFromGitLab
, mesa
, libunwind
, lm_sensors
}:

(mesa.override {
  galliumDrivers = [ "swrast" "asahi" ];
  vulkanDrivers = [ "swrast" ];
  enableGalliumNine = false;
}).overrideAttrs (oldAttrs: {
  version = "23.1.0";
  # https://github.com/AsahiLinux/PKGBUILDs/blob/stable/mesa-asahi-edge/PKGBUILD
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "asahi";
    repo = "mesa";
    rev = "asahi-20230311";
    hash = "sha256-Qy1OpjTohSDGwONK365QFH9P8npErswqf2TchUxR1tQ=";
  };
  patches = [
    ./disk_cache-include-dri-driver-path-in-cache-key.patch
  ];
  buildInputs = oldAttrs.buildInputs ++ [
    libunwind
    lm_sensors
  ];
  # remove flag to configure xvmc functionality as having it
  # breaks the build because that no longer exists in Mesa 23
  mesonFlags = [
    "-Dgallium-vdpau=disabled"
    "-Dgallium-va=disabled"
    "-Dgallium-xa=disabled"
    "-Dandroid-libbacktrace=disabled"
  ] ++ lib.filter (x: !(lib.hasPrefix "-Dxvmc-libs-path=" x)) oldAttrs.mesonFlags;
})
