local stack = {}

local function dropAll(l)
    for _, f in ipairs(l.drops) do
        f()
    end
    l.drops = {}
end

local function currentListener()
    return stack[#stack]
end

local function pushListener(l)
    stack[#stack + 1] = l
end

local function popListener()
    stack[#stack] = nil
end

local function signal(v)
    local subscribers = {}

    local function get()
        local l = currentListener()

        if l and not subscribers[l] then
            subscribers[l] = true

            -- add drop function for this signal
            l.drops[#l.drops + 1] = function()
                subscribers[l] = nil
            end
        end

        if l and l.deps then
            l.deps[get] = true
        end

        return v
    end

    local function set(newValue)
        v = newValue

        for l in pairs(subscribers) do
            l.run()
        end
    end

    return get, set
end

local function effect(f)
    local l = {
        drops = {},
    }
    local running = false
    local rerun = false

    l.run = function()
        if running then
            rerun = true
            return
        end

        running = true
        repeat
            rerun = false
            dropAll(l)
            pushListener(l)
            f()
            popListener()
        until not rerun
        running = false
    end

    l.run()
end

local function memo(f)
    local previous = {}

    local function same(deps)
        for get in pairs(deps) do
            local v = get()

            if previous[get] ~= v then
                return false
            end
        end

        return true
    end

    effect(function()
        local l = currentListener()

        if l.deps and same(l.deps) then
            return
        end

        l.deps = {}
        f()

        for get in pairs(l.deps) do
            previous[get] = get()
        end
    end)
end

return { signal = signal, effect = effect, memo = memo }