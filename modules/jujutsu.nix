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
    {
      packages.jujutsu = inputs.wrapper-modules.wrappers.jujutsu.wrap {
        inherit pkgs;
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
