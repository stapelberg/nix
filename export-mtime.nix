{ pkgs }:

# For string literal escaping rules (''${), see:
# https://nix.dev/manual/nix/2.26/language/string-literals#string-literals

# For writers.writeBashBin, see https://wiki.nixos.org/wiki/Nix-writers

pkgs.writers.writeBashBin "export-mtime" ''
  NIX_STORE_MTIME=$(stat -c %Y /nix/store)
  mkdir -p /run/prometheus-node-exporter/textfile
  echo -e "# TYPE nix_store_mtime_seconds gauge\nnix_store_mtime_seconds $NIX_STORE_MTIME" \
    > /run/prometheus-node-exporter/textfile/nix_store_mtime.prom
''
