-- Require the LuaRegistry libarary.
local LuaRegistry = require("LuaRegistry")

-- Generate a Random Mac Address.
math.randomseed(os.time())

local randomMacAddress = ("02XXXXXXXXXX"):gsub("X", function()
    local randomIDX = math.random(16)
    return ("0123456789ABCDEF"):sub(randomIDX, randomIDX)
end)

print("rMA", randomMacAddress)

-- Change the Mac Address using LuaRegistry library.
LuaRegistry.shellExecute('netsh interface set interface "Wi-Fi" DISABLED')

local success, error = LuaRegistry.writeValue("HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001\\Control\\Class\\{4d36e972-e325-11ce-bfc1-08002be10318}\\0002", "NetworkAddress", "REG_SZ", randomMacAddress)

if not success then
    return print("Failed to modify NetworkAddress value -> " .. error)
else
    print("Successfully modified NetworkAddress value.")
end

LuaRegistry.shellExecute('netsh interface set interface "Wi-Fi" ENABLED')

-- Find & Delete the long key.
local longKey = LuaRegistry.getKey("HKEY_CURRENT_USER").key:gsub("%D", "")
local success, error = LuaRegistry.deleteKey("HKEY_CURRENT_USER\\" .. longKey)

if not success then
    return print("Failed to delete long key -> " .. error)
else
    print("Successfully deleted long key.")
end

-- Find & Delete the short key.
local shortKey = LuaRegistry.getKey("HKEY_CURRENT_USER\\SOFTWARE\\Microsoft").key:gsub("%D", "")
local success, error = LuaRegistry.deleteKey("HKEY_CURRENT_USER\\SOFTWARE\\Microsoft" .. shortKey)

if not success then
    return print("Failed to delete short key -> " .. error)
else
    print("Successfully deleted short key.")
end

-- Delete the Machine GUID/Cryptography GUID.
local success, error = LuaRegistry.deleteValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Cryptography", "MachineGuid")

if not success then
    return print("Failed to delete MachineGuid value -> " .. error)
else
    print("Successfully deleted MachineGuid value.")
end

print("Operation completed successfully.")