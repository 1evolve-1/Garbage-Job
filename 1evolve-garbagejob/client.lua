ESX = exports["es_extended"]:getSharedObject()
local lib = exports.ox_lib

local rifiutiProxies = {}
local rifiutiModel = "prop_ld_rub_binbag_01"
local rifiutiRaccolti = 0
local posizioniRaccoltaUsate = {}
local rifiutiTargetAttivi = {}
local propCreati = {}

posizioniRaccolta = Config.posizioniRaccolta
rifiutiTargetAttivi = {}
posizioniRaccoltaUsate = {}

function impostaNuovoPunto()
    if #posizioniRaccolta > 0 then
        local indice = math.random(#posizioniRaccolta)
        local posizioneCasuale = posizioniRaccolta[indice]

        SetNewWaypoint(posizioneCasuale.x, posizioneCasuale.y)
        lib:notify({title = 'Information', description = Config.Scritte.gotolocation, type = 'inform', position = 'top'})

        generaRifiutiCasuali(posizioneCasuale)

        table.insert(posizioniRaccoltaUsate, posizioneCasuale)
        table.remove(posizioniRaccolta, indice)
    else
        lib:notify({title = 'Information', description = Config.Scritte.gotolocationsell, type = 'inform', position = 'top'})
        SetNewWaypoint(640.11, -3008.71) 
    end
end

function generaRifiutiCasuali(posizione)
    local numeroRifiuti = math.random(2, 4)
    for i = 1, numeroRifiuti do
        local offsetX = math.random(-1, 1)
        local offsetY = math.random(-1, 1)
        local nuovaPosizione = vector3(posizione.x + offsetX, posizione.y + offsetY, posizione.z)

        local isPropNearby = false
        for _, prop in ipairs(rifiutiProxies) do
            local propCoords = GetEntityCoords(prop)
            if #(nuovaPosizione - propCoords) < 1.0 then
                isPropNearby = true
                break
            end
        end

        if not isPropNearby then
            generaRifiuto(nuovaPosizione)
        else
        end
    end
end

function generaRifiuto(posizione)
    local rifiutoHash = GetHashKey(rifiutiModel)
    RequestModel(rifiutoHash)
    while not HasModelLoaded(rifiutoHash) do
        Wait(500)
    end

    local rifiuto = CreateObject(rifiutoHash, posizione.x, posizione.y, posizione.z, true, true, true)
    FreezeEntityPosition(rifiuto, true)
    SetEntityAsMissionEntity(rifiuto, true, true)

    table.insert(rifiutiProxies, rifiuto)
end

function gestisciInterazione(rifiuto)
    if DoesEntityExist(rifiuto) then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local rifiutoCoords = GetEntityCoords(rifiuto)

        RequestAnimDict("pickup_object")
        while not HasAnimDictLoaded("pickup_object") do
            Wait(100)
        end

        TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, -8.0, 2000, 0, 0, false, false, false)
        Wait(2000)

        local prop = CreateObject(GetHashKey('prop_cs_rub_binbag_01'), playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
        AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, 0.0, 0.0, -90.0, 180.0, -40.0, false, false, false, false, 1, true)

        SetEntityAsMissionEntity(prop, true, true)
        PlayerCarryingProp = prop

        table.insert(propCreati, { prop = prop, coords = playerCoords })

        RequestAnimDict("anim@heists@narcotics@trash")
        while not HasAnimDictLoaded("anim@heists@narcotics@trash") do
            Wait(100)
        end
        TaskPlayAnim(playerPed, "anim@heists@narcotics@trash", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)

        NetworkRequestControlOfEntity(rifiuto)
        local attempts = 0

        while DoesEntityExist(rifiuto) and attempts < 5 do
            SetEntityAsMissionEntity(rifiuto, true, true)
            DeleteObject(rifiuto)
            Wait(500) 
            attempts = attempts + 1

        end

        for i, v in ipairs(rifiutiProxies) do
            if v == rifiuto then
                table.remove(rifiutiProxies, i)
                break
            end
        end

        rifiutiRaccolti = rifiutiRaccolti + 1

        if #rifiutiProxies == 0 then
            impostaNuovoPunto()
        end

        local targetName = 'rifiuto_' .. tostring(rifiuto)
        exports.ox_target:removeGlobalObject(targetName)
    end
end

function gestisciTarget()
    for _, rifiuto in ipairs(rifiutiProxies) do
        local targetName = 'rifiuto_' .. tostring(rifiuto)
        if not rifiutiTargetAttivi[targetName] then
            rifiutiTargetAttivi[targetName] = true
            exports.ox_target:addLocalEntity(rifiuto, {
                {
                    name = targetName,
                    icon = 'fas fa-trash',
                    label = Config.Scritte.collectgarbage,
                    event = 'raccogliRifiuto',
                    distance = 1.5
                }
            })
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        gestisciTarget()
    end
end)


