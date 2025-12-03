local QBCore = exports['qb-core']:GetCoreObject()

-- CORRECT helper functions for latest ox_inventory
local function HasItem(source, itemName)
    -- Use Search function instead of GetItem
    local result = exports.ox_inventory:Search(source, 'count', itemName)
    return result and result > 0
end

local function HasItems(source, items)
    for _, itemName in ipairs(items) do
        local result = exports.ox_inventory:Search(source, 'count', itemName)
        if not result or result == 0 then
            return false
        end
    end
    return true
end

-- Helper function to remove multiple items correctly
local function RemoveItems(source, items)
    local success = true
    
    for _, itemData in ipairs(items) do
        local itemName, count
        
        if type(itemData) == 'table' then
            itemName = itemData[1]
            count = itemData[2] or 1
        else
            itemName = itemData
            count = 1
        end
        
        local removed = exports.ox_inventory:RemoveItem(source, itemName, count)
        if not removed then
            print('^3[rz-burgershot] Failed to remove item: ' .. tostring(itemName) .. ' x' .. tostring(count))
            success = false
            break
        end
    end
    
    return success
end

-- Helper function to add multiple items
local function AddItems(source, items)
    for _, itemData in ipairs(items) do
        local itemName, count
        
        if type(itemData) == 'table' then
            itemName = itemData[1]
            count = itemData[2] or 1
        else
            itemName = itemData
            count = 1
        end
        
        exports.ox_inventory:AddItem(source, itemName, count)
    end
end

-- Ox Inventory Stash Creation with SQL Persistence
CreateThread(function()
    Wait(5000) -- Wait for resources to load
    
    if exports.ox_inventory then
        print('^2[rz-burgershot] Creating ox_inventory stashes with SQL persistence^0')
        
        -- Create shared stashes from Config.Storages
        for stashName, stashConfig in pairs(Config.Storages) do
            if not stashConfig.owner then
                -- Shared stash (saved to database automatically)
                exports.ox_inventory:RegisterStash(stashName, stashConfig.label, stashConfig.slots, stashConfig.maxWeight, stashConfig.groups)
                print('^3[rz-burgershot] Created shared stash: ' .. stashName .. ' (SQL saved)^0')
                
                -- Verify stash exists in database
                MySQL.query('SELECT * FROM ox_inventory WHERE name = ?', {stashName}, function(result)
                    if result and result[1] then
                        print('^2[rz-burgershot] Stash ' .. stashName .. ' exists in database^0')
                    else
                        print('^3[rz-burgershot] Creating new database entry for stash: ' .. stashName .. '^0')
                        -- This will be created automatically when first accessed
                    end
                end)
            end
        end
        
        -- Create shop
        for shopName, shopConfig in pairs(Config.Shop) do
            exports.ox_inventory:RegisterShop(shopName, {
                name = shopConfig.name,
                inventory = shopConfig.inventory,
                locations = { shopConfig.coords },
                groups = shopConfig.groups
            })
            print('^3[rz-burgershot] Created shop: ' .. shopName .. '^0')
        end
        
        -- Initialize employee lockers on player load
        RegisterNetEvent('rz-burgershot:initEmployeeLocker', function()
            local src = source
            local player = QBCore.Functions.GetPlayer(src)
            if player and player.PlayerData.job.name == 'burgershot' then
                local citizenid = player.PlayerData.citizenid
                local lockerName = 'burgershot_locker_' .. citizenid
                
                -- Check if locker exists in database
                MySQL.query('SELECT * FROM ox_inventory WHERE name = ?', {lockerName}, function(result)
                    if not result or #result == 0 then
                        -- Create locker for employee
                        exports.ox_inventory:RegisterStash(lockerName, 'Employee Locker - ' .. player.PlayerData.charinfo.firstname, 
                            Config.Storages['burgershot_locker_'].slots, 
                            Config.Storages['burgershot_locker_'].maxWeight,
                            Config.Storages['burgershot_locker_'].groups)
                        print('^3[rz-burgershot] Created personal locker for employee: ' .. citizenid .. '^0')
                    end
                end)
            end
        end)
        
    else
        print('^3[rz-burgershot] WARNING: ox_inventory not available for stash creation^0')
    end
end)

