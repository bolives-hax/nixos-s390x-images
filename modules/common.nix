{
  nix = {
    settings = {
      cores = 0;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs.flake.setNixPath = true;

}
