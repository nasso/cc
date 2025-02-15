local config = require("config")
local mc = require("libmc")

local TERM_W, TERM_H = term.getSize()
local BG = colors.black
local FG = colors.white

local gStates = {}
local gItems = {}
local gHighlighted = 1
local gScroll = 0

local function quitHandler()
  local lCtrl = false
  local rCtrl = false

  parallel.waitForAny(
    function()
      while true do
        local _, code = os.pullEvent("key")
        local ctrl = lCtrl or rCtrl

        if code == keys.leftCtrl then
          lCtrl = true
        elseif code == keys.rightCtrl then
          rCtrl = true
        elseif ctrl and code == keys.c then
          break
        end
      end
    end,
    function()
      while true do
        local _, code = os.pullEvent("key_up")
        if code == keys.leftCtrl then
          lCtrl = false
        elseif code == keys.rightCtrl then
          rCtrl = false
        end
      end
    end
  )
end

local function search(tStore, sText)
  local results = {}

  for id, item in pairs(tStore.items) do
    if id:find(sText, 1, true) then
      results[#results+1] = {
        id = id,
        item = item,
      }
    end
  end
  return results
end

local function drawItemList()
  local x, y = term.getCursorPos()

  for y = 2, TERM_H do
    local i = gScroll + y - 1
    local tEntry = gItems[i]

    term.setCursorPos(1, y)
    if tEntry and gHighlighted == i then
      term.setTextColor(colors.white)
      term.setBackgroundColor(colors.gray)
    end
    term.clearLine()
    if tEntry then
      term.write(("%4d %s"):format(
        tEntry.item.total,
        tEntry.id
      ))
    end
    if tEntry and gHighlighted == i then
      term.setBackgroundColor(BG)
      term.setTextColor(FG)
    end
  end
  term.setCursorPos(x, y)
end

local function highlight(i)
  gHighlighted = i

  if gHighlighted > #gItems then
    gHighlighted = 1
  elseif gHighlighted < 1 then
    gHighlighted = #gItems
  end

  gScroll = math.max(gScroll, gHighlighted - TERM_H + 1)
  gScroll = math.min(gScroll, gHighlighted - 1)
end

local function highlightHandler()
  while true do
    local _, code = os.pullEvent("key")

    if code == keys.up then
      highlight(gHighlighted - 1)
      drawItemList()
    elseif code == keys.down then
      highlight(gHighlighted + 1)
      drawItemList()
    end
  end
end

local function promptHandler(prompt, onChange, sText)
  term.setCursorPos(1, 1)
  term.clearLine()
  term.write(prompt)
  return read(nil, nil, function(s)
    local x, y = term.getCursorPos()
    term.setCursorPos(1, 1)
    if onChange(s) == false then
      term.setTextColor(colors.red)
      term.write(prompt)
      term.setTextColor(FG)
    else
      term.write(prompt)
    end
    term.setCursorPos(x, y)
  end, sText)
end

function gStates.search(store, hand, sText)
  local nextState = gStates.pull
  sText = sText or ""

  parallel.waitForAny(
    highlightHandler,
    function()
      while true do
        local _, code = os.pullEvent("key")
        if code == keys.tab then
          nextState = gStates.push
          return
        end
      end
    end,
    function()
      while true do
        sText = promptHandler(
          "Search: ",
          function(s)
            gItems = search(store, s)
            highlight(gHighlighted)
            drawItemList()
          end,
          sText
        )
        if gItems[gHighlighted] then
          return
        end
      end
    end
  )

  return nextState, store, hand, sText
end

function gStates.pull(store, hand, sText)
  local entry = gItems[gHighlighted]
  local sQty = ""

  while true do
    sQty = promptHandler(
      "Quantity: ",
      function(s)
        if s == "" then return end
        if s == "all" then return end

        local n = tonumber(s)
        return n ~= nil
          and n > 0
          and n <= entry.item.total
      end,
      sQty
    )

    local nQty = nil
    if sQty == "" then
      break
    elseif sQty == "all" then
      nQty = entry.item.total
    else
      nQty = tonumber(sQty)
    end

    if nQty then
      store:move(entry.id, nQty, hand)
      break
    end
  end

  return gStates.search, store, hand, sText
end

function gStates.push(store, hand)
  term.clear()
  term.setCursorPos(1, 1)

  print("Storing all items in hand...")
  print("Press <Tab> to go back to search mode")

  parallel.waitForAny(
    function()
      while true do
        local _, code = os.pullEvent("key")
        if code == keys.tab then return end
      end
    end,
    function()
      while true do
        hand:syncAll()
        for k, v in pairs(hand.items) do
          print(("%d %s"):format(v.total, k))
          hand:move(k, v.total, store)
        end
        sleep(1)
      end
    end
  )

  return gStates.search, store, hand
end

local function mounting(msg)
  term.setCursorPos(
    math.floor(TERM_W/2 - #msg/2 + 0.5),
    math.floor(TERM_H/2 + 0.5) - 1
  )
  term.write(msg)
end

local function mountingProgress(p)
  local nBarWidth = TERM_W/2
  local nBarProgress = math.floor(p*nBarWidth)

  term.setCursorPos(
    math.floor(TERM_W/2 - nBarWidth/2 + 0.5),
    math.floor(TERM_H/2 + 0.5) + 1
  )
  term.blit(
    (" "):rep(nBarWidth),
    ("0"):rep(nBarWidth),
    ("0"):rep(nBarProgress)
    ..("8"):rep(nBarWidth - nBarProgress)
  )
end

local M = {}

function M.run()
  local store = mc.new(config.cache_dir)
  local hand = mc.new(config.cache_dir)

  term.clear()

  local names = peripheral.getNames()
  for i, name in ipairs(names) do
    mountingProgress((i-1) / #names)
    if name:match(config.hand_pat) then
      mounting("Mounting hand "..name.."...")
      hand:add(name)
    elseif name:match(config.store_pat) then
      mounting("Mounting store "..name.."...")
      store:add(name)
    end
  end

  term.clear()

  parallel.waitForAny(
    quitHandler,
    function()
      local s = { gStates.search(store, hand) }
      while s[1] do
        s = { s[1](table.unpack(s, 2)) }
      end
    end
  )
  term.clear()
  term.setCursorPos(1, 1)
end

return M
