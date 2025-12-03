local QBCore = exports['qb-core']:GetCoreObject()
local onDuty = false
local clean = false
local client = false
local status = false
local smallblip = false
local bigblip = false
local bliptable = {}
local delivery = 0
local PlayerPed = nil

-- Function to check if player has item (for client-side checks)
local function HasItem(item)
    local itemData = exports.ox_inventory:Search('count', item)
    return itemData and itemData > 0
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerPed = PlayerPedId()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        if PlayerData.job.onduty then
            if PlayerData.job.name == Config.Job then
                TriggerServerEvent("QBCore:ToggleDuty")
            end
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = PlayerJob.onduty
end)

RegisterNetEvent('QBCore:Client:SetDuty')
AddEventHandler('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)

-- Tray access functions
RegisterNetEvent("rz-burgershot:tray")
AddEventHandler("rz-burgershot:tray", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray1')
end)

RegisterNetEvent("rz-burgershot:tray2")
AddEventHandler("rz-burgershot:tray2", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray2')
end)

RegisterNetEvent("rz-burgershot:tray3")
AddEventHandler("rz-burgershot:tray3", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray3')
end)

RegisterNetEvent("rz-burgershot:tray4")
AddEventHandler("rz-burgershot:tray4", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray4')
end)

-- Storage access function
RegisterNetEvent("rz-burgershot:storge")
AddEventHandler("rz-burgershot:storge", function()
    if onDuty then
        exports.ox_inventory:openInventory('stash', 'burgershot_storage')
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

-- Fridge access function
RegisterNetEvent("rz-burgershot:fridge")
AddEventHandler("rz-burgershot:fridge", function()
    if onDuty then
        exports.ox_inventory:openInventory('stash', 'burgershot_fridge')
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

-- Update the shop event to use ox_inventory
RegisterNetEvent("rz:burgershot:shop", function()
    if onDuty then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData.job and PlayerData.job.name == Config.Job then 
            -- Open shop using ox_inventory shop system
            exports.ox_inventory:openInventory('shop', 'burgershot_shop')
        end
    else 
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end  
end)

RegisterNetEvent('rz-burgershot:CraftSmallBagItem', function()
    TriggerServerEvent('rz-burgershot:SmallBagItem')
end)

RegisterNetEvent('rz-burgershot:CraftBigBagItem', function()
    TriggerServerEvent('rz-burgershot:BigBagItem')
end)

RegisterNetEvent('rz-burgershot:CraftGoatMenuItem', function()
    TriggerServerEvent('rz-burgershot:GoatMenuItem')
end)

RegisterNetEvent('rz-burgershot:CraftCoffeeMenuItem', function()
    TriggerServerEvent('rz-burgershot:CoffeeMenuItem')
end)

RegisterNetEvent("rz-burgershot:duty")
AddEventHandler("rz-burgershot:duty", function()
    TriggerServerEvent("QBCore:ToggleDuty")
end)

RegisterNetEvent("rz-burgershot:tray")
AddEventHandler("rz-burgershot:tray", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray1')
end)

RegisterNetEvent("rz-burgershot:tray2")
AddEventHandler("rz-burgershot:tray2", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray2')
end)

RegisterNetEvent("rz-burgershot:tray3")
AddEventHandler("rz-burgershot:tray3", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray3')
end)

RegisterNetEvent("rz-burgershot:tray4")
AddEventHandler("rz-burgershot:tray4", function()
    exports.ox_inventory:openInventory('stash', 'burgershot_tray4')
end)

RegisterNetEvent("rz-burgershot:storge")
AddEventHandler("rz-burgershot:storge", function()
    if onDuty then
        exports.ox_inventory:openInventory('stash', 'burgershot_storage')
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:smallpacket")
AddEventHandler("rz-burgershot:smallpacket", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:smallpacket', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("pickup_sla", Lang:t("label.small"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:add:smallpacket')
                            Dirt()
                            client = true
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:bigpacket")
AddEventHandler("rz-burgershot:bigpacket", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:bigpacket', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("pickup_big", Lang:t("label.big"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:add:bigpacket')
                            Dirt()
                            client = true
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:goatpacket")
AddEventHandler("rz-burgershot:goatpacket", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:goatpacket', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("pickup_goat", Lang:t("label.goat"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:add:goatpacket')
                            Dirt()
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:coffeepacket")
AddEventHandler("rz-burgershot:coffeepacket", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:coffeepacket', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("pickup_coffee", Lang:t("label.coffee"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:add:coffeepacket')
                            Dirt()
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:bigcola")
AddEventHandler("rz-burgershot:client:bigcola", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("bigcola", Lang:t("label.bigcola"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:bigcola')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.BigEmptyGlass)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:smallcola")
AddEventHandler("rz-burgershot:client:smallcola", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("smallcola", Lang:t("label.smallcola"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:smallcola')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.SmallEmptyGlass)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:coffee")
AddEventHandler("rz-burgershot:client:coffee", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("coffee2", Lang:t("label.coffee2"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:coffee')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.CoffeeEmptyGlass)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:bigpotato")
AddEventHandler("rz-burgershot:client:bigpotato", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:bigpotato', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("bigpotato", Lang:t("label.bigpotato"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {
                        model = "prop_cs_fork",
                        bone = 28422,
                        coords = vector3(-0.005, 0.00, 0.00),
                        rotation = vector3(175.0, 160.0, 0.0),
                    }, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:bigpotato')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:smallpotato")
AddEventHandler("rz-burgershot:client:smallpotato", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:smallpotato', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("smallpotato", Lang:t("label.smallpotato"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {
                        model = "prop_cs_fork",
                        bone = 28422,
                        coords = vector3(-0.005, 0.00, 0.00),
                        rotation = vector3(175.0, 160.0, 0.0),
                    }, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:smallpotato')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:rings")
AddEventHandler("rz-burgershot:client:rings", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:rings', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("rings", Lang:t("label.rings"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {
                        model = "prop_cs_fork",
                        bone = 28422,
                        coords = vector3(-0.005, 0.00, 0.00),
                        rotation = vector3(175.0, 160.0, 0.0),
                    }, {}, function() -- Done
                        TriggerServerEvent('rz-burgershot:server:rings')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:nuggets")
AddEventHandler("rz-burgershot:client:nuggets", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:nuggets', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("nuggets", Lang:t("label.nuggets"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {
                        model = "prop_cs_fork",
                        bone = 28422,
                        coords = vector3(-0.005, 0.00, 0.00),
                        rotation = vector3(175.0, 160.0, 0.0),
                    }, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:nuggets')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:meat")
AddEventHandler("rz-burgershot:client:meat", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("meat", Lang:t("label.meat"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {
                        model = "prop_cs_fork",
                        bone = 28422,
                        coords = vector3(-0.005, 0.00, 0.00),
                        rotation = vector3(175.0, 160.0, 0.0),
                    }, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:meat')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.FrozenMeat)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:bleederburger")
AddEventHandler("rz-burgershot:client:bleederburger", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:bleederburger', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("bleederburger", Lang:t("label.bleederburger"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:bleederburger')
                            Dirt()
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:bigkingburger")
AddEventHandler("rz-burgershot:client:bigkingburger", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:bigkingburger', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("bigkingburger", Lang:t("label.bigkingburger"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:bigkingburger')
                            Dirt()
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:wrap")
AddEventHandler("rz-burgershot:client:wrap", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz:eat:server:get:wrap', function(HasItems)  
                if HasItems then
                    QBCore.Functions.Progressbar("wrap", Lang:t("label.wrap"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_player",
                        flags = 49,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:wrap')
                            Dirt()
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:macaroon")
AddEventHandler("rz-burgershot:client:macaroon", function()
    if onDuty then
        if clean then 
            QBCore.Functions.Progressbar("macaroon", Lang:t("label.macaroon"), Config.ProgressbarTime, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "mp_common",
                anim = "givetake1_a",
                flags = 8,
            }, {}, {}, function() -- Done
                    TriggerServerEvent('rz-burgershot:server:macaroon')
                    Dirt()
                QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
            end, function()
                QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:chocolateicecream")
AddEventHandler("rz-burgershot:client:chocolateicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("chocolateicecream", Lang:t("label.chocolateicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:chocolateicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:vanillaicecream")
AddEventHandler("rz-burgershot:client:vanillaicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("vanillaicecream", Lang:t("label.vanillaicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:vanillaicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:thesmurfsicecream")
AddEventHandler("rz-burgershot:client:thesmurfsicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("thesmurfsicecream", Lang:t("label.thesmurfsicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:thesmurfsicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:strawberryicecream")
AddEventHandler("rz-burgershot:client:strawberryicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("strawberryicecream", Lang:t("label.strawberryicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:strawberryicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:matchaicecream")
AddEventHandler("rz-burgershot:client:matchaicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("matchaicecream", Lang:t("label.matchaicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:matchaicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:ubeicecream")
AddEventHandler("rz-burgershot:client:ubeicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("ubeicecream", Lang:t("label.ubeicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:ubeicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:smurfetteicecream")
AddEventHandler("rz-burgershot:client:smurfetteicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("smurfetteicecream", Lang:t("label.smurfetteicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:smurfetteicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:unicornicecream")
AddEventHandler("rz-burgershot:client:unicornicecream", function()
    if onDuty then
        if clean then 
            QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
                if data then
                    QBCore.Functions.Progressbar("unicornicecream", Lang:t("label.unicornicecream"), Config.ProgressbarTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@prop_human_bbq@male@base",
                        anim = "base",
                        flags = 8,
                    }, {}, {}, function() -- Done
                            TriggerServerEvent('rz-burgershot:server:unicornicecream')
                        QBCore.Functions.Notify(Lang:t("notify.createpacket"), "success")
                    end, function()
                        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
                end
            end, Config.Cone) 
        else
            QBCore.Functions.Notify(Lang:t("notify.clean"), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:clean")
AddEventHandler("rz-burgershot:client:clean", function()
    QBCore.Functions.Progressbar("clean", Lang:t("label.clean"), Config.ProgressbarTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "amb@world_human_bum_standing@twitchy@idle_a",
        anim = "idle_a",
        flags = 49,
    }, {}, {}, function() -- Done
            clean = true
        QBCore.Functions.Notify(Lang:t("notify.dirt2"), "success")
    end, function()
        QBCore.Functions.Notify(Lang:t("notify.cancel"), "error")
    end)
end)

function Dirt()
	if math.random(1,100) < Config.Dirt then
		clean = false
        QBCore.Functions.Notify(Lang:t("notify.dirt"), "error")
	end
end

RegisterNetEvent("rz-burgershot:client:smallpacketsell")
AddEventHandler("rz-burgershot:client:smallpacketsell", function()
    if onDuty then
        smallblip = true
        random = math.random(1,#Config.SmallCoords)
        QBCore.Functions.Notify(Lang:t("notify.neworder"), "primary")
        SetNewWaypoint(Config.SmallCoords[random]["x"],Config.SmallCoords[random]["y"])
        status = true
        while status do
            local ped = PlayerPedId()
            local plycoords = GetEntityCoords(ped)
            local distance = #(plycoords - vector3(Config.SmallCoords[random]["x"],Config.SmallCoords[random]["y"],Config.SmallCoords[random]["z"])) 
            Citizen.Wait(1)
            if distance < 1.0 and client  then
                QBCore.Functions.DrawText3D(Config.SmallCoords[random]["x"],Config.SmallCoords[random]["y"],Config.SmallCoords[random]["z"], Lang:t("label.deliver"))
                if IsControlJustPressed(1, 38) then
                    SmallPacketSell()
                end
            end	
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:startdeliverysmall")
AddEventHandler("rz-burgershot:client:startdeliverysmall", function()
    if delivery == 0 then
        TriggerEvent("rz-burgershot:client:smallpacketsell")
        QBCore.Functions.SpawnVehicle(Config.Car, function(vehicle)
            SetEntityCoords(PlayerPed, Config.CarSpawnCoord.x, Config.CarSpawnCoord.y, Config.CarSpawnCoord.z-1.0)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
            SetVehicleLivery(vehicle, 14)
            SetVehicleColours(vehicle, 30, 30, 30)
            delivery = 1
        end, Config.CarSpawnCoord, true)
    else
        QBCore.Functions.Notify(Lang:t("notify.ondelivery"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:startdeliverybig")
AddEventHandler("rz-burgershot:client:startdeliverybig", function()
    if delivery == 0 then
        TriggerEvent("rz-burgershot:client:bigpacketsell")
        QBCore.Functions.SpawnVehicle(Config.Car, function(vehicle)
            SetEntityCoords(PlayerPed, Config.CarSpawnCoord.x, Config.CarSpawnCoord.y, Config.CarSpawnCoord.z-1.0)
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
            SetVehicleLivery(vehicle, 15)
            SetVehicleColours(vehicle, 62, 62, 62)
            delivery = 1
        end, Config.CarSpawnCoord, true)
    else
        QBCore.Functions.Notify(Lang:t("notify.ondelivery"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:bigpacketsell")
AddEventHandler("rz-burgershot:client:bigpacketsell", function()
    if onDuty then
        random = math.random(1,#Config.BigCoords)
        QBCore.Functions.Notify(Lang:t("notify.neworder"), "primary")
        SetNewWaypoint(Config.BigCoords[random]["x"],Config.BigCoords[random]["y"])
        bigblip = true
        status = true
        while status do
            local ped = PlayerPedId()
            local plycoords = GetEntityCoords(ped)
            local distance = #(plycoords - vector3(Config.BigCoords[random]["x"],Config.BigCoords[random]["y"],Config.BigCoords[random]["z"])) 
            Citizen.Wait(1)
            if distance < 1.0 and client then
                QBCore.Functions.DrawText3D(Config.BigCoords[random]["x"],Config.BigCoords[random]["y"],Config.BigCoords[random]["z"], Lang:t("label.deliver"))
                if IsControlJustPressed(1, 38) then
                    BigPacketSell()
                end
            end	
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.duty"), "error")
    end
end)

RegisterNetEvent("rz-burgershot:client:sellingfinish")
AddEventHandler("rz-burgershot:client:sellingfinish", function()
    if IsPedInAnyVehicle(PlayerPedId()) then
        if delivery == 1 then
            local car = GetVehiclePedIsIn(PlayerPedId(),true)
            NetworkFadeOutEntity(car, true,false)
            QBCore.Functions.DeleteVehicle(car)
            client = false
            status = false
            delivery = 0
            QBCore.Functions.Notify(Lang:t("notify.finish"), "primary")
        else
            QBCore.Functions.Notify(Lang:t("notify.notselling"), "primary")
        end
    else
        QBCore.Functions.Notify(Lang:t("notify.notfinish"), "primary")
    end
end)

function SmallPacketSell()
    local ped = PlayerPedId()
    QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
        if data then
            QBCore.Functions.Progressbar("smallpacksell", Lang:t("label.packetsell"), Config.ProgressbarTime, false, true, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
                }, {
                animDict = "timetable@jimmy@doorknock@",
                anim = "knockdoor_idle",
                flags = 49,
            }, {}, {}, function() -- Done
                TriggerServerEvent("rz-burgershot:server:smallpacketsell")
                TriggerEvent("rz-burgershot:client:smallpacketsell")
                map = true
                ClearPedTasksImmediately(ped)
            end, function() -- Cancel
                -- Cancel
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
            client = false
        end
    end, Config.SmallBagItem) 
end

function BigPacketSell()
    local ped = PlayerPedId()
    QBCore.Functions.TriggerCallback('rz-burgershot:itemcheck', function(data)
        if data then
            QBCore.Functions.Progressbar("bigpacketsell", Lang:t("label.packetsell"), Config.ProgressbarTime, false, true, { 
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
                }, {
                animDict = "timetable@jimmy@doorknock@",
                anim = "knockdoor_idle",
                flags = 49,
            }, {}, {}, function() -- Done
                TriggerServerEvent("rz-burgershot:server:bigpacketsell")
                TriggerEvent("rz-burgershot:client:bigpacketsell")
                map = true
                ClearPedTasksImmediately(ped)
            end, function() -- Cancel
                -- Cancel
            end)
        else
            QBCore.Functions.Notify(Lang:t("notify.needitem"), "error")
            client = false
        end
    end, Config.BigBagItem) 
end

-- Function to check stash contents (client-side)
function CheckStashContents(stashName)
    QBCore.Functions.TriggerCallback('rz-burgershot:getStashInfo', function(stashInfo)
        if stashInfo then
            QBCore.Functions.Notify('Stash: ' .. stashInfo.label .. ' | Items: ' .. stashInfo.itemCount .. ' | Weight: ' .. stashInfo.weight .. '/' .. stashInfo.slots, 'primary', 5000)
        else
            QBCore.Functions.Notify('Stash not found', 'error')
        end
    end, stashName)
end

-- Open employee locker
RegisterNetEvent('rz-burgershot:openEmployeeLocker')
AddEventHandler('rz-burgershot:openEmployeeLocker', function()
    TriggerServerEvent('rz-burgershot:openEmployeeLocker')
end)

-- Debug command to check stash (client-side)
RegisterCommand('checkmystash', function()
    if onDuty then
        CheckStashContents('burgershot_storage')
    else
        QBCore.Functions.Notify('You must be on duty', 'error')
    end
end)

-- Add target for employee lockers (add to your target setup)
exports['qb-target']:AddBoxZone('employee_locker', vector3(-1195.0, -901.5, 13.89), 1.0, 0.5, {
    name = 'employee_locker', debugPoly = false, heading=75, useZ=true}, {
    options = {
        {
            label = 'Employee Locker',
            icon = 'fa-solid fa-locker',
            job = Config.Job,
            action = function() 
                TriggerEvent('rz-burgershot:openEmployeeLocker')
            end
        },
        {
            label = 'Check Storage',
            icon = 'fa-solid fa-box-open',
            job = Config.Job,
            action = function()
                CheckStashContents('burgershot_storage')
            end
        }
    },
    distance = 1.5
})


-- Billing system - Using lib input dialog
RegisterNetEvent("ex-burgershot:bill", function()
    local input = lib.inputDialog('Cash Register', {
        {type = 'input', label = 'Server ID (#)', description = 'Enter the player server ID', required = true, min = 1, max = 10},
        {type = 'number', label = 'Bill Price ($)', description = 'Enter the amount to charge', icon = 'dollar-sign', required = true, min = 1}
    })
    
    if input then
        local citizenid = input[1]
        local billprice = input[2]
        if citizenid and billprice then
            TriggerServerEvent("ex-burgershot:server:billPlayer", citizenid, billprice)
        end
    end
end)

-- Blip
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(vector3(-1183.37, -884.14, 13.86))
    SetBlipSprite(blip, 106)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Burger Shot")
    EndTextCommandSetBlipName(blip)
end)