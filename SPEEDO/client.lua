local showing = false
local odometers = {}
local lastPos, lastVeh

local function round(n, d) return math.floor((n * 10^d) + 0.5) / 10^d end
local function veh()
    local p = PlayerPedId()
    if IsPedInAnyVehicle(p, false) then
        return GetVehiclePedIsIn(p, false)
    end
    return 0
end

-- fuel safe (support ox_fuel / LegacyFuel / oxygen_fuel / natif)
local function getFuel(v)
    if v == 0 then return 0 end
    if GetResourceState('ox_fuel') == 'started' and exports.ox_fuel and exports.ox_fuel.getFuel then
        local ok, f = pcall(exports.ox_fuel.getFuel, v)
        if ok and f then return math.max(0, math.min(100, f)) end
    end
    if GetResourceState('LegacyFuel') == 'started' and exports.LegacyFuel and exports.LegacyFuel.GetFuel then
        local ok, f = pcall(exports.LegacyFuel.GetFuel, v)
        if ok and f then return math.max(0, math.min(100, f)) end
    end
    if GetResourceState('oxygen_fuel') == 'started' and exports['oxygen_fuel'] and exports['oxygen_fuel'].GetFuel then
        local ok, f = pcall(exports['oxygen_fuel'].GetFuel, v)
        if ok and f then return math.max(0, math.min(100, f)) end
    end
    local lvl = GetVehicleFuelLevel(v) or 0.0
    return math.max(0, math.min(100, lvl))
end

local function getVehHealth(v)
    local h = (GetVehicleEngineHealth(v) or 0.0) / 10.0
    if h < 0 then h = 0 end
    if h > 100 then h = 100 end
    return h
end

local function getRpm(v)
    local r = (GetVehicleCurrentRpm(v) or 0.0) * 100.0
    if r < 0 then r = 0 end
    if r > 100 then r = 100 end
    return r
end

local function updateOdometer(v)
    if v == 0 then lastPos, lastVeh = nil, nil; return 0.0 end
    local plate = string.gsub(GetVehicleNumberPlateText(v) or "UNKNOWN", "%s+", "")
    odometers[plate] = odometers[plate] or 0.0
    local coords = GetEntityCoords(PlayerPedId())
    if lastPos and lastVeh == v then
        local dist = #(coords - lastPos)
        if dist > 0.05 then odometers[plate] = odometers[plate] + dist end
    end
    lastPos, lastVeh = coords, v
    return round(odometers[plate] / 1000.0, 1)
end

-- Init NUI
AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "show", show = false })
        
    end
end)

-- Commande de test (ouvre l’UI et envoie des valeurs factices)
RegisterCommand('speedodebug', function()
    SendNUIMessage({ type = "show", show = true })
    SendNUIMessage({ type="update", kmh=123, fuel=66, rpm=45, health=88, odokm=12.3 })
    
end)

-- Carte moins envahissante
CreateThread(function()
    while true do
        Wait(2000)
        if IsPedInAnyVehicle(PlayerPedId(), false) then SetRadarZoom(1200) end
    end
end)

-- Boucle principale (TOUS types de véhicules, conducteur ou passager)
CreateThread(function()
    while true do
        local v = veh()
        if v ~= 0 then
            if not showing then
                showing = true
                SendNUIMessage({ type = "show", show = true })
            end

            local class = GetVehicleClass(v) -- 0 compact, 8 moto, 14 bateau, etc.
            local speedKmh = GetEntitySpeed(v) * 3.6
            local data = {
                type   = "update",
                kmh    = math.floor(speedKmh + 0.5),
                fuel   = math.floor(getFuel(v) + 0.5),
                rpm    = math.floor(getRpm(v) + 0.5),
                health = math.floor(getVehHealth(v) + 0.5),
                odokm  = updateOdometer(v) or 0.0
            }
            SendNUIMessage(data)

             --print(('[vectra_speed_v] class=%s kmh=%s fuel=%s rpm=%s health=%s odo=%.1f'):
               --format(class, data.kmh, data.fuel, data.rpm, data.health, data.odokm))

            Wait(100)
        else
            if showing then
                showing = false
                SendNUIMessage({ type = "show", show = false })
            end
            Wait(350)
        end
    end
end)

CreateThread(function()
    Wait(2500)
    print('[SPEEDO] ping NUI')
    SendNUIMessage({type='show', show=true})
    Wait(1500)
    SendNUIMessage({type='show', show=false})
end)

local currentPlate = nil
local currentOdo = 0.0
local lastSave = 0

-- Quand tu entres dans un véhicule → récupérer km
CreateThread(function()
    while true do
        Wait(1000)
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            local plate = string.gsub(GetVehicleNumberPlateText(veh) or "", "%s+", "")
            if currentPlate ~= plate then
                currentPlate = plate
                TriggerServerEvent('speedo:getOdo', plate)
            end
        else
            currentPlate = nil
        end
    end
end)

-- Réception du km actuel depuis le serveur
RegisterNetEvent('speedo:setOdo', function(plate, km)
    if plate == currentPlate then
        currentOdo = km
    end
end)


local function updateOdometer(v)
    if v == 0 then lastPos, lastVeh = nil, nil; return 0.0 end

    local plate = string.gsub(GetVehicleNumberPlateText(v) or "UNKNOWN", "%s+", "")
    odometers[plate] = odometers[plate] or currentOdo or 0.0

    local coords = GetEntityCoords(PlayerPedId())
    if lastPos and lastVeh == v then
        local dist = #(coords - lastPos)
        if dist > 0.05 then
            odometers[plate] = odometers[plate] + dist
            currentOdo = odometers[plate]
        end
    end
    lastPos, lastVeh = coords, v

    -- sauvegarde serveur toutes les 60 secondes
    if GetGameTimer() - lastSave > 60000 and currentPlate then
        TriggerServerEvent('speedo:saveOdo', currentPlate, currentOdo / 1000.0)
        lastSave = GetGameTimer()
    end

    return round((odometers[plate] / 1000.0), 1)
end



RegisterNetEvent('speedo:getOdo', function(plate)
    local src = source
    if not plate or plate == '' then return end


    if string.find(string.upper(plate), 'VECTRA') then
        print('[Speedo] Ignoré: véhicule admin ('..plate..')')
        TriggerClientEvent('speedo:setOdo', src, plate, 0.0)
        return
    end

    local result = MySQL.single.await('SELECT distance_km FROM vehicle_odometer WHERE plate = ?', {plate})
    local km = result and result.distance_km or 0.0

    TriggerClientEvent('speedo:setOdo', src, plate, km)
end)

RegisterNetEvent('speedo:saveOdo', function(plate, km)
    if not plate or not km then return end

    if string.find(string.upper(plate), 'VECTRA') then
        return
    end

    MySQL.insert('INSERT INTO vehicle_odometer (plate, distance_km) VALUES (?, ?) ON DUPLICATE KEY UPDATE distance_km = ?', {plate, km, km})
end)
