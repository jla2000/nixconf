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
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.jumpoptions = "stack"
vim.opt.termguicolors = true

vim.cmd.colorscheme("catppuccin")

vim.pack.add({
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

require("vim._core.ui2").enable({})

require("nvim-treesitter").install({
  "lua",
  "rust",
  "vim",
  "vimdoc",
  "markdown",
})

require("blink.pairs").build()
require("blink.cmp").setup({ keymap = { preset = "default" } })
require("blink.pairs").setup({ highlights = { enabled = false } })
require("blink.indent").setup({ scope = { char = "│" }, static = { char = "│" } })

require("fidget").setup({})
require("oil").setup({ default_file_explorer = true })
require("lazydev").setup()
require("fzf-lua").setup({ keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } } })
require("fzf-lua").register_ui_select()
require("live-rename").setup()
require("persistence").setup()

vim.lsp.enable("rust_analyzer")
vim.lsp.enable("lua_ls")
vim.lsp.enable("nixd")

vim.keymap.set("n", "<esc>", "<cmd>nohl<cr><esc>")
vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("n", "<leader>bn", "<cmd>bn<cr>")
vim.keymap.set("n", "<leader>bp", "<cmd>bp<cr>")
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "s", function()
  require("flash").jump()
end)
vim.keymap.set("n", "-", "<cmd>Oil<cr>")
vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>")
vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>")
vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>")
vim.keymap.set("n", "<leader>sg", "<cmd>FzfLua live_grep<cr>")
vim.keymap.set("n", "<leader>sR", "<cmd>FzfLua resume<cr>")
vim.keymap.set("n", "<leader>S", "<cmd>FzfLua lsp_live_workspace_symbols<cr>")
vim.keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<cr>")
vim.keymap.set("n", "grr", "<cmd>FzfLua lsp_references<cr>")
vim.keymap.set("n", "gra", "<cmd>FzfLua lsp_code_actions<cr>")
vim.keymap.set("n", "grn", function()
  require("live-rename").rename()
end)
vim.keymap.set("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end)

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
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
