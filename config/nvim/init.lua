vim.g.mapleader = " "
-- <C-h/j/k/l> is owned by vim-herdr-navigation (falls back to tmux/wincmd)
vim.g.tmux_navigator_no_mappings = 1

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

vim.cmd.packadd("cfilter")
vim.cmd.packadd("nvim.undotree")

local on_jump = function(diagnostic, bufnr)
  if not diagnostic then
    return
  end
  vim.diagnostic.show(diagnostic.namespace, bufnr, { diagnostic }, {
    virtual_lines = { current_line = true },
  })
end
vim.diagnostic.config({ jump = { on_jump = on_jump } })

vim.keymap.set("n", "<esc>", "<cmd>nohl<cr><esc>")
vim.keymap.set("n", "<tab>", "<cmd>bn<cr>")
vim.keymap.set("n", "<s-tab>", "<cmd>bp<cr>")
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>")

vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

require("vim._core.ui2").enable({})

vim.cmd.colorscheme(vim.env.NVIM_COLORSCHEME or "catppuccin-latte")

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
        end,
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
  max_lines = 2,
})

require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

-- Select
local select = function(object)
  return function()
    require("nvim-treesitter-textobjects.select").select_textobject(object, "textobjects")
  end
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
vim.keymap.set({ "n", "x", "o" }, "]f", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[f", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "]a", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[a", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.outer", "textobjects")
end)

require("oil").setup({
  default_file_explorer = true,
  delete_to_trash = true,
})

require("flash").setup()
vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end)
-- vim.keymap.set({ "n", "x", "o" }, "r", function()
--   require("flash").remote()
-- end)

require("sidekick").setup({})
vim.keymap.set({ "n", "x" }, "<leader>aa", function()
  require("sidekick.cli").toggle()
end)
vim.keymap.set({ "n", "x" }, "<leader>ad", function()
  require("sidekick.cli").close()
end)
vim.keymap.set({ "n", "x" }, "<leader>at", function()
  require("sidekick.cli").send({ msg = "{this}" })
end)
vim.keymap.set({ "n", "x" }, "<leader>af", function()
  require("sidekick.cli").send({ msg = "{file}" })
end)
vim.keymap.set({ "n", "x" }, "<leader>av", function()
  require("sidekick.cli").send({ msg = "{selection}" })
end)
vim.keymap.set({ "n", "x" }, "<leader>ap", function()
  require("sidekick.cli").prompt()
end)

require("live-rename").setup()
vim.keymap.set("n", "grn", function()
  require("live-rename").rename()
end)

require("mini.extra").setup()
require("mini.pick").setup({
  window = {
    config = function()
      return {
        anchor = "NW",
        row = 0,
        col = 0,
        width = vim.o.columns,
        height = vim.o.lines - 2,
      }
    end,
  },
  mappings = {
    toggle_explorer = {
      char = "<C-e>",
      func = function()
        local source = MiniPick.get_picker_opts().source
        local cwd, was_explorer = source.cwd, source.name == "File explorer"
        vim.schedule(function()
          if was_explorer then
            MiniPick.builtin.files(nil, { source = { cwd = cwd } })
          else
            MiniExtra.pickers.explorer({ cwd = cwd })
          end
        end)
        return true
      end,
    },
    wipeout = {
      char = "<C-d>",
      func = function()
        local item = MiniPick.get_picker_matches().current
        if type(item) == "table" and item.bufnr then
          vim.api.nvim_buf_delete(item.bufnr, {})
          MiniPick.set_picker_items(MiniPick.get_picker_items(), { do_match = true })
        end
      end,
    },
  },
})
vim.ui.select = MiniPick.ui_select

local function workspace()
  return vim.fs.root(0, ".git") or vim.fn.getcwd()
end

-- Buffer name is empty when unnamed and a URI for oil:// buffers.
local function buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  return vim.fn.isdirectory(dir) == 1 and dir or vim.fn.getcwd()
end

vim.keymap.set("n", "-", "<cmd>Oil<cr>")
vim.keymap.set("n", "<leader>e", function()
  MiniExtra.pickers.explorer({ cwd = buf_dir() })
end)
vim.keymap.set("n", "<leader>E", function()
  MiniExtra.pickers.explorer({ cwd = workspace() })
end)
vim.keymap.set("n", "<leader>ff", function()
  MiniPick.builtin.files(nil, { source = { cwd = workspace() } })
end)
vim.keymap.set("n", "<leader>fr", function()
  MiniExtra.pickers.oldfiles()
end)
vim.keymap.set("n", "<leader>fb", function()
  MiniPick.builtin.buffers()
end)
vim.keymap.set("n", "<leader>sg", function()
  MiniPick.builtin.grep_live()
end)
vim.keymap.set("n", "<leader>ss", function()
  MiniExtra.pickers.lsp({ scope = "document_symbol" })
end)
vim.keymap.set("n", "<leader>sS", function()
  MiniExtra.pickers.lsp({ scope = "workspace_symbol" })
end)
vim.keymap.set("n", "<leader>sR", function()
  MiniPick.builtin.resume()
end)
vim.keymap.set("n", "<leader>d", function()
  MiniExtra.pickers.diagnostic({ scope = "all" })
end)
vim.keymap.set("n", "grr", function()
  MiniExtra.pickers.lsp({ scope = "references" })
end)
vim.keymap.set("n", "gd", function()
  MiniExtra.pickers.lsp({ scope = "definition" })
end)

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
