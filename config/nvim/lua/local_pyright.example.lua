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

  -- Current repo virtualenv site-packages. This makes namespace packages like
  -- `some.weird.*` resolve even when Pyright does not pick up venv settings.
  for _, site_packages in ipairs(vim.fn.glob(workspace .. "/.venv/lib/python*/site-packages", false, true)) do
    add_if_dir(paths, site_packages)
  end

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
    --     extraPaths = paths,
    --   },
    -- },
  }
end
