-- Unit tests for copy-mode's pure helpers. Run headlessly with Neovim's Lua:
--   nvim --headless -u NONE -i NONE -l config/rex/copy_mode_test.lua
local root = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)")
local common = dofile(root .. "copy_mode_common.lua")

local failures, passed = 0, 0

local function test(name, body)
  local ok, err = pcall(body)
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n     " .. tostring(err))
  end
end

local function assert_equal(expected, actual)
  if expected ~= actual then
    error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
  end
end

-- Reject a byte string containing an ill-formed UTF-8 sequence.
local function is_valid_utf8(text)
  local i, n = 1, #text
  while i <= n do
    local b = text:byte(i)
    local width
    if b < 128 then
      width = 1
    elseif b >= 194 and b <= 223 then
      width = 2
    elseif b >= 224 and b <= 239 then
      width = 3
    elseif b >= 240 and b <= 244 then
      width = 4
    else
      return false
    end
    for follow = 1, width - 1 do
      i = i + 1
      if i > n or not (text:byte(i) >= 128 and text:byte(i) <= 191) then
        return false
      end
    end
    i = i + 1
  end
  return true
end

test("sanitizer passes plain text through untouched", function()
  assert_equal("plain text\twith.tab and\nnewline", common.sanitize_vt("plain text\twith.tab and\rnewline"))
end)

test("sanitizer keeps SGR color sequences and their text", function()
  local styled = "\27[31mred\27[38;5;120mrgb\27[0m"
  assert_equal(styled, common.sanitize_vt(styled))
end)

test("sanitizer drops OSC titles with BEL terminator", function()
  assert_equal("after", common.sanitize_vt("\27]0;evil title\7after"))
end)

test("sanitizer drops OSC titles with ST terminator and parameter form", function()
  assert_equal("after", common.sanitize_vt("\27]2;evil\27\\after"))
end)

test("sanitizer drops DCS responses and SOS, keeping only bracketing text", function()
  assert_equal("afteryadda", common.sanitize_vt("\27Pevilstuff\27\\after\27Xevil\27\\yadda"))
end)

test("sanitizer drops cursor/device queries, keeping neighbor text", function()
  assert_equal("afterechoes", common.sanitize_vt("\27[6nafter\27[999Dechoes"))
end)

test("sanitizer translates UTF-8-encoded C1 CSI to ESC form", function()
  -- 0xC2 0x9B is U+009B (CSI); parameters follow without a literal '['.
  assert_equal("\27[1;31m", common.sanitize_vt("\194\1551;31m"))
end)

test("sanitizer keeps kept sequences before a truncated escape, safe on end of input", function()
  assert_equal("", common.sanitize_vt("\27"))
  assert_equal("", common.sanitize_vt("\27["))
  assert_equal("", common.sanitize_vt("\27[38;5"))
  assert_equal("\27[38;5;1mokay", common.sanitize_vt("\27[38;5;1mokay\27"))
end)

test("sanitizer keeps real UTF-8 text", function()
  assert_equal("héllo ☃", common.sanitize_vt("h\195\169llo \226\152\131"))
end)

test("sanitizer strips DEL and other C0 controls except whitespace", function()
  assert_equal("ab", common.sanitize_vt("a\7\127b\22"))
  assert_equal("a\12", common.sanitize_vt("a\12")) -- formfeed is treated as layout whitespace
end)

test("title falls back to Terminal when both labels are generic", function()
  assert_equal("(copy-mode) Terminal", common.title("", "shell"))
  assert_equal("(copy-mode) Terminal", common.title(nil, nil))
end)

test("title prefers a specific block label over the terminal title", function()
  assert_equal("(copy-mode) build", common.title("make", "build"))
end)

test("title uses the terminal title when the block label is generic", function()
  assert_equal("(copy-mode) make", common.title("make", "shell"))
end)

test("title strips a stacked marker and surrounding control bytes", function()
  assert_equal("(copy-mode) inner", common.title("(copy-mode) inner", "shell"))
  assert_equal("(copy-mode) clean", common.title("\2\3clean\5", "Terminal"))
end)

test("title truncates long UTF-8 titles on a codepoint boundary", function()
  local snow = "\226\152\131" -- ☃, 3 bytes, repeated past the 128-byte cap
  local long = snow:rep(60)
  local result = common.title(long, "shell")
  -- A char-aligned cut may land a few bytes under the cap; never over it.
  assert(#result <= 128 and #result >= 128 - 5, string.format("unexpected title length %d", #result))
  assert(is_valid_utf8(result), "truncated title is not valid UTF-8")
  assert(result:sub(1, #"(copy-mode) ") == "(copy-mode) ", "prefix lost")
end)

test("pane_bounds finds a nested block inside splits", function()
  local view = {
    windows = {
      { window_id = 1, zoomed_block_id = nil, layers = {
        { layout = { split = {
          before = { block_id = 11, rect = { 0, 0, 0.5, 1 } },
          after = { split = {
            before = { block_id = 22, rect = { 0.5, 0, 0.5, 0.5 } },
            after = { block_id = 33, rect = { 0.5, 0.5, 0.5, 0.5 } },
          } },
        } } },
      } },
    },
  }
  local bounds, zoomed = common.pane_bounds(view, 1, 33)
  assert_equal(0.5, bounds[1])
  assert_equal(0.5, bounds[4])
  if zoomed then
    error("expected zoomed to be false", 0)
  end
end)

test("pane_bounds reports a zoomed pane as the full window", function()
  local view = { windows = { { window_id = 5, zoomed_block_id = 9, layers = {} } } }
  local bounds, zoomed = common.pane_bounds(view, 5, 9)
  if not zoomed then
    error("expected zoomed to be true", 0)
  end
  assert_equal(1, bounds[2] + bounds[3])
end)

test("pane_bounds errors when the block is gone", function()
  local ok, err = pcall(common.pane_bounds, { windows = {} }, 3, 7)
  if ok then
    error("expected an error", 0)
  end
  if not tostring(err):find("layout", 1, true) then
    error("unexpected error text: " .. tostring(err), 0)
  end
end)

print(string.format("%d passed, %d failed", passed, failures))
if failures > 0 then
  os.exit(1)
end
