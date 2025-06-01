{ config, pkgs, ... }:

let
  export-mtime = import ./export-mtime.nix { pkgs = pkgs; };
in
{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "${config.networking.hostName}.monkey-turtle.ts.net";

    # Export metrics from text files as well so that we can
    # export the mtime of /nix/store
    #
    # TODO: can we somehow tell NixOS to restart the prometheus-exporter
    # on each nixos-rebuild switch?
    enabledCollectors = [ "textfile" ];
    extraFlags = [
      "--collector.textfile.directory=/run/prometheus-node-exporter/textfile/"
    ];
  };

  systemd.services."prometheus-node-exporter" = {
    # https://michael.stapelberg.ch/posts/2024-01-17-systemd-indefinite-service-restarts/
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "always";
      RestartSec = 1;

      # export the mtime of /nix/store
      ExecStartPre = "${export-mtime}/bin/export-mtime";
    };
  };
}
