{ inputs, ... }:
{
  flake.nixosModules.alacritty =
    { pkgs, ... }:
    let
      # Catppuccin Mocha as a base16 palette.
      c = {
        base00 = "#1e1e2e";
        base03 = "#6c7086";
        base05 = "#cdd6f4";
        base07 = "#b4befe";
        base08 = "#f38ba8";
        base0A = "#f9e2af";
        base0B = "#a6e3a1";
        base0C = "#94e2d5";
        base0D = "#89b4fa";
        base0E = "#cba6f7";
      };
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
