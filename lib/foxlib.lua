require ("moonloader")
local dlstatus = require('moonloader').download_status
local requests = require("requests")
local memory = require("memory")
local ffi = require ('ffi')
local sampfuncs = getModuleHandle("SampFuncs.asi")

local fl = {}

local json_url = "https://raw.githubusercontent.com/Gabunavig/foxlib/refs/heads/main/v.json"
local script_version = "1"

-- local CPed_SetModelIndex = ffi.cast('void(__thiscall *)(void*, unsigned int)', 0x5E4880)

-- ffi.cdef('struct CVector2D {float x, y;}')
-- local CRadar_TransformRealWorldPointToRadarSpace = ffi.cast('void (__cdecl*)(struct CVector2D*, struct CVector2D*)', 0x583530)
-- local CRadar_TransformRadarPointToScreenSpace = ffi.cast('void (__cdecl*)(struct CVector2D*, struct CVector2D*)', 0x583480)
-- local CRadar_IsPointInsideRadar = ffi.cast('bool (__cdecl*)(struct CVector2D*)', 0x584D40)

function main()
    while not isSampAvailable() do wait(0) end
    while true do
        wait(0)
    end
end
 
function download_handler(id, status, p1, p2)
  if status == dlstatus.STATUS_ENDDOWNLOADDATA then
    reloadScripts()
  end
end

function fl.test()
    sampAddChatMessage(script_version, -1)
end
  
function fl.check_update(url, v, down, filename, reload, func)
	if url == nil or v == nil then return false end
    local response = requests.get(url)
    if response.status_code == 200 then
        local version_info = decodeJson(response.text)
        if version_info.version ~= nil and version_info.download ~= nil then
            if version_info.version ~= v then
				if down then
					downloadUrlToFile(version_info.download, filename, func)
					-- if reload then reloadScripts() end					
				else
					return version_info.version
				end
            end
        end
    end
end

function fl.inTable(arg, table, mode)
    if mode == 1 then 
        for k, v in pairs(table) do
            if k == arg then
                return true
            end
        end
    else 
        for k, v in pairs(table) do
            if v == arg then
                return true
            end
        end
    end
    return false
end

function fl.findInTable(table, text)
    local items = {}
    for k, v in pairs(table) do
        if (('%s'):format(v):lower():find(ffi.string(text):lower(), nil, true)) then
            table.insert(items, v)
        end
    end
    if table.maxn(items) >= 1 then
        return items
    else 
        return false
    end
end

function fl.removeDuplicates(table)
  local uniqueTable = {}
  local seen = {}

  for _, value in ipairs(table) do
    if not seen[value] then
      table.insert(uniqueTable, value)
      seen[value] = true
    end
  end

  return uniqueTable
end

function fl.loadJson(filename)
    local file = io.open(filename, r)
    local items = {}
    a = file:read("*a")
    file:close()
    tempitems = decodeJson(a)
    for i, r in pairs(tempitems) do
        table.insert(items, r)
    end
    return items
end

function fl.saveJson(table, filename)
    encodedTable = encodeJson(table)
    local file = io.open(filename, "w")
    file:write(encodedTable) 
    file:close()
end 

function fl.currentFunctionName()
    local info = debug.getinfo(2, "n")
    if info then return info.name or "unknown" end
    return "main"
end

function fl.callerFunctionName()
    local info = debug.getinfo(3, "n")
    if info then return info.name or "unknown" end
    return "main"
end

function fl.packetLoss()
    local pRakClient = sampGetRakclientInterface()
    local pRakClientStatistic = callMethod(sampGetRakclientFuncAddressByIndex(51), sampGetRakclientInterface(), 1, 0, pRakClient)
    local nStatValue1 = memory.getuint32(pRakClientStatistic + 0x94, true)
    local nStatValue2 = memory.getuint32(pRakClientStatistic + 0xB8, true)
    return nStatValue1 * 100.0 / nStatValue2
end

function fl.getAveragePing() -- Crash
    local sampHandle = getModuleHandle("samp.dll")
    local pRakClientGetAveragePing = ffi.cast("int(__thiscall*)(uintptr_t pRakClient)", sampHandle + 0x308C0)

    return pRakClientGetAveragePing(sampGetRakclientInterface())
end

function fl.getLastPing() -- Crash
    local sampHandle = getModuleHandle("samp.dll")
    local pRakClientGetLastPing = ffi.cast("int(__thiscall*)(uintptr_t pRakClient)", sampHandle + 0x308F0)
  
    return pRakClientGetLastPing(sampGetRakclientInterface())
end

function fl.removeColorCodes(str)
    return str:gsub("{%x%x%x%x%x%x}", "")
end

function fl.isServerName(arg)
    return sampGetCurrentServerName():lower():find(arg) ~= nil;
end

function fl.displayText(entryName, text, x, y, width, height, style, alignment, color)
    if alignment == 1 then
        setTextJustify(true) 
    elseif alignment == 2 then
        setTextCentre(true)
    elseif alignment == 3 then
        setTextRightJustify(true) 
    end

    setGxtEntry(entryName, text)
    setTextScale(width, height) 
    setTextColour(unpack(color))
    setTextEdge(1, 0, 0, 0, 255)
    setTextFont(style)
    displayText(x, y, entryName)
