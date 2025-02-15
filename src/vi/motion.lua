local M = {}

local function cls(ch)
  if #ch == 0 then return "s" end

  local c = "w"

  if not c or ch:match("%s") then c = "s" end
  if ch:match("%p") then c = "p" end

  return c
end

local function inc_cursor(x, y, lines)
  x = x + 1
  if x > #lines[y] then
    x = 1
    y = y + 1
    if y > #lines then
      return
    end
  end

  return x, y
end

--- Parses a motion.
-- @param m motion string
-- @param x start x
-- @param y start y
-- @param lines lines in the buffer
-- @return new x
-- @return new y
-- @return true if inclusive
-- @return true if linewise
function M.motion(m, x, y, lines)
    local n = m:match("^%d+")

    if n then
        m = m:sub(#n + 1)
        n = tonumber(n)
    end

    if m == "h" then
        n = n or 1
        return math.max(x - n, 1), y
    elseif m == "j" then
        n = n or 1
        return x, math.min(y + n, #lines), true, true
    elseif m == "k" then
        n = n or 1
        return x, math.max(y - n, 1), true, true
    elseif m == "l" then
        n = n or 1
        return math.min(x + n, #lines[y]), y
    elseif m == "$" then
        return #lines[y], y, true
    elseif m == "0" then
        return 1, y
    elseif m == "G" then
        n = n or #lines
        return x, math.min(math.max(n, 1), #lines), true, true
    elseif m == "gg" then
        n = n or 1
        return x, math.min(math.max(n, 1), #lines), true, true
    elseif m == "w" then
        local c = lines[y]:sub(x, x)
        local startCls = cls(c)

        local cx, cy = inc_cursor(x, y, lines)
        if not cx then return x, y end
        c = lines[cy]:sub(cx, cx)

        -- go one past end of current word
        if startCls ~= "s" then
          while cls(c) == startCls do
            local ncx, ncy = inc_cursor(cx, cy, lines)
            if not ncx then return cx, cy end
            cx, cy = ncx, ncy
            c = lines[cy]:sub(cx, cx)
          end
        end

        -- go to first char of next word
        while cls(c) == "s" do
          -- stop on empty lines
          if #lines[cy] == 0 then break end

          local ncx, ncy = inc_cursor(cx, cy, lines)
          if not ncx then return cx, cy end
          cx, cy = ncx, ncy
          c = lines[cy]:sub(cx, cx)
        end
        
        return cx, cy
    elseif m == "e" then
        local cx, cy = x, y
        local x = nil

        repeat
            local l = lines[cy]

            x = l:match("%w+()", cx)

            if not x then
                if cy < #lines then
                    cy = cy + 1 
                    cx = 1
                else
                    x = #l
                end
            end
        until x

        return x - 1, cy, true
    elseif m == "b" then
        local cx, cy = x, y
        local x = nil

        repeat
            local l = lines[cy]:sub(1, cx - 1)

            x = l:match("()%w+%W*$")

            if not x then
                if cy > 1 then
                    cy = cy - 1 
                    cx = #lines[cy]
                else
                    x = 1
                end
            end
        until x

        return x, cy
    end
end

return M
