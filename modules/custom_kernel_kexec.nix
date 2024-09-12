{ lib, pkgs, ... }:
{

  boot.kernelModules = [ "loop" ];
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linuxPackages_latest.kernel.override {
      version = "6.11.2";
      modDirVersion = "6.11.2";
      src = fetchTarball {
        url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.2.tar.xz";
        #sha256 = "sha256:0h52b741c602ff7i6hyndpjn8n1k06qa2pqprncd2ax9zn0k2d86";
        sha256 = "sha256:ec9ef7a0b9cebb55940e1ef87a1f9e1004b10456a119dc386bb3e565b0d39c42";
      };
      structuredExtraConfig = with lib.kernel; {
        # BAKA CFG
        HZ = freeform "100";
        SCHED_HRTICK = yes;
        # CONFIG_CERT_STORE is not set
        # CONFIG_KERNEL_NOBP is not set
        # CONFIG_EXPOLINE is not set
        RELOCATABLE = yes;
        RANDOMIZE_BASE = yes;
        RANDOMIZE_IDENTITY_BASE = yes;
        KERNEL_IMAGE_BASE = freeform "0x3FFE0000000";
        # end of Processor type and features

        EARLY_PRINTK = yes;
        CRASH_DUMP = lib.mkForce yes;
        DEBUG_INFO = yes;
        EXPERT = yes;
        DEBUG_KERNEL = yes;
        TASK_DELAY_ACCT = yes;
        IKHEADERS = yes; # bcc needs this for memleak testing

        # test if that fixes kernel
        SCLP_TTY = yes;
        SCLP_CONSOLE = yes;
        SCLP_VT220_TTY = yes;
        SCLP_VT220_CONSOLE = yes;
      };
    }
  );
}
