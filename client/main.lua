lib.locale()

IsJobActive = false

PedBlip = nil

-- The prop in the player's hand
CurrentGarbageProp = nil

IsWearingJobsClothes = false
PlayerSavedSkin = nil

-- Saved garbage points
local garbagePoints = {}

local function spawnGarbageBag()
    if CurrentGarbageProp and DoesEntityExist(CurrentGarbageProp) then return end

    local playerPed = PlayerPedId()
    local modelName = "prop_ld_binbag_01"
    local hash = GetHashKey(modelName)

    -- Carica il modello
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end

    local coords = GetEntityCoords(playerPed)

    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
    Wait(100)

    -- Crea l'oggetto
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)

    -- Indice dell'osso della mano destra
    local boneIndex = GetPedBoneIndex(playerPed, 60309)

    -- Attacca l'oggetto alla mano (con offset e rotazione testati per /prop_cs_rub_bag_01/)
    AttachEntityToEntity(prop, playerPed, boneIndex, 0.12, 0.0, -0.05, 0.0, 270.0, 60.0, true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(hash)
    CurrentGarbageProp = prop

    -- === AGGIUNTA: Ferma la scenario task dopo l'attacco ===
    -- Il prop rimarrà attaccato anche dopo aver fermato l'animazione
    ClearPedTasksImmediately(playerPed)
end

local function removeGarbageBag()
    if CurrentGarbageProp and DoesEntityExist(CurrentGarbageProp) then
        DeleteEntity(CurrentGarbageProp)
        CurrentGarbageProp = nil
    end
end

local function changeBlipColor(id)
    local blip = garbagePoints[id].blip
    SetBlipColour(blip, 2) -- Change blip color to indicate it's taken
end

local function addGarbagesPoints()
    for _, coords in pairs(Config.GarbagesPos) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 318)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Raccolta Rifiuti")
        EndTextCommandSetBlipName(blip)

        local point = lib.points.new({
            coords = coords,
            distance = 20,
            blip = blip,
            index = _
        })

        function point:onEnter()
            print('entered range of point', self.id)
        end
        function point:onExit()
            print('left range of point', self.id)
        end
        function point:nearby()
            local currentColor = GetBlipColour(blip)
            if currentColor == 2 then
                return -- Already taken, do nothing
            end
            DrawMarker(27,
                self.coords.x, self.coords.y, self.coords.z + 0.1,
                0.0, 0.0, 0.0,
                0.0, 180.0, 0.0,
                1.0, 1.0, 1.0,
                0.0, 255, 20, 50,
                false, true, 2, false, nil, nil, false)
            if self.currentDistance < 2 and IsControlJustReleased(0, 38) then

                -- Wait a couple of seconds
                if lib.progressCircle({
                    duration = math.random(Config.GarbageBagPickupTime.Min, Config.GarbageBagPickupTime.Max),
                    label = 'Raccogliendo il sacco',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                        mouse = true,
                        sprint = true
                    },
                    --anim = {
                    --    dict = 'mp_player_intdrink',
                    --    clip = 'loop_bottle'
                    --},
                    --prop = {
                    --    model = `prop_ld_flow_bottle`,
                    --    pos = vec3(0.03, 0.03, 0.02),
                    --    rot = vec3(0.0, 0.0, -1.5)
                    --},
                }) then 
                    spawnGarbageBag()
                    
                    -- Give the item
                    TriggerServerEvent('garbageCollectorJob:server:giveGarbageBag')
                    
                    changeBlipColor(self.index)
                end
            end
        end

        garbagePoints[point.index] = point
    end
end

local function removeGarbagesPoints()
    for _, point in ipairs(garbagePoints) do
        RemoveBlip(point.blip)
        point:remove()
    end
    garbagePoints = {}
end

exports('useGarbageBag', function (data)
    if CurrentGarbageProp and DoesEntityExist(CurrentGarbageProp) then
        removeGarbageBag()
    else
        spawnGarbageBag()
    end
end)

function SavePlayerClothes()
    local skinData = Config.Clothes.GetPedAppearance(PlayerPedId())
    PlayerSavedSkin = skinData
end

function WearJobsClothes()
    Config.Clothes.WearJobsClothes(cache.ped)
    IsWearingJobsClothes = true
end

function RemoveJobsClothes()
    if IsWearingJobsClothes and PlayerSavedSkin ~= nil then
        Config.Clothes.SetPedAppearance(PlayerSavedSkin)
        IsWearingJobsClothes = false
        PlayerSavedSkin = nil
    end