local haRifiutoInMano = false

RegisterNetEvent('buttaRifiuto')
AddEventHandler('buttaRifiuto', function()
    local playerPed = PlayerPedId()

    if haRifiutoInMano  then
    RequestAnimDict('anim@heists@narcotics@trash')

    while not HasAnimDictLoaded('anim@heists@narcotics@trash') do
        Citizen.Wait(100)
    end

    TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'throw_ranged_f', 8.0, -8.0, 1000, 50, 0, false, false, false)
    
        Citizen.Wait(1000)
        ClearPedTasks(playerPed)
        haRifiutoInMano = false

        DetachEntity(PlayerCarryingProp, true, true)
        DeleteEntity(PlayerCarryingProp)
        PlayerCarryingProp = nil
        TriggerServerEvent('registraRifiutoButtato')
    else
        lib:notify({title = 'Attention', description = Config.Scritte.nothrewgarbage, type = 'error', position = 'top'})
    end
end)

RegisterNetEvent('raccogliRifiuto')
AddEventHandler('raccogliRifiuto', function()
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    if haRifiutoInMano then
        lib:notify({title = 'Attention', description = Config.Scritte.garbagehave, type = 'error', position = 'top'})
        return
    end
    for _, rifiuto in ipairs(rifiutiProxies) do
        local rifiutoCoords = GetEntityCoords(rifiuto)
            gestisciInterazione(rifiuto)
                haRifiutoInMano = true
            break
    end
end)

local veicoliTrash = {
    GetHashKey('trash'), 
    GetHashKey('trash2')
}

local function isTrashVehicle(vehicle)
    local model = GetEntityModel(vehicle)
    for _, trashModel in ipairs(veicoliTrash) do
        if model == trashModel then
            return true
        end
    end
    return false
end

local veicoliConTarget = {}

function aggiungiTargetVeicoloTrash(vehicle)
    local dio = 'dioaa' .. tostring(vehicle)
    if not veicoliConTarget[vehicle] and isTrashVehicle(vehicle) then
        exports.ox_target:addLocalEntity(vehicle, {
            {
                name = dio,
                event = 'buttaRifiuto',
                icon = 'fas fa-trash',
                label = Config.Scritte.throwgarbage,
                distance = 1.5
            }
        })
        veicoliConTarget[vehicle] = true
    end
end

RegisterNetEvent('iniziaLavoroRaccolta')
AddEventHandler('iniziaLavoroRaccolta', function()
    posizioniRaccolta = Config.posizioniRaccolta
    posizioniRaccoltaUsate = {}
    rifiutiRaccolti = 0
    impostaNuovoPunto()
    local playerPed = PlayerPedId()
    local vehicleHash = GetHashKey("trash")
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(500)
    end

    local vehicle = CreateVehicle(vehicleHash, 668.9907, -2961.121, 5.758783, 60.0, true, false)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local vehicles = GetAllVehicles()
        for _, vehicle in ipairs(vehicles) do
            if GetEntityModel(vehicle) == GetHashKey("trash") then
                aggiungiTargetVeicoloTrash(vehicle)
            end
        end
    end
end)

function GetAllVehicles()
    local vehicles = {}
    for vehicle in EnumerateVehicles() do
        table.insert(vehicles, vehicle)
    end
    return vehicles
end

function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end

Citizen.CreateThread(function()
    Wait(1000)
    local blip = AddBlipForCoord(Config.npc)
    SetBlipSprite(blip, 318) 
    SetBlipDisplay(blip, 4) 
    SetBlipScale(blip, 0.9) 
    SetBlipColour(blip, 11) 
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Garbage")
    EndTextCommandSetBlipName(blip)
end)

function creaVenditore()
    local venditoreCoords = Config.npc
    local npcModel = "s_m_y_garbage"

    local npcHash = GetHashKey(npcModel)
    RequestModel(npcHash)
    while not HasModelLoaded(npcHash) do
        Wait(500)
    end

    local npc = CreatePed(4, npcHash, venditoreCoords.x, venditoreCoords.y, venditoreCoords.z, 0.0, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    
    exports.ox_target:addGlobalPed({
        {
            name = 'venditore_rifiuti',
            coords = venditoreCoords,
            type = 'client',
            event = 'iniziaLavoroRaccolta',
            icon = 'fas fa-briefcase',
            label = Config.Scritte.startwork,

        },
        {
            name = 'venditore_rifiuti',
            coords = venditoreCoords,
            type = 'client',
            event = 'vendiRifiuti',
            icon = 'fas fa-recycle',
            label = Config.Scritte.sellgarbage,
        }
    })
end

function vendiRifiuti()
    TriggerServerEvent('vendiRifiutiServer')
end

RegisterNetEvent('vendiRifiuti')
AddEventHandler('vendiRifiuti', function()
    vendiRifiuti()
end)

Citizen.CreateThread(function()
    creaVenditore()
end)