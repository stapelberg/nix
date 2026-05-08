{ pkgs, ... }:

# Mitigation for the "Dirty Frag" local privilege escalation
# (https://github.com/V4bel/dirtyfrag): blacklist the kernel modules
# carrying the page-cache-write vulnerabilities (esp4, esp6, rxrpc).
# Per the NixOS discourse thread
# https://discourse.nixos.org/t/is-nixos-affected-by-dirty-frag/77479

{
  boot.extraModprobeConfig = ''
    install esp4 ${pkgs.coreutils}/bin/false
    install esp6 ${pkgs.coreutils}/bin/false
    install rxrpc ${pkgs.coreutils}/bin/false
  '';
  boot.blacklistedKernelModules = [
    "esp4"
    "esp6"
    "rxrpc"
  ];
}