end

function fl.setPlayerColor(playerId, color, sampVersion)
    local nColor = tonumber(color)
    local nPlayerId = tonumber(playerId)
    if not nColor or not nPlayerId then return end
    local offsets = {
        setPlayerColor = {
            ["DLR1"] = 0xA6F50,
            ["R1"] = 0xAD550,
            ["R2"] = 0xAD720,
            ["R3"] = 0xA6AD0,
            ["R4"] = 0xA7220,
            ["R5"] = 0xA7210,
        }       
    }
    local samp = getModuleHandle("samp.dll")
    local setPlayerColor = ffi.cast("int(__stdcall*)(unsigned int, int)", (samp + offsets.setPlayerColor[sampVersion]))
    return setPlayerColor(nPlayerId, nColor)
end

function fl.getSampVersion()
    local version = "unknown"
    local versions = {[0xFDB60] = "DLR1",  [0x31DF13] = "R1", [0x3195DD] = "R2", [0xCC4D0] = "R3",  [0xCBCB0] = "R4", [0xCBC90] = "R5"}
    local sampHandle = getModuleHandle("samp.dll")
    if sampHandle then
        local e_lfanew = ffi.cast("long*", (sampHandle + 60))
        local ntHeader = (sampHandle + e_lfanew[0])
        local pEntryPoint = ffi.cast("uintptr_t*", (ntHeader + 40))
        if versions[pEntryPoint[0]] then version = versions[pEntryPoint[0]] end
    end
    return version
end

function fl.getPlayersInArea(ax, ay, az, bx, by, bz, sphere) 
    local players = {}
    for _, ped in ipairs(getAllChars()) do
        if isCharInArea3d(ped, ax, ay, az, bx, by, bz, sphere) then
            if (ped ~= PLAYER_PED) then
                table.insert(players, ped)
            end
        end
    end
    return players
end

function fl.getCountDate(count, time)
    local result = {}
    local timezone = (3 + (time and time or 0)) * 3600
    for i = 1, count + 1 do
        result[i] = os.date('!*t', os.time() + timezone + 86400 * (i - 1))
    end
    return result
end

function fl.getFilesInPath(path, ftype)
    assert(path, '"path" is required');
    assert(type(ftype) == 'table' or type(ftype) == 'string', '"ftype" must be a string or array of strings');
    local result = {};
    for _, thisType in ipairs(type(ftype) == 'table' and ftype or { ftype }) do
        local searchHandle, file = findFirstFile(path.."\\"..thisType);
        table.insert(result, file)
        while file do file = findNextFile(searchHandle) table.insert(result, file) end
    end
    return result;
end

function fl.setSFConsoleState(bValue, sampVersion)
    local offsets = {
        setFirst = {
            -- ["DLR1"] = 0xA6F50,
            ["R1"] = 0x11572C,
            -- ["R2"] = 0xAD720,
            ["R3"] = 0x1136C0,
            -- ["R4"] = 0xA7220,
            -- ["R5"] = 0xA7210,
        },
        setSecond = {
            -- ["DLR1"] = 0xA6F50,
            ["R1"] = 0x12EBB,
            -- ["R2"] = 0xAD720,
            ["R3"] = 0x131E7,
            -- ["R4"] = 0xA7220,
            -- ["R5"] = 0xA7210,
        }
    }
    local pSfConsole = ffi.cast("void**", sampfuncs + offsets.setFirst[sampVersion])[0]
    ffi.cast("void(__thiscall*)(void*, bool)", sampfuncs + offsets.setSecond[sampVersion])(pSfConsole, bValue)
end

function fl.getNearestPedByPed(HndlPed, radius, minPlayerNear)
    if doesCharExist(HndlPed) then 
        local tableArr = {}
        local countPlayers = 0
        local posXpl, posYpl = getCharCoordinates(HndlPed)
        for _,player in pairs(getAllChars()) do 
            if player ~= HndlPed then
                local playerid = select(2, sampGetPlayerIdByCharHandle(player))
                if not sampIsPlayerNpc(playerid) and playerid ~= -1 then 
                    local posX, posY, posZ = getCharCoordinates(player) 
                    for _,player1 in pairs(getAllChars()) do
                        local playerid = select(2, sampGetPlayerIdByCharHandle(player1)) 
                        if not sampIsPlayerNpc(playerid) and playerid ~= -1 then 
                            local x,y,z = getCharCoordinates(player1)
                            if getDistanceBetweenCoords2d(x, y, posX, posY) < 2 then countPlayers = countPlayers + 1 end 
                        end
                    end
                    local distBetween2d = getDistanceBetweenCoords2d(posXpl, posYpl, posX, posY)
                    if minPlayerNear ~= false then
                        if tonumber(minPlayerNear) >= countPlayers then 
                            table.insert(tableArr, {distBetween2d, player, posX, posY, posZ, countPlayers - 1}) 
                        end
                    else table.insert(tableArr, {distBetween2d, player, posX, posY, posZ, countPlayers - 1}) end 
                    countPlayers = 0
                end
            end
        end
        if #tableArr > 0 then 
            table.sort(tableArr, function(a, b) return (a[1] < b[1]) end) 
            if radius ~= false then
                if tableArr[1][1] <= tonumber(radius) then  
                    return true, tableArr[1][2], tableArr[1][1], tableArr[1][3], tableArr[1][4], tableArr[1][5], tableArr[1][6] 
                end
            else return true, tableArr[1][2], tableArr[1][1], tableArr[1][3], tableArr[1][4], tableArr[1][5], tableArr[1][6] end 
        end
    end
    return false
