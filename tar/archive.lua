local M = {}

local Archive = {} 
Archive.__index = Archive

local Entry = {}
Entry.__index = Entry

local function pad(n, b)
    return (b - (n % b)) % b
end

function M.newArchive()
    local archive = {
        entries = {};
    }

    return setmetatable(archive, Archive)
end

function Archive:append(name, data)
    assert(
        type(name) == "string",
        "expected string"
    )
    assert(
        data == nil or type(data) == "string",
        "expected string or nil"
    )

    local entry = setmetatable({}, Entry)

    entry.name = name
    entry.data = data
    table.insert(self.entries, entry)

    return entry
end

function Archive:appendFile(name, h)
    local data = h:read("a")

    if data == nil then
        return nil
    end

    return self:append(name, data)
end

function Archive:appendPath(path)
    local absPath = shell.resolve(path)
    local h, err = io.open(absPath, "rb")

    if h == nil then
        return nil, err
    end

    local entry = self:appendFile(path, h)

    h:close()

    return entry
end

function Archive:loadEntries(h)
    error("todo")
end

function Archive:write(h)
    for _, e in ipairs(self.entries) do
        e:write(h)
    end

    h:write(string.rep("\0", 1024))
end

function Entry:write(h)
    local size = #self.data
    local header = ""

    local function wrh(bytes)
        header = header .. bytes
    end

    ------------------------------------
    -- Field                   off  len
    ------------------------------------
    -- File name                 0  100
    wrh(
        (self.name .. string.rep("\0", 100))
            :sub(1, 100)
    )
    -- File mode               100    8
    wrh("000644 \0") -- -rw-r--r-
    -- Owner ID                108    8
    wrh("000000 \0")
    -- Group ID                116    8
    wrh("000000 \0")
    -- File size in bytes      124   12
    wrh(string.format("%011o ", size))
    -- Last modified           136   12
    wrh("00000000000 ")
    -- Header checksum         148    8
    wrh(string.rep(" ", 8))
    -- File/link type          156    1
    wrh("\0")
    -- Name of linked file     157  100
    wrh(string.rep("\0", 100))

    -- compute checksum and write it
    local cksum = 0
    for i = 1, #header do
        local byte = header:byte(i)

        cksum = cksum + byte
    end
    h:write(header:sub(1, 148))
    h:write(string.format("%06o\0 ", cksum))
    h:write(header:sub(157))

    -- pad header to 512 bytes
    h:write(string.rep("\0", pad(#header, 512)))

    -- write entry data
    h:write(self.data)

    -- pad data to 512 bytes
    h:write(string.rep("\0", pad(size, 512)))
end

return M
