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

    local result, focus_error = rex.call("session.focus_direction", {
      session_id = ctx.session_id,
      direction = direction,
    })
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

local agent_picker_script = "/Users/foz/.dotfiles/config/rex/agent_picker.sh"

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
					cwd = "/Users/foz/.dotfiles",
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
