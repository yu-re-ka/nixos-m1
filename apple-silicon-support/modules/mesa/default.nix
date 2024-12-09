{ options, config, pkgs, lib, ... }:
{
  config = lib.mkIf config.hardware.asahi.enable (lib.mkMerge [
    {
      # required for proper DRM setup even without GPU driver
      services.xserver.config = ''
        Section "OutputClass"
            Identifier "appledrm"
            MatchDriver "apple"
            Driver "modesetting"
            Option "PrimaryGPU" "true"
        EndSection
      '';
    }
    (lib.mkIf config.hardware.asahi.useExperimentalGPUDriver (
      # install the drivers
      if builtins.hasAttr "graphics" options.hardware then {
        hardware.graphics.package = config.hardware.asahi.pkgs.mesa-asahi-edge.drivers;
      } else { # for 24.05
        hardware.opengl.package = config.hardware.asahi.pkgs.mesa-asahi-edge.drivers;
      })
    )
  ]);

  options.hardware.asahi.useExperimentalGPUDriver = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Use the experimental Asahi Mesa GPU driver.

      Do not report issues using this driver under NixOS to the Asahi project.
    '';
  };
}
