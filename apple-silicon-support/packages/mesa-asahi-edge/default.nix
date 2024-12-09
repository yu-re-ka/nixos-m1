{ lib
, fetchFromGitLab
, mesa
}:

(mesa.override {
  galliumDrivers = [ "swrast" "asahi" "zink" ];
  vulkanDrivers = [ "swrast" "asahi" ];
}).overrideAttrs (oldAttrs: {
  # version must be the same length (i.e. no unstable or date)
  # so that system.replaceRuntimeDependencies can work
  version = "25.0.0";
  src = fetchFromGitLab {
    # tracking: https://pagure.io/fedora-asahi/mesa/commits/asahi
    domain = "gitlab.freedesktop.org";
    owner = "asahi";
    repo = "mesa";
    rev = "asahi-20241211";
    hash = "sha256-Ny4M/tkraVLhUK5y6Wt7md1QBtqQqPDUv+aY4MpNA6Y=";
  };

  mesonFlags = lib.filter (x: !(lib.hasPrefix "-Dopencl-spirv=" x)) oldAttrs.mesonFlags ++ [
      # we do not build any graphics drivers these features can be enabled for
      "-Dgallium-va=disabled"
      "-Dgallium-vdpau=disabled"
      "-Dgallium-xa=disabled"
    ];

  patches = map (x: if lib.hasSuffix "cross_clc.patch" x then ./0001-meson-Add-mesa-clc-and-install-mesa-clc-options.patch else x) oldAttrs.patches;

  outputs = lib.remove "spirv2dxil" oldAttrs.outputs;
})
