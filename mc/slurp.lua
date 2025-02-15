local config = require("config")
local mc = require("libmc")

local SLURPING = {
  "Chewing",
  "Consuming",
  "Devouring",
  "Downing",
  "Drinking",
  "Eating",
  "Ingesting",
  "Savouring",
  "Slurping",
  "Sucking",
  "Swallowing",
  "Voring",
}

local function slurpAll(store, hand)
  local nMoved = 0

  for k, v in pairs(hand.items) do
    local verb = SLURPING[math.random(#SLURPING)]
    print(("%s %d %s"):format(verb, v.total, k))
    nMoved = nMoved + hand:move(k, v.total, store)
  end
  return nMoved
end

local M = {}

function M.run()
  local store = mc.new(config.cache_dir)
  local hand = mc.new(config.cache_dir)

  for
    _, name in
    ipairs(peripheral.getNames())
  do
    if name:match(config.hand_pat) then
      print("Mounting hand "..name.."...")
      hand:add(name)
    elseif name:match(config.store_pat) then
      print("Mounting store "..name.."...")
      store:add(name)
    end
  end

  local nTotal = 0

  print("Press any key to stop")
  parallel.waitForAny(
    function()
      os.pullEvent("key")
    end,
    function()
      while true do
        hand:syncAll()
        nTotal = nTotal + slurpAll(store, hand)
        sleep(1)
      end
    end
  )

  if nTotal == 0 then
    print("I got NOTHING!")
  elseif nTotal < 10 then
    print(("Just %d? But I'm starving..."):format(nTotal))
  elseif nTotal < 100 then
    print(("%d items. Yummy!"):format(nTotal))
  elseif nTotal < 1000 then
    print(("%d items. What a feast..."):format(nTotal))
  else
    print(("oh my god where did all the %d items go"):format(nTotal))
    print((
      "me rubbing my %d items shaped belly: "
      .."*buuuurp* uhhhh i dont know"
    ):format(nTotal))
  end
end

return M
