local version = "0.2.0"
local args = { ... }

print("MegaChest " .. version)

if
  args[1] == "--version"
  or args[1] == "-V"
then
  -- we already printed it lol
  return
end

local config = {
  prompt = "(mc) ",
  store_pat = "chest",
  hand_pat = "barrel",
}

local function readConfig(path)
  local f = fs.open(path, "r")
  if not f then return end

  local data = f.readAll()
  f.close()

  data = textutils.unserialize(data)

  if not data then
    error("Syntax error in config file!", 0)
  end

  for k in pairs(config) do
    if data[k] then
      config[k] = data[k]
    end
  end

  return f
end

readConfig("/etc/mc.conf")

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
  if name:match(config.hand_pat) then
    print("Mounting hand " .. name .. "...")
    state.hand:add(name)
  elseif name:match(config.store_pat) then
    print("Mounting store " .. name .. "...")
    state.store:add(name)
  end
end

print("Type 'help' for a list of commands.")

while running do
    term.write(config.prompt)

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
