local M = {}

M.description = "Retrieve items"

function M.run(state, qty, pat)
    if qty ~= "all" then
        qty = tonumber(qty)
    end

    if qty == nil then
        print("Not a valid quantity")
        return
    end

    for k, v in pairs(state.store.items) do
        if k:match(pat) then
            if qty == "all" then
                qty = v.total
            end

            if v.total < qty then
                print("Not enough items")
                return
            end

            state.store:move(
                k,
                qty,
                state.hand
            )
            return
        end
    end
end

return M
