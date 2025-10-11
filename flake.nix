{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self, nixpkgs, ... }:
    {
      lib.userSettings = import ./user-settings.nix;
      lib.zshConfig = import ./zsh-config.nix;
      lib.systemdNetwork = import ./systemd-network.nix;
      lib.systemdBoot = import ./systemd-boot.nix;
      lib.prometheusNode = import ./prometheus-node.nix;
      lib.emacsWithPackages = import ./emacs-config.nix;

      formatter = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
