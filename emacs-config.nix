{ pkgs }:

pkgs.emacs.pkgs.withPackages (
  epkgs: with epkgs; [
    nix-mode
    counsel
    counsel-projectile
    eglot
    go-mode
    gotest # for go-test-current-test
    magit
    magit-popup
    markdown-mode
    org
    projectile
    smex
    window-purpose
    ag
    ledger-mode
    vterm
    notmuch
  ]
)