end

function fl.getSelectedText()
    local input = sampGetChatInputText()
    local ptr = sampGetInputInfoPtr()
    local chat = getStructElement(ptr, 0x8, 4)
    local pos1 = readMemory(chat + 0x11E, 4, false)
    local pos2 = readMemory(chat + 0x119, 4, false)
    local count = pos2 - pos1
    return string.sub(input, count < 0 and pos2 + 1 or pos1 + 1, count < 0 and pos2 - count or pos2)
end

function fl.getNearestObject(modelid)
    local objects = {}
    local x, y, z = getCharCoordinates(playerPed)
    for i, obj in ipairs(getAllObjects()) do
        if getObjectModel(obj) == modelid then
            local result, ox, oy, oz = getObjectCoordinates(obj)
            table.insert(objects, {getDistanceBetweenCoords3d(ox, oy, oz, x, y, z), ox, oy, oz})
        end
    end
    if #objects <= 0 then return false end
    table.sort(objects, function(a, b) return a[1] < b[1] end)
    return true, unpack(objects[1])
end

function fl.pauseMenu(bool)
    if bool then
        memory.setuint8(0xBA6748 + 0x33, 1)
    else
        memory.setuint8(0xBA6748 + 0x32, 1)
    end
end

function fl.pauseMenuStatus()
    return memory.getuint8(0xBA6748 + 0x5C)
end









-- function fl.setNextRequestTime(time)
--     local samp = getModuleHandle("samp.dll")
--     memory.setuint32(samp + 0x3DBAE, time, true)
-- end

-- function fl.getNearestRoadCoordinates(radius)
--     local A = { getCharCoordinates(PLAYER_PED) }
--     local B = { getClosestStraightRoad(A[1], A[2], A[3], 0, radius or 600) }
--     if B[1] ~= 0 and B[2] ~= 0 and B[3] ~= 0 then
--         return true, B[1], B[2], B[3]
--     end
--     return false
-- end

-- function convert2DCoordsToMenuMapScreenCoords(x, y)
    -- local fMapZoom = ffi.cast("float*", 0xBA6748+0x64)[0]
    -- local fMapBaseX = ffi.cast("float*", 0xBA6748+0x68)[0]
    -- local fMapBaseY = ffi.cast("float*", 0xBA6748+0x6C)[0]

    -- if isKeyDown(0x5A) then
        -- return convertGameScreenCoordsToWindowScreenCoords(320+(x/3000)*140, 206-(y/3000)*140)
    -- else
        -- return convertGameScreenCoordsToWindowScreenCoords(fMapBaseX+(x/3000)*fMapZoom, fMapBaseY-(y/3000)*fMapZoom)
    -- end
-- end

-- function get_camera_look_point(distance)
    -- local cam_x, cam_y, cam_z = getActiveCameraCoordinates()
    -- local at_x, at_y, at_z = getActiveCameraPointAt()

    -- local dir_x, dir_y, dir_z = at_x - cam_x, at_y - cam_y, at_z - cam_z
    -- local length = math.sqrt(dir_x^2 + dir_y^2 + dir_z^2)

    -- local norm_dir_x, norm_dir_y, norm_dir_z = dir_x / length, dir_y / length, dir_z / length

    -- return cam_x + distance * norm_dir_x, cam_y + distance * norm_dir_y, cam_z + distance * norm_dir_z
-- end

-- function govnaPacket(dist)
  -- local w, h = getScreenResolution()
  -- return convertScreenCoordsToWorld3D(w/2, h/2, dist)
-- end

-- function isLookingAtPlayer()
    -- return readMemory(0xB6F028+0x2B, 1, true) == 1
-- end

-- function nForm(num, v1, v2, v3)
    -- if num % 10 == 1 then return v1
    -- elseif num % 10 >= 2 and num % 10 <= 4 then return v2
    -- else return v3 end
-- end

