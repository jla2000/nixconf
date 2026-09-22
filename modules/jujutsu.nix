{ self, inputs, ... }:
{
  flake.nixosModules.jujutsu =
    { pkgs, config, ... }:
    {
      environment.systemPackages = [
        (self.packages.${pkgs.stdenv.hostPlatform.system}.jujutsu.wrap {
          settings.user = { inherit (config.profile.identity) name email; };
        })
      ];
    };

  perSystem =
    { pkgs, lib, ... }:
    let
      # Track jj main instead of the nixpkgs release.
      src = pkgs.fetchFromGitHub {
        owner = "jj-vcs";
        repo = "jj";
        rev = "55705c3d65c58bb439786a1545cde83066078b5b";
        hash = "sha256-R3z7NrZqYybrty6OqhmKVZ/3iemtZ24Clc2ia5ERVJs=";
      };
      jujutsu-main = pkgs.jujutsu.overrideAttrs {
        version = "0.45.1-unstable-2026-09-22";
        inherit src;
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-0gKJR6/0CszL3z1oV0Iu3EGB6TaRXyuNHn0Y4C5i6sA=";
        };
        # `jj --version` reports the Cargo.toml version, not the -unstable suffix.
        doInstallCheck = false;
      };
    in
    {
      packages.jujutsu = inputs.wrapper-modules.wrappers.jujutsu.wrap {
        inherit pkgs;
        package = jujutsu-main;
        settings = {
          user = {
            name = lib.mkDefault "Jan Lafferton";
            email = lib.mkDefault "jan@lafferton.de";
          };
          ui = {
            pager = ":builtin";
            default-command = "status";
            streampager.interface = "quit-quickly-or-clear-output";
            merge-editor = "vimdiff";
          };
          signing = {
            behavior = "own";
            backend = "ssh";
            key = "~/.ssh/id_ed25519.pub";
          };
        };
      };
    };
}
