# this creates a nixos system tarball 
{
  pkgs,
  config,
  modulesPath,
  lib,
  ...
}:
{

  system.build.tarball = pkgs.callPackage "${modulesPath}/../lib/make-system-tarball.nix" {
    extraArgs = "--owner=0";

    storeContents = [
      {
        object = config.system.build.toplevel;
        symlink = "none";
      }
    ];

    contents = [
      {
        source = config.system.build.toplevel + "/init";
        target = "/sbin/init";
      }
      # Technically this is not required for lxc, but having also make this configuration work with systemd-nspawn.
      # Nixos will setup the same symlink after start.
      {
        source = config.system.build.toplevel + "/etc/os-release";
        target = "/etc/os-release";
      }
    ];
    extraCommands = "mkdir -p proc sys dev";
  };
}
