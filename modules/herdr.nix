{ inputs, ... }:
{
  flake.nixosModules.herdr =
    { pkgs, config, ... }:
    let
      settings = {
        onboarding = false;
        theme.name = config.stylix.colorscheme;
        keys = {
          prefix = "ctrl+s";
          split_vertical = "prefix+%";
          split_horizontal = "prefix+\"";
          command = [
            {
              key = "prefix+g";
              type = "pane";
              command = "jjui";
              description = "run jjui";
            }
          ];
        };
        ui = {
          prompt_new_tab_name = false;
          pane_gaps = false;
        };
        experimental.pane_history = false;
      };
    in
    {
      environment.systemPackages = [
        (inputs.wrapper-modules.lib.wrapPackage (
          { ... }:
          {
            inherit pkgs;
            package = pkgs.herdr;
            env.HERDR_CONFIG_PATH = (pkgs.formats.toml { }).generate "herdr-config.toml" settings;
          }
        ))
      ];
    };
}
