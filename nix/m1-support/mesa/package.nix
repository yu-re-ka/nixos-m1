{ mesa, fetchFromGitLab, lib }:

(mesa.override {
  galliumDrivers = [ "swrast" "asahi" ];
  enableGalliumNine = false;
}).overrideAttrs (oldAttrs: {
  version = "23.0.0";
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "asahi";
    repo = "mesa";
    rev = "c1738bbe4eebde4d5392b1c14e2926f95e7655fd"; # from asahi/main
    hash = "sha256-rxpD2FU5KvS/YsD3GbPWJkzZKqLqIhXsLLC17SHvFXI=";
  };
  mesonFlags = lib.filter (x: !(lib.hasPrefix "-Dxvmc-libs-path=" x)) oldAttrs.mesonFlags;
})