-- function formatUnixTime(time, format)
    -- -- or use %B, but needs string.lower & change the ending
    -- local month = {'v–‚¿‹v—‚¿‘v–‚¿‹v¬¨?v–‚¿‹v—?åv–‚¿‹v¬¨Üv–‚¿‹v¬¨?v–‚¿‹v—‚¿‘','v–‚¿‹v“‚¿ v–‚¿‹v“¨–v–‚¿‹v—?åv–‚¿‹v¬¨?v–‚¿‹v¬¨Üv–‚¿‹v¬¨Äv–‚¿‹v—‚¿‘','v–‚¿‹v¬¨êv–‚¿‹v¬¨Üv–‚¿‹v¬¨?v–‚¿‹v–‚¿Üv–‚¿‹v¬¨Ü','v–‚¿‹v¬¨Üv–‚¿‹v–‚¿∞v–‚¿‹v¬¨?v–‚¿‹v“¨–v–‚¿‹v¬¨Äv–‚¿‹v—‚¿‘','v–‚¿‹v¬¨êv–‚¿‹v¬¨Üv–‚¿‹v—‚¿‘','v–‚¿‹v–¨¡v–‚¿‹v—‚¿?v–‚¿‹v¬¨?v–‚¿‹v—‚¿‘','v–‚¿‹v–¨¡v–‚¿‹v—‚¿?v–‚¿‹v¬¨Äv–‚¿‹v—‚¿‘','v–‚¿‹v¬¨Üv–‚¿‹v—?åv–‚¿‹v–é∆v–‚¿‹v—‚¿”v–‚¿‹v¬¨±v–‚¿‹v–‚¿Üv–‚¿‹v¬¨Ü','v–‚¿‹v¬¨±v–‚¿‹v“¨–v–‚¿‹v¬¨?v–‚¿‹v–‚¿Üv–‚¿‹v—‚¿‘v–‚¿‹v–?öv–‚¿‹v¬¨?v–‚¿‹v—‚¿‘','v–‚¿‹v¬¨Åv–‚¿‹v–‚¿ﬁv–‚¿‹v–‚¿Üv–‚¿‹v—‚¿‘v–‚¿‹v–?öv–‚¿‹v¬¨?v–‚¿‹v—‚¿‘','v–‚¿‹v¬¨?v–‚¿‹v¬¨Åv–‚¿‹v—‚¿‘v–‚¿‹v–?öv–‚¿‹v¬¨?v–‚¿‹v—‚¿‘','v–‚¿‹v¬¨ßv–‚¿‹v“¨–v–‚¿‹v–‚¿ﬁv–‚¿‹v¬¨Üv–‚¿‹v–?öv–‚¿‹v¬¨?v–‚¿‹v—‚¿‘'}
    -- local forms = {
        -- { 'sec', 'v–‚¿‹v¬¨±v–‚¿‹v“¨–v–‚¿‹v–‚¿ﬁv–‚¿‹v—‚¿”v–‚¿‹v¬¨?v–‚¿‹v¬¨ßv–‚¿‹v—‚¿”', 'v–‚¿‹v¬¨±v–‚¿‹v“¨–v–‚¿‹v–‚¿ﬁv–‚¿‹v—‚¿”v–‚¿‹v¬¨?v–‚¿‹v¬¨ßv–‚¿‹v¬¨ø', 'v–‚¿‹v¬¨±v–‚¿‹v“¨–v–‚¿‹v–‚¿ﬁv–‚¿‹v—‚¿”v–‚¿‹v¬¨?v–‚¿‹v¬¨ß' },
        -- { 'min', 'v–‚¿‹v¬¨êv–‚¿‹v–¨¡v–‚¿‹v¬¨?v–‚¿‹v—‚¿”v–‚¿‹v–‚¿Üv–‚¿‹v—‚¿”', 'v–‚¿‹v¬¨êv–‚¿‹v–¨¡v–‚¿‹v¬¨?v–‚¿‹v—‚¿”v–‚¿‹v–‚¿Üv–‚¿‹v¬¨ø', 'v–‚¿‹v¬¨êv–‚¿‹v–¨¡v–‚¿‹v¬¨?v–‚¿‹v—‚¿”v–‚¿‹v–‚¿Ü' },
        -- { 'hour', 'v–‚¿‹v¬¨£v–‚¿‹v¬¨Üv–‚¿‹v¬¨±', 'v–‚¿‹v¬¨£v–‚¿‹v¬¨Üv–‚¿‹v¬¨±v–‚¿‹v¬¨Ü', 'v–‚¿‹v¬¨£v–‚¿‹v¬¨Üv–‚¿‹v¬¨±v–‚¿‹v¬¨Åv–‚¿‹v—?å' },
        -- { 'day', 'v–‚¿‹v¬¨ßv–‚¿‹v“¨–v–‚¿‹v¬¨?v–‚¿‹v— ', 'v–‚¿‹v¬¨ßv–‚¿‹v¬¨?v–‚¿‹v—‚¿‘', 'v–‚¿‹v¬¨ßv–‚¿‹v¬¨?v–‚¿‹v“¨–v–‚¿‹v¬¨©' },
        -- { 'month', 'v–‚¿‹v¬¨êv–‚¿‹v“¨–v–‚¿‹v¬¨±v–‚¿‹v—‚¿‘v–‚¿‹v¬¨?', 'v–‚¿‹v¬¨êv–‚¿‹v“¨–v–‚¿‹v¬¨±v–‚¿‹v—‚¿‘v–‚¿‹v¬¨?v–‚¿‹v¬¨Ü', 'v–‚¿‹v¬¨êv–‚¿‹v“¨–v–‚¿‹v¬¨±v–‚¿‹v—‚¿‘v–‚¿‹v¬¨?v–‚¿‹v“¨–v–‚¿‹v—?å' },
        -- { 'year', 'v–‚¿‹v–é∆v–‚¿‹v¬¨Åv–‚¿‹v¬¨ß', 'v–‚¿‹v–é∆v–‚¿‹v¬¨Åv–‚¿‹v¬¨ßv–‚¿‹v¬¨Ü', 'v–‚¿‹v¬¨Äv–‚¿‹v“¨–v–‚¿‹v–‚¿Ü' }
    -- }

    -- local formats = {
        -- ['t'] = function()
            -- return os.date('%H:%M', time)
        -- end,
        -- ['T'] = function()
            -- return os.date('%H:%M:%S', time)
        -- end,
        -- ['d'] = function()
            -- return os.date('%x', time)
        -- end,
        -- ['D'] = function()
            -- local table_time = os.date('*t', time)
            -- return ('%02d %s %d v–‚¿‹v–é∆.'):format(table_time.day, month[table_time.month], table_time.year)
        -- end,
        -- ['f*'] = function()
            -- return ('%s, %s'):format(formatUnixTime(time, 'D'), formatUnixTime(time, 't'))
        -- end,
        -- ['F'] = function()
            -- return ('%s, %s'):format(os.date('%A', time), formatUnixTime(time, 'f*'))
        -- end,
        -- ['R'] = function()
            -- local diff = os.difftime(os.time(), time)

            -- local diff_str = ''
            -- local table_diff = os.date('*t', math.abs(diff))
            -- local table_default = os.date('*t', 0)
            -- for i = #forms, 1, -1 do
                -- local form = forms[i]
                -- local value = table_diff[form[1]] - table_default[form[1]]
                -- if value > 0 then
                    -- local form_str = nForm(value, form[2], form[3], form[4])
                    -- diff_str = ('%d %s'):format(value, form_str)
                    -- break
                -- end
            -- end

            -- if diff < 0 then
                -- return ('v–‚¿‹v¬¨£v–‚¿‹v“¨–v–‚¿‹v¬¨?v–‚¿‹v“¨–v–‚¿‹v¬¨≤ %s'):format(diff_str)
            -- elseif diff > 0 then
                -- return ('%s v–‚¿‹v¬¨?v–‚¿‹v¬¨Üv–‚¿‹v¬¨≤v–‚¿‹v¬¨Üv–‚¿‹v¬¨ß'):format(diff_str)
            -- end
            -- return 'v–‚¿‹v¬¨±v–‚¿‹v“¨–v–‚¿‹v¬¨©v–‚¿‹v¬¨£v–‚¿‹v¬¨Üv–‚¿‹v¬¨±'
        -- end
    -- }
    -- return formats[format] and formats[format]() or nil
