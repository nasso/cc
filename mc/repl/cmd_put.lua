local M = {}

M.description = "Put items into the megachest"

function M.run(state, qty, pat)
  if qty ~= "all" then
    qty = tonumber(qty)
  end

  if
    not qty or (qty ~= "all" and not pat)
  then
    print("Usage:")
    print("  put all")
    print("  put all <pattern>")
    print("  put <qty> <pattern>")
    return
  end

  for k, v in pairs(state.hand.items) do
    if pat == nil or k:match(pat) then
      local movingQty = qty

      if movingQty == "all" then
        movingQty = v.total
      elseif movingQty > v.total then
        print("Not enough items")
        return
      end

      state.hand:move(
        k,
        movingQty,
        state.store
      )

      if pat ~= nil then
        break
      end
    end
  end
end

return M
