{ config, pkgs, ... }:

{
  time.timeZone = "Europe/Zurich";

  i18n.supportedLocales = [
    "en_DK.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
    "de_CH.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.michael = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGSGdjns3/K3vwrQvwtvEMruFIqDtV//CHWVLUm4XNt michael@midna"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlXLvR47KGYvY27G0+QKqGl4100VcGNclmhrnloZP6/ michael@m1a.lan"
    ];

    isNormalUser = true;
    description = "Michael Stapelberg";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs; [
    git # for checking out github.com/stapelberg/configfiles
    rsync
    zsh
    vim
    (import ./emacs-config.nix {
      inherit pkgs;
    })
    wget
    curl
    rxvt-unicode # for terminfo
    btop
    dool # dstat clone
    ncdu # often useful to get a sense of data
    lsof
    psmisc # for killall
  ];

  programs.zsh.enable = true;
  services.openssh.enable = true;

  # Adding michael as trusted user means
  # we can upgrade the system via SSH (see Makefile).
  nix.settings.trusted-users = [
    "michael"
    "root"
  ];

  # Enable flakes for interactive usage.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Clean the Nix store every week.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
