return {
  'nvim-neo-tree/neo-tree.nvim',
  cmd = 'Neotree',
  keys = {
    { '<leader>ee', ':Neotree filesystem reveal toggle right<CR>', { desc = 'Open file explorer' } },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    {
      's1n7ax/nvim-window-picker',
      opts = {
        filter_rules = {
          autoselect_one = true,
          include_current_win = false,
          bo = {
            filetype = { 'neo-tree', "neo-tree-popup", "notify" },
            buftype = { 'terminal', "quickfix" },
          },
        },
      },
    },
  },
  opts = {
    close_if_last_window = true,
    hide_root_node = true,
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "document_symbols",
    },
    source_selector = {
      winbar = true,
      statusline = false,
      -- separator = { left = "", right= "" },
      show_separator_on_edge = true,
      -- highlight_tab = "SidebarTabInactive",
      -- highlight_tab_active = "SidebarTabActive",
      -- highlight_background = "StatusLine",
      -- highlight_separator = "SidebarTabInactiveSeparator",
      -- highlight_separator_active = "SidebarTabActiveSeparator",
    },
    default_component_configs = {
      indent = {
        padding = 0,
      },
      name = {
        use_git_status_colors = false,
        highlight_opened_files = true,
      },
    },
    window = {
      width = 80,
    },
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_by_name = {
          ".git",
        },
      },
      -- follow_current_file = {
      --   enabled = true,
      -- },
      group_empty_dirs = false
    },
  },
}