-- end

-- function setWeaponsScrollable(bool)
    -- ffi.copy(ffi.cast("void*", 0x60D8C6), bool and "\x0F\x84\xB0\x01\x00\x00" or "\xE9\xF3\x00\x00\x00\x90", 6)
-- end

-- function imgui.TextColoredRGB(text)
    -- local style = imgui.GetStyle()
    -- local colors = style.Colors
    -- local ImVec4 = imgui.ImVec4
    -- local explode_argb = function(argb)
        -- local a = bit.band(bit.rshift(argb, 24), 0xFF)
        -- local r = bit.band(bit.rshift(argb, 16), 0xFF)
        -- local g = bit.band(bit.rshift(argb, 8), 0xFF)
        -- local b = bit.band(argb, 0xFF)
        -- return a, r, g, b
    -- end
    -- local getcolor = function(color)
        -- if color:sub(1, 6):upper() == 'SSSSSS' then
            -- local r, g, b = colors[1].x, colors[1].y, colors[1].z
            -- local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            -- return ImVec4(r, g, b, a / 255)
        -- end
        -- local color = type(color) == 'string' and tonumber(color, 16) or color
        -- if type(color) ~= 'number' then return end
        -- local r, g, b, a = explode_argb(color)
        -- return imgui.ImVec4(r/255, g/255, b/255, a/255)
    -- end
    -- local render_text = function(text_)
        -- for w in text_:gmatch('[^\r\n]+') do
            -- local text, colors_, m = {}, {}, 1
            -- w = w:gsub('{(......)}', '{%1FF}')
            -- while w:find('{........}') do
                -- local n, k = w:find('{........}')
                -- local color = getcolor(w:sub(n + 1, k - 1))
                -- if color then
                    -- text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    -- colors_[#colors_ + 1] = color
                    -- m = n
                -- end
                -- w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            -- end
            -- if text[0] then
                -- for i = 0, #text do
                    -- imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    -- imgui.SameLine(nil, 0)
                -- end
                -- imgui.NewLine()
            -- else imgui.Text(u8(w)) end
        -- end
    -- end
    -- render_text(text)
-- end

-- function getNearestCarHandle(maxDistance)
    -- maxDistance = maxDistance or 9999
    -- local resX, resY = getScreenResolution()
    -- local centerX, centerY = resX / 2, resY / 2
    -- local distanceBetweenVehicles = {}
    -- local plX, plY, plZ = getCharCoordinates(PLAYER_PED)
    -- for k, v in ipairs(getAllVehicles()) do
        -- local carX, carY, carZ = getCarCoordinates(v)
        -- local screenX, screenY = convert3DCoordsToScreen(carX, carY, carZ)
        -- local distance = getDistanceBetweenCoords2d(centerX, centerY, screenX, screenY)
        -- local distanceBetweenPlayerAndVehicle = getDistanceBetweenCoords3d(plX, plY, plZ, carX, carY, carZ)
        -- if distanceBetweenPlayerAndVehicle < maxDistance then
            -- table.insert(distanceBetweenVehicles, {handle = v, distance = distance})
        -- end
    -- end
    -- local smallestDistance, handle = 9999, -1
    -- for k, v in ipairs(distanceBetweenVehicles) do
        -- if smallestDistance > v.distance then
            -- smallestDistance = v.distance
            -- handle = v.handle
        -- end
    -- end
    -- return handle, smallestDistance
-- end

-- function changeScreenPos()
    -- local x, y = getCursorPos() 
    -- if isKeyJustPressed(1) then 
        -- return x, y
    -- end
    -- if isKeyJustPressed(27) then
        -- return false
    -- end
-- end

-- function addDebugMessage(message, ...)
    -- local samp = getModuleHandle("samp.dll")
    -- -- R1: pChat - 0x21A0E4, pAddDebugMessage = 0x64520
    -- -- R3: pChat - 0x26E8C8, pAddDebugMessage = 0x67970
    -- -- R5: pChat - 0x26EB80, pAddDebugMessage = 0x68070
    -- local pChat = ffi.cast("void*", tonumber(ffi.cast("unsigned int*", (samp + 0x21A0E4))[0]))
    -- local pAddDebugMessage = (samp + 0x64520)   
    -- local pszMessage = ffi.cast("const char*", message)
    -- return ffi.cast("unsigned int(__cdecl*)(void*, const char*, ...)", pAddDebugMessage)(pChat, pszMessage, ...)
-- end

-- function addInfoMessage(message, ...)
    -- local samp = getModuleHandle("samp.dll")
    -- -- R1: pChat - 0x21A0E4, pAddInfoMessage = 0x644A0
    -- -- R3: pChat - 0x26E8C8, pAddInfoMessage = 0x678F0
    -- -- R5: pChat - 0x26EB80, pAddInfoMessage = 0x680F0
    -- local pChat = ffi.cast("void*", tonumber(ffi.cast("unsigned int*", (samp + 0x21A0E4))[0]))
    -- local pAddInfoMessage = (samp + 0x644A0) 
    -- local pszMessage = ffi.cast("const char*", message)
    -- return ffi.cast("unsigned int(__cdecl*)(void*, const char*, ...)", pAddInfoMessage)(pChat, pszMessage, ...)
-- end

-- function setCharModel(ped, model)
    -- assert(doesCharExist(ped), 'ped not found')
    -- if not hasModelLoaded(model) then
        -- requestModel(model)
        -- loadAllModelsNow()
    -- end
    -- CPed_SetModelIndex(ffi.cast('void*', getCharPointer(ped)), ffi.cast('unsigned int', model))
-- end

-- function TransformRealWorldPointToRadarSpace(x, y)
    -- local RetVal = ffi.new('struct CVector2D', {0, 0})
    -- CRadar_TransformRealWorldPointToRadarSpace(RetVal, ffi.new('struct CVector2D', {x, y}))
    -- return RetVal.x, RetVal.y
-- end

-- function TransformRadarPointToScreenSpace(x, y)
    -- local RetVal = ffi.new('struct CVector2D', {0, 0})
    -- CRadar_TransformRadarPointToScreenSpace(RetVal, ffi.new('struct CVector2D', {x, y}))
    -- return RetVal.x, RetVal.y
-- end

-- function IsPointInsideRadar(x, y)
    -- return CRadar_IsPointInsideRadar(ffi.new('struct CVector2D', {x, y}))
-- end

--MimGUI Themes

function fl.BlueTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
  
    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.93, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.18, 0.20, 0.22, 0.30)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.80, 0.80, 0.90, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.60, 0.60, 0.65, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.12, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.18, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
