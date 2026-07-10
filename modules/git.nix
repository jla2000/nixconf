{ self, inputs, ... }:
{
  flake.nixosModules.git =
    { pkgs, config, ... }:
    {
      programs.git = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.git.wrap {
          settings.user = { inherit (config.profile.identity) name email; };
        };
      };
    };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.git = inputs.wrapper-modules.wrappers.git.wrap {
        inherit pkgs;
        settings = {
          user = {
            name = lib.mkDefault "Jan Lafferton";
            email = lib.mkDefault "jan@lafferton.de";
            signingKey = "~/.ssh/id_ed25519.pub";
          };
          core.whitespace = "error";
          pull.rebase = true;
          gpg.format = "ssh";
          commit.gpgsign = true;
          merge.tool = "vimdiff";
          diff.tool = "nvim_difftool";
          difftool."nvim_difftool".cmd = "nvim -c \"packadd nvim.difftool\" -c \"DiffTool $LOCAL $REMOTE\"";
        };
      };
    };
}
