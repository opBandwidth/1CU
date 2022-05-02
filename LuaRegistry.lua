local LuaRegistry = {}

local remove = os.remove

local function shellExecute(cmd)
    local outfile, errfile = os.tmpname(), os.tmpname()
    remove(outfile)
    remove(errfile)

    outfile = os.getenv("TEMP") .. outfile
    errfile = os.getenv("TEMP") .. errfile
    cmd = cmd .. ' >"' .. outfile.. '" 2>"' .. errfile .. '"'

    local success, retcode = os.execute(cmd)

    local outcontent, errcontent

    local fh = io.open(outfile)
    if fh then
        outcontent = fh:read("*a")
        fh:close()
    end
    remove(outfile)

    fh = io.open(errfile)
    if fh then
        errcontent = fh:read("*a")
        fh:close()
    end
    remove(errfile)

    return success, retcode, (outcontent or ""), (errcontent or "")
end

local function split(str, pat)
    local result, regex = {}, ("([^%s]+)"):format(pat)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

local function wrapString(str)
    assert(type(str) == "string", "Expected string, got " .. type(str))
    return ('"%s"'):format(str)
end

local function parseQuery(output, i)
    assert(type(output) == "string" or type(output) == "table", "Expected string or table, got " .. type(output))

    local lines = type(output) == "string" and split(output, "\n") or output

    i = i or 1
    local result = {values = {}, keys = {}}

    while i <= #lines do
        if lines[i] ~= "" then
            if result.key then
                if lines[i]:sub(1, 1) == " " then
                    local n, t, v = lines[i]:match("^%s%s%s%s(.+)%s%s%s%s(REG_.+)%s%(%d%d?%)%s%s%s%s(.*)$") -- :face_with_raised_eyebrow: when u dont know shet about regex
                    result.values[n] = { ["type"] = t, value = v, name = n}
                elseif lines[i]:find(result.key, 1, true) == 1 then
                    local name = lines[i]:sub(#result.key + 2, -1)
                    local skey
                    skey, i = parseQuery(lines, i)
                    result.keys[name] = skey
                else
                    return result, i - 1
                end
            else
                result.key = lines[i]
            end
        else
            if result.key then
                while lines[i] == "" and i <= #lines do
                    i = i + 1
                end
                if lines[i] then
                    if lines[i]:find(result.key, 1, true) ~= 1 then
                        return result, i
                    end
                else
                    i = i - 1
                end
            end
        end
        i = i + 1
    end

    return result.key and result, i or nil
end

function LuaRegistry.getKey(key, recursive)
    assert(type(key) == "string", "String expected, got " .. type(key))

    local options = " /z"
    if recursive then
        options = options .. " /s"
    end

    local success, ec, out, err = shellExecute("reg.exe query " .. wrapString(key) .. options)
    if not success then
        return nil, split(err, "\n")[1]
    else
        local result = parseQuery(out)
        if not recursive then
            for _, v in next, result.keys do
                v.keys = nil
                v.values = nil
            end
        end
        return result
    end
end

function LuaRegistry.createKey(key)
    local success, ec, out, err = shellExecute("reg.exe add " .. wrapString(key) .. " /f")
    if not success then
        return nil, split(err, "\n")[1]
    else
        return true
    end
end

function LuaRegistry.deleteKey(key)
    local success, ec, out, err = shellExecute("reg.exe delete " .. wrapString(key) .. " /f")
    if not success then
        if not LuaRegistry.getKey(key) then
            return true
        end
        return nil, split(err, "\n")[1]
    else
        return true
    end
end

function LuaRegistry.writeValue(key, name, vtype, value)
    local command
    if name == "(Default)" or not name then
        command = ("reg.exe add %s /ve /t %s /d %s /f"):format(wrapString(key), vtype, wrapString(value))
    else
        command = ("reg.exe add %s /v %s /t %s /d %s /f"):format(wrapString(key), wrapString(name), vtype, wrapString(value))
    end
    local success, ec, out, err = shellExecute(command)
    if not success then
        return nil, split(err, "\n")[1]
    else
        return true
    end
end

function LuaRegistry.deleteValue(key, name)
    local command
    if name == "(Default)" or not name then
        command = ("reg.exe delete %s /ve /f"):format(wrapString(key))
    else
        command = ("reg.exe delete %s /v %s /f"):format(wrapString(key), wrapString(name))
    end
    local success, ec, out, err = shellExecute(command)
    if not success then
        if not LuaRegistry.getValue(key, name) then
            return true
        end
        return nil, split(err, "\n")[1]
    else
        return true
    end
end

function LuaRegistry.getValue(key, name)
    local keyt = LuaRegistry.getKey(key)
    if keyt then
        local keytName = keyt[name]
        if keytName then
            return keytName.value, keytName.type
        end
    end
    return nil
end

LuaRegistry.shellExecute = shellExecute
return LuaRegistry