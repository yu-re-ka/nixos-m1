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
    rev = "3fc6e787ce9da1b5e323974ca134647d69dd2573"; # from asahi/main
    hash = "sha256-DItDDEPuiCIn206KvvIO5cWjfDCQsRy5Ywc2mP9+k9U=";
  };
  mesonFlags = lib.filter (x: !(lib.hasPrefix "-Dxvmc-libs-path=" x)) oldAttrs.mesonFlags;
})
