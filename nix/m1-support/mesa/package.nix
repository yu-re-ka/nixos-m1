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
    rev = "0a12b60a6b4363315ca3789e7e289240704a26da"; # from asahi/main
    hash = "sha256-q3If3xuFsT0UQRmvyL4juuaOMWwftqFDfCAh4nEpVno=";
  };
  mesonFlags = lib.filter (x: !(lib.hasPrefix "-Dxvmc-libs-path=" x)) oldAttrs.mesonFlags;
})
