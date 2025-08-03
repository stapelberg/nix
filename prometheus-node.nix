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

  # Ensure the exported mtime is refreshed on each nixos-rebuild switch,
  # even when the prometheus-node-exporter does not change.
  system.activationScripts."nix-export-mtime" = {
    text = ''
      ${pkgs.systemd}/bin/systemctl restart prometheus-node-exporter.service || true
    '';
  };
}
