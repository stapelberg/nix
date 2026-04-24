{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-index-database,
      ...
    }:
    {
      lib.userSettings = import ./user-settings.nix;
      lib.zshConfig = import ./zsh-config.nix;
      lib.systemdNetwork = import ./systemd-network.nix;
      lib.systemdBoot = import ./systemd-boot.nix;
      lib.prometheusNode = import ./prometheus-node.nix;
      lib.emacsWithPackages = import ./emacs-config.nix;
      lib.enableComma = import ./enable-comma.nix { inherit nix-index-database; };

      overlays.goVcsStamping = (import ./go-vcs-stamping.nix { inherit (nixpkgs) lib; }).overlay;

      formatter = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