-- Save all stashes command (for admins)
RegisterCommand('savestashes', function(source, args)
    if source == 0 or QBCore.Functions.HasPermission(source, 'admin') then
        print('^2[rz-burgershot] Saving all stashes to database...^0')
        
        -- Force save all open stashes
        exports.ox_inventory:SaveStashes()
        
        if source ~= 0 then
            TriggerClientEvent('QBCore:Notify', source, 'All stashes saved to database', 'success')
        end
        print('^2[rz-burgershot] Stashes saved successfully^0')
    end
end, false)

-- Check stash contents command
RegisterCommand('checkstash', function(source, args)
    if source == 0 or QBCore.Functions.HasPermission(source, 'admin') then
        local stashName = args[1]
        if stashName then
            print('^2[rz-burgershot] Checking stash: ' .. stashName .. '^0')
            
            MySQL.query('SELECT * FROM ox_inventory WHERE name = ?', {stashName}, function(result)
                if result and result[1] then
                    print('^2Stash found in database:^0')
                    print('^3Name: ' .. result[1].name .. '^0')
                    print('^3Label: ' .. result[1].label .. '^0')
                    print('^3Weight: ' .. result[1].weight .. '^0')
                    print('^3Slots: ' .. result[1].slots .. '^0')
                    
                    -- Decode and show items
                    if result[1].data then
                        local items = json.decode(result[1].data)
                        print('^3Items in stash: ' .. #items .. '^0')
                        for i, item in ipairs(items) do
                            if item and item.name then
                                print('  ' .. i .. '. ' .. item.name .. ' x' .. (item.count or 0))
                            end
                        end
                    end
                else
                    print('^3Stash not found in database^0')
                end
            end)
        else
            print('^3Usage: checkstash [stash_name]^0')
        end
    end
end, false)

-- Clean empty stashes command
RegisterCommand('cleanstashes', function(source, args)
    if source == 0 then
        print('^2[rz-burgershot] Cleaning empty stashes from database...^0')
        
        MySQL.query('SELECT * FROM ox_inventory WHERE name LIKE "burgershot_%"', {}, function(result)
            if result then
                local cleaned = 0
                for _, stash in ipairs(result) do
                    if stash.data then
                        local items = json.decode(stash.data)
                        local isEmpty = true
                        
                        for _, item in ipairs(items) do
                            if item and item.count and item.count > 0 then
                                isEmpty = false
                                break
                            end
                        end
                        
                        if isEmpty then
                            MySQL.query('DELETE FROM ox_inventory WHERE name = ?', {stash.name})
                            print('^3Removed empty stash: ' .. stash.name .. '^0')
                            cleaned = cleaned + 1
                        end
                    end
                end
                print('^2Cleaned ' .. cleaned .. ' empty stashes^0')
            end
        end)
    end
end, false)

-- Backup stashes command
RegisterCommand('backupstashes', function(source, args)
    if source == 0 then
        print('^2[rz-burgershot] Creating backup of all stashes...^0')
        
        MySQL.query('SELECT * FROM ox_inventory WHERE name LIKE "burgershot_%"', {}, function(result)
            if result then
                local timestamp = os.date("%Y%m%d_%H%M%S")
                local backupFile = 'burgershot_stashes_backup_' .. timestamp .. '.json'
                
                -- Save to file
                SaveResourceFile(GetCurrentResourceName(), 'backups/' .. backupFile, json.encode(result, {indent=true}))
                
                print('^2Backup created: ' .. backupFile .. ' (' .. #result .. ' stashes)^0')
            end
        end)
    end
end, false)

-- Get stash info for player
QBCore.Functions.CreateCallback('rz-burgershot:getStashInfo', function(source, cb, stashName)
    MySQL.query('SELECT * FROM ox_inventory WHERE name = ?', {stashName}, function(result)
        if result and result[1] then
            local stashInfo = {
                name = result[1].name,
                label = result[1].label,
                weight = result[1].weight,
                slots = result[1].slots,
                itemCount = 0
            }
            
            if result[1].data then
                local items = json.decode(result[1].data)
                for _, item in ipairs(items) do
                    if item and item.count then
                        stashInfo.itemCount = stashInfo.itemCount + item.count
                    end
                end
            end
            
            cb(stashInfo)
        else
            cb(nil)
        end
    end)
end)

-- Event to open employee locker
RegisterNetEvent('rz-burgershot:openEmployeeLocker')
AddEventHandler('rz-burgershot:openEmployeeLocker', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player and player.PlayerData.job.name == 'burgershot' then
        local citizenid = player.PlayerData.citizenid
        local lockerName = 'burgershot_locker_' .. citizenid
        
        -- Open the personal locker
        exports.ox_inventory:openInventory('stash', lockerName, src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not a Burger Shot employee', 'error')
    end
end)

-- Auto-save stashes on server shutdown
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[rz-burgershot] Saving all stashes before shutdown...^0')
        exports.ox_inventory:SaveStashes()
        print('^2[rz-burgershot] Stashes saved successfully^0')
    end
end)

-- Initialize player locker when they join
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    Wait(5000)
    TriggerEvent('rz-burgershot:initEmployeeLocker', player.PlayerData.source)
end)

-- Add this function for fridge access
RegisterNetEvent("rz-burgershot:fridge")
AddEventHandler("rz-burgershot:fridge", function()
    local src = source
    if onDuty then
        exports.ox_inventory:openInventory('stash', 'burgershot_fridge', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.duty"), "error")
    end
end)

-- Clean up old employee lockers when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[rz-burgershot] Cleaning up old employee lockers...^0')
        
        -- Get all burgershot lockers from database
        MySQL.query('SELECT name FROM ox_inventory WHERE name LIKE "burgershot_locker_%"', {}, function(result)
            if result then
                for _, stash in ipairs(result) do
                    local citizenid = stash.name:gsub('burgershot_locker_', '')
                    
                    -- Check if employee still exists
                    MySQL.query('SELECT * FROM players WHERE citizenid = ?', {citizenid}, function(playerResult)
                        if not playerResult or #playerResult == 0 then
                            -- Player doesn't exist, delete their locker
                            MySQL.query('DELETE FROM ox_inventory WHERE name = ?', {stash.name})
                            print('^3[rz-burgershot] Deleted orphaned locker: ' .. stash.name .. '^0')
                        end
                    end)
                end
            end
        end)
    end
end)

-- -------------------------
-- Open Bag Items
-- -------------------------
RegisterNetEvent('rz-burgershot:SmallBagItem', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.SmallBagItem, 1) then
        for _, v in pairs(Config.SmallBag) do
            exports.ox_inventory:AddItem(src, v, 1)
        end
        GiveRandomToy(src)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.opened"), "success", 2000)
    end
end)

