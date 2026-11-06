{ self, inputs, ... }:
{
  flake.nixosModules.helix =
    { pkgs, config, ... }:
    {
      environment.systemPackages = [
        # The colorscheme is a per-host NixOS option, so the theme is applied
        # here instead of in perSystem. Helix names its built-in themes with
        # underscores where base16 schemes use dashes.
        (self.packages.${pkgs.stdenv.hostPlatform.system}.helix.wrap {
          settings.theme = builtins.replaceStrings [ "-" ] [ "_" ] config.stylix.colorscheme;
        })
      ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.helix = inputs.wrapper-modules.wrappers.helix.wrap {
        inherit pkgs;
      };
    };
}
