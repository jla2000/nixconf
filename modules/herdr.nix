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
            {
              key = "ctrl+h";
              type = "plugin_action";
              command = "vim-herdr-navigation.left";
              description = "navigate left (vim/herdr)";
            }
            {
              key = "ctrl+j";
              type = "plugin_action";
              command = "vim-herdr-navigation.down";
              description = "navigate down (vim/herdr)";
            }
            {
              key = "ctrl+k";
              type = "plugin_action";
              command = "vim-herdr-navigation.up";
              description = "navigate up (vim/herdr)";
            }
            {
              key = "ctrl+l";
              type = "plugin_action";
              command = "vim-herdr-navigation.right";
              description = "navigate right (vim/herdr)";
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
        # jq: vim-herdr-navigation's navigate.sh needs it to detect Vim panes
        pkgs.jq
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