end

function fl.OrangeTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 0.90, 0.85, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.75, 0.60, 0.55, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.30, 0.20, 0.15, 0.30)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.80, 0.35, 0.20, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.45, 0.25, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.55, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.20, 0.10, 0.05, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.80, 0.35, 0.20, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(1.00, 0.70, 0.55, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.45, 0.25, 0.20, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.55, 0.30, 0.25, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.65, 0.40, 0.30, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.80, 0.35, 0.20, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.45, 0.25, 0.20, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.55, 0.30, 0.25, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.65, 0.40, 0.30, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.55, 0.30, 0.25, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.25, 0.15, 0.10, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
end

function fl.LightTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.55, 0.55, 0.55, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.45, 0.45, 0.45, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.55, 0.55, 0.55, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.85, 0.85, 0.85, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
end

function fl.GrayTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.80, 0.80, 0.83, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.16, 0.16, 0.17, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.18, 0.18, 0.19, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.31, 0.31, 0.35, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.35, 0.35, 0.37, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.45, 0.45, 0.47, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.33, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.60, 0.60, 0.63, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.45, 0.45, 0.47, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.45, 0.45, 0.48, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.30, 0.30, 0.33, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.30, 0.30, 0.33, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.65, 0.65, 0.68, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.75, 0.75, 0.78, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.65, 0.65, 0.68, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.75, 0.75, 0.78, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.20, 0.20, 0.22, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
end

function fl.GreenTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
  
    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.85, 0.93, 0.85, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.55, 0.65, 0.55, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.13, 0.22, 0.13, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.17, 0.27, 0.17, 1.00)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.15, 0.24, 0.15, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.18, 0.28, 0.18, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.30, 0.40, 0.30, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.35, 0.45, 0.35, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.50, 0.70, 0.50, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.50, 0.70, 0.50, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.55, 0.75, 0.55, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.28, 0.38, 0.28, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.30, 0.40, 0.30, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.30, 0.40, 0.30, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.35, 0.45, 0.35, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.60, 0.70, 0.60, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.65, 0.75, 0.65, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.60, 0.70, 0.60, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.65, 0.75, 0.65, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.15, 0.25, 0.15, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
