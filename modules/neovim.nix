{ self, inputs, ... }:
{
  flake.nixosModules.neovim =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.profile.neovim.configDirectory = lib.mkOption {
        type = lib.types.either lib.types.path lib.types.str;
        default = ../config/nvim;
        description = ''
          Neovim config directory. A path is copied into the store
          (reproducible); a string path is read live at runtime (mutable, for
          editing the config in place).
        '';
      };

      config = {
        # Deliver the wrapper-modules neovim directly. Routing it through
        # `programs.neovim` makes nixpkgs re-wrap it and discard the
        # wrapper-modules config (config_directory, aliases, runtimePkgs).
        environment.systemPackages = [
          (self.packages.${pkgs.stdenv.hostPlatform.system}.neovim.wrap {
            settings.config_directory = config.profile.neovim.configDirectory;
          })
        ];
        environment.variables.NVIM_COLORSCHEME = config.stylix.colorscheme;
      };
    };

  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;
        settings = {
          aliases = [
            "vi"
            "vim"
          ];
          config_directory = lib.mkDefault ../config/nvim;
        };
        runtimePkgs = with pkgs; [
          tree-sitter
          ripgrep
          clang-tools
          lua-language-server
          marksman
          nixd
          nixfmt
          rust-analyzer
          rustfmt
          taplo
          zls
        ];
      };
    };
}
