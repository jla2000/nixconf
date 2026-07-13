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
        specs = {
          start = with pkgs.vimPlugins; [
            flash-nvim
            fzf-lua
            live-rename-nvim
            nvim-lspconfig
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-treesitter.withAllGrammars
            nvim-surround
            oil-nvim
            vim-tmux-navigator
            blink-indent
            blink-cmp
            blink-pairs
            sidekick-nvim
            persistence-nvim
            gruvbox-nvim
            catppuccin-nvim
            (pkgs.vimUtils.buildVimPlugin {
              pname = "fzf-oil-nvim";
              version = "unstable-2026-07-15";
              src = pkgs.fetchFromGitHub {
                owner = "ingur";
                repo = "fzf-oil.nvim";
                rev = "bc20b4d0d3531c9af93247158f89872bf1cea46b";
                hash = "sha256-XIpSCYjIckz4yZPQWmU60yG9+CcvmaODfLtwkkn4Y8w=";
              };
              dependencies = with pkgs.vimPlugins; [
                fzf-lua
                oil-nvim
              ];
            })
          ];
        };
        settings = {
          aliases = [
            "vi"
            "vim"
          ];
          config_directory = lib.mkDefault ../config/nvim;
        };
        runtimePkgs = with pkgs; [
          lua-language-server
          markdownlint-cli2
          marksman
          nixd
          nixfmt
          rust-analyzer
          rustfmt
          shfmt
          stylua
          taplo
          zls
        ];
      };
    };
}