end

function fl.RedTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 10.0
    style.ChildRounding = 6.0
    style.FramePadding = imgui.ImVec2(8, 7)
    style.FrameRounding = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing = imgui.ImVec2(10, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 12.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 6.0
    style.PopupRounding = 8
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

    -- ÷‚ÂÚ‡
    style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.85, 0.85, 1.00)
    style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.15, 0.03, 0.03, 1.00)
    style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.18, 0.05, 0.05, 0.30)
    style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.15, 0.03, 0.03, 1.00)
    style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.50, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.25, 0.07, 0.07, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.08, 0.08, 1.00)
    style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.30, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.20, 0.05, 0.05, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.15, 0.03, 0.03, 1.00)
    style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.25, 0.07, 0.07, 1.00)
    style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.20, 0.05, 0.05, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.15, 0.03, 0.03, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.50, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.60, 0.12, 0.12, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.70, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.90, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.90, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.90, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.25, 0.07, 0.07, 1.00)
    style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.80, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.90, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.25, 0.07, 0.07, 1.00)
    style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.80, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.90, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.50, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.60, 0.12, 0.12, 1.00)
    style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.70, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.25, 0.07, 0.07, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.80, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.90, 0.25, 0.25, 1.00)
    style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.80, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.90, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.80, 0.10, 0.10, 1.00)
    style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.90, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.90, 0.15, 0.15, 1.00)
    style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.20, 0.05, 0.05, 0.80)
    style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.25, 0.07, 0.07, 1.00)
    style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.80, 0.20, 0.20, 1.00)
    style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.90, 0.25, 0.25, 1.00)
end

function fl.LightGreenTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
   
    -- ŒÒÌÓ‚Ì˚Â ˆ‚ÂÚ‡
    local bgColor = imgui.ImVec4(0.12, 0.13, 0.14, 1.00) -- “ÂÏÌ˚È ÙÓÌ
    local panelColor = imgui.ImVec4(0.18, 0.19, 0.20, 1.00) -- œ‡ÌÂÎ¸
    local highlightColor = imgui.ImVec4(0.00, 0.80, 0.60, 1.00) -- «ÂÎÂÌ˚È ‡ÍˆÂÌÚ
    local glowColor = imgui.ImVec4(0.00, 0.80, 0.60, 0.5)
   
    -- Õ‡ÒÚÓÈÍ‡ ˆ‚ÂÚÓ‚
    colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[imgui.Col.WindowBg] = bgColor
    colors[imgui.Col.ChildBg] = panelColor
    colors[imgui.Col.PopupBg] = panelColor
    colors[imgui.Col.Border] = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
    colors[imgui.Col.FrameBg] = panelColor
    colors[imgui.Col.FrameBgHovered] = highlightColor
    colors[imgui.Col.FrameBgActive] = highlightColor
    colors[imgui.Col.TitleBg] = panelColor
    colors[imgui.Col.TitleBgActive] = highlightColor
    colors[imgui.Col.TitleBgCollapsed] = panelColor
    colors[imgui.Col.CheckMark] = highlightColor
    colors[imgui.Col.SliderGrab] = highlightColor
    colors[imgui.Col.SliderGrabActive] = highlightColor
    colors[imgui.Col.Button] = panelColor
    colors[imgui.Col.ButtonHovered] = glowColor
    colors[imgui.Col.ButtonActive] = highlightColor
    colors[imgui.Col.Header] = panelColor
    colors[imgui.Col.HeaderHovered] = highlightColor
    colors[imgui.Col.HeaderActive] = highlightColor
    colors[imgui.Col.Separator] = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
    colors[imgui.Col.SeparatorHovered] = highlightColor
    colors[imgui.Col.SeparatorActive] = highlightColor
    colors[imgui.Col.ResizeGrip] = highlightColor
    colors[imgui.Col.ResizeGripHovered] = highlightColor
    colors[imgui.Col.ResizeGripActive] = highlightColor
    colors[imgui.Col.Tab] = panelColor
    colors[imgui.Col.TabHovered] = highlightColor
    colors[imgui.Col.TabActive] = highlightColor
    colors[imgui.Col.TabUnfocused] = panelColor
    colors[imgui.Col.TabUnfocusedActive] = highlightColor
    colors[imgui.Col.PlotLines] = highlightColor
    colors[imgui.Col.PlotLinesHovered] = highlightColor
    colors[imgui.Col.PlotHistogram] = highlightColor
    colors[imgui.Col.PlotHistogramHovered] = highlightColor
    colors[imgui.Col.TextSelectedBg] = highlightColor
    colors[imgui.Col.DragDropTarget] = highlightColor
    colors[imgui.Col.NavHighlight] = highlightColor
    colors[imgui.Col.NavWindowingHighlight] = highlightColor
    colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
    colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
   
    -- Õ‡ÒÚÓÈÍ‡ ‡ÁÏÂÓ‚ Ë ÓÚÒÚÛÔÓ‚
    style.WindowPadding = imgui.ImVec2(10, 10)
    style.FramePadding = imgui.ImVec2(5, 5)
    style.ItemSpacing = imgui.ImVec2(5, 5)
    style.WindowBorderSize = 1.0
    style.FrameBorderSize = 1.0
    style.WindowRounding = 5.0
    style.ChildRounding = 5.0
    style.FrameRounding = 5.0
    style.GrabRounding = 5.0
    style.ScrollbarRounding = 5.0
