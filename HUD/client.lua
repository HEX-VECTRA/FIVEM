local health, hunger, thirst = 100, 100, 100
local hasESXStatus = false

CreateThread(function()
    if GetResourceState('esx_status') == 'started' then hasESXStatus = true end
end)

-- Boucle pour MAJ santé
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        health = math.max(0, math.min(100, GetEntityHealth(ped) - 100))
        if not hasESXStatus then
            SendNUIMessage({type="update", health=health, hunger=hunger, thirst=thirst})
        end
    end
end)

-- Si ESX_status actif
RegisterNetEvent('esx_status:onTick', function(statuses)
    if not hasESXStatus then return end
    for _, s in ipairs(statuses) do
        if s.name == 'hunger' then hunger = math.floor(s.percent) end
        if s.name == 'thirst' then thirst = math.floor(s.percent) end
    end
    local ped = PlayerPedId()
    health = math.max(0, math.min(100, GetEntityHealth(ped) - 100))
    SendNUIMessage({type="update", health=health, hunger=hunger, thirst=thirst})
end)
