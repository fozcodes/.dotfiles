-- Pure helpers shared by the Rex side and the Neovim side of copy-mode, so
-- both can be tested without a live Rex server or an interactive Neovim.
-- Written for Lua 5.1 (Rex and Neovim both embed LuaJIT).
local M = {}

local ESCAPE = string.char(27)
local UTF8_RANDOM_LEFTOVER = "\194" -- first byte of UTF-8-encoded C1 controls

function M.strip_terminal_nul(text)
  return (text:gsub("%z", ""))
end

local C1_TO_CSI = {
  [0x10] = "P", -- DCS  (0x90)
  [0x18] = "X", -- SOS  (0x98)
  [0x1B] = "[", -- CSI  (0x9B)
  [0x1C] = "\\", -- ST   (0x9C)
  [0x1D] = "]", -- OSC  (0x9D)
  [0x1E] = "^", -- PM   (0x9E)
  [0x1F] = "_", -- APC  (0x9F)
}

local function is_plain_text_byte(b)
  return b >= 32 and b < 127 or b >= 128 or b == 9 or b == 10 or b == 13
    or b == 8 or b == 11 or b == 12
end

-- Reduce a captured VT byte stream to a safe replay subset: printable UTF-8
-- text (+ tab/newline/backspace changed), and SGR sequences ("...m") for
-- color/style. Everything else (OSC/DCS titles, clipboard commands, cursor
-- and device queries, most C0/C1 controls) is dropped rather than forwarded,
-- so replaying the capture cannot drive the viewer terminal.
function M.sanitize_vt(text)
  local out, n = {}, #text
  local i = 1
  while i <= n do
    local b = text:byte(i)
    if b == 27 then
      -- Escape sequence: keep only SGR. Unknown/unfinished endings truncate.
      local kind = text:byte(i + 1)
      i = i + 2
      if kind == nil then
        break
      elseif kind == 91 then -- "[": CSI
        local final = i
        while final <= n and not (text:byte(final) >= 64 and text:byte(final) <= 126) do
          final = final + 1
        end
        if final > n then
          break
        end
        if text:sub(final, final) == "m" and text:sub(i, final - 1):match("^[0-9;:]*$") then
          out[#out + 1] = text:sub(i - 2, final)
        end
        i = final + 1
      elseif kind == 93 or kind == 80 or kind == 88 or kind == 94 or kind == 95 then
        -- "]", "P", "X", "^", "_": bounded string sequences, skip to terminator.
        local stop = text:find(ESCAPE .. "\\", i, true)
        local bell = kind == 93 and text:find("\7", i, true) or nil
        if bell and (not stop or bell < stop) then
          i = bell + 1
        elseif stop then
          i = stop + 2
        else
          break
        end
      elseif kind >= 32 and kind <= 47 then
        -- Two-character escape prefixes (intermediates 0x20..0x2F)
        while i <= n and text:byte(i) >= 32 and text:byte(i) <= 47 do
          i = i + 1
        end
        i = i + 1
      end -- single-character escapes (0x30..0x7E) need no data: already skipped
    elseif b == 0xC2 and text:byte(i + 1) and text:byte(i + 1) >= 128 and text:byte(i + 1) <= 159 then
      -- UTF-8-encoded C1 control: translate to its ESC form where meaningful.
      -- (Checked before the plain-text run, which would swallow the pair.)
      local csi = C1_TO_CSI[text:byte(i + 1) - 128]
      if csi then
        out[#out + 1] = ESCAPE .. csi
      end
      i = i + 2
    elseif is_plain_text_byte(b) then
      local start = i
      i = i + 1
      while i <= n and is_plain_text_byte(text:byte(i)) do
        i = i + 1
      end
      out[#out + 1] = text:sub(start, i - 1)
    elseif b > 127 then
      -- Other non-ASCII bytes: real UTF-8 text, copy the whole run.
      local start = i
      while i <= n and text:byte(i) > 127 do
        i = i + 1
      end
      out[#out + 1] = text:sub(start, i - 1)
    else
      i = i + 1 -- other C0 controls: drop
    end
  end
  return (table.concat(out):gsub("\r\n", "\n"):gsub("\r", "\n"))
end

local GENERIC_LABELS = { [""] = true, shell = true, terminal = true, Terminal = true }

-- Compose the viewer pane label from the terminal title and block label.
-- Kept stable: strips an existing marker first so nesting never stacks.
function M.title(terminal_title, label)
  label = label or "Terminal"
  local prefix = "(copy-mode) "
  local base
  if not GENERIC_LABELS[label] then
    base = label -- the pane has a specific label; it wins
  elseif terminal_title and not GENERIC_LABELS[terminal_title] then
    base = terminal_title
  else
    base = "Terminal"
  end
  base = (base:gsub(UTF8_RANDOM_LEFTOVER .. "[\128-\159]", ""):gsub("[%z\1-\31\127]", ""))
  base = base:gsub("^%s*(.-)%s*$", "%1")
  -- Strip stale markers so labels never accumulate "(copy-mode) (copy-mode)".
  while base:sub(1, #prefix) == prefix do
    base = base:gsub("^%s*", ""):sub(#prefix + 1):gsub("%s*$", "")
  end
  if #base == 0 then
    base = "Terminal"
  end
  -- Rex labels cap at 128 bytes; never cut inside a UTF-8 codepoint.
  local limit = 128 - #prefix
  if #base > limit then
    -- Stepping back over continuation bytes leaves limit on a codepoint start.
    while limit > 0 and base:byte(limit + 1) >= 128 and base:byte(limit + 1) <= 191 do
      limit = limit - 1
    end
    base = base:sub(1, limit)
  end
  return prefix .. (base ~= "" and base or "Terminal")
end

function M.find_rect(node, block_id)
  if node then
    if node.block_id == block_id then
      return node.rect
    end
    if node.split then
      return M.find_rect(node.split.before, block_id) or M.find_rect(node.split.after, block_id)
    end
  end
  return nil
end

-- Locate `block_id` inside `view` (shape of rex.session.view) and return the
-- fraction bounds {x, y, w, h} of its last known layout rectangle plus whether
-- the pane is zoomed. Floating-layer offsets are already baked into node rects.
function M.pane_bounds(view, window_id, block_id)
  for _, window in ipairs(view and view.windows or {}) do
    if window.window_id == window_id then
      if window.zoomed_block_id == block_id then
        return { 0, 0, 1, 1 }, true
      end
      for _, layer in ipairs(window.layers or {}) do
        local rect = M.find_rect(layer.layout, block_id)
        if rect then
          local x, y = math.max(0, rect[1]), math.max(0, rect[2])
          return { x, y, math.min(rect[3], 1 - x), math.min(rect[4], 1 - y) }, false
        end
      end
    end
  end
  error("block not found in the session's current layout", 0)
end

return M
