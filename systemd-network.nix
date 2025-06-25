{ config, pkgs, ... }:

{
  services.resolved = {
    enable = true;
    llmnr = "false";
  };
  networking.useDHCP = false;
  systemd.network.enable = true;

  systemd.network.networks."10-e" = {
    matchConfig.Name = "e*";  # matches e.g. enp9s0, eth0, etc.
    networkConfig = {
      IPv6AcceptRA = true;
      DHCP = "yes";
    };
  };
}
