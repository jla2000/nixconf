{ inputs, ... }:
{
  flake.nixosModules.stylix =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.stylix.colorscheme = lib.mkOption {
        type = lib.types.str;
        default = "gruvbox-light";
        description = "Base16 colorscheme to use with Stylix";
      };

      imports = [ inputs.stylix.nixosModules.stylix ];

      config = {
        stylix = {
          enable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.stylix.colorscheme}.yaml";
          targets.console.enable = false;
        };
      };
    };
}
