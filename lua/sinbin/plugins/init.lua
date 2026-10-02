-- Plugin list, managed by the built-in vim.pack (docs/DECISIONS.md D-007).
-- Add each plugin with a one-line reason (docs/RULES.md Plugin).
-- Lock file: nvim-pack-lock.json at the repository root, tracked by git.
-- Plugin settings and keymaps live in the per-area modules required below.

local function mini(name)
  return { src = "https://github.com/nvim-mini/mini." .. name, version = "stable" }
end

vim.pack.add({
  -- Editing (TASK-005, D-008)
  -- Auto-close brackets/quotes: no built-in equivalent.
  mini("pairs"),
  -- Add/delete/replace surroundings: no built-in equivalent.
  mini("surround"),

  -- Search / Navigation (TASK-006)
  -- Fuzzy picker for files, grep, buffers, help: built-in :find/:grep have no live preview list.
  mini("pick"),
  -- Extra pickers (oldfiles) not shipped with mini.pick.
  mini("extra"),
  -- File explorer that edits directories like buffers: netrw kept for remote files.
  mini("files"),

  -- UI (TASK-006)
  -- File icons used by pick/files/statusline.
  mini("icons"),
  -- Statusline with mode, file info, diagnostics.
  mini("statusline"),
  -- Shows next possible keys after a prefix such as <Leader>.
  mini("clue"),
  -- Notification window for vim.notify and LSP progress.
  mini("notify"),
  -- Start screen with recent files and search entry points.
  mini("starter"),

  -- LSP / Completion (TASK-007)
  -- Server configs (cmd, root markers) for the built-in vim.lsp.config.
  { src = "https://github.com/neovim/nvim-lspconfig" },
  -- Installs LSP servers the same way on every OS.
  { src = "https://github.com/mason-org/mason.nvim" },
  -- Completion popup with docs and signature help on top of built-in LSP.
  mini("completion"),

  -- Treesitter (TASK-008)
  -- Installs/updates parsers and queries; highlighting itself is built-in vim.treesitter.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },

  -- Git (TASK-011)
  -- Changed-line signs, hunk preview/stage/reset, inline blame: no built-in equivalent.
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  -- Review all changed files / file history side by side. Maintained fork of sindrets/diffview.nvim.
  -- Default branch: its tags (v0.38) are not semver, so vim.pack cannot use them as versions.
  { src = "https://github.com/dlyongemallo/diffview-plus.nvim" },

  -- Colorscheme: soft neon dark (tokyonight-moon), user choice.
  { src = "https://github.com/folke/tokyonight.nvim" },
})

-- UI first: colorscheme and icons must exist before other modules draw.
require("sinbin.plugins.ui")
require("sinbin.plugins.editing")
require("sinbin.plugins.search")
require("sinbin.plugins.lsp")
require("sinbin.plugins.treesitter")
require("sinbin.plugins.git")
