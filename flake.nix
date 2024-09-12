{
  inputs = {
    nixpkgs = {
      # once all fixes are merged you can use nixos/nixpkgs instead of my fork
      url = "github:bolives-hax/nixpkgs/nixos-s390x-overlay-multioption-fixes";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-s390x.url = "github:bolives-hax/nixos-s390x/dbg-fm";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      nixos-s390x,
    }:
    let
      baseSystem = {
        specialArgs = {
          inherit
            nixpkgs # nixos-s390x
            ;
        };
        system = "s390x-linux";
        modules = [
          nixos-s390x.nixosModules.default
          ./modules/host_platform.nix
          ./modules/common.nix
          ./modules/network.nix
          {
            # V get storage and network to work, these are mainframe specific modules
            boot.initrd.kernelModules = [
              "dasd_eckd_mod"
              "ccwgroup"
              "qeth"
              "qeth_l2"
              "qeth_l3"
              "virtio-net"
              "dasd_fba_mod"
              "dasd_mod"
            ];
          }

          # V if we remove this things break with this qeum arch error
          # go see if we can fix it
          (
            { modulesPath, ... }:
            {
              imports = [ "${nixpkgs}/nixos/modules/profiles/minimal.nix" ];
            }
          )
        ];
      };
    in
    {
      packages.s390x-linux =
        let
          mkLxc =
            format:
            nixos-generators.nixosGenerate ({
              inherit (baseSystem) system;
              inherit format;

              specialArgs = baseSystem.specialArgs;
              modules = baseSystem.modules ++ [
                # TODO put meaningful things in there	
                # ./modules/lxc/lxc-guest.nix
              ];
            });
        in
        {
          lxcImage = mkLxc "lxc";
          lxcImageMetadata = mkLxc "lxc-metadata";
          tarball =
            (nixpkgs.lib.nixosSystem {
              inherit (baseSystem) system specialArgs;
              modules = baseSystem.modules ++ [
                # make a tarball
                ./modules/tarball.nix
              ];
            }).config.system.build.tarball;

          /*
            produces kernel + initrd which can be either netbooted or booted
            	via kexec providing you with a nixos system running in the memory.
            	The kexec utility as well as a script is also included thus kexec -e still
            	needs to be manually run <as that allows for more freedom> after the script thus its included as well.
            	You can of course change the script to directly -e
          */
          kexecBundle =
            let
              kexecSystem = (
                nixpkgs.lib.nixosSystem {
                  inherit (baseSystem) system specialArgs;
                  modules = baseSystem.modules ++ [
                    ./modules/systemz_specific.nix
                    /*
                      uses my all-hardware.nix with until the issues with the original one
                      			are resolved and ready to go upstream
                    */
                    nixos-s390x.nixosModules.allHardwareFixed
                    #({modulesPath,...}: {imports = [ "${modulesPath}/profiles/all-hardware.nix" ]; })

                    /*
                      provides the "big" initrd containing a whole nixos system which would usually
                      			be loaded from disk
                    */
                    (
                      { modulesPath, ... }:
                      {
                        imports = [ "${modulesPath}/installer/netboot/netboot.nix" ];
                      }
                    )
                    # TOOD remove the "minimal" module from baseSystem so we can reduce dublication

                    /*
                      there  were some issues when not using the latest kernel
                      			alpine seemed to have the same issues
                    */
                    ./modules/custom_kernel_kexec.nix
                  ];
                }
              );
              loadAndExec = false;
            in
            kexecSystem.pkgs.linkFarm "kexec-boot" [
              # kexec kernel image
              {
                name = "bzImage";
                path = "${kexecSystem.config.system.build.kernel}/bzImage";
              }
              # kexec initrd containing an entire nixos stystem
              {
                name = "initrd.gz";
                path = "${kexecSystem.config.system.build.netbootRamdisk}/initrd";
              }
              # include kexec itself so no dep on the systems kexec-tools <as long as the kernel can do it ofc>
              {
                name = "kexec";
                path = "${kexecSystem.pkgs.kexec-tools}/bin/kexec";
              }
              # script that calls kexec  with the correct commandline and initrd, optionally executes it right away
              # TODO  V make ./bzImage and ./initrd relative to the folder the script is in not where its called from
              {
                name = "kexec-boot";
                path = kexecSystem.pkgs.writeScriptBin "kexec-boot" ''
                  ./kexec --load ./bzImage \
                  --initrd=./initrd.gz \
                  --command-line "init=${kexecSystem.config.system.build.toplevel}/init ${toString kexecSystem.config.boot.kernelParams}"
                  ${kexecSystem.lib.strings.optionalString loadAndExec "kexec -e"}
                '';
              }
            ];
          iso =
            (nixpkgs.lib.nixosSystem {
              inherit (baseSystem) system specialArgs;
              modules = baseSystem.modules ++ [

                nixos-s390x.nixosModules.iso
                (
                  { modulesPath, ... }:
                  {

                    imports = [
                      "${modulesPath}/profiles/installation-device.nix"
                      "${modulesPath}/profiles/base.nix"
                    ];
                  }
                )
                # TODO remove (too big for cdrom either way)
                #./modules/fat-debug.nix

                /*
                  use VVV once modules from overlay are upstream or
                  			you use my fork directly youd use this instead
                    			"${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image-s390x.nix"
                */
              ];
            }).config.system.build.isoImage;
        };
    };
}
