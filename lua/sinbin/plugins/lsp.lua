-- LSP / Completion (TASK-007): built-in vim.lsp + nvim-lspconfig configs,
-- mason.nvim for server installs, mini.completion for the popup.
-- Built-in LSP keymaps (K, grn, gra, grr, gri, gO, Insert <C-s>) are kept as is.

-- Puts Mason's bin directory on PATH so installed servers are found.
require("mason").setup()

require("mini.completion").setup()
-- Kind icons in the completion popup.
MiniIcons.tweak_lsp_kind()

vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })

-- Server names are nvim-lspconfig config names (lsp/<name>.lua).
vim.lsp.enable({
  "dartls", -- Ships with the Dart/Flutter SDK, no install needed.
  -- Installed with :MasonInstall (see docs/USAGE.md).
  "vtsls", -- TypeScript / JavaScript
  "basedpyright", -- Python types, completion, navigation
  "ruff", -- Python lint and format
  "clangd", -- C / C++
  "jdtls", -- Java (needs JDK 21+ on PATH)
})

-- Completion popup: <Tab>/<S-Tab> move, <CR> accepts the selected item.
local map = vim.keymap.set
map("i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { expr = true, desc = "Next completion item" })
map("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { expr = true, desc = "Previous completion item" })
-- Replaces the mini.pairs <CR> mapping, so fall back to it when nothing is selected.
map("i", "<CR>", function()
  if vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "\25" -- <C-y>: accept
  end
  return MiniPairs.cr()
end, { expr = true, replace_keycodes = false, desc = "Accept completion or newline" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("sinbin_lsp", { clear = true }),
  desc = "Buffer-local LSP keymaps",
  callback = function(args)
    local function bmap(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, { buffer = args.buf, desc = desc })
    end
    -- basedpyright already provides richer hover for Python.
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    bmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
    bmap({ "n", "x" }, "<Leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")
  end,
})
