{ configfiles, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.tmux ];
  # tmux reads /etc/tmux.conf system-wide (no ~/.tmux.conf needed).
  environment.etc."tmux.conf".source = "${configfiles}/tmux.conf";
}
