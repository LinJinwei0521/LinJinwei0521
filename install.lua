local function encodeUTF8(asciiText)
    local utf8Text = ""
    
    for i=1, #asciiText, 32768 do
        utf8Text = utf8Text..utf8.char(string.byte(asciiText, i, math.min(i + 32767, #asciiText)))
    end
    
    return utf8Text
end

local function decodeUTF8(utf8Text)
    local asciiText = ""
    
    for i = 1, #utf8Text, 32768 do
        local ok, t = pcall(function() return string.char(utf8.codepoint(utf8Text, i, math.min(i + 32767, #utf8Text))) end)
        if ok then
            asciiText = asciiText .. t
        else
            for _, codepoint in utf8.codes(string.sub(utf8Text, i, i + 32767)) do
                if codepoint < 256 then
                    asciiText = asciiText .. string.char(codepoint)
                else
                    asciiText = asciiText .. "?"
                end
            end
        end
    end
    
    return asciiText
end

local function encodeAll(...)
    local tbl = table.pack(...)
    for k,v in pairs(tbl) do
        if type(v) == "string" and not utf8.len(v) then
            tbl[k] = encodeUTF8(v)
        end
    end
    
    return table.unpack(tbl, 1, tbl.n)
end
 
local function decodeAll(...)
    local tbl = table.pack(...)
    for k,v in pairs(tbl) do
        if type(v) == "string" then
            tbl[k] = decodeUTF8(v)
        end
    end
    
    return table.unpack(tbl, 1, tbl.n)
end

local function extractVersion(str)
    local version = str:match("ComputerCraft (%d+%.%d+%.%d+)")
    return version
end

local function isVersionAbove(version1, version2)
    local function splitVersion(version)
        local parts = {}
        for part in version:gmatch("(%d+)") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end

    local v1Parts = splitVersion(version1)
    local v2Parts = splitVersion(version2)

    for i = 1, math.max(#v1Parts, #v2Parts) do
        local v1 = v1Parts[i] or 0
        local v2 = v2Parts[i] or 0
        if v1 > v2 then
            return true
        elseif v1 < v2 then
            return false
        end
    end

    return true -- They are equal if all parts are equal
end

if isVersionAbove(extractVersion(_HOST), "1.109") then
    print("NOTE: Enabling text-mode conversion")
    os.sleep(0.5)
    local fopen = fs.open
     
    function fs.open(path, mode)
        local f = fopen(path, mode)
        if not f then return nil end
        
        local customHandle = {}
        
        for k,v in pairs(f) do
            if mode:find("b") then
                customHandle[k] = function(...) return v(...) end
            else
                customHandle[k] = function(...) return decodeAll(v(encodeAll(...))) end
            end
        end
        
        return customHandle
    end
else
    print("NOTE: Disabling text-mode conversion")
    os.sleep(0.5)
end

local lStore = {}

local hpost = function(...)
    while true do
        local ret = table.pack(http.post(...))
        if not ret[1] then
            os.sleep(0.5)
        else
            badConn = false
            return table.unpack(ret, 1, ret.n)
        end
    end
end

local ping = http.get("https://os.leveloper.cc/ping.php")
if not ping then
    local ping2 = http.get("http://os.leveloper.cc/ping.php")
    if not ping2 then
        printError("Could not connect to Leveloper servers. Please contact Leveloper for assistance.")
        return
    end
    function http.post(...)
        local args = table.pack(...)
        local r = table.pack(hpost(...))
        if not r[1] and string.find(args[1],"https://",nil,true) == 1 then
            args[1] = "http"..string.sub(args[1],6,#args[1])
            return hpost(table.unpack(args))
        else
            return table.unpack(r)
        end
    end
    local hget = http.get
    function http.get(...)
        local args = table.pack(...)
        local r = table.pack(hget(...))
        if not r[1] and string.find(args[1],"https://",nil,true) == 1 then
            args[1] = "http"..string.sub(args[1],6,#args[1])
            return hget(table.unpack(args))
        else
            return table.unpack(r)
        end
    end
	function lStore.run(code,path)
        local f = hpost("http://os.leveloper.cc/sGet.php","path="..textutils.urlEncode(path).."&code="..textutils.urlEncode(code),{Cookie=userID}).readAll()
        local func,err = loadstring(f,nil,_ENV)
        if not func then
            return false,err
        else
            return func()
        end
    end
else
    function lStore.run(code,path)
        local f = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode(path).."&code="..textutils.urlEncode(code),{Cookie=userID}).readAll()
        local func,err = loadstring(f,nil,_ENV)
        if not func then
            return false,err
        else
            return func()
        end
    end
end

lStore.run("lSlb8kZq","LevelOS/startup/lUtils.lua")

local oTerm = term.current()
local nTerm = window.create(term.current(),1,1,term.getSize())
nTerm.setVisible(false)
term.redirect(nTerm)
local function render()
    local w,h = nTerm.getSize()
    local oW,oH = oTerm.getSize()
    if oW ~= w or oH ~= h then
        nTerm.reposition(1,1,oW,oH)
    end
    w,h = nTerm.getSize()
    for t=0,15,1 do
        oTerm.setPaletteColor(2^t,table.unpack({nTerm.getPaletteColor(2^t)}))
    end
    local ocursor = {nTerm.getCursorPos()}
    local otext = nTerm.getCursorBlink()
    oTerm.setCursorBlink(false)
    for t=1,h do
        oTerm.setCursorPos(1,t)
        oTerm.blit(nTerm.getLine(t))
    end
    oTerm.setTextColor(nTerm.getTextColor())
    oTerm.setCursorBlink(otext)
    oTerm.setCursorPos(table.unpack(ocursor))
end

shell.run("pastebin get 3LfWxRWh bigfont")
_G.bigfont = loadfile("bigfont",_ENV)()

--parallel.waitForAny(function() local ok,err = pcall(function() lStore.run("ddsx0eg5","Installer.sgui") end) if not ok then printError(err) print("Press a key to continue...") os.sleep(1) os.pullEvent("key") end end,render)
local cor = coroutine.create(
    function()
        local ok, err = pcall(function() lStore.run("ddsx0eg5", "Installer.sgui") end)
        if not ok then
            printError(err)
            print("Press a key to continue...")
            os.sleep(1)
            os.pullEvent("key")
        end
    end
)

coroutine.resume(cor)
render()

while coroutine.status(cor) ~= "dead" do
    local e = table.pack(os.pullEventRaw())
    if isVersionAbove(extractVersion(_HOST), "1.109") and e[1] == "http_success" then
        local h = e[3]

        e[3] = {}

        for k,v in pairs(h) do
            e[3][k] = function(...) return decodeAll(v(encodeAll(...))) end
        end
    end

    coroutine.resume(cor, table.unpack(e, 1, e.n))
    render()
    coroutine.resume(cor, "extra_update")
    render()
end

-- goodbye pastebin! we had a good ru
