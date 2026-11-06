-- CLI entry point for the golden ratio module. Two uses:
--   rex do ~/.config/rex/golden_ratio.lua test=1   run unit tests
--   rex do ~/.config/rex/golden_ratio.lua          attach + register handlers
--
-- The server normally does this itself at every start via init.lua; this file
-- exists so the module can be exercised without restarting the server.

local function locate_module()
  local file_source = debug.getinfo(1, "S").source
  if type(file_source) == "string" then
    local script_directory = file_source:gsub("^@", ""):match("(.*/)[^/]+$")
    if script_directory then
      return script_directory .. "lib/golden_ratio.lua"
    end
  end
  local golden_ratio_directory = os.getenv("XDG_CONFIG_HOME")
    or (os.getenv("HOME") or "") .. "/.config"
  return golden_ratio_directory .. "/rex/lib/golden_ratio.lua"
end

local golden_ratio = assert(dofile(locate_module()))

if rex.args and rex.args.test then
  golden_ratio.run_tests()
  return
end

golden_ratio.activate()
