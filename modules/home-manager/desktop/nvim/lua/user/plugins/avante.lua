return {
  "yetone/avante.nvim",
  dir = vim.g.nix.avante.dir,
  pin = true,
  event = "VeryLazy",
  opts = {
    -- provider = "ollama",
    -- ollama = {
    --   model = "qwq:32b",
    -- },
    provider = "gemini-pro",
    cursor_applying_provider = "gemini-pro",
    behaviour = {
      minimize_diff = true,
      enable_cursor_planning_mode = true,
    },
    gemini = {
      model = "gemini-2.0-flash",
    },
    vendors = {
      ["gemini-pro"] = {
        __inherited_from = "gemini",
        model = "gemini-2.5-pro-exp-03-25",
        timeout = 120000,
      },
      ["gemini-flash"] = {
        __inherited_from = "gemini",
        model = "gemini-2.0-flash-lite",
        timeout = 120000,
      },
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional:
    "nvim-tree/nvim-web-devicons",
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