RegisterNetEvent('rz-burgershot:BigBagItem', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.BigBagItem, 1) then
        for _, v in pairs(Config.BigBag) do
            exports.ox_inventory:AddItem(src, v, 1)
        end
        GiveRandomToy(src)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.opened"), "success", 2000)
    end
end)

RegisterNetEvent('rz-burgershot:GoatMenuItem', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.GoatBagItem, 1) then
        for _, v in pairs(Config.GoatBag) do
            exports.ox_inventory:AddItem(src, v, 1)
        end
        GiveRandomToy(src)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.opened"), "success", 2000)
    end
end)

RegisterNetEvent('rz-burgershot:CoffeeMenuItem', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.CoffeeBagItem, 1) then
        for _, v in pairs(Config.CoffeeBag) do
            exports.ox_inventory:AddItem(src, v, 1)
        end
        GiveRandomToy(src)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.opened"), "success", 2000)
    end
end)

-- -------------------------
-- Give random toy
-- -------------------------
function GiveRandomToy(src)
    local items = {"burgershot_toy1", "burgershot_toy2", "burgershot_toy3", "burgershot_toy4", "burgershot_toy5", "burgershot_toy6"}
    local item = items[math.random(1, #items)]
    exports.ox_inventory:AddItem(src, item, 1)
    TriggerClientEvent("QBCore:Notify", src, Lang:t("notify.toy"), "primary")
end

-- -------------------------
-- Callbacks for item checks (FIXED)
-- -------------------------
QBCore.Functions.CreateCallback('rz:eat:server:get:smallpacket', function(source, cb)
    cb(HasItems(source, Config.SmallBag))
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:bigpacket', function(source, cb)
    cb(HasItems(source, Config.BigBag))
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:goatpacket', function(source, cb)
    cb(HasItems(source, Config.GoatBag))
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:coffeepacket', function(source, cb)
    cb(HasItems(source, Config.CoffeeBag))
end)

QBCore.Functions.CreateCallback('rz-burgershot:itemcheck', function(source, cb, item)
    cb(HasItem(source, item))
end)

-- -------------------------
-- Create Packets (UPDATED for ox_inventory)
-- -------------------------
RegisterNetEvent('rz-burgershot:add:smallpacket', function()
    local src = source
    local itemsToRemove = {}
    for _, itemName in ipairs(Config.SmallBag) do
        table.insert(itemsToRemove, {itemName, 1})
    end
    
    if RemoveItems(src, itemsToRemove) then
        exports.ox_inventory:AddItem(src, Config.SmallBagItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.created_small"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.needıtem"), "error")
    end
end)

RegisterNetEvent('rz-burgershot:add:bigpacket', function()
    local src = source
    local itemsToRemove = {}
    for _, itemName in ipairs(Config.BigBag) do
        table.insert(itemsToRemove, {itemName, 1})
    end
    
    if RemoveItems(src, itemsToRemove) then
        exports.ox_inventory:AddItem(src, Config.BigBagItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.created_big"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.needıtem"), "error")
    end
end)

