{ config, ... }:

{
  hardware.opengl.package = let
    mesaAsahi = config.hardware.asahi.pkgs.callPackage ./package.nix { };
  in mesaAsahi.drivers;
}
