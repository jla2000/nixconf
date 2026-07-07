{ inputs, ... }:
{
  flake.nixosModules.stylix =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-light.yaml";
        targets.console.enable = false;
      };
    };
}
