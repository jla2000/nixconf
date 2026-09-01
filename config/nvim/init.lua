vim.g.mapleader = " "

vim.o.number = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.confirm = true
vim.o.cursorline = true
vim.o.signcolumn = "yes:1"
vim.o.scrolloff = 8
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.wrap = false
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.jumpoptions = "stack"
vim.o.termguicolors = true

vim.pack.add({
  "https://github.com/catppuccin/nvim",
  "https://github.com/saecki/live-rename.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/folke/flash.nvim",
  "https://github.com/folke/persistence.nvim",
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/j-hui/fidget.nvim",
  "https://github.com/folke/lazydev.nvim",
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/saghen/blink.indent",
  "https://github.com/saghen/blink.lib",
  { src = "https://github.com/saghen/blink.pairs", version = "v0.6.0" },
  { src = "https://github.com/saghen/blink.cmp",   version = "v1.10.2" },
})

vim.cmd.colorscheme(vim.env.NVIM_COLORSCHEME or "catppuccin")

pcall(function()
  require("vim._core.ui2").enable({})
end)

require("nvim-treesitter").install({
  "lua",
  "rust",
  "vim",
  "vimdoc",
  "markdown",
  "yaml",
  "c",
  "cpp",
  "json",
  "toml",
  "nix",
})

require("blink.pairs").build()
require("blink.cmp").setup({ keymap = { preset = "default" } })
require("blink.pairs").setup({ highlights = { enabled = false } })
require("blink.indent").setup({ scope = { char = "│" }, static = { char = "│" } })

require("fidget").setup({})
require("oil").setup({ default_file_explorer = true })
require("lazydev").setup()
require("fzf-lua").setup({
  keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } },
  winopts = {
    on_create = function()
      vim.keymap.set("t", "<C-r>", [['<C-\><C-N>"'.nr2char(getchar()).'pi']], { expr = true, buffer = true })
    end
  }
})
require("fzf-lua").register_ui_select()
require("live-rename").setup()
require("persistence").setup()

vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      files = {
        exclude = {
          "target",
          ".direnv",
          "tmp"
        }
      },
      cargo = {
        targetDir = true,
        features = "all",
        target = vim.env.CARGO_BUILD_TARGET or vim.env.REDOX_TARGET,
      },
      check = {
        command = "clippy",
        workspace = false,
      },
      imports = {
        granularity = {
          group = "crate",
          enforce = true,
        },
        group = { enable = true },
        prefix = "crate",
        preferNoStd = true,
        emitMustUse = true,
        prefixExternPrelude = true,
      },
      inlayHints = { lifetimeElisionHints = { enable = "skip_trivial" } },
    }
  }
})

vim.lsp.enable("rust_analyzer")
vim.lsp.enable("lua_ls")
vim.lsp.enable("nixd")
vim.lsp.enable("clangd")
vim.lsp.enable("marksman")
vim.lsp.enable("taplo")
vim.lsp.enable("zls")

vim.keymap.set("n", "<esc>", "<cmd>nohl<cr><esc>")
vim.keymap.set("n", "<leader>bn", "<cmd>bn<cr>")
vim.keymap.set("n", "<leader>bp", "<cmd>bp<cr>")
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "s", require("flash").jump)
vim.keymap.set("n", "-", require("oil").open)
vim.keymap.set("n", "<leader><leader>", FzfLua.global)
vim.keymap.set("n", "<leader>ff", FzfLua.files)
vim.keymap.set("n", "<leader>fr", FzfLua.oldfiles)
vim.keymap.set("n", "<leader>fb", FzfLua.buffers)
vim.keymap.set("n", "<leader>sg", FzfLua.live_grep)
vim.keymap.set("n", "<leader>sR", FzfLua.resume)
vim.keymap.set("n", "<leader>d", FzfLua.lsp_workspace_diagnostics)
vim.keymap.set("n", "<leader>ss", FzfLua.lsp_document_symbols)
vim.keymap.set("n", "<leader>sS", FzfLua.lsp_live_workspace_symbols)
vim.keymap.set("n", "gd", FzfLua.lsp_definitions)
vim.keymap.set("n", "grr", FzfLua.lsp_references)
vim.keymap.set("n", "gra", FzfLua.lsp_code_actions)
vim.keymap.set("n", "gri", FzfLua.lsp_incoming_calls)
vim.keymap.set("n", "gro", FzfLua.lsp_outgoing_calls)
vim.keymap.set("n", "grn", require("live-rename").rename)
vim.keymap.set("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end)


vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("treesitter_update", { clear = true }),
  callback = function(ev)
    if ev.data.kind == "update" and ev.data.spec.name == "nvim-treesitter" then
      require("nvim-treesitter").update()
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_completion", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
    if client:supports_method("textDocument/inlineCompletion") then
      vim.lsp.inline_completion.enable(true, { bufnr = args.buf })
    end
    if client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,
        group = vim.api.nvim_create_augroup("lsp_format_" .. args.buf, { clear = true }),
        callback = function()
          vim.lsp.buf.format({ bufnr = args.buf })
        end,
      })
    end
  end,
})
