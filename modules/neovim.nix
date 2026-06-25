{ self, inputs, ... }:
{
  flake.nixosModules.neovim =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
      };
    };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;
        specs = {
          start =
            with pkgs.vimPlugins;
            let
              direnv-nvim = pkgs.vimUtils.buildVimPlugin {
                name = "direnv.nvim";
                src = pkgs.fetchFromGitHub {
                  owner = "NotAShelf";
                  repo = "direnv.nvim";
                  rev = "564146278b3d5fe4ffa389cd103bab20f9b515d6";
                  hash = "sha256-JbnGoZMApLtq4lSdGolcpKdsneolSOrzIi+O5yR2NDQ=";
                };
              };
            in
            [
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
              direnv-nvim
              persistence-nvim
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
