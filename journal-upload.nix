{ ... }:

{
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://haus.monkey-turtle.ts.net:19532";
  };

  # Wait for tailscale before trying to upload.
  systemd.services.systemd-journal-upload = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    # https://michael.stapelberg.ch/posts/2024-01-17-systemd-indefinite-service-restarts/
    startLimitIntervalSec = 0;
  };
}
