local config = require("config")
local version = "0.2.1"

local USAGE = [[
USAGE
  $0 [opts] [repl] Start the REPL (default)
  $0 [opts] mkcfg  Write config to config path
OPTIONS
  -h,--help        Show this message and exit
  -V,--version     Show the version and exit
  --config <path>  Specify path to config file
]]

local options = {
  config_file = "/etc/mc.conf",
  mode = nil,
}

print("MegaChest "..version)

local function parseArguments(args)
  local i = 1

  while args[i] do
    local arg = args[i]
    i = i + 1

    if arg == "--version" or arg == "-V" then
      -- already printed
      options.exit = true
      return
    elseif arg == "--help" or arg == "-h" then
      print(USAGE:gsub("%$0", args[0]))
      options.exit = true
      return
    elseif arg == "--config" then
      options.config_file = args[i]
      i = i + 1
    elseif not options.mode then
      options.mode = arg
    else
      printError("Unexpected argument: "..arg)
      printError("Try --help for usage.")
      options.exit = true
      return
    end
  end

  options.mode = options.mode or "repl"
end

local function loadConfigFile(path, cfg)
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
end

parseArguments(arg)

if options.exit then
  return
end

loadConfigFile(options.config_file)

if options.mode == "repl" then
  local repl = require("repl")
  repl.run(config)
elseif options.mode == "mkcfg" then
  local path = options.config_file
  local f = fs.open(path, "w")
  f.write(textutils.serialize(config))
  f.close()
  print("Wrote config to "..path)
else
  error("Unknown command: "..mode, 0)
end
