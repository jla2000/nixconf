{ self, inputs, ... }:
{
  # Additive alternative to `self.nixosModules.neovim` (the wrapper-modules +
  # Lua config setup in modules/neovim.nix / config/nvim/init.lua), fully
  # declared in Nix via nixvim. Not imported by any profile/host: both
  # modules place a `bin/nvim` into environment.systemPackages, so having
  # both active on one host at once is a build-time file collision. See
  # `flake.nixosConfigurations.nixvim-test` below for how to build/try it
  # without touching a real host.
  flake.nixosModules.nixvim-config =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.nixvim.nixosModules.nixvim ];

      programs.nixvim = {
        enable = true;
        viAlias = false;
        vimAlias = false;

        opts = {
          number = true;
          cursorline = true;
          undofile = true;
          shiftwidth = 2;
          smarttab = true;
          smartindent = true;
          tabstop = 2;
          expandtab = true;
          signcolumn = "yes:1";
          scrolloff = 8;
          ignorecase = true;
          smartcase = true;
          wrap = false;
          swapfile = false;
          confirm = true;
          splitbelow = true;
          splitright = true;
          foldmethod = "expr";
          foldexpr = "v:lua.vim.treesitter.foldexpr()";
          foldtext = "";
          foldlevel = 99;
          jumpoptions = "stack";
          grepprg = "rg --vimgrep --hidden -g '!.git/*'";
          termguicolors = true;
        };

        globals.mapleader = " ";

        diagnostic.settings.jump.on_jump = lib.nixvim.mkRaw ''
          function(diagnostic, bufnr)
            if not diagnostic then
              return
            end
            vim.diagnostic.show(diagnostic.namespace, bufnr, { diagnostic }, {
              virtual_lines = { current_line = true },
            })
          end
        '';

        autoCmd = [
          {
            event = "TextYankPost";
            callback = lib.nixvim.mkRaw "function() vim.highlight.on_yank() end";
          }
        ];

        colorschemes.catppuccin = {
          enable = true;
          settings.flavour = "macchiato";
        };

        plugins = {
          treesitter = {
            enable = true;
            # Grammar packages default to allGrammars, matching the old
            # nvim-treesitter.withAllGrammars; highlight.enable calls
            # vim.treesitter.start() on FileType, same as the manual
            # autocmd + pcall(vim.treesitter.start) in init.lua. Folding
            # is left out here since foldmethod/foldexpr are set manually
            # in `opts` above.
            highlight.enable = true;
          };

          treesitter-context = {
            enable = true;
            settings.max_lines = 2;
          };

          treesitter-textobjects = {
            enable = true;
            settings = {
              select.lookahead = true;
              move.set_jumps = true;
            };
          };

          oil = {
            enable = true;
            settings = {
              default_file_explorer = true;
              delete_to_trash = true;
            };
          };

          flash.enable = true;

          # NES requires a Copilot client, which this config doesn't set
          # up; disable it explicitly or nixvim's assertion fails eval.
          sidekick = {
            enable = true;
            settings.nes.enabled = false;
          };

          fzf-lua = {
            enable = true;
            profile = "telescope";
            settings = {
              keymap.fzf."ctrl-q" = "select-all+accept";
              buffers.actions."ctrl-d" = lib.nixvim.mkRaw ''
                function(selected)
                  require("fzf-lua.actions").buf_del(selected)
                end
              '';
            };
            keymaps = {
              "<leader>ff" = "files";
              "<leader>fr" = "oldfiles";
              "<leader>fb" = "buffers";
              "<leader>sg" = {
                action = "live_grep";
                settings.hidden = true;
              };
              "<leader>ss" = "lsp_document_symbols";
              "<leader>sS" = "lsp_live_workspace_symbols";
              "<leader>sR" = "resume";
              "<leader>d" = "lsp_workspace_diagnostics";
              "grr" = "lsp_references";
              "gra" = "lsp_code_actions";
              "gd" = "lsp_definitions";
            };
          };

          nvim-surround.enable = true;
          tmux-navigator.enable = true;

          blink-cmp.enable = true;

          blink-pairs = {
            enable = true;
            settings.highlights.enabled = false;
          };

          blink-indent = {
            enable = true;
            settings = {
              scope.char = "│";
              static.char = "│";
            };
          };

          persistence.enable = true;
        };

        # live-rename-nvim has no native nixvim module.
        extraPlugins = with pkgs.vimPlugins; [ live-rename-nvim ];

        lsp = {
          servers = {
            nixd.enable = true;
            rust_analyzer.enable = true;
            zls.enable = true;
            taplo.enable = true;
            marksman.enable = true;

            lua_ls = {
              enable = true;
              config.settings.Lua = {
                diagnostics.globals = [ "vim" ];
                workspace.library = [ (lib.nixvim.mkRaw "vim.env.VIMRUNTIME") ];
              };
            };

            # Custom server, not in nixvim's known-package list: its
            # binary must already be on $PATH some other way.
            cfu = {
              enable = true;
              config = {
                cmd = [
                  "cfu"
                  "lsp"
                  "--stdio"
                ];
                filetypes = [ "json5" ];
              };
            };
          };

          # Global on-attach body, equivalent to init.lua's LspAttach
          # autocmd (client/bufnr are already in scope).
          onAttach = ''
            if client:supports_method("textDocument/inlayHint") then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end
            if client:supports_method("textDocument/inlineCompletion") then
              vim.lsp.inline_completion.enable(true, { bufnr = bufnr })
            end
            if client:supports_method("textDocument/formatting") then
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({ async = false, bufnr = bufnr })
                end,
              })
            end
          '';
        };

        keymaps = [
          {
            mode = "n";
            key = "<esc>";
            action = "<cmd>nohl<cr><esc>";
          }
          {
            mode = "n";
            key = "<tab>";
            action = "<cmd>bn<cr>";
          }
          {
            mode = "n";
            key = "<s-tab>";
            action = "<cmd>bp<cr>";
          }
          {
            mode = "n";
            key = "<leader>bd";
            action = "<cmd>bd<cr>";
          }
          {
            mode = "n";
            key = "<C-k>";
            action = "<C-w>k";
          }
          {
            mode = "n";
            key = "<C-j>";
            action = "<C-w>j";
          }
          {
            mode = "n";
            key = "<C-h>";
            action = "<C-w>h";
          }
          {
            mode = "n";
            key = "<C-l>";
            action = "<C-w>l";
          }
          {
            mode = "v";
            key = ">";
            action = ">gv";
          }
          {
            mode = "v";
            key = "<";
            action = "<gv";
          }
          {
            mode = "t";
            key = "<C-k>";
            action = "<C-w>k";
          }
          {
            mode = "t";
            key = "<C-j>";
            action = "<C-w>j";
          }
          {
            mode = "t";
            key = "<C-h>";
            action = "<C-w>h";
          }
          {
            mode = "t";
            key = "<C-l>";
            action = "<C-w>l";
          }

          {
            mode = [
              "x"
              "o"
            ];
            key = "af";
            action.__raw = ''function() require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects") end'';
          }
          {
            mode = [
              "x"
              "o"
            ];
            key = "if";
            action.__raw = ''function() require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects") end'';
          }
          {
            mode = [
              "x"
              "o"
            ];
            key = "ac";
            action.__raw = ''function() require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects") end'';
          }
          {
            mode = [
              "x"
              "o"
            ];
            key = "ic";
            action.__raw = ''function() require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects") end'';
          }
          {
            mode = [
              "x"
              "o"
            ];
            key = "aa";
            action.__raw = ''function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects") end'';
          }
          {
            mode = [
              "x"
              "o"
            ];
            key = "ia";
            action.__raw = ''function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects") end'';
          }
          {
            mode = "n";
            key = "<leader>a";
            action.__raw = ''function() require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner") end'';
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "]f";
            action.__raw = ''function() require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects") end'';
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "[f";
            action.__raw = ''function() require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects") end'';
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "]a";
            action.__raw = ''function() require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.outer", "textobjects") end'';
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "[a";
            action.__raw = ''function() require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.outer", "textobjects") end'';
          }

          {
            mode = "n";
            key = "-";
            action = "<cmd>Oil<CR>";
          }

          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "s";
            action.__raw = ''function() require("flash").jump() end'';
          }

          {
            mode = "n";
            key = "grn";
            action.__raw = ''function() require("live-rename").rename() end'';
          }

          {
            mode = [
              "n"
              "x"
            ];
            key = "<leader>aa";
            action.__raw = ''function() require("sidekick.cli").toggle() end'';
          }
          {
            mode = [
              "n"
              "x"
            ];
            key = "<leader>ad";
            action.__raw = ''function() require("sidekick.cli").close() end'';
          }
          {
            mode = [
              "n"
              "x"
            ];
            key = "<leader>at";
            action.__raw = ''function() require("sidekick.cli").send({ msg = "{this}" }) end'';
          }
          {
            mode = [
              "n"
              "x"
            ];
            key = "<leader>af";
            action.__raw = ''function() require("sidekick.cli").send({ msg = "{file}" }) end'';
          }
          {
            mode = [
              "n"
              "x"
            ];
            key = "<leader>av";
            action.__raw = ''function() require("sidekick.cli").send({ msg = "{selection}" }) end'';
          }
          {
            mode = [
              "n"
              "x"
            ];
            key = "<leader>ap";
            action.__raw = ''function() require("sidekick.cli").prompt() end'';
          }

          {
            mode = "n";
            key = "<leader>ql";
            action.__raw = ''function() require("persistence").load({ last = true }) end'';
          }
        ];

        # Constructs with no dedicated nixvim option.
        extraConfigLua = ''
          require("live-rename").setup()
          require("fzf-lua").register_ui_select()

          vim.cmd.packadd("cfilter")
          vim.cmd.packadd("nvim.undotree")

          if vim.g.neovide then
            vim.fn.chdir("~")
            vim.g.neovide_cursor_animation_length = 0.05
            vim.g.neovide_scroll_animation_length = 0.15
          end
        '';

        # Runtime tool packages (formatters/LSPs not covered by lsp.servers
        # package defaults), mirroring the old wrapper's runtimePkgs.
        extraPackages = with pkgs; [
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
