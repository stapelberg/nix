{ ... }:

# Restrict SSH (port 22/tcp) to LAN + tailnet sources, denying access from
# the public IPv6 internet.
#
# Background: on home VMs the LAN interface (`ens18`, `eno1`, …) carries
# both the LAN IPv4 (10.0.0.0/24) AND the public IPv6 prefix delegated from
# the WAN (2a02:…::/56). An interface-scoped allow rule
# (`networking.firewall.interfaces.<iface>.allowedTCPPorts = [22]`) would
# therefore still accept public-IPv6 SSH connections — they arrive on the
# same interface. Filtering by source address is the only way to block
# them while keeping LAN access.
#
# Tailnet access is already accepted by `ts-input` (Tailscale's hook,
# jumped from the INPUT chain before `nixos-fw`), so no rule for the
# tailnet is needed here.
{
  # Default `openssh.openFirewall = true` adds 22 to
  # `networking.firewall.allowedTCPPorts`, which is unconditional and
  # would override what we set below. Disable it.
  services.openssh.openFirewall = false;

  # Allow SSH from the home LAN. `extraCommands` is plain shell — both
  # `iptables` and `ip6tables` are available; the iptables-based firewall
  # module doesn't expose a separate `extraCommandsIPv6` option.
  #
  # IPv4: 10.0.0.0/24 (home LAN).
  # IPv6: fdf5:3606:2a21::/48 (home LAN ULA prefix, covers the /64 currently
  # in use) and fe80::/10 (link-local). Public-v6 sources are implicitly
  # denied — they fall through to nixos-fw-log-refuse.
  networking.firewall.extraCommands = ''
    iptables  -A nixos-fw -s 10.0.0.0/24         -p tcp --dport 22 -j nixos-fw-accept
    ip6tables -A nixos-fw -s fdf5:3606:2a21::/48 -p tcp --dport 22 -j nixos-fw-accept
    ip6tables -A nixos-fw -s fe80::/10           -p tcp --dport 22 -j nixos-fw-accept
  '';
}
