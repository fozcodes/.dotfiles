local function add_if_dir(paths, path)
  if vim.fn.isdirectory(path) == 1 then
    table.insert(paths, path)
  end
end

return function(workspace)
  workspace = workspace or vim.fn.getcwd()

  local paths = {}
  local parent = vim.fn.fnamemodify(workspace, ":h")

  -- Current repo src layout.
  add_if_dir(paths, workspace .. "/src")
  add_if_dir(paths, workspace .. "/lib")

  -- Do not add .venv/site-packages here. Pyright gets installed packages from
  -- the configured venv; adding site-packages to extraPaths makes the language
  -- server index thousands of library files on save.

  -- Sibling Vantage service checkouts, e.g.
  -- ../some-weird-lib-naming-apis/src/some/weird/apis
  -- ../some-weird-lib-naming-ioc/src/some/weird/ioc
  for _, path in ipairs(vim.fn.glob(parent .. "/some-weird-lib-naming-*/src", false, true)) do
    add_if_dir(paths, path)
  end

  return {

    -- Return the extraPaths in the format expected by Pyright.
    -- python = {
    --   analysis = {
    --     diagnosticMode = "openFilesOnly",
    --     indexing = false,
    --     extraPaths = paths,
    --   },
    -- },
  }
end
