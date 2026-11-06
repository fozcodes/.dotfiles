rex.bind("ctrl+s>ctrl+s", "pane.send_key", { key = "ctrl+s" })
local nvim_process_names = {
  nvim = true,
  nvimdiff = true,
}

local function is_nvim_foreground(process)
  if not process then
    return false
  end
  local executable = process.name or process.argv0 or process.path
  if type(executable) ~= "string" then
    return false
  end
  local name = (executable:match("([^/]+)$") or executable):lower():gsub("^%-", "")
  return nvim_process_names[name] == true
end

local layout_epsilon = 0.000001

local function active_window(view)
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == view.active_window_id then
      return window
    end
  end
  return nil
end

local function collect_layout_blocks(node, blocks)
  if node.block_id and node.rect then
    blocks[#blocks + 1] = { block_id = node.block_id, rect = node.rect }
    return
  end
  if not node.split then
    return
  end
  collect_layout_blocks(node.split.before, blocks)
  collect_layout_blocks(node.split.after, blocks)
end

local function adjacent_pane_distance(source, candidate, direction)
  local source_x, source_y, source_width, source_height = unpack(source.rect)
  local candidate_x, candidate_y, candidate_width, candidate_height = unpack(candidate.rect)
  if direction == "up" or direction == "down" then
    local overlap = math.min(source_x + source_width, candidate_x + candidate_width)
      - math.max(source_x, candidate_x)
    if overlap <= layout_epsilon then
      return nil
    end
    if direction == "up" then
      local distance = source_y - (candidate_y + candidate_height)
      if distance >= -layout_epsilon then
        return math.max(0, distance), overlap
      end
    else
      local distance = candidate_y - (source_y + source_height)
      if distance >= -layout_epsilon then
        return math.max(0, distance), overlap
      end
    end
    return nil
  end

  local overlap = math.min(source_y + source_height, candidate_y + candidate_height)
    - math.max(source_y, candidate_y)
  if overlap <= layout_epsilon then
    return nil
  end
  if direction == "left" then
    local distance = source_x - (candidate_x + candidate_width)
    if distance >= -layout_epsilon then
      return math.max(0, distance), overlap
    end
  else
    local distance = candidate_x - (source_x + source_width)
    if distance >= -layout_epsilon then
      return math.max(0, distance), overlap
    end
  end
  return nil
end

local function adjacent_tiled_pane(view, focused_block_id, direction)
  local window = active_window(view)
  if not window then
    return nil
  end

  local blocks = {}
  for _, layer in ipairs(window.layers or {}) do
    if layer.kind == "tiled" and layer.layout then
      collect_layout_blocks(layer.layout, blocks)
    end
  end

  local focused_block
  for _, block in ipairs(blocks) do
    if block.block_id == focused_block_id then
      focused_block = block
      break
    end
  end
  if not focused_block then
    return nil
  end

  local nearest_block_id
  local nearest_distance
  local nearest_overlap
  for _, candidate in ipairs(blocks) do
    if candidate.block_id ~= focused_block_id then
      local distance, overlap = adjacent_pane_distance(focused_block, candidate, direction)
      if distance and overlap and (
        not nearest_distance
        or distance < nearest_distance - layout_epsilon
        or (math.abs(distance - nearest_distance) <= layout_epsilon and overlap > nearest_overlap)
      ) then
        nearest_block_id = candidate.block_id
        nearest_distance = distance
        nearest_overlap = overlap
      end
    end
  end
  return nearest_block_id
end

local function focus_adjacent_pane(session_id, block_id, direction)
  local view, view_error = rex.session.view { session_id = session_id }
  if not view then
    rex.log("warn", "pane navigation: view lookup failed: " .. tostring(view_error))
    return nil, view_error
  end

  local target_block_id = adjacent_tiled_pane(view, block_id, direction)
  if target_block_id then
    return rex.session.focus_block { session_id = session_id, block_id = target_block_id }
  end
  return rex.call("session.focus_direction", {
    session_id = session_id,
    direction = direction,
    wrap = false,
  })
end

local function bind_pane_navigation(key, direction)
  rex.bind(key, function(ctx)
    if not ctx.session_id or not ctx.block_id then
      return false
    end

    local process, process_error = rex.call("block.method", {
      session_id = ctx.session_id,
      block_id = ctx.block_id,
      method = "process",
    })
    if process and is_nvim_foreground(process.foreground) then
      return false
    end
    if not process and process_error then
      rex.log("warn", "pane navigation: process lookup failed: " .. tostring(process_error))
    end

    local title = rex.call("block.method", {
      session_id = ctx.session_id,
      block_id = ctx.block_id,
      method = "title",
    })
    if title and type(title.title) == "string" and title.title:lower() == "nvim" then
      return false
    end

    local result, focus_error = focus_adjacent_pane(ctx.session_id, ctx.block_id, direction)
    if not result then
      rex.log("warn", "pane navigation: focus failed: " .. tostring(focus_error))
    end
    return true
  end)
end

bind_pane_navigation("ctrl+h", "left")
bind_pane_navigation("ctrl+j", "down")
bind_pane_navigation("ctrl+k", "up")
bind_pane_navigation("ctrl+l", "right")
rex.bind("ctrl+s>s", "session.switch")
rex.bind("ctrl+s>shift+s", "session.new")
rex.bind("ctrl+s>shift+w", "session.rename")
rex.bind("ctrl+s>c", "client.tab.new")
rex.bind("ctrl+s>shift+p", "client.tab.move", { direction = "backward" })
rex.bind("ctrl+s>shift+n", "client.tab.move", { direction = "forward" })
rex.bind("ctrl+s>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+s>-", "pane.split", { direction = "down" })
rex.bind("ctrl+s>e", "client.sidebar.toggle")
rex.bind("ctrl+s>h", "pane.resize", { amount = 7, direction = "left" })
rex.bind("ctrl+s>j", "pane.resize", { amount = 7, direction = "down" })
rex.bind("ctrl+s>k", "pane.resize", { amount = 7, direction = "up" })
rex.bind("ctrl+s>l", "pane.resize", { amount = 7, direction = "right" })

rex.bind("ctrl+s>shift+r", "client.config.reload")
rex.bind("ctrl+s>shift+d", "session.close")
rex.bind("ctrl+s>shift+t", "client.tab.rename")
rex.bind("ctrl+s>p", "client.tab.previous")
rex.bind("ctrl+s>n", "client.tab.next")
rex.bind("ctrl+s>1", "client.tab.goto", { index = 1 })
rex.bind("ctrl+s>2", "client.tab.goto", { index = 2 })
rex.bind("ctrl+s>3", "client.tab.goto", { index = 3 })
rex.bind("ctrl+s>4", "client.tab.goto", { index = 4 })
rex.bind("ctrl+s>5", "client.tab.goto", { index = 5 })
rex.bind("ctrl+s>6", "client.tab.goto", { index = 6 })
rex.bind("ctrl+s>7", "client.tab.goto", { index = 7 })
rex.bind("ctrl+s>8", "client.tab.goto", { index = 8 })
rex.bind("ctrl+s>9", "client.tab.goto", { index = 9 })
rex.bind("ctrl+s>shift+x", "client.tab.close")
rex.bind("ctrl+s>tab", "pane.focus_next")
rex.bind("ctrl+s>shift+tab", "pane.focus_previous")
rex.bind("ctrl+s>x", "pane.close")
rex.bind("ctrl+s>z", "pane.zoom")

rex.mode("resize", { exclusive = true })
rex.bind("ctrl+s>r", "client.mode.enter", { name = "resize" })
rex.bind("resize/h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("resize/j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("resize/k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("resize/l", "pane.resize", { amount = 5, direction = "right" })

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local agent_picker_script = config_home .. "/rex/agent_picker.sh"
local agent_picker_cwd = os.getenv("HOME") or "/"

-- Copy-mode: scrollback overlay with vim keys. Own code, see copy_mode*.lua.
-- Based on the concept of https://github.com/CJNE/rex-copy-mode (MIT),
-- rewritten from scratch: starts in normal mode, y closes after yanking.
dofile(config_home .. "/rex/copy_mode.lua").setup({
  key = "ctrl+s>[",
  nvim = "/opt/homebrew/bin/nvim",
  rex = os.getenv("HOME")
    .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
})

rex.action({
	name = "pi_agent_picker",
	title = "Pick Pi Agent",
	description = "Find and focus a Pi pane across Rex sessions.",
	run = function(ctx, args)
		if not ctx.session_id then
			error("Pi agent picker needs an active session", 0)
		end
		local clients, clients_error = rex.session.list_clients({ session_id = ctx.session_id })
		if not clients then
			error(clients_error or "could not list Rex clients", 0)
		end
		local app_client_id
		for _, client in ipairs(clients.clients or {}) do
			if client.info and client.info.kind == "app" then
				if client.client_id == ctx.client_id then
					app_client_id = client.client_id
					break
				end
				app_client_id = app_client_id or client.client_id
			end
		end
		if not app_client_id then
			error("Pi agent picker needs a connected Rex app", 0)
		end
		local result, err = rex.session.new_layer({
			session_id = ctx.session_id,
			bounds = { 0.1, 0.25, 0.8, 0.5 },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				label = "Pi Agent Picker",
				options = {
					command = { "/bin/bash", agent_picker_script, "pick", app_client_id },
					shell = "none",
					cwd = agent_picker_cwd,
					exit = { on_completion = false },
				},
			}),
		})
		if not result then
			error(err, 0)
		end
	end,
})
rex.bind("ctrl+s>a", "pi_agent_picker")

-- Toggle the golden ratio focus tracking. The ratio logic runs in the
-- watcher CLI process (rex do golden_ratio.lua --all, kept alive by the
-- LaunchAgent), so the hotkey and the logic are different Lua VMs and
-- this handler passes the switch through the state file both read.
local golden_ratio_state_path = function()
	local home = os.getenv("HOME") or ""
	local xdg_cache_home = os.getenv("XDG_CACHE_HOME") or home .. "/.cache"
	return xdg_cache_home .. "/rex/golden_ratio_state.lua"
end

local golden_ratio_state_enabled = function()
	local chunk = loadfile(golden_ratio_state_path())
	if not chunk then
		return true -- no state file means tracking is on
	end
	local loaded, state = pcall(chunk)
	if loaded and type(state) == "table" and state.enabled == false then
		return false
	end
	return true
end

local golden_ratio_write_state = function(enabled)
	local directory = golden_ratio_state_path():match("(.*/)[^/]+$") or ""
	os.execute(string.format("mkdir -p %q && printf '%%b' 'return { enabled = %s }\\n' > %q", directory, tostring(enabled), golden_ratio_state_path()))
end

rex.bind("ctrl+s>g", function()
	local enabled = golden_ratio_state_enabled() == false
	golden_ratio_write_state(enabled)
	rex.log("info", "golden ratio: " .. (enabled and "tracking on" or "tracking off"))
	return true
end)
