{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self, nixpkgs, ... }:
    {
      lib.userSettings = import ./user-settings.nix;
      lib.systemdNetwork = import ./systemd-network.nix;
      lib.systemdBoot = import ./systemd-boot.nix;
      lib.prometheusNode = import ./prometheus-node.nix;
      lib.emacsWithPackages = import ./emacs-config.nix;
    };
}
