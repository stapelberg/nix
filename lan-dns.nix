{ config, pkgs, ... }:

# Make single-label LAN hostnames (e.g. `myStrom-Switch-E33414`,
# `gw-hue`) resolvable via the home DNS server.
#
# systemd-resolved refuses to send single-label queries over unicast DNS
# unless ResolveUnicastSingleLabel=yes.
#
# Opt in per machine; do NOT enable this on internet-facing servers.

{
  services.resolved = {
    enable = true;
    domains = [ "lan" ];
    extraConfig = ''
      ResolveUnicastSingleLabel=yes
    '';
  };
}