end

function ActivateJob()
    IsJobActive = true
    addGarbagesPoints()
end

function DeactivateJob()
    -- Delete the job's vehicle
    TriggerServerEvent('garbageCollectorJob:server:removeJobVeh')
    RemoveJobsClothes()
    IsJobActive = false
    removeGarbagesPoints()
    removeGarbageBag()
end

-- Check if the job is on
local function toggleJob(jobInfo)
    if jobInfo == nil then
        return
    end
    -- jobInfo (name, grade, label, ecc.)
    local currentJob = jobInfo.name
    print(currentJob)
    local currentGrade = jobInfo.grade.level

    if not IsJobActive and currentJob == "garbage" then
        ActivateJob()
    elseif IsJobActive and currentJob == "garbage" then
        local alert = lib.alertDialog({
            header = 'Resettare il lavoro attuale',
            content = 'Hai selezionato lo stesso lavoro, perderai i progressi fatti. Procedere?',
            centered = true,
            cancel = true
        })
        if alert == 'confirm' then
            DeactivateJob()
            ActivateJob()
        else
            print('Lavoro non resettato.')
        end
    elseif IsJobActive then
       DeactivateJob()
    end
    
end

RegisterNetEvent('esx:setJob', toggleJob)

RegisterNetEvent('QBCore:Client:OnJobUpdate', toggleJob)

-- Waste Disposal Point
local disposalPoint = lib.points.new({
    coords = Config.WasteDisposalPoint,
    distance = 20,
})

function disposalPoint:onEnter()
    print('entered range of point', self.id)
    
end
function disposalPoint:onExit()
    print('left range of point', self.id)
end
function disposalPoint:nearby()
    DrawMarker(23,
        self.coords.x, self.coords.y, self.coords.z + 0.1,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        3.0, 3.0, 3.0,
        255, 255, 20,  100,
        false, true, 2, false, nil, nil, false)
    if self.currentDistance < 3 then
        if not lib.isTextUIOpen() and self.currentDistance < 3 then
            lib.showTextUI(locale('waste_point_label'), {
                position = 'right-center',
                icon = 'trash',
                style = {
                    borderRadius = 0,
                    backgroundColor = '#222',
                    color = '#fff'
                }
            })
        end
        if IsControlJustReleased(0, 38) then
            TriggerServerEvent('garbageCollectorJob:server:giveMoney')
            if CurrentGarbageProp then
                removeGarbageBag()
            end
        end
    elseif lib.isTextUIOpen() and self.currentDistance > 3 then
        lib.hideTextUI()
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if Framework.name == "esx" then
        local pData = exports.esx_core:GetPlayerData()

        if pData and pData.job then
            toggleJob(pData.job)
        end
    elseif Framework.name == "qb" or Framework.name == "qbx" then
        local QBCore = exports['qb-core']:GetCoreObject()

        -- Ottieni tutti i dati del giocatore locale
        local pData = QBCore.Functions.GetPlayerData()

        if pData and pData.job then
            toggleJob(pData.job)
        end
    end

    -- Create ped's blip
    if Config.PedBlip then
        PedBlip = AddBlipForCoord(Config.PedPosition.x, Config.PedPosition.y, Config.PedPosition.z)
    
        SetBlipSprite(PedBlip, 318)
        SetBlipDisplay(PedBlip, 4)
        SetBlipScale(PedBlip, 1.2)
        SetBlipColour(PedBlip, 25)
        SetBlipAsShortRange(PedBlip, true)
        
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName("Test")
        EndTextCommandSetBlipName(PedBlip)
    end

end)


local CHOSEN_RADIUS = 20.0
local PROP_MODEL = `prop_ld_binbag_01` --prop_bin_01a`

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Reset the clothes
    RemoveJobsClothes()

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local handle, object = FindFirstObject()
    local success
    
    repeat
        if DoesEntityExist(object) then
            local objCoords = GetEntityCoords(object)
            local distance = #(playerCoords - objCoords)

            if distance <= CHOSEN_RADIUS then
                if GetEntityModel(object) == PROP_MODEL then
                    
                    SetEntityAsMissionEntity(object, true, true)
                    DeleteObject(object)
                    
                end
            end
        end
        
        success, object = FindNextObject(handle)
    until not success
    
    EndFindObject(handle)
    print("Pulizia dei prop completata nel raggio di " .. CHOSEN_RADIUS .. " metri.")
end)