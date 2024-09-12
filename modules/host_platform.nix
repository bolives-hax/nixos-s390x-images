# TODO supply this over instead lib.systems.platforms.z10;
{
  nixpkgs.hostPlatform = {
    system = "s390x-linux";
    linux-kernel = {
      # TODO there actually are z10-15 specifc kernel
      # optimisation flags. Set them adequately if
      # we already have gcc arch. But also have a fallback
      # that works on all upwars z10
      target = "bzImage";
      name = "s390x-defconfig";
      autoModules = true;
      baseConfig = "defconfig";
    };
    gcc.arch = "z10";
  };
}
