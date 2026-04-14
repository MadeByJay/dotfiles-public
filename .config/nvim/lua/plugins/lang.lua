return {
  -- Additional treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Only parsers NOT already installed by active lang extras
      -- (typescript extra covers: javascript, typescript, tsx)
      -- (json extra covers: json, json5)
      -- (python extra covers: python, ninja, rst)
      -- (terraform extra covers: terraform, hcl)
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "css",
        "dockerfile",
        "graphql",
        "html",
        "lua",
        "yaml",
      })
    end,
  },
}
