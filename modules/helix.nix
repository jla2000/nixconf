{ self, inputs, ... }:
{
  flake.nixosModules.helix =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.helix
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.helix = inputs.wrapper-modules.wrappers.helix.wrap {
        inherit pkgs;
        settings.theme = "catppuccin_mocha";
      };
    };
}
