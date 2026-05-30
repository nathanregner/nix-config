---@module "lazy"
---@type LazySpec
return {
  -- "mtrajano/tssorter.nvim",
  "nathanregner/tssorter.nvim",
  branch = "query",
  keys = function()
    return {
      { "<leader>st", function() require("tssorter").sort({ range = "paragraph" }) end, desc = "[S]ort [t]ree" },
      { "<leader>sT", require("tssorter").sort, desc = "[S]ort full [t]ree" },
    }
  end,
  opts = {
    sortables = {
      graphql = {
        argument = { node = "argument", ordinal = "name" },
        selection = { node = "selection", ordinal = "name" },

        fragments = { node = "definition", ordinal = "fragment_definition" },
        variable = { node = "variable_definition", ordinal = "name" },
        field = { node = "field_definition", ordinal = "name" },
      },
      java = {
        annotation_array = { node = "class_literal" },
        annotation_element = { node = "element_value_pair" },
        method = {
          node = "method_declaration",
          ordinal = "identifier",
          order_by = function(node1, node2)
            local bufnr = vim.api.nvim_get_current_buf()
            ---@param node TSNode
            local function method_name(node) return vim.treesitter.get_node_text(node:field("name")[1], bufnr) end
            return method_name(node1) < method_name(node2)
          end,
        },
      },
      nu = {
        map = { node = "record_entry" },
        list = { node = "val_entry" },
      },
      nix = {
        formal = {
          node = { "formal" },
          order_by = function(node1, node2)
            local line1 = require("tssorter.tshelper").get_text(node1)
            local line2 = require("tssorter.tshelper").get_text(node2)
            local overrides = {}
            for index, value in ipairs({
              "self",
              "inputs",
              "inputs'",
              "outputs",
              "outputs'",
              "sources",
              "options",
              "config",
              "pkgs",
              "lib",
            }) do
              overrides[value] = index
            end

            local index1 = overrides[line1]
            local index2 = overrides[line2]
            if index1 and index2 then
              return index1 < index2
            elseif index1 then
              return true
            elseif index2 then
              return false
            else
              return line1 < line2
            end
          end,
        },
        list = { node = { "element" } },
      },
      terraform = {
        attribute = { node = "attribute", ordinal = "identifier" },
        list = { node = "expression", ordinal = "literal_value" },
      },
      toml = {
        array = { node = "string" },
        pair = { node = "pair", ordinal = "bare_key" },
        table = { node = { "table" } },
      },
      typescript = {
        keys = { node = "pair" },
      },
      typescriptreact = {
        keys = { node = "pair" },
        -- TODO: shorthand_property_identifier
      },
      yaml = {
        keys = { node = "block_mapping_pair" },
        list = { node = "block_sequence_item" },
      },
    },
    logger = {
      -- level = vim.log.levels.TRACE,
      -- outfile = "~/tssorter.log", -- nil prints to messages, or add a path to a file to output logs there
    },
  },
}
