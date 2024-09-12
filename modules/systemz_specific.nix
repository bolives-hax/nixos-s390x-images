{ pkgs, ... }:
{
  # for zipl
  environment.defaultPackages = with pkgs; [ s390-tools ];
}
