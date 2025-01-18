local tar = require("archive")

local args = { ... }
local flagBundle = table.remove(args, 1) 
local archivePath = table.remove(args, 1) 

local function printUsage()
    print("Usage:")
    print("  tar c[v]f <archive> <files> ...")
    print("  tar x[v]f <archive>")
    print("  tar t[v]f <archive>")
end

local function hasFlag(f)
    return flagBundle:find(f, 1, true) ~= nil
end

local function findMode(modes)
    local mode = nil

    for i = 1, #modes do
        local m = modes:sub(i, i)

        if hasFlag(m) then
            if mode then
                return nil
            end

            mode = m
        end
    end

    return mode
end

if not flagBundle or not archivePath then
    printUsage()
    return
end

local verbose = hasFlag("v")
local mode = findMode("cxt")

if mode == "c" then
    local archive = tar.newArchive()

    for _, path in ipairs(args) do
        if verbose then
            print("a " .. path)
        end

        local _, err = archive:appendPath(path)

        if err then
            print(err)
            return
        end
    end

    local absPath = shell.resolve(archivePath)
    local h, err = io.open(absPath, "wb")

    if h == nil then
        print(err)
        return
    end

    archive:write(h)
    h:close()
elseif mode == "x" then
    print("extracting archive " .. archivePath)
elseif mode == "t" then
    print("listing archive " .. archivePath)
end
