local M = {}

M.description = "List all items"

function M.run(state, pat)
  print("---- Store ----")
  for k, v in pairs(state.store.items) do
    if not pat or k:match(pat) then
      print(" " .. v.total .. "x " .. k)
    end
  end

  print("---- Hand ----")
  for k, v in pairs(state.hand.items) do
    if not pat or k:match(pat) then
      print(" " .. v.total .. "x " .. k)
    end
  end
end

return M
