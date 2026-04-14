return {
  -- Mason: only tools NOT managed by the active lang/formatting extras
  -- Prettier extra manages: prettier
  -- Python extra manages: pyright, ruff (replaces black/isort/flake8)
  -- Terraform extra manages: terraform-ls, tflint
  -- LazyVim defaults manage: stylua, shfmt
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "eslint_d",   -- JS/TS linter (not included in typescript extra)
        "shellcheck", -- Shell linter
      },
    },
  },

  -- JS/TS linting via eslint_d
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      },
    },
  },

  -- conform.nvim: only formatters not covered by the prettier extra or LazyVim defaults
  -- Prettier extra covers: js, ts, jsx, tsx, css, html, json, yaml, markdown, graphql
  -- LazyVim defaults cover: lua (stylua), sh (shfmt)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        terraform = { "terraform_fmt" },
      },
    },
  },
}
