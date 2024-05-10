local inactiveBg = {
  bg = { attribute = 'bg', highlight = 'BufferlineInactive' },
}

return {
  'akinsho/bufferline.nvim',
  dependencies = 'nvim-tree/nvim-web-devicons',
  opts = {
    options = {
      indicator = {
        icon = ' ',
      },
      show_close_icon = false,
      tab_size = 0,
      max_name_length = 25,
      offsets = {
        {
          filetype = 'NvimTree',
          text = '  Files',
          highlight = 'StatusLine',
          text_align = 'left',
        },
        {
          filetype = 'neo-tree',
          text = function()
            return ' '..vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
          end,
          highlight = 'StatusLineComment',
          text_align = 'left',
        },
      },
      hover = {
        enabled = true,
        delay = 0,
        reveal = { "close" },
      },
      separator_style = 'slant',
      modified_icon = '',
      custom_areas = {
        left = function()
          return {
            { text = ' ' },
          }
        end,
        right = function()
          return {
            { text = '    ', fg = '#8fff6d' },
          }
        end,
      },
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match("error") and " " or " "
        return icon .. count
      end,
    },
  }
}
