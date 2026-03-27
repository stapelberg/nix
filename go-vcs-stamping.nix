# go-vcs-stamping.nix — Overlay that adds automatic VCS stamping to
# `buildGoModule` and `buildGoLatestModule`.
#
# Usage in a flake:
#
#   nixpkgs.overlays = [
#     stapelbergnix.overlays.goVcsStamping
#   ];
#
# That's it. When the `src` attribute of a Go package is a flake input
# (i.e. has `.rev` and `.lastModified`), the built Go binary will
# automatically contain `vcs.revision`, `vcs.time`, and `vcs.modified`
# fields in `debug.ReadBuildInfo()` — without requiring `.git/` in the
# source tree.
#
# For patched/synthetic sources that lack `.rev`, specify explicitly:
#
#   buildGoModule {
#     src = patchedSrc;
#     vcsMetadata = { inherit (originalSrc) rev lastModified; };
#   };
#
# To disable for a specific package:
#
#   buildGoModule {
#     src = mySrc;
#     vcsMetadata = null;  # explicit opt-out
#   };
#
# How it works:
#   1. Creates a minimal `.git/HEAD` so Go's `vcs.FromDir()` detects a repo.
#   2. Puts a tiny shell wrapper on PATH as `git` that answers the two exact
#      commands Go's `gitStatus()` runs.
#   3. Adds `-buildvcs=true` to GOFLAGS.
#   4. If the source already has `.git/`, verifies that our metadata matches
#      the real repository and lets Go use the real git.

{ lib }:

let
  # Detect VCS metadata from src if it's a flake input (has .rev + .lastModified).
  detectVcsMetadata =
    src:
    if builtins.isAttrs src && src ? rev && src ? lastModified then
      {
        inherit (src) rev lastModified;
      }
    else
      null;

  wrapBuildGoModule =
    origBuildGoModule: args:
    # Pass through unchanged when args is a function (nixpkgs finalAttrs pattern).
    # Those are upstream packages — we don't have VCS metadata for them.
    if builtins.isFunction args then
      origBuildGoModule args
    else
      let
        # Priority: explicit vcsMetadata > auto-detect from src > null
        vcsMetadata =
          if args ? vcsMetadata then
            args.vcsMetadata # explicit (including explicit null to opt out)
          else
            detectVcsMetadata (args.src or null);

        cleanArgs = builtins.removeAttrs args [ "vcsMetadata" ];

        vcsAttrs = lib.optionalAttrs (vcsMetadata != null) (
          let
            rev =
              assert lib.asserts.assertMsg (
                builtins.match "[0-9a-f]{40}" vcsMetadata.rev != null
              ) "go-vcs-stamping: rev must be a 40-char hex SHA, got: ${vcsMetadata.rev}";
              vcsMetadata.rev;
            epoch =
              assert lib.asserts.assertMsg (builtins.isInt vcsMetadata.lastModified)
                "go-vcs-stamping: lastModified must be an integer";
              toString vcsMetadata.lastModified;
            # If patches are applied, report vcs.modified=true so the binary
            # honestly reflects that the source differs from the commit.
            isPatched = (args.patches or [ ]) != [ ];
          in
          {
            preConfigure =
              (if args ? preConfigure && args.preConfigure != null then args.preConfigure else "")
              + ''
                              # === go-vcs-stamping.nix ===
                              # Stamp Go binaries with VCS metadata (rev=${lib.strings.substring 0 12 rev}).
                              export GOFLAGS="''${GOFLAGS:+$GOFLAGS }-buildvcs=true"

                              if [ -d .git ] || [ -f .git ]; then
                                # Source has .git — verify metadata matches if git is available.
                                if command -v git >/dev/null 2>&1; then
                                  _real_rev=$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="*" \
                                    git rev-parse HEAD 2>/dev/null || true)
                                  if [ -n "$_real_rev" ] && [ "$_real_rev" != "${rev}" ]; then
                                    echo "" >&2
                                    echo "=== go-vcs-stamping.nix: METADATA MISMATCH ===" >&2
                                    echo "vcsMetadata.rev = ${rev}" >&2
                                    echo ".git HEAD       = $_real_rev" >&2
                                    echo "" >&2
                                    echo "The source has a .git/ directory whose HEAD does not match" >&2
                                    echo "the VCS metadata being stamped. This usually means the flake" >&2
                                    echo "input or vcsMetadata attribute is stale." >&2
                                    echo "=== END METADATA MISMATCH ===" >&2
                                    echo "" >&2
                                    exit 1
                                  fi
                                  echo "go-vcs-stamping.nix: .git present and verified (${lib.strings.substring 0 12 rev})" >&2
                                  # Real git + real .git → Go can use them directly.
                                else
                                  echo "go-vcs-stamping.nix: .git present but no git binary, installing fake wrapper" >&2
                                  # Fall through to fake git setup below.
                                  _govcs_need_fake=1
                                fi
                              else
                                _govcs_need_fake=1
                              fi

                              if [ -n "''${_govcs_need_fake:-}" ]; then
                                # No usable .git — synthesize a minimal one and a fake git wrapper.
                                mkdir -p .git
                                echo "ref: refs/heads/main" > .git/HEAD

                                mkdir -p "$TMPDIR/fake-git-bin"
                                cat > "$TMPDIR/fake-git-bin/git" << FAKEGIT
                #!/bin/sh
                # Fake git wrapper for Go VCS stamping (go-vcs-stamping.nix).
                # Only handles the two exact commands that Go's gitStatus() runs.
                # If Go changes its git invocations, this wrapper will fail the
                # build loudly so you know to update it.
                case "\$*" in
                  "status --porcelain")
                    ${lib.optionalString isPatched ''echo "M patched"''}
                    exit 0
                    ;;
                  *"log -1 --format=%H:%ct"*)
                    echo "${rev}:${epoch}"
                    exit 0
                    ;;
                  *)
                    echo "" >&2
                    echo "=== go-vcs-stamping.nix: FAKE GIT WRAPPER FAILURE ===" >&2
                    echo "Received unexpected git command: git \$*" >&2
                    echo "" >&2
                    echo "Go's VCS detection has likely changed. The fake git wrapper in" >&2
                    echo "go-vcs-stamping.nix needs to be updated to handle this command." >&2
                    echo "" >&2
                    echo "Expected only:" >&2
                    echo "  git status --porcelain" >&2
                    echo "  git -c log.showsignature=false log -1 --format=%H:%ct" >&2
                    echo "" >&2
                    echo "See: https://github.com/golang/go/blob/master/src/cmd/go/internal/vcs/vcs.go" >&2
                    echo "=== END FAKE GIT WRAPPER FAILURE ===" >&2
                    echo "" >&2
                    exit 1
                    ;;
                esac
                FAKEGIT
                                chmod +x "$TMPDIR/fake-git-bin/git"
                                export PATH="$TMPDIR/fake-git-bin:$PATH"
                              fi
                              # === end go-vcs-stamping.nix ===
              '';
          }
        );
      in
      origBuildGoModule (cleanArgs // vcsAttrs);
in
{
  overlay =
    final: prev:
    {
      buildGoModule = wrapBuildGoModule prev.buildGoModule;
    }
    // lib.optionalAttrs (prev ? buildGoLatestModule) {
      buildGoLatestModule = wrapBuildGoModule prev.buildGoLatestModule;
    };
}
