local config = require("config")
local mc = require("libmc")

local M = {}

local commands
commands = {
  list = require("repl/cmd_list"),
  get = require("repl/cmd_get"),
  put = require("repl/cmd_put"),
  help = {
    description = "Print this message",
    run = function()
      print("Available commands:")
      for k, v in pairs(commands) do
        print(k.." - "..v.description)
      end
    end,
  },
  exit = {
    description = "Quit the program",
    run = function(state)
      state.running = false
    end,
  }
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

function M.run()
  local history = {}
  local state = {}

  state.running = true
  state.store = mc.new(config.cache_dir)
  state.hand = mc.new(config.cache_dir)

  for
    _, name in
    ipairs(peripheral.getNames())
  do
    if name:match(config.hand_pat) then
      print("Mounting hand "..name.."...")
      state.hand:add(name)
    elseif name:match(config.store_pat) then
      print("Mounting store "..name.."...")
      state.store:add(name)
    end
  end

  print("Type 'help' for a list of commands.")

  while state.running do
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
end

return M
