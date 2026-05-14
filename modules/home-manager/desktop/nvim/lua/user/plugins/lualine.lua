---@module "lazy"
---@type LazySpec
return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      icons_enabled = false,
      -- theme = "catppuccin",
      component_separators = "|",
    },
    sections = {
      lualine_a = {
        "mode",
        function()
          local reg = vim.fn.reg_recording()
          if reg == "" then return "" end
          return "recording to " .. reg
        end,
      },
      lualine_b = { "diagnostics" },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress", "searchcount" },
      lualine_z = { "location", "selectioncount" },
    },
  },
}
