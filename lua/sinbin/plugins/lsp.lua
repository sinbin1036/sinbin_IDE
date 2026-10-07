-- LSP / Completion (TASK-007): built-in vim.lsp + nvim-lspconfig configs,
-- mason.nvim for server installs, mini.completion for the popup.
-- Built-in LSP keymaps (K, grn, gra, grr, gri, gO, Insert <C-s>) are kept as is.

-- Puts Mason's bin directory on PATH so installed servers are found.
require("mason").setup()

require("mini.completion").setup()
-- Kind icons in the completion popup.
MiniIcons.tweak_lsp_kind()
-- Symbol kinds keep plain names: aerial (Outline) uses them as filter keys and
-- highlight group names ("AerialClass"), which cannot contain icons.
for name, id in pairs(vim.lsp.protocol.SymbolKind) do
  if type(name) == "string" then
    vim.lsp.protocol.SymbolKind[id] = name
  end
end

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

-- Completion popup: <Tab>/<S-Tab> move, <CR> accepts the selected item. Without the
-- popup they keep the built-in jump between snippet placeholders (`foo(a, b)`: a -> b).
local map = vim.keymap.set
for key, dir in pairs({ ["<Tab>"] = 1, ["<S-Tab>"] = -1 }) do
  map({ "i", "s" }, key, function()
    if vim.fn.pumvisible() == 1 then
      return dir == 1 and "<C-n>" or "<C-p>"
    end
    if vim.snippet.active({ direction = dir }) then
      return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(dir)
    end
    return key
  end, { expr = true, desc = dir == 1 and "Next completion item / snippet field" or "Previous completion item / snippet field" })
end
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
