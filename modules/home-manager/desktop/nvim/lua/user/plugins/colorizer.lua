return {
  "catgoose/nvim-colorizer.lua",
  -- event = "BufReadPre",
  opts = {
    filetypes = {}, -- manual start with `ColorizerAttachToBuffer`
    parsers = {
      hex = { default = true, no_hash = true },
    },
  },
}
