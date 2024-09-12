{ lib, ... }:
{
  boot.loader = {
    grub.enable = lib.mkDefault false;
    # V TODO 
    # generic-extlinux-compatible.enable = lib.mkDefault true;
  };
  fileSystems."/" = {
    fsType = "tmpfs";
  };
  imports = [
    ./make-tarball.nix
  ];
}
