{ inputs, ... }:
{
  flake.nixosModules.alacritty =
    { pkgs, config, ... }:
    let
      c = config.lib.stylix.colors.withHashtag;
    in
    {
      environment.systemPackages = [
        (inputs.wrapper-modules.wrappers.alacritty.wrap {
          inherit pkgs;
          settings = {
            colors = {
              primary = {
                background = c.base00;
                foreground = c.base05;
              };
              normal = {
                black = c.base00;
                red = c.base08;
                green = c.base0B;
                yellow = c.base0A;
                blue = c.base0D;
                magenta = c.base0E;
                cyan = c.base0C;
                white = c.base05;
              };
              bright = {
                black = c.base03;
                red = c.base08;
                green = c.base0B;
                yellow = c.base0A;
                blue = c.base0D;
                magenta = c.base0E;
                cyan = c.base0C;
                white = c.base07;
              };
            };
          };
        })
      ];
    };
}
