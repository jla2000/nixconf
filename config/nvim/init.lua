vim.g.mapleader = " "

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.undofile = true
vim.opt.shiftwidth = 2
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.signcolumn = "yes:1"
vim.opt.scrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.confirm = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.foldlevel = 99
vim.opt.jumpoptions = "stack"
vim.opt.grepprg = "rg --vimgrep --hidden -g '!.git/*'"
vim.opt.termguicolors = true
-- vim.opt.timeoutlen = 300

vim.cmd.packadd "cfilter"
vim.cmd.packadd "nvim.undotree"

local on_jump = function(diagnostic, bufnr)
  if not diagnostic then return end
  vim.diagnostic.show(diagnostic.namespace, bufnr, { diagnostic }, {
    virtual_lines = { current_line = true },
  })
end
vim.diagnostic.config({ jump = { on_jump = on_jump } })

vim.keymap.set("n", "<esc>", "<cmd>nohl<cr><esc>")
vim.keymap.set("n", "<tab>", "<cmd>bn<cr>")
vim.keymap.set("n", "<s-tab>", "<cmd>bp<cr>")
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>")

vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end
})

require("vim._core.ui2").enable({})

vim.opt.background = "light"
vim.cmd.colorscheme("gruvbox")

vim.lsp.enable("nixd")
vim.lsp.enable("lua_ls")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("zls")
vim.lsp.enable("taplo")
vim.lsp.enable("marksman")
vim.lsp.enable("cfu")

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { library = { vim.env.VIMRUNTIME } },
    },
  },
})

vim.lsp.config("cfu", {
  cmd = { "cfu", "lsp", "--stdio" },
  filetypes = { "json5" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_completion", { clear = true }),
  callback = function(args)
    local client_id = args.data.client_id
    if not client_id then
      return
    end

    local client = vim.lsp.get_client_by_id(client_id)
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
        callback = function()
          vim.lsp.buf.format({ async = false, bufnr = args.buf })
        end
      })
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "*" },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

require("treesitter-context").setup({
  max_lines = 2
})

require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

-- Select
local select = function(object)
  return function() require("nvim-treesitter-textobjects.select").select_textobject(object, "textobjects") end
end
vim.keymap.set({ "x", "o" }, "af", select("@function.outer"))
vim.keymap.set({ "x", "o" }, "if", select("@function.inner"))
vim.keymap.set({ "x", "o" }, "ac", select("@class.outer"))
vim.keymap.set({ "x", "o" }, "ic", select("@class.inner"))
vim.keymap.set({ "x", "o" }, "aa", select("@parameter.outer"))
vim.keymap.set({ "x", "o" }, "ia", select("@parameter.inner"))

-- Swap
vim.keymap.set("n", "<leader>a", function()
  require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
end)

-- Move
vim.keymap.set({ "n", "x", "o" }, "]f",
  function() require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[f",
  function() require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]a",
  function() require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "[a",
  function() require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.outer", "textobjects") end)

require("oil").setup({
  default_file_explorer = true,
  delete_to_trash = true,
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>")

require("flash").setup()
vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end)

require("sidekick").setup({})
vim.keymap.set({ "n", "x" }, "<leader>aa", function() require("sidekick.cli").toggle() end)
vim.keymap.set({ "n", "x" }, "<leader>ad", function() require("sidekick.cli").close() end)
vim.keymap.set({ "n", "x" }, "<leader>at", function() require("sidekick.cli").send({ msg = "{this}" }) end)
vim.keymap.set({ "n", "x" }, "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" }) end)
vim.keymap.set({ "n", "x" }, "<leader>av", function() require("sidekick.cli").send({ msg = "{selection}" }) end)
vim.keymap.set({ "n", "x" }, "<leader>ap", function() require("sidekick.cli").prompt() end)

require("fzf-lua").setup({
  "telescope",
  keymap = {
    fzf = {
      ["ctrl-q"] = "select-all+accept"
    }
  },
  buffers = {
    actions = {
      ["ctrl-d"] = function(selected)
        require("fzf-lua.actions").buf_del(selected)
      end,
    },
  },
})

require("live-rename").setup()
vim.keymap.set("n", "grn", function() require("live-rename").rename() end)

require("fzf-lua").register_ui_select()
vim.keymap.set("n", "<leader>ff", function() require("fzf-lua").files() end)
vim.keymap.set("n", "<leader>fr", function() require("fzf-lua").oldfiles() end)
vim.keymap.set("n", "<leader>fb", function() require("fzf-lua").buffers() end)
vim.keymap.set("n", "<leader>sg", function() require("fzf-lua").live_grep({ hidden = true }) end)
vim.keymap.set("n", "<leader>ss", function() require("fzf-lua").lsp_document_symbols() end)
vim.keymap.set("n", "<leader>sS", function() require("fzf-lua").lsp_live_workspace_symbols() end)
vim.keymap.set("n", "<leader>sR", function() require("fzf-lua").resume() end)
vim.keymap.set("n", "<leader>d", function() require("fzf-lua").lsp_workspace_diagnostics() end)
vim.keymap.set("n", "grr", function() require("fzf-lua").lsp_references() end)
vim.keymap.set("n", "gra", function() require("fzf-lua").lsp_code_actions() end)
vim.keymap.set("n", "gd", function() require("fzf-lua").lsp_definitions() end)

require("blink.cmp").setup({})
require("blink.pairs").setup({ highlights = { enabled = false } })
require("blink.indent").setup({
  scope = { char = "│" },
  static = { char = "│" },
})

require("persistence").setup()
vim.keymap.set("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end)

vim.keymap.set("t", "<C-k>", "<C-w>k")
vim.keymap.set("t", "<C-j>", "<C-w>j")
vim.keymap.set("t", "<C-h>", "<C-w>h")
vim.keymap.set("t", "<C-l>", "<C-w>l")

if vim.g.neovide then
  vim.fn.chdir("~")
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_scroll_animation_length = 0.15
end