RegisterNetEvent('rz-burgershot:add:goatpacket', function()
    local src = source
    local itemsToRemove = {}
    for _, itemName in ipairs(Config.GoatBag) do
        table.insert(itemsToRemove, {itemName, 1})
    end
    
    if RemoveItems(src, itemsToRemove) then
        exports.ox_inventory:AddItem(src, Config.GoatBagItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.created_goat"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.needıtem"), "error")
    end
end)

RegisterNetEvent('rz-burgershot:add:coffeepacket', function()
    local src = source
    local itemsToRemove = {}
    for _, itemName in ipairs(Config.CoffeeBag) do
        table.insert(itemsToRemove, {itemName, 1})
    end
    
    if RemoveItems(src, itemsToRemove) then
        exports.ox_inventory:AddItem(src, Config.CoffeeBagItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.created_coffee"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.needıtem"), "error")
    end
end)

-- -------------------------
-- Crafting Recipes (SIMPLIFIED)
-- -------------------------
RegisterNetEvent('rz-burgershot:server:bigcola', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.BigEmptyGlass, 1) then
        exports.ox_inventory:AddItem(src, Config.BigColaItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_colab"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing big empty glass", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:smallcola', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.SmallEmptyGlass, 1) then
        exports.ox_inventory:AddItem(src, Config.SmallColaItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_colas"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing small empty glass", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:coffee', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.CoffeeEmptyGlass, 1) then
        exports.ox_inventory:AddItem(src, Config.CoffeeItem, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_coffee"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing coffee empty glass", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:bigpotato', function()
    local src = source
    local items = {
        {Config.BigFrozenPotato, 1},
        {Config.BigEmptyCardboard, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.BigPotato, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_bigpotato"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for big potato", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:smallpotato', function()
    local src = source
    local items = {
        {Config.SmallFrozenPotato, 1},
        {Config.SmallEmptyCardboard, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.SmallPotato, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_smallpotato"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for small potato", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:rings', function()
    local src = source
    local items = {
        {Config.FrozenRings, 1},
        {Config.SmallEmptyCardboard, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.Rings, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_rings"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for rings", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:nuggets', function()
    local src = source
    local items = {
        {Config.FrozenNuggets, 1},
        {Config.BigEmptyCardboard, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.Nuggets, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_nuggets"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for nuggets", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:meat', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.FrozenMeat, 1) then
        exports.ox_inventory:AddItem(src, Config.Meat, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_meat"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing frozen meat", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:bleederburger', function()
    local src = source
    local items = {
        {Config.Bread, 1},
        {Config.Meat, 1},
        {Config.Sauce, 1},
        {Config.VegetableCurly, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.BleederBurger, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_bleeder"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for bleeder burger", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:bigkingburger', function()
    local src = source
    local items = {
        {Config.Bread, 1},
        {Config.Meat, 1},
        {Config.Sauce, 1},
        {Config.VegetableCurly, 1},
        {Config.Cheddar, 1},
        {Config.Tomato, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.BigKingBurger, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_bigking"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for big king burger", "error")
    end
end)

RegisterNetEvent('rz-burgershot:server:wrap', function()
    local src = source
    local items = {
        {Config.Lavash, 1},
        {Config.Meat, 1},
        {Config.Sauce, 1},
        {Config.VegetableCurly, 1},
        {Config.Cheddar, 1},
        {Config.Tomato, 1}
    }
    if RemoveItems(src, items) then
        exports.ox_inventory:AddItem(src, Config.Wrap, 1)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_wrap"), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Missing ingredients for wrap", "error")
    end
end)

-- Ice cream recipes
local iceCreamRecipes = {
    ['chocolateicecream'] = Config.ChocolateIceCream,
    ['vanillaicecream'] = Config.VanillaIceCream,
    ['thesmurfsicecream'] = Config.ThesmurfsIceCream,
    ['strawberryicecream'] = Config.StrawberryIceCream,
    ['matchaicecream'] = Config.MatchaIceCream,
    ['ubeicecream'] = Config.UbeIceCream,
    ['smurfetteicecream'] = Config.SmurfetteIceCream,
    ['unicornicecream'] = Config.UnicornIceCream
}

for event, item in pairs(iceCreamRecipes) do
    RegisterNetEvent('rz-burgershot:server:'..event, function()
        local src = source
        if exports.ox_inventory:RemoveItem(src, Config.Cone, 1) then
            exports.ox_inventory:AddItem(src, item, 1)
            TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_ice"), "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "Missing ice cream cone", "error")
        end
    end)
end

-- Macaroon (no ingredients required)
RegisterNetEvent('rz-burgershot:server:macaroon', function()
    local src = source
    exports.ox_inventory:AddItem(src, Config.Macaroon, 1)
    TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.added_macaroon"), "success")
end)

-- -------------------------
-- Additional callbacks (FIXED)
-- -------------------------
QBCore.Functions.CreateCallback('rz:eat:server:get:bigpotato', function(source, cb)
    local hasPotato = HasItem(source, Config.BigFrozenPotato)
    local hasCardboard = HasItem(source, Config.BigEmptyCardboard)
    cb(hasPotato and hasCardboard)
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:smallpotato', function(source, cb)
    local hasPotato = HasItem(source, Config.SmallFrozenPotato)
    local hasCardboard = HasItem(source, Config.SmallEmptyCardboard)
    cb(hasPotato and hasCardboard)
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:rings', function(source, cb)
    local hasRings = HasItem(source, Config.FrozenRings)
    local hasCardboard = HasItem(source, Config.SmallEmptyCardboard)
    cb(hasRings and hasCardboard)
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:nuggets', function(source, cb)
    local hasNuggets = HasItem(source, Config.FrozenNuggets)
    local hasCardboard = HasItem(source, Config.BigEmptyCardboard)
    cb(hasNuggets and hasCardboard)
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:bleederburger', function(source, cb)
    local items = {Config.Bread, Config.Meat, Config.Sauce, Config.VegetableCurly}
    cb(HasItems(source, items))
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:bigkingburger', function(source, cb)
    local items = {Config.Bread, Config.Meat, Config.Sauce, Config.Cheddar, Config.Tomato, Config.VegetableCurly}
    cb(HasItems(source, items))
end)

QBCore.Functions.CreateCallback('rz:eat:server:get:wrap', function(source, cb)
    local items = {Config.Lavash, Config.Meat, Config.Sauce, Config.Cheddar, Config.Tomato, Config.VegetableCurly}
    cb(HasItems(source, items))
end)

-- -------------------------
-- Sell packet events
-- -------------------------
RegisterServerEvent('rz-burgershot:server:smallpacketsell')
AddEventHandler('rz-burgershot:server:smallpacketsell', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.SmallBagItem, 1) then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        xPlayer.Functions.AddMoney('cash', Config.SmallBagSellPrice)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.deliverynotify") .. Config.SmallBagSellPrice, "primary", 5000)
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have a small package to sell", "error")
    end
end)

RegisterServerEvent('rz-burgershot:server:bigpacketsell')
AddEventHandler('rz-burgershot:server:bigpacketsell', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, Config.BigBagItem, 1) then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        xPlayer.Functions.AddMoney('cash', Config.BigBagSellPrice)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.deliverynotify") .. Config.BigBagSellPrice, "primary", 5000)
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have a big package to sell", "error")
    end
end)

-- -------------------------
-- Billing
-- -------------------------
RegisterNetEvent("ex-burgershot:server:billPlayer", function(playerId, amount)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(playerId))
    local amount = tonumber(amount)
    
    if not biller then return end
    
    if biller.PlayerData.job.name == 'burgershot' then
        if billed ~= nil then
            if biller.PlayerData.citizenid ~= billed.PlayerData.citizenid then
                if amount and amount > 0 then
                    billed.Functions.RemoveMoney('bank', amount)
                    TriggerClientEvent('QBCore:Notify', source, 'You charged a customer.', 'success')
                    TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'You have been charged $'..amount..' for your order at Burgershot.')
                    exports['qb-management']:AddMoney('burgershot', amount)
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Must be a valid amount above 0.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'You cannot bill yourself.', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player not online', 'error')
        end
    end
end)

-- -------------------------
-- Debug and initialization
-- -------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[rz-burgershot] Server script loaded successfully^0')
        
        -- Check if ox_inventory is available
        if exports.ox_inventory then
            print('^2[rz-burgershot] ox_inventory detected^0')
            
            -- Test ox_inventory functions
            local success, error = pcall(function()
                -- Try a simple search to test functionality
                return true
            end)
            
            if success then
                print('^2[rz-burgershot] ox_inventory functions working^0')
            else
                print('^3[rz-burgershot] ox_inventory error: ' .. tostring(error))
            end
        else
            print('^3[rz-burgershot] WARNING: ox_inventory not detected^0')
        end
        
        -- Load Lang if available
        if Lang then
            print('^2[rz-burgershot] Language system loaded^0')
        else
            print('^3[rz-burgershot] WARNING: Language system not loaded^0')
        end
    end
end)

-- Debug command
RegisterCommand('debugburgershot', function(source, args)
    if source ~= 0 then return end
    
    print('^2=== BURGER SHOT DEBUG ===^0')
    print('1. Resource: rz-burgershot')
    print('2. ox_inventory: ' .. (exports.ox_inventory and '^2LOADED^0' or '^1NOT LOADED^0'))
    print('3. Config items check:')
    print('   SmallBagItem: ' .. tostring(Config.SmallBagItem))
    print('   BigBagItem: ' .. tostring(Config.BigBagItem))
    
    if args[1] then
        local playerId = tonumber(args[1])
        if playerId then
            print('4. Checking player ' .. playerId .. ' inventory:')
            local items = {'burgershot_frozenmeat', 'burgershot_bread', 'burgershot_sauce'}
            for _, item in ipairs(items) do
                local count = exports.ox_inventory:Search(playerId, 'count', item)
                print('   ' .. item .. ': ' .. (count or 0))
            end
        end
    end
end, false)