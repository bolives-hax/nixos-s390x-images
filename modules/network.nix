{ pkgs, ... }:
{
  # dhcpcd is useful to have
  environment.defaultPackages = with pkgs; [ dhcpcd ];
  networking = {
    # LKL is broken
    nftables = {
      enable = false;
    };
  };
}
