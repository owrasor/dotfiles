# Markdown Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add comprehensive Markdown support to Neovim including visual rendering, browser preview, LSP navigation, and linting.

**Architecture:** Use `mason` for tool management, `render-markdown.nvim` for in-editor aesthetics, `markdown-preview.nvim` for external preview, and `nvim-lint` for asynchronous linting.

**Tech Stack:** Lua, Mason, nvim-lspconfig, conform.nvim, nvim-lint.

---

### Task 1: Setup Mason Tools

**Files:**
- Modify: `nvim/lua/plugins/mason.lua`

- [ ] **Step 1: Add marksman and markdownlint to Mason configuration**

```lua
-- nvim/lua/plugins/mason.lua
-- Find mason_lspconfig.setup and add "marksman"
-- Find mason_tool_installer.setup and add "markdownlint"

-- In mason_lspconfig.setup:
ensure_installed = {
    -- ... existing ones
    "marksman",
},

-- In mason_tool_installer.setup:
ensure_installed = {
    -- ... existing ones
    "markdownlint",
},
```

- [ ] **Step 2: Commit changes**

```bash
git add nvim/lua/plugins/mason.lua
git commit -m "feat(markdown): add marksman and markdownlint to mason"
```

---

### Task 2: Setup Markdown Plugins

**Files:**
- Create: `nvim/lua/plugins/markdown.lua`

- [ ] **Step 1: Create the markdown plugin configuration file**

```lua
return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		ft = { "markdown" },
		opts = {},
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
}
```

- [ ] **Step 2: Commit changes**

```bash
git add nvim/lua/plugins/markdown.lua
git commit -m "feat(markdown): add render-markdown and markdown-preview plugins"
```

---

### Task 3: Setup Linting with nvim-lint

**Files:**
- Create: `nvim/lua/plugins/lint.lua`

- [ ] **Step 1: Create the linting configuration file**

```lua
return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			markdown = { "markdownlint" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
```

- [ ] **Step 2: Commit changes**

```bash
git add nvim/lua/plugins/lint.lua
git commit -m "feat(markdown): add nvim-lint for markdownlint support"
```

---

### Task 4: Final Verification

- [ ] **Step 1: Verify installation and functionality**

1. Open a Markdown file (e.g., `test.md`).
2. Run `:Mason` and ensure `marksman` and `markdownlint` are installed.
3. Check if headers are rendered visually by `render-markdown`.
4. Run `:MarkdownPreviewToggle` to verify browser preview.
5. Check status line for linter status (it should now show `markdownlint`).
6. Run `:LspInfo` to ensure `marksman` is attached.
