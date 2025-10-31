-- Persistance du kilométrage (universel, compatible ESX / QBCore / standalone)
-- Nécessite oxmysql

RegisterNetEvent('speedo:getOdo', function(plate)
    local src = source
    if not plate or plate == '' then return end

    local result = MySQL.single.await('SELECT distance_km FROM vehicle_odometer WHERE plate = ?', {plate})
    local km = result and result.distance_km or 0.0

    TriggerClientEvent('speedo:setOdo', src, plate, km)
end)

RegisterNetEvent('speedo:saveOdo', function(plate, km)
    if not plate or not km then return end
    MySQL.insert('INSERT INTO vehicle_odometer (plate, distance_km) VALUES (?, ?) ON DUPLICATE KEY UPDATE distance_km = ?', {plate, km, km})
end)
