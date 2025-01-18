local r = require("signal")
local motion = require("motion")
local tclexer = require("lexer")

local INSTANCE = os.clock() .. "-" .. math.random(999999)

local function startsWith(s, p)
    return s:sub(1, #p) == p
end

local WIDTH, HEIGHT = term.getSize()
local W_VIEWPORT = window.create(term.current(), 1, 1, WIDTH, HEIGHT - 1)
local W_EDITOR = window.create(W_VIEWPORT, 1, 1, WIDTH, HEIGHT - 1)
local W_STATUS = window.create(term.current(), 1, HEIGHT, WIDTH, 1)
local W_CMD = window.create(term.current(), 1, HEIGHT, WIDTH, 1, false)
local W_NUMBER = window.create(term.current(), 1, 1, 2, HEIGHT - 1, false)

local BG = colors.black
local FG = colors.white
local NUM_BG = BG
local NUM_FG = colors.gray
local HI_PALETTE = {
  ["string"] = colors.green,
  ["char"] = colors.orange,
  ["number"] = colors.orange,
  ["false"] = colors.orange,
  ["true"] = colors.orange,
  ["nil"] = colors.orange,
  ["..."] = colors.lightGray,
  ["let"] = colors.purple,
  ["fn"] = colors.purple,
  ["pub"] = colors.purple,
  ["mod"] = colors.purple,
  ["return"] = colors.purple,
  ["while"] = colors.purple,
  ["break"] = colors.purple,
  ["if"] = colors.purple,
  ["elseif"] = colors.purple,
  ["else"] = colors.purple,
  ["("] = colors.red,
  [")"] = colors.red,
  ["["] = colors.red,
  ["]"] = colors.red,
  ["."] = colors.lightGray,
  [","] = colors.lightGray,
  [":"] = colors.lightGray,
  ["&&"] = colors.lightGray,
  ["||"] = colors.lightGray,
  ["=="] = colors.lightGray,
  ["!="] = colors.lightGray,
  ["<="] = colors.lightGray,
  [">="] = colors.lightGray,
  ["<"] = colors.lightGray,
  [">"] = colors.lightGray,
  ["="] = colors.lightGray,
  [".."] = colors.lightGray,
  ["#"] = colors.yellow,
  ["!"] = colors.yellow,
  ["+"] = colors.yellow,
  ["-"] = colors.yellow,
  ["*"] = colors.yellow,
  ["/"] = colors.yellow,
  ["//"] = colors.yellow,
  ["^"] = colors.yellow,
  ["%"] = colors.yellow,
}

W_EDITOR.setBackgroundColour(BG)
W_EDITOR.setTextColour(FG)
W_EDITOR.clear()

W_STATUS.setBackgroundColour(BG)
W_STATUS.setTextColour(FG)

W_CMD.setBackgroundColour(BG)
W_CMD.setTextColour(FG)

W_NUMBER.setBackgroundColour(NUM_BG)
W_NUMBER.setTextColour(NUM_FG)

local mode, setMode = r.signal("NORMAL")
local cmd, setCmd = r.signal("")
local cmdLineVisible = function()
    return mode() == "COMMAND"
end
local statusLineVisible = function()
    return not cmdLineVisible()
end

local curX, setCurX = r.signal(1)
local curY, setCurY = r.signal(1)
local lineCount, setLineCount = r.signal(0)
local scroll, setScroll = r.signal(0)
local msg, setMsg = r.signal("")

function mkopt(def)
    local get, set = r.signal(def)

    return { get = get, set = set, ty = type(def) }
end

local options = {
    number = mkopt(false);
    relativenumber = mkopt(false);
}
options.nu = options.number
options.rnu = options.relativenumber

local ctrl = false
local register = {}
local buffers = {}
local bi = 0

function yankLines(s, n)
    local b = buffers[bi]

    register = {}

    for i = 1, n do
        register[i] = b.lines[s + i - 1]
    end
end

function switchBuffer(index)
    local oldBuf = buffers[bi]
    local newBuf = buffers[index]

    if oldBuf then
        oldBuf.cx = curX()
        oldBuf.cy = curY()
        oldBuf.scroll = scroll()
    end

    bi = index

    newBuf.cx = newBuf.cx or 1
    newBuf.cy = newBuf.cy or 1
    newBuf.scroll = newBuf.scroll or 0

    setLineCount(#newBuf.lines)
    setCursor(newBuf.cx, newBuf.cy)
    scrollTo(newBuf.scroll)

    -- force draw all visible lines
    do
        local _, h = W_EDITOR.getSize()

        for i = 1, h do
            drawLine(newBuf.scroll + i)
        end
    end
end

function edit(path)
    path = path and shell.resolve(path) or nil

    local newBuffer = {
        lines = {};
        saved = true;
        file = path;
    }

    if path:match("%.tc$") then
      newBuffer.syntax = "tc"
    end

    if path and fs.exists(path) then
        newBuffer.lines = {}
        for line in io.lines(path) do
            table.insert(newBuffer.lines, line)
        end
    end

    table.insert(buffers, newBuffer)
    switchBuffer(#buffers)
end

function save()
    local b = buffers[bi]
    local new = not fs.exists(b.file)
    local f = fs.open(b.file, "wb")
    local bytes = 0

    for _, l in ipairs(b.lines) do
        f.write(l .. "\n")
        bytes = bytes + #l + 1
    end

    f.close()

    b.saved = true

    echo(
        '"' .. b.file .. '"' ..
        (new and " [New] " or " ") ..
        #b.lines .. "L, " ..
        bytes .. "B written"
    )
end

function quit(force)
    local b = buffers[bi]

    if not b.saved and not force then
        echo("E37: No write since last change (add ! to override)")
        return
    end

    table.remove(buffers, bi)

    local newIndex = math.min(bi, #buffers)

    if buffers[newIndex] then
        switchBuffer(newIndex)
        return
    end

    os.queueEvent("exit", INSTANCE)
end

function echo(msg)
    setMsg(msg)
end

function runExCommand(c)
    if c == "q" or c == "q!" then
        quit(c == "q!")
        return true
    elseif c == "w" then
        save()
        return true
    elseif c == "x" or c == "wq" then
        save()
        quit()
        return true
    elseif c:sub(1, 5) == "edit " then
        local path = c:sub(6)

        edit(path)
        return true
    elseif c:sub(1, 2) == "e " then
        local path = c:sub(3)

        edit(path)
        return true
    elseif c:sub(1, 2) == "b " then
        local i = tonumber(c:sub(3))

        if i and buffers[i] then
            switchBuffer(i)
        else
            echo("No buffer: " .. i)
        end
        return true
    elseif c:sub(1, 5) == "echo " then
        echo(c:sub(6))
    elseif c:sub(1, 4) == "set " then
        for optn in c:sub(5):gmatch("%a+") do
            local o = options[optn]

            if not o then
                if optn:sub(1, 2) == "no" then
                    o = options[optn:sub(3)]

                    if o and o.ty == "boolean" then
                        o.set(false)
                    else
                        return false, "'" .. optn:sub(3) .. "' not a boolean"
                    end
                else
                    return false, "'" .. optn .. "' unknown option"
                end
            elseif o.ty == "boolean" then
                o.set(true)
            end
        end

        return true
    elseif c:match("^%d+$") then
        local n = tonumber(c)

        setCursor(1, n)
        return true
    end

    return false, "Unknown command"
end

local ops = {}

function cdyOp(op, m, cx, cy, lines)
    local newX, newY, inc, lw

    if m == op then
        newX = 1
        newY = cy
        inc = true
        lw = true
    else
        newX, newY, inc, lw = motion.motion(m, cx, cy, lines)
    end

    if not newX then return end

    if lw then
        local sy = math.min(newY, cy)
        local ey = math.max(newY, cy)
        local n = ey - sy + 1

        yankLines(sy, n)

        if op == "d" then
            deleteLines(sy, n)
            setCursor(newX, sy)
        elseif op == "c" then
            deleteLines(sy + 1, n - 1)
            setLine(sy, "")
            setCursor(newX, sy)
            setMode("INSERT")
        end
    elseif newY == cy then
        local sx = math.min(newX, cx)
        local ex = math.max(newX, cx)
        local n = ex - sx
        local l = lines[cy]

        if inc then
            n = n + 1
        end

        register = {l:sub(sx, sx + n)}

        if op == "d" or op == "c" then
            setLine(cy, l:sub(1, sx - 1) .. l:sub(sx + n))
            setCursor(sx, cy)
        end

        if op == "c" then
            setMode("INSERT")
        end
    else
        echo("Unsupported motion!")
    end

    return true
end

ops.c = function(...) return cdyOp("c", ...) end
ops.d = function(...) return cdyOp("d", ...) end
ops.y = function(...) return cdyOp("y", ...) end

function runCommand(c)
    local b = buffers[bi]
    local c1 = c:sub(1, 1)
    local cx, cy = curX(), curY()

    for k, v in pairs(ops) do
        if c:sub(1, #k) == k then
            return ops[k](c:sub(#k + 1), cx, cy, b.lines)
        end
    end

    local newX, newY = motion.motion(c, cx, cy, b.lines)

    if newX and newY then
        setCursor(newX, newY)
        return true
    elseif c == "i" then
        setMode("INSERT")
        return true
    elseif c == "s" then
        deleteChar()
        setMode("INSERT")
        return true
    elseif c == "a" then
        setMode("INSERT")
        setCursor(curX() + 1, curY(), true)
        return true
    elseif c == "I" then
        setCursor(1, curY())
        setMode("INSERT")
        return true
    elseif c == "A" then
        setCursor(#b.lines[curY()] + 1, curY(), true)
        setMode("INSERT")
        return true
    elseif c == "o" then
        insertLines(curY() + 1, 1)
        setMode("INSERT")
        setCursor(1, curY() + 1)
        return true
    elseif c == "O" then
        insertLines(curY(), 1)
        setMode("INSERT")
        setCursor(1, curY())
        return true
    elseif c == "x" then                -- EDIT
        deleteChar()
        setCursor(math.min(curX(), #b.lines[curY()]), curY())
        return true
    elseif c == "p" then
        local cy = curY()

        insertLines(cy + 1, register)
        setCursor(1, cy + 1)
        return true
    elseif c == "P" then
        local y = curY()

        insertLines(y, register)
        setCursor(1, y)
        return true
    elseif c == "zz" or c == "zt" or c == "zb" then        -- VIEW
        local cy = curY()

        if c == "zt" then
            scrollTo(cy - 1)
        elseif c == "zz" then
            local _, h = W_EDITOR.getSize()
            scrollTo(cy - math.floor(0.5 + h / 2))
        elseif c == "zb" then
            local _, h = W_EDITOR.getSize()
            scrollTo(cy - h)
        end

        return true
    end

    return false, "Unknown command"
end

function setCursor(x, y, allowOnePastEndOfLine)
    local b = buffers[bi]

    y = math.min(y, #b.lines)
    y = math.max(y, 1)
    local l = b.lines[y] or ""
    x = math.min(x, #l + (allowOnePastEndOfLine and 1 or 0))
    x = math.max(x, 1)

    setCurX(x)
    setCurY(y)
end

function drawLine(i)
    local b = buffers[bi]
    local s = b.lines[i]
    local hi = b.syntax == "tc"
    local y =  i - scroll()
    local cy = curY()

    if hi then
      W_EDITOR.setTextColor(colors.lightGray)
      W_EDITOR.setBackgroundColor(colors.black)
    end
    
    W_EDITOR.setCursorPos(1, y)
    W_EDITOR.clearLine()

    if s then
        W_EDITOR.write(s)
    else
        W_EDITOR.write("~")
    end

    if hi then
      local tokens = tclexer.scan(s)      

      if tokens then
        for i = 1, #tokens do
          local t = tokens[i]
                  
          W_EDITOR.setTextColor(HI_PALETTE[t.ty] or FG)
          W_EDITOR.setCursorPos(t.col, y)
          W_EDITOR.write(t.text)
        end
      end

      W_EDITOR.setTextColor(FG)
    end
    
    if i == cy then
        local x = curX()

        s = s or ""
        c = s:sub(x, x)
        if c == "" then c = " " end

        W_VIEWPORT.setCursorPos(x, i - scroll())
        W_VIEWPORT.setBackgroundColour(FG)
        W_VIEWPORT.setTextColour(BG)
        W_VIEWPORT.write(c)
        W_VIEWPORT.setBackgroundColour(BG)
        W_VIEWPORT.setTextColour(FG)
    end
end

function drawLines(i, n)
    if not n then
        local _, h = W_EDITOR.getSize()
        local s = scroll()

        n = s + h - i
    end

    for y = i, i + n do
        drawLine(y)
    end
end

function setLine(i, s)
    local b = buffers[bi]

    b.lines[i] = s
    b.saved = false

    if i == #b.lines then
        setLineCount(i)
    end
    
    local _, h = W_EDITOR.getSize()
    local s = scroll()
    
    if i > s and i <= h + s then
        drawLine(i)
    end
end

function scrollTo(y)
    y = math.max(0, y)
    local dy = y - scroll()
    
    W_EDITOR.scroll(dy)
    
    local _, h = W_EDITOR.getSize()
    
    setScroll(y)
    
    if dy > 0 then
        for i = 1, dy do
            drawLine(y + h - i + 1)
        end
    elseif dy < 0 then
        for i = 1, -dy do
            drawLine(y + i)
        end
    end
end

function insertChar(c, x, y)
    local b = buffers[bi]

    x = x or curX()
    y = y or curY()

    local l = b.lines[y] or ""
    l = l:sub(1, x - 1) .. c .. l:sub(x)

    setLine(y, l)
end

function insertLines(y, ls)
    local b = buffers[bi]
    local lines = b.lines

    if y > #lines + 1 then
        for i = #lines + 1, y - 1 do
            table.insert(lines, i, "")
        end
    end

    if type(ls) == "number" then
        for i = 1, ls do
            table.insert(lines, y, "")
        end
    else
        for i, l in ipairs(ls) do
            table.insert(lines, y + i - 1, l)
        end
    end

    b.saved = false
    setLineCount(#lines)
    drawLines(y)
end

function deleteChar(x, y)
    local b = buffers[bi]
    local lines = b.lines

    x = x or curX()
    y = y or curY()

    local l = lines[y]
    l = l:sub(1, x - 1) .. l:sub(x + 1)

    setLine(y, l)
end

function deleteLines(y, n)
    local b = buffers[bi]
    local lines = b.lines

    for i = n - 1, 0, -1 do
        table.remove(lines, y + i)
    end

    b.saved = false
    setLineCount(#lines)
    drawLines(y)

    -- clamp cursor
    setCursor(curX(), curY())
end

function handleKeyUp(k)
    if k == keys.leftCtrl or k == keys.rightCtrl then
        ctrl = false
    end
end

function handleKey(k)
    local m = mode()

    if k == keys.leftCtrl or k == keys.rightCtrl then
        ctrl = true
    elseif m == "INSERT" then
        if ctrl and k == keys.c then
            setMode("NORMAL")
            setCursor(curX(), curY())
        elseif k == keys.backspace then
            deleteChar(curX() - 1)
            setCursor(curX() - 1, curY(), true)
        elseif k == keys.enter then
            insertLines(curY() + 1, 1)
            setCursor(1, curY() + 1)
        elseif k == keys.tab then
            insertChar("  ")
            setCursor(curX() + 2, curY(), true)
        end
    elseif m == "NORMAL" then
        if ctrl and k == keys.d then
            setCursor(curX(), curY() + 5)
        elseif ctrl and k == keys.u then
            setCursor(curX(), curY() - 5)
        elseif ctrl and k == keys.c then
            setCmd("")
        elseif ctrl and k == keys.e then
            setCursor(curX(), math.max(curY(), scroll() + 2))
            scrollTo(scroll() + 1)
        elseif ctrl and k == keys.y then
            local _, h = W_EDITOR.getSize()

            setCursor(curX(), math.min(curY(), scroll() + h - 1))
            scrollTo(scroll() - 1)
        end
    elseif m == "COMMAND" then
        if k == keys.enter then
            runExCommand(cmd())
            setCmd("")
            setMode("NORMAL")
        elseif k == keys.backspace then
            local c = cmd()

            if c == "" then
                setMode("NORMAL")
            else
                setCmd(c:sub(1, #c - 1))
            end
        elseif ctrl and k == keys.c then
            setCmd("")
            setMode("NORMAL")
        end
    end
end

function handleChar(c)
    local m = mode()

    if m == "INSERT" then
        insertChar(c)
        setCursor(curX() + 1, curY(), true)
    elseif m == "NORMAL" then
        local command = cmd()

        if c == ":" and command == "" then
            setMode("COMMAND")
        else
            command = command .. c

            if runCommand(command) then
                setCmd("")
            else                
                setCmd(command)
            end
        end
    elseif m == "COMMAND" then
        setCmd(cmd() .. c)
    end
end

-- load file
local args = { ... }

if #args >= 1 then
    edit(args[1])
else
    edit()
end

-- line numbers window
r.memo(function()
    local nu = options.nu.get()
    local rnu = options.rnu.get()
    local visible = nu or rnu

    W_NUMBER.setVisible(visible)

    local _, h = W_EDITOR.getSize()

    if visible then
        local n = math.max(nu and lineCount() or h, 100)
        local w = #tostring(n) + 1

        W_VIEWPORT.reposition(w + 1, 1, WIDTH - w, h)
        W_EDITOR.reposition(1, 1, WIDTH - w, h)
        W_NUMBER.reposition(1, 1, w, h)
    else
        W_VIEWPORT.reposition(1, 1, WIDTH, h)
        W_EDITOR.reposition(1, 1, WIDTH, h)
    end
end)

-- draw line numbers
r.memo(function()
    local nu = options.nu.get()
    local rnu = options.rnu.get()
    local visible = nu or rnu

    if not visible then return end

    local w, h = W_NUMBER.getSize()
    local s = scroll()
    local lc = lineCount()
    local lastY = math.min(h, lc - s)

    W_NUMBER.clear()

    if rnu then
        local cy = curY() - s

        for i = 1, lastY do
            local n = math.abs(i - cy)

            if nu and n == 0 then
                n = tostring(i + s)
                W_NUMBER.setCursorPos(1, i)
            else
                n = tostring(n)
                W_NUMBER.setCursorPos(w - #n, i)
            end

            W_NUMBER.write(n)
        end
    else
        for i = 1, lastY do
            local n = tostring(i + s)

            W_NUMBER.setCursorPos(w - #n, i)
            W_NUMBER.write(n)
        end
    end
end)

-- status line
r.effect(function()
    local visible = statusLineVisible()

    W_STATUS.setVisible(visible)

    if not visible then return end

    local w = W_STATUS.getSize()
    local m = mode()

    W_STATUS.clearLine()
    W_STATUS.setCursorPos(1, 1)

    if m ~= "NORMAL" and m ~= "COMMAND" then
        W_STATUS.write("-- " .. m .. " --")
        setMsg("")
    else
        W_STATUS.write(msg())
    end

    W_STATUS.setCursorPos(w - 28, 1)
    W_STATUS.write(cmd())

    W_STATUS.setCursorPos(w - 18, 1)
    W_STATUS.write(curY() .. "," .. curX())
end)

-- command line
r.effect(function()
    local visible = cmdLineVisible()

    W_CMD.setVisible(visible)

    if not visible then return end

    local c = cmd()

    W_CMD.clearLine()
    W_CMD.setCursorPos(1, 1)
    W_CMD.write(":" .. c)
end)

-- cursor
do
    local oldX, oldY = curX(), curY()

    r.memo(function()
        local b = buffers[bi]
        local lines = b.lines
        local _, h = W_EDITOR.getSize()
        local x, y = curX(), curY()
        local c = string.sub(lines[y] or "~", x, x)

        -- scroll view with cursor
        scrollTo(math.min(math.max(scroll(), y - h), y - 1))

        -- "erase" old cursor
        local oldYScr = oldY - scroll()
        if oldYScr >= 1 and oldYScr <= h then
          local srcTxt, srcFg, srcBg = W_EDITOR.getLine(oldYScr)

          srcTxt = srcTxt:sub(oldX, oldX)
          srcFg = srcFg:sub(oldX, oldX)
          srcBg = srcBg:sub(oldX, oldX)

          if srcTxt == "" then
            srcTxt, srcFg, srcBg = " ", colors.toBlit(FG), colors.toBlit(BG)
          end

          W_VIEWPORT.setCursorPos(oldX, oldYScr)
          W_VIEWPORT.blit(srcTxt, srcFg, srcBg)
        end

        -- draw new cursor
        W_VIEWPORT.setCursorPos(x, y - scroll())
        W_VIEWPORT.setBackgroundColour(FG)
        W_VIEWPORT.setTextColour(BG)
        W_VIEWPORT.write(c == "" and " " or c)
        W_VIEWPORT.setBackgroundColour(BG)
        W_VIEWPORT.setTextColour(FG)

        oldX, oldY = x, y
    end)
end

setMode("NORMAL")
setCursor(1, 1)

-- load /.vimrc if it exists
if fs.exists("/.vimrc") then
    for cmd in io.lines("/.vimrc") do
        runExCommand(cmd)
    end
end

while true do
    local e, k = os.pullEvent()

    if e == "key" then
        handleKey(k)
    elseif e == "key_up" then
        handleKeyUp(k)
    elseif e == "char" then
        handleChar(k)
    elseif e == "exit" and k == INSTANCE then
        term.clear()
        term.setCursorPos(1, 1)
        return
    end
end
