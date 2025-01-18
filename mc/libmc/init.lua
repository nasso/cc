local MegaChest = {}
MegaChest.__index = MegaChest

function MegaChest.new()
  local mc = {}

  mc._ps = {}
  mc._freeLists = {}
  mc.items = {}

  return setmetatable(mc, MegaChest)
end

--- Attach inventory from peripheral `pname`
function MegaChest:add(pname)
  local p = peripheral.wrap(pname)
  
  self._ps[pname] = p
  self._freeLists[pname] = {}
  self:sync(pname)
end

--- Rescan all peripherals
function MegaChest:syncAll()
  for k in pairs(self._ps) do
    self:sync(k)
  end
end

--- Scan the contents of an inventory
function MegaChest:sync(pname)
  local p = self._ps[pname]
  local freeList = self._freeLists[pname]

  -- "forget" old items
  -- perf: this iterates over ALL slots!
  for key, gInfo in pairs(self.items) do
    for i = #gInfo.slots, 1, -1 do
      local slot = gInfo.slots[i]

      if slot.pname == pname then
        gInfo.total = gInfo.total - slot.count
        table.remove(gInfo.slots, i)
      end
    end

    if gInfo.total == 0 then
      self.items[key] = nil
    end
  end

  local itemList = p.list()
  local slotCount = p.size()

  for slotId = 1, slotCount  do
    local item = itemList[slotId]

    if not item then
      freeList[#freeList + 1] = slotId
    else
      local name = item.name
      local count = item.count
      local nbt = item.nbt
      local storeKey = name

      if nbt ~= nil then
        storeKey = name .. "." .. nbt
      end

      local gInfo = self.items[storeKey]

      if gInfo == nil then
        gInfo = {}
        gInfo.slots = {}
        gInfo.total = 0
        self.items[storeKey] = gInfo
      end

      local slot = {}
      slot.pname = pname
      slot.id = slotId
      slot.count = count
      slot.max = p.getItemLimit(slotId)

      gInfo.total = gInfo.total + count
      table.insert(gInfo.slots, slot)
    end
  end
end

local function allocSlot(self, key)
  local gInfo = self.items[key]

  if gInfo == nil then
    gInfo = {}
    gInfo.slots = {}
    gInfo.total = 0
  end

  local retSlot = nil

  -- first check for underfilled slots
  for _, slot in ipairs(gInfo.slots) do
    if slot.max > slot.count then
      retSlot = slot
      break
    end
  end

  if retSlot == nil then
    -- find a free (empty) slot
    for pname, p in pairs(self._ps) do
      local freeList = self._freeLists[pname]

      if #freeList > 0 then
        local id = table.remove(freeList)

        local slot = {}
        slot.pname = pname
        slot.id = id
        slot.count = 0
        slot.max = 64

        table.insert(gInfo.slots, slot)
        retSlot = slot
        break
      end
    end
  end

  -- set gInfo in case it didn't exist before
  self.items[key] = gInfo
  return retSlot
end

--- Move items to another store
-- @param key The key of the item to move
-- @param qty How many items to move
-- @param dst The destination `MegaChest`
function MegaChest:move(key, qty, dst)
  local desiredQty = qty
  local gInfo = self.items[key]

  for i = #gInfo.slots, 1, -1 do
    local slot = gInfo.slots[i]
    local count = slot.count
    local p = self._ps[slot.pname]

    while slot.count > 0 do
      local dstSlot = allocSlot(dst, key)

      -- actually move the items
      local movedQty = p.pushItems(
        dstSlot.pname,
        slot.id,
        qty,
        dstSlot.id
      )

      -- update slots info
      qty = qty - movedQty
      slot.count = slot.count - movedQty
      dstSlot.max = dst._ps[dstSlot.pname].getItemLimit(dstSlot.id)
      dstSlot.count = dstSlot.count + movedQty

      if qty <= 0 or movedQty == 0 then
        break
      end
    end

    if slot.count <= 0 then
      table.remove(gInfo.slots, i)
    end

    if qty <= 0 or movedQty == 0 then
      break
    end
  end

  local totalMoved = desiredQty - qty

  -- update total info
  gInfo.total = gInfo.total - totalMoved
  dst.items[key].total =
    dst.items[key].total + totalMoved

  if gInfo.total == 0 then
    self.items[key] = nil
  end

  return totalMoved
end

return MegaChest