end

function fl.PinkTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 10
    style.ChildWindowRounding = 10
    style.FrameRounding = 6.0
    style.ItemSpacing = imgui.ImVec2(5.00, 5.00)
    style.ItemInnerSpacing = imgui.ImVec2(5.00, 5.00)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 17.0
    style.GrabRounding = 16.0

    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                    = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]            = ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[clr.WindowBg]                = ImVec4(0.00, 0.00, 0.00, 0.70)
    colors[clr.ChildWindowBg]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.PopupBg]                 = ImVec4(0.05, 0.05, 0.10, 0.90)
    colors[clr.Border]                  = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]            = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                 = ImVec4(0.80, 0.80, 0.80, 0.30)
    colors[clr.FrameBgHovered]          = ImVec4(0.90, 0.80, 0.80, 0.40)
    colors[clr.FrameBgActive]           = ImVec4(0.90, 0.70, 0.97, 0.50)
    colors[clr.TitleBg]                 = ImVec4(0.85, 0.45, 0.78, 0.78)
    colors[clr.TitleBgActive]           = ImVec4(0.85, 0.45, 0.78, 0.78)
    colors[clr.TitleBgCollapsed]        = ImVec4(0.90, 0.53, 1.00, 0.20)
    colors[clr.MenuBarBg]               = ImVec4(0.85, 0.53, 0.80, 0.70)
    colors[clr.ScrollbarBg]             = ImVec4(1.25, 1.25, 1.25, 0.00)
    colors[clr.ScrollbarGrab]           = ImVec4(1.00, 0.60, 1.00, 0.30)
    colors[clr.ScrollbarGrabHovered]    = ImVec4(1.00, 0.60, 1.00, 0.43)
    colors[clr.ScrollbarGrabActive]     = ImVec4(1.00, 0.60, 1.00, 0.21)
    colors[clr.ComboBg]                 = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.CheckMark]               = ImVec4(0.90, 0.90, 0.90, 0.50)
    colors[clr.SliderGrab]              = ImVec4(0.85, 0.61, 0.98, 0.30)
    colors[clr.SliderGrabActive]        = ImVec4(0.98, 0.62, 0.95, 0.60)
    colors[clr.Button]                  = ImVec4(1.00, 0.68, 0.95, 0.60)
    colors[clr.ButtonHovered]           = ImVec4(1.00, 0.68, 0.95, 0.47)
    colors[clr.ButtonActive]            = ImVec4(1.00, 0.68, 0.95, 0.70)
    colors[clr.Header]                  = ImVec4(1.00, 0.68, 0.95, 0.60)
    colors[clr.HeaderHovered]           = ImVec4(1.00, 0.68, 0.95, 0.47)
    colors[clr.HeaderActive]            = ImVec4(1.00, 0.68, 0.95, 0.78)
    colors[clr.Separator]               = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.SeparatorHovered]        = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.SeparatorActive]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.ResizeGrip]              = ImVec4(1.00, 1.00, 1.00, 0.30)
    colors[clr.ResizeGripHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.ResizeGripActive]        = ImVec4(1.00, 1.00, 1.00, 0.90)
    colors[clr.CloseButton]             = ImVec4(1.00, 1.00, 1.00, 0.20)
    colors[clr.CloseButtonHovered]      = ImVec4(0.93, 0.52, 1.00, 0.60)
    colors[clr.CloseButtonActive]       = ImVec4(0.70, 0.70, 0.70, 1.00)
    colors[clr.PlotLines]               = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]        = ImVec4(0.86, 0.60, 1.00, 1.00)
    colors[clr.PlotHistogram]           = ImVec4(0.83, 0.46, 1.00, 1.00)
    colors[clr.PlotHistogramHovered]    = ImVec4(0.90, 0.42, 1.00, 1.00)
    colors[clr.TextSelectedBg]          = ImVec4(0.86, 0.63, 1.00, 0.35)
    colors[clr.ModalWindowDarkening]    = ImVec4(0.20, 0.20, 0.20, 0.35)
end

return fl