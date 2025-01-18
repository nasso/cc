local version = "0.1.2"

local prompt = "% "
local storePat = "minecraft:barrel_%d+"
local storeExcludePat = "minecraft:barrel_222"
local handPat = "minecraft:barrel_223"

local history = {}
local running = true
local commands = require("commands")

commands.help = {
    description = "Print this message";
    run = function()
        print("Available commands:")
        for k, v in pairs(commands) do
            print(k .. " - " .. v.description)
        end
    end;
}

commands.exit = {
    description = "Quit the program";
    run = function()
        running = false
    end;
}

local function split(str, sep)
    sep = sep or "%s"

    local t = {}
    local pattern = "([^" .. sep .. "]+)"

    for str in str:gmatch(pattern) do
        table.insert(t, str)
    end

    return t
end

local mc = require("libmc")
local state = {}

state.store = mc.new()
state.hand = mc.new()

for
  _, name in
  ipairs(peripheral.getNames())
do
  if name:match(handPat) then
    print("Mounting hand " .. name .. "...")
    state.hand:add(name)
  elseif name:match(storePat) and not name:match(storeExcludePat) then
    print("Mounting store " .. name .. "...")
    state.store:add(name)
  end
end

print("MegaChest " .. version)
print("Type 'help' for a list of commands.")

while running do
    term.write(prompt)

    local cmd = read(nil, history)
    local cmdArgs = split(cmd)
    local cmdName = table.remove(cmdArgs, 1) 

    state.hand:syncAll()
    table.insert(history, cmd)

    if cmdName ~= nil then
        local cmd = commands[cmdName]

        if cmd == nil then
            print("Unknown command")
        else
            cmd.run(state, table.unpack(cmdArgs))
        end
    end
end
