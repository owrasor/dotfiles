# Design Spec: Markdown Support for Neovim

## Objective
Enhance the Neovim environment to support writing, previewing, and navigating Markdown files with modern features like visual rendering, real-time browser preview, and LSP-backed navigation.

## Proposed Changes

### 1. Plugin Management (`lua/plugins/markdown.lua`)
Introduce a new plugin file to manage Markdown-specific enhancements:
- **`MeanderingProgrammer/render-markdown.nvim`**: For visual rendering of headers, bullets, and tables within the editor.
- **`iamcco/markdown-preview.nvim`**: For real-time browser preview.

### 2. Tool Integration (`lua/plugins/mason.lua`)
Update the `mason` and `mason-tool-installer` configuration to ensure necessary tools are installed:
- **`marksman`**: LSP for Markdown navigation and completion.
- **`markdownlint`**: Linter for Markdown style and syntax.

### 3. Linting Configuration (`lua/plugins/lint.lua`)
Introduce `mfussenegger/nvim-lint` to support asynchronous linting, integrated with `markdownlint` for Markdown files. This will also fix the currently empty `linter_status()` in the status line.

### 4. Formatting Configuration (Existing)
Verify and maintain `conform.nvim` using `prettier` for Markdown formatting.

## User Interaction
- **Rendering:** Automatically active for Markdown files.
- **Preview:** Toggle with `:MarkdownPreviewToggle`.
- **Navigation:** Use LSP features (Goto definition, find symbols) for headers and cross-references.
- **Linting/Formatting:** Automatic on save or via keybinds.

## Success Criteria
- Opening a `.md` file shows rendered headers/lists.
- `:MarkdownPreviewToggle` opens a browser window.
- `marksman` LSP attaches and provides symbol navigation.
- `markdownlint` provides diagnostic feedback for style issues.
- Formatting with `prettier` works as expected.
