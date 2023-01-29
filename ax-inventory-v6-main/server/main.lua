QBCore = nil
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

Drops = {}
Trunks = {}
Gloveboxes = {}
Stashes = {}
ShopItems = {}

RegisterServerEvent("inventory:server:LoadDrops")
AddEventHandler('inventory:server:LoadDrops', function()
	local src = source
	if next(Drops) ~= nil then
		TriggerClientEvent("inventory:client:AddDropItem", -1, dropId, source)
		TriggerClientEvent("inventory:client:AddDropItem", src, Drops)
	end
end)

RegisterServerEvent("inventory:server:addTrunkItems")
AddEventHandler('inventory:server:addTrunkItems', function(plate, items)
	Trunks[plate] = {}
	Trunks[plate].items = items
end)

RegisterServerEvent("inventory:server:combineItem")
AddEventHandler('inventory:server:combineItem', function(item, fromItem, toItem)
	local src = source
	local ply = QBCore.Functions.GetPlayer(src)
	if ply.Functions.GetItemByName(fromItem) ~= nil and ply.Functions.GetItemByName(toItem) ~= nil then
		ply.Functions.AddItem(item, 1)
		ply.Functions.RemoveItem(fromItem, 1)
		ply.Functions.RemoveItem(toItem, 1)
	else
		DropPlayer(src, "You Have Been Auto Kicked For Exploting Glitches")
	end
end)

RegisterServerEvent("inventory:server:CraftItems")
AddEventHandler('inventory:server:CraftItems', function(itemName, itemCosts, amount, toSlot, points)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local amount = tonumber(amount)
	if itemName ~= nil and itemCosts ~= nil then
		for k, v in pairs(itemCosts) do
			Player.Functions.RemoveItem(k, (v*amount))
		end
		Player.Functions.AddItem(itemName, amount, toSlot)
		Player.Functions.SetMetaData("craftingrep", Player.PlayerData.metadata["craftingrep"]+(points*amount))
		TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, false)
	end
end)

RegisterServerEvent('inventory:server:CraftAttachment')
AddEventHandler('inventory:server:CraftAttachment', function(itemName, itemCosts, amount, toSlot, points)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local amount = tonumber(amount)
	if itemName ~= nil and itemCosts ~= nil then
		for k, v in pairs(itemCosts) do
			Player.Functions.RemoveItem(k, (v*amount))
		end
		Player.Functions.AddItem(itemName, amount, toSlot)
		Player.Functions.SetMetaData("attachmentcraftingrep", Player.PlayerData.metadata["attachmentcraftingrep"]+(points*amount))
		TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, false)
	end
end)

RegisterServerEvent("inventory:server:SetIsOpenState")
AddEventHandler('inventory:server:SetIsOpenState', function(IsOpen, type, id)
	if not IsOpen then
		if type == "stash" then
			Stashes[id].isOpen = false
		elseif type == "trunk" then
			Trunks[id].isOpen = false
		elseif type == "glovebox" then
			Gloveboxes[id].isOpen = false
		end
	end
end)
RegisterServerEvent("inventory:server:GiveItem")
AddEventHandler('inventory:server:GiveItem', function(name, inventory, item, amount)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local OtherPlayer = QBCore.Functions.GetPlayer(tonumber(name))
	local Target = OtherPlayer.PlayerData.charinfo.firstname..' '..OtherPlayer.PlayerData.charinfo.lastname
	local YourName = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
	if amount ~= 0 then
		if Player.Functions.RemoveItem(item.name, amount,false, item.info) and OtherPlayer.Functions.AddItem(item.name, amount,false, item.info) then
			TriggerClientEvent('QBCore:Notify', src, "You Sent "..item.label..' To '..Target)
			TriggerClientEvent('inventory:client:ItemBox',src, QBCore.Shared.Items[item.name], "remove")
			TriggerClientEvent('QBCore:Notify', name, "You Received "..item.label..' From '..YourName)
			TriggerClientEvent('inventory:client:ItemBox',name, QBCore.Shared.Items[item.name], "add")
		end
	end
end)
RegisterServerEvent("inventory:server:OpenInventory")
AddEventHandler('inventory:server:OpenInventory', function(name, id, other)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local PlayerAmmo = {}
	QBCore.Functions.ExecuteSql(false, "SELECT * FROM `playerammo` WHERE `citizenid` = '"..Player.PlayerData.citizenid.."'", function(ammo)
		if ammo[1] ~= nil then
			PlayerAmmo = json.decode(ammo[1].ammo)
		end

		if name ~= nil and id ~= nil then
			local secondInv = {}
			if name == "stash" then
				if Stashes[id] ~= nil then
					if Stashes[id].isOpen then
						local Target = QBCore.Functions.GetPlayer(Stashes[id].isOpen)
						if Target ~= nil then
							TriggerClientEvent('inventory:client:CheckOpenState', Stashes[id].isOpen, name, id, Stashes[id].label)
						else
							Stashes[id].isOpen = false
						end
					end
				end
				local maxweight = 1000000
				local slots = 50
				if other ~= nil then 
					maxweight = other.maxweight ~= nil and other.maxweight or 1000000
					slots = other.slots ~= nil and other.slots or 50
				end
				secondInv.name = "stash-"..id
				secondInv.label = "Stash-"..id
				secondInv.maxweight = maxweight
				secondInv.inventory = {}
				secondInv.slots = slots
				if Stashes[id] ~= nil and Stashes[id].isOpen then
					secondInv.name = "none-inv"
					secondInv.label = "Stash-None"
					secondInv.maxweight = 1000000
					secondInv.inventory = {}
					secondInv.slots = 0
				else
					local stashItems = GetStashItems(id)
					if next(stashItems) ~= nil then
						secondInv.inventory = stashItems
						Stashes[id] = {}
						Stashes[id].items = stashItems
						Stashes[id].isOpen = src
						Stashes[id].label = secondInv.label
					else
						Stashes[id] = {}
						Stashes[id].items = {}
						Stashes[id].isOpen = src
						Stashes[id].label = secondInv.label
					end
				end
			elseif name == "trunk" then
				if Trunks[id] ~= nil then
					if Trunks[id].isOpen then
						local Target = QBCore.Functions.GetPlayer(Trunks[id].isOpen)
						if Target ~= nil then
							TriggerClientEvent('inventory:client:CheckOpenState', Trunks[id].isOpen, name, id, Trunks[id].label)
						else
							Trunks[id].isOpen = false
						end
					end
				end
				secondInv.name = "trunk-"..id
				secondInv.label = "Trunk-"..id
				secondInv.maxweight = other.maxweight ~= nil and other.maxweight or 60000
				secondInv.inventory = {}
				secondInv.slots = other.slots ~= nil and other.slots or 50
				if (Trunks[id] ~= nil and Trunks[id].isOpen) or (QBCore.Shared.SplitStr(id, "PLZI")[2] ~= nil and Player.PlayerData.job.name ~= "police") then
					secondInv.name = "none-inv"
					secondInv.label = "Trunk-None"
					secondInv.maxweight = other.maxweight ~= nil and other.maxweight or 60000
					secondInv.inventory = {}
					secondInv.slots = 0
				else
					if id ~= nil then 
						local ownedItems = GetOwnedVehicleItems(id)
						if IsVehicleOwned(id) and next(ownedItems) ~= nil then
							secondInv.inventory = ownedItems
							Trunks[id] = {}
							Trunks[id].items = ownedItems
							Trunks[id].isOpen = src
							Trunks[id].label = secondInv.label
						elseif Trunks[id] ~= nil and not Trunks[id].isOpen then
							secondInv.inventory = Trunks[id].items
							Trunks[id].isOpen = src
							Trunks[id].label = secondInv.label
						else
							Trunks[id] = {}
							Trunks[id].items = {}
							Trunks[id].isOpen = src
							Trunks[id].label = secondInv.label
						end
					end
				end
			elseif name == "glovebox" then
				if Gloveboxes[id] ~= nil then
					if Gloveboxes[id].isOpen then
						local Target = QBCore.Functions.GetPlayer(Gloveboxes[id].isOpen)
						if Target ~= nil then
							TriggerClientEvent('inventory:client:CheckOpenState', Gloveboxes[id].isOpen, name, id, Gloveboxes[id].label)
						else
							Gloveboxes[id].isOpen = false
						end
					end
				end
				secondInv.name = "glovebox-"..id
				secondInv.label = "Glovebox-"..id
				secondInv.maxweight = 10000
				secondInv.inventory = {}
				secondInv.slots = 5
				if Gloveboxes[id] ~= nil and Gloveboxes[id].isOpen then
					secondInv.name = "none-inv"
					secondInv.label = "Glovebox-None"
					secondInv.maxweight = 10000
					secondInv.inventory = {}
					secondInv.slots = 0
				else
					local ownedItems = GetOwnedVehicleGloveboxItems(id)
					if Gloveboxes[id] ~= nil and not Gloveboxes[id].isOpen then
						secondInv.inventory = Gloveboxes[id].items
						Gloveboxes[id].isOpen = src
						Gloveboxes[id].label = secondInv.label
					elseif IsVehicleOwned(id) and next(ownedItems) ~= nil then
						secondInv.inventory = ownedItems
						Gloveboxes[id] = {}
						Gloveboxes[id].items = ownedItems
						Gloveboxes[id].isOpen = src
						Gloveboxes[id].label = secondInv.label
					else
						Gloveboxes[id] = {}
						Gloveboxes[id].items = {}
						Gloveboxes[id].isOpen = src
						Gloveboxes[id].label = secondInv.label
					end
				end
			elseif name == "shop" then
				secondInv.name = "itemshop-"..id
				secondInv.label = other.label
				secondInv.maxweight = 900000
				secondInv.inventory = SetupShopItems(id, other.items)
				ShopItems[id] = {}
				ShopItems[id].items = other.items
				secondInv.slots = #other.items
			elseif name == "traphouse" then
				secondInv.name = "traphouse-"..id
				secondInv.label = other.label
				secondInv.maxweight = 900000
				secondInv.inventory = other.items
				secondInv.slots = other.slots
			elseif name == "crafting" then
				secondInv.name = "crafting"
				secondInv.label = other.label
				secondInv.maxweight = 900000
				secondInv.inventory = other.items
				secondInv.slots = #other.items
			elseif name == "attachment_crafting" then
				secondInv.name = "attachment_crafting"
				secondInv.label = other.label
				secondInv.maxweight = 900000
				secondInv.inventory = other.items
				secondInv.slots = #other.items
			elseif name == "otherplayer" then
				local OtherPlayer = QBCore.Functions.GetPlayer(tonumber(id))
				if OtherPlayer ~= nil then
					secondInv.name = "otherplayer-"..id
					secondInv.label = "Player-"..id
					secondInv.maxweight = QBCore.Config.Player.MaxWeight
					secondInv.inventory = OtherPlayer.PlayerData.items
					if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
						secondInv.slots = QBCore.Config.Player.MaxInvSlots
					else
						secondInv.slots = QBCore.Config.Player.MaxInvSlots - 1
					end
					Citizen.Wait(250)
				end
			else
				if Drops[id] ~= nil and not Drops[id].isOpen then
					secondInv.name = id
					secondInv.label = "Dropped-"..tostring(id)
					secondInv.maxweight = 100000
					secondInv.inventory = Drops[id].items
					secondInv.slots = 30
					Drops[id].isOpen = src
					Drops[id].label = secondInv.label
				else
					secondInv.name = "none-inv"
					secondInv.label = "Dropped-None"
					secondInv.maxweight = 100000
					secondInv.inventory = {}
					secondInv.slots = 0
					--Drops[id].label = secondInv.label
				end
			end
			for k,v in pairs(Player.PlayerData.items) do
				if v.image == 'placeholder.png' then 
					v.image = v.name..'.png' or v.name..'.jpg'
				end
				if type(v.info) == 'string' then 
					v.info = {}
				end
				if not string.find(v.name,'weapon') then
					if v.info.quality == nil then 
						v.info.quality = 100
					end
				end
			end
			for k,v in pairs(secondInv.inventory) do
				if v.image == 'placeholder.png' then 
					v.image = v.name..'.png' or v.name..'.jpg'
				end
				if type(v.info) == 'string' then 
					v.info = {}
				end
				if not string.find(v.name,'weapon') then
					if v.info.quality == nil then 
						v.info.quality = 100
					end
				end
			end
			TriggerClientEvent("inventory:client:OpenInventory", src, PlayerAmmo, Player.PlayerData.items, secondInv)
		else
			for k,v in pairs(Player.PlayerData.items) do
				if v.image == 'placeholder.png' then 
					v.image = v.name..'.png' or v.name..'.jpg'
				end
				if type(v.info) == 'string' then 
					v.info = {}
				end
				if not string.find(v.name,'weapon') then
					if v.info.quality == nil then 
						v.info.quality = 100
					end
				end
			end
			TriggerClientEvent("inventory:client:OpenInventory", src, PlayerAmmo, Player.PlayerData.items)
		end
	end)
end)

RegisterServerEvent("inventory:server:SaveInventory")
AddEventHandler('inventory:server:SaveInventory', function(type, id)
	if type == "trunk" then
		if (IsVehicleOwned(id)) then
			SaveOwnedVehicleItems(id, Trunks[id].items)
		else
			Trunks[id].isOpen = false
		end
	elseif type == "glovebox" then
		if (IsVehicleOwned(id)) then
			SaveOwnedGloveboxItems(id, Gloveboxes[id].items)
		else
			Gloveboxes[id].isOpen = false
		end
	elseif type == "stash" then
		SaveStashItems(id, Stashes[id].items)
	elseif type == "drop" then
		if Drops[id] ~= nil then
			Drops[id].isOpen = false
			if Drops[id].items == nil or next(Drops[id].items) == nil then
				Drops[id] = nil
				TriggerClientEvent("inventory:client:RemoveDropItem", -1, id)
			end
		end
	end
end)

RegisterServerEvent("inventory:server:UseItemSlot")
AddEventHandler('inventory:server:UseItemSlot', function(slot)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local itemData = Player.Functions.GetItemBySlot(slot)

	if itemData ~= nil then
		local itemInfo = QBCore.Shared.Items[itemData.name]
		if itemData.type == "weapon" then
			if itemData.info.quality ~= nil then
				if itemData.info.quality > 0 then
					TriggerClientEvent("inventory:client:UseWeapon", src, itemData, true)
				else
					TriggerClientEvent("inventory:client:UseWeapon", src, itemData, false)
				end
			else
				TriggerClientEvent("inventory:client:UseWeapon", src, itemData, true)
			end
			TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, "use")
		elseif itemData.useable then
			TriggerClientEvent("QBCore:Client:UseItem", src, itemData)
			TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, "use")
		end
	end
end)

RegisterServerEvent("inventory:server:UseItem")
AddEventHandler('inventory:server:UseItem', function(inventory, item)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if inventory == "player" or inventory == "hotbar" then
		local itemData = Player.Functions.GetItemBySlot(item.slot)
		if itemData ~= nil then
			TriggerClientEvent("QBCore:Client:UseItem", src, itemData)
		end
	end
end)

RegisterServerEvent("inventory:server:SetInventoryData")
AddEventHandler('inventory:server:SetInventoryData', function(fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local fromSlot = tonumber(fromSlot)
	local toSlot = tonumber(toSlot)

	if (fromInventory == "player" or fromInventory == "hotbar") and (QBCore.Shared.SplitStr(toInventory, "-")[1] == "itemshop" or toInventory == "crafting") then
		return
	end

	if fromInventory == "player" or fromInventory == "hotbar" then
		local fromItemData = Player.Functions.GetItemBySlot(fromSlot)
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			elseif QBCore.Shared.SplitStr(toInventory, "-")[1] == "otherplayer" then
				local playerId = tonumber(QBCore.Shared.SplitStr(toInventory, "-")[2])
				local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
				local toItemData = OtherPlayer.PlayerData.items[toSlot]
				Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
				TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="citizen2", name=itemInfo["name"], amount=fromAmount, target=OtherPlayer.PlayerData.citizenid})
				TriggerEvent("qb-log:server:CreateLog", "robbing", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** to player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | id: *"..OtherPlayer.PlayerData.source.."*)")
				OtherPlayer.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			elseif QBCore.Shared.SplitStr(toInventory, "-")[1] == "trunk" then
				local plate = QBCore.Shared.SplitStr(toInventory, "-")[2]
				local toItemData = Trunks[plate].items[toSlot]
				Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					--Player.PlayerData.items[fromSlot] = toItemData
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						RemoveFromTrunk(plate, fromSlot, itemInfo["name"], toAmount)
						Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="trunk1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=plate})
						TriggerEvent("qb-log:server:CreateLog", "trunk", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
					end
				else
					local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="trunk2", name=fromItemData.name, amount=fromAmount, target=plate})
					TriggerEvent("qb-log:server:CreateLog", "trunk", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToTrunk(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			elseif QBCore.Shared.SplitStr(toInventory, "-")[1] == "glovebox" then
				local plate = QBCore.Shared.SplitStr(toInventory, "-")[2]
				local toItemData = Gloveboxes[plate].items[toSlot]
				Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					--Player.PlayerData.items[fromSlot] = toItemData
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						RemoveFromGlovebox(plate, fromSlot, itemInfo["name"], toAmount)
						Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="glovebox1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=plate})
						TriggerEvent("qb-log:server:CreateLog", "glovebox", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
					end
				else
					local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="glovebox2", name=fromItemData.name, amount=fromAmount, target=plate})
					TriggerEvent("qb-log:server:CreateLog", "glovebox", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToGlovebox(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			elseif QBCore.Shared.SplitStr(toInventory, "-")[1] == "stash" then
				local stashId = QBCore.Shared.SplitStr(toInventory, "-")[2]
				local toItemData = Stashes[stashId].items[toSlot]
				Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					--Player.PlayerData.items[fromSlot] = toItemData
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						RemoveFromStash(stashId, fromSlot, itemInfo["name"], toAmount)
						Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="stash1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=stashId})
						TriggerEvent("qb-log:server:CreateLog", "stash", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - stash: *" .. stashId .. "*")
					end
				else
					local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="stash2", name=fromItemData.name, amount=fromAmount, target=stashId})
					TriggerEvent("qb-log:server:CreateLog", "stash", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - stash: *" .. stashId .. "*")
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToStash(stashId, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			elseif QBCore.Shared.SplitStr(toInventory, "-")[1] == "traphouse" then
				-- Traphouse
				local traphouseId = QBCore.Shared.SplitStr(toInventory, "-")[2]
				local toItemData = exports['qb-traphouses']:GetInventoryData(traphouseId, toSlot)
				local IsItemValid = exports['qb-traphouses']:CanItemBeSaled(fromItemData.name:lower())
				if IsItemValid then
					Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
					TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
					if toItemData ~= nil then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
						if toItemData.name ~= fromItemData.name then
							exports['qb-traphouses']:RemoveHouseItem(traphouseId, fromSlot, itemInfo["name"], toAmount)
							Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
							TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="traphouse1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=traphouseId})
							TriggerEvent("qb-log:server:CreateLog", "traphouse", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - traphouse: *" .. traphouseId .. "*")
						end
					else
						local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="traphouse2", name=fromItemData.name, amount=fromAmount, target=traphouseId})
						TriggerEvent("qb-log:server:CreateLog", "traphouse", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - traphouse: *" .. traphouseId .. "*")
					end
					local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
					exports['qb-traphouses']:AddHouseItem(traphouseId, toSlot, itemInfo["name"], fromAmount, fromItemData.info, src)
				else
					TriggerClientEvent('QBCore:Notify', src, "You can\'t sell this item..", 'error')
				end
			else
				-- drop
				toInventory = tonumber(toInventory)
				if toInventory == nil or toInventory == 0 then
					CreateNewDrop(src, fromSlot, toSlot, fromAmount)
				else
					local toItemData = Drops[toInventory].items[toSlot]
					Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
					TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
					if toItemData ~= nil then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
						if toItemData.name ~= fromItemData.name then
							Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
							RemoveFromDrop(toInventory, fromSlot, itemInfo["name"], toAmount)
							TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="drop1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=toInventory})
							TriggerEvent("qb-log:server:CreateLog", "drop", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - dropid: *" .. toInventory .. "*")
						end
					else
						local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="drop2", name=fromItemData.name, amount=fromAmount, target=toInventory})
						TriggerEvent("qb-log:server:CreateLog", "drop", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - dropid: *" .. toInventory .. "*")
					end
					local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
					AddToDrop(toInventory, toSlot, itemInfo["name"], fromAmount, fromItemData.info)
					if itemInfo["name"] == "radio" then
						TriggerClientEvent('qb-radio:onRadioDrop', src)
					end
				end
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "You doesn\'t have this item!", "error")
		end
	elseif QBCore.Shared.SplitStr(fromInventory, "-")[1] == "otherplayer" then
		local playerId = tonumber(QBCore.Shared.SplitStr(fromInventory, "-")[2])
		local OtherPlayer = QBCore.Functions.GetPlayer(playerId)
		local fromItemData = OtherPlayer.PlayerData.items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				OtherPlayer.Functions.RemoveItem(itemInfo["name"], fromAmount, fromSlot)
				TriggerClientEvent("inventory:client:CheckWeapon", OtherPlayer.PlayerData.source, fromItemData.name)
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						OtherPlayer.Functions.AddItem(itemInfo["name"], toAmount, fromSlot, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2citizen1", toName=itemInfo["name"], toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=OtherPlayer.PlayerData.citizenid})
						TriggerEvent("qb-log:server:CreateLog", "robbing", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** from player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | *"..OtherPlayer.PlayerData.source.."*)")
					end
				else
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2citizen2", name=fromItemData.name, amount=fromAmount, target=OtherPlayer.PlayerData.citizenid})
					TriggerEvent("qb-log:server:CreateLog", "robbing", "Retrieved Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) took item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** from player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | *"..OtherPlayer.PlayerData.source.."*)")
				end
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				local toItemData = OtherPlayer.PlayerData.items[toSlot]
				OtherPlayer.Functions.RemoveItem(itemInfo["name"], fromAmount, fromSlot)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						OtherPlayer.Functions.RemoveItem(itemInfo["name"], toAmount, toSlot)
						OtherPlayer.Functions.AddItem(itemInfo["name"], toAmount, fromSlot, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				OtherPlayer.Functions.AddItem(itemInfo["name"], fromAmount, toSlot, fromItemData.info)
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn\'t exist??", "error")
		end
	elseif QBCore.Shared.SplitStr(fromInventory, "-")[1] == "trunk" then
		local plate = QBCore.Shared.SplitStr(fromInventory, "-")[2]
		local fromItemData = Trunks[plate].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				RemoveFromTrunk(plate, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						AddToTrunk(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2trunk1", toName=itemInfo["name"], toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=plate})
						TriggerEvent("qb-log:server:CreateLog", "trunk", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** plate: *" .. plate .. "*")
					else
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2trunk3", name=toItemData.name, amount=toAmount, target=plate})
						TriggerEvent("qb-log:server:CreateLog", "trunk", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from plate: *" .. plate .. "*")
					end
				else
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2trunk2", name=fromItemData.name, amount=fromAmount, target=plate})
					TriggerEvent("qb-log:server:CreateLog", "trunk", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** plate: *" .. plate .. "*")
				end
				SaveOwnedVehicleItems(plate,Trunks[plate].items)
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				local toItemData = Trunks[plate].items[toSlot]
				RemoveFromTrunk(plate, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						RemoveFromTrunk(plate, toSlot, itemInfo["name"], toAmount)
						AddToTrunk(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToTrunk(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn\'t exist??", "error")
		end
	elseif QBCore.Shared.SplitStr(fromInventory, "-")[1] == "glovebox" then
		local plate = QBCore.Shared.SplitStr(fromInventory, "-")[2]
		local fromItemData = Gloveboxes[plate].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				RemoveFromGlovebox(plate, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						AddToGlovebox(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2glovebox1", toName=itemInfo["name"], toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=plate})
						TriggerEvent("qb-log:server:CreateLog", "glovebox", "Swapped", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src..")* swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** plate: *" .. plate .. "*")
					else
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2glovebox3", name=toItemData.name, amount=toAmount, target=plate})
						TriggerEvent("qb-log:server:CreateLog", "glovebox", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from plate: *" .. plate .. "*")
					end
				else
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2glovebox2", name=fromItemData.name, amount=fromAmount, target=plate})
					TriggerEvent("qb-log:server:CreateLog", "glovebox", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** plate: *" .. plate .. "*")
				end
				SaveOwnedGloveboxItems(plate,Gloveboxes[plate].items)
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				local toItemData = Gloveboxes[plate].items[toSlot]
				RemoveFromGlovebox(plate, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						RemoveFromGlovebox(plate, toSlot, itemInfo["name"], toAmount)
						AddToGlovebox(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToGlovebox(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn\'t exist??", "error")
		end
	elseif QBCore.Shared.SplitStr(fromInventory, "-")[1] == "stash" then
		local stashId = QBCore.Shared.SplitStr(fromInventory, "-")[2]
		local fromItemData = Stashes[stashId].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				RemoveFromStash(stashId, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						AddToStash(stashId, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2stash1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=stashId})
						TriggerEvent("qb-log:server:CreateLog", "stash", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** stash: *" .. stashId .. "*")
					else
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2stash3", name=toItemData.name, amount=toAmount, target=stashId})
						TriggerEvent("qb-log:server:CreateLog", "stash", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from stash: *" .. stashId .. "*")
					end
				else
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2stash2", name=fromItemData.name, amount=fromAmount, target=stashId})
					TriggerEvent("qb-log:server:CreateLog", "stash", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** stash: *" .. stashId .. "*")
				end
				SaveStashItems(stashId, Stashes[stashId].items)
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				local toItemData = Stashes[stashId].items[toSlot]
				RemoveFromStash(stashId, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						RemoveFromStash(stashId, toSlot, itemInfo["name"], toAmount)
						AddToStash(stashId, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToStash(stashId, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn\'t exist??", "error")
		end
	elseif QBCore.Shared.SplitStr(fromInventory, "-")[1] == "traphouse" then
		local traphouseId = QBCore.Shared.SplitStr(fromInventory, "-")[2]
		local fromItemData = exports['qb-traphouses']:GetInventoryData(traphouseId, fromSlot)
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				exports['qb-traphouses']:RemoveHouseItem(traphouseId, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						exports['qb-traphouses']:AddHouseItem(traphouseId, fromSlot, itemInfo["name"], toAmount, toItemData.info, src)
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2stash1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=traphouseId})
						TriggerEvent("qb-log:server:CreateLog", "stash", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** stash: *" .. traphouseId .. "*")
					else
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2stash3", name=toItemData.name, amount=toAmount, target=traphouseId})
						TriggerEvent("qb-log:server:CreateLog", "stash", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from stash: *" .. traphouseId .. "*")
					end
				else
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2stash2", name=fromItemData.name, amount=fromAmount, target=traphouseId})
					TriggerEvent("qb-log:server:CreateLog", "stash", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** stash: *" .. traphouseId .. "*")
				end
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				local toItemData = exports['qb-traphouses']:GetInventoryData(traphouseId, toSlot)
				exports['qb-traphouses']:RemoveHouseItem(traphouseId, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						exports['qb-traphouses']:RemoveHouseItem(traphouseId, toSlot, itemInfo["name"], toAmount)
						exports['qb-traphouses']:AddHouseItem(traphouseId, fromSlot, itemInfo["name"], toAmount, toItemData.info, src)
					end
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				exports['qb-traphouses']:AddHouseItem(traphouseId, toSlot, itemInfo["name"], fromAmount, fromItemData.info, src)
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn't exist??", "error")
		end
	elseif QBCore.Shared.SplitStr(fromInventory, "-")[1] == "itemshop" then
		local shopType = QBCore.Shared.SplitStr(fromInventory, "-")[2]
		local itemData = ShopItems[shopType].items[fromSlot]
		local itemInfo = QBCore.Shared.Items[itemData.name:lower()]
		local bankBalance = Player.PlayerData.money["bank"]
		local price = tonumber((itemData.price*fromAmount))

		if QBCore.Shared.SplitStr(shopType, "_")[1] == "Dealer" then
			if QBCore.Shared.SplitStr(itemData.name, "_")[1] == "weapon" then
				price = tonumber(itemData.price)
				if Player.Functions.RemoveMoney("cash", price, "dealer-item-bought") then
					itemData.info.serie = tostring(Config.RandomInt(2) .. Config.RandomStr(3) .. Config.RandomInt(1) .. Config.RandomStr(2) .. Config.RandomInt(3) .. Config.RandomStr(4))
					Player.Functions.AddItem(itemData.name, 1, toSlot, itemData.info)
					TriggerClientEvent('qb-drugs:client:updateDealerItems', src, itemData, 1)
					TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemshop", {type="dealer", name=itemInfo["name"], amount=1, paymentType="cash", price=price})
					TriggerEvent("qb-log:server:CreateLog", "dealers", "Dealer item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
				else
					TriggerClientEvent('QBCore:Notify', src, "You don\'t have enough cash..", "error")
				end
			else
				if Player.Functions.RemoveMoney("cash", price, "dealer-item-bought") then
					Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
					TriggerClientEvent('qb-drugs:client:updateDealerItems', src, itemData, fromAmount)
					TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " ingekocht!", "success")
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemshop", {type="dealer", name=itemInfo["name"], amount=fromAmount, paymentType="cash", price=price})
					TriggerEvent("qb-log:server:CreateLog", "dealers", "Dealer item gekocht", "green", "**"..GetPlayerName(src) .. "** heeft een " .. itemInfo["label"] .. " bought for $"..price)
				else
					TriggerClientEvent('QBCore:Notify', src, "You don't have enough cash..", "error")
				end
			end
		elseif QBCore.Shared.SplitStr(shopType, "_")[1] == "Itemshop" then
			if Player.Functions.RemoveMoney("cash", price, "itemshop-bought-item") then
				Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
				TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
				TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
				TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemshop", {type="itemshop", name=itemInfo["name"], amount=fromAmount, paymentType="cash", price=price})
				TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			elseif bankBalance >= price then
				Player.Functions.RemoveMoney("bank", price, "itemshop-bought-item")
				Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
				TriggerClientEvent('qb-shops:client:UpdateShop', src, QBCore.Shared.SplitStr(shopType, "_")[2], itemData, fromAmount)
				TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
				TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemshop", {type="itemshop", name=itemInfo["name"], amount=fromAmount, paymentType="bank", price=price})
				TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			else
				TriggerClientEvent('QBCore:Notify', src, "You don't have enough cash..", "error")
			end
		else
			if Player.Functions.RemoveMoney("cash", price, "unkown-itemshop-bought-item") then
				Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
				TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
				TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemshop", {type="other", name=itemInfo["name"], amount=fromAmount, paymentType="cash", price=price})
				TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			elseif bankBalance >= price then
				Player.Functions.RemoveMoney("bank", price, "unkown-itemshop-bought-item")
				Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
				TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
				TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemshop", {type="other", name=itemInfo["name"], amount=fromAmount, paymentType="bank", price=price})
				TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			else
				TriggerClientEvent('QBCore:Notify', src, "You don\'t have enough cash..", "error")
			end
		end
	elseif fromInventory == "crafting" then
		local itemData = Config.CraftingItems[fromSlot]
		if hasCraftItems(src, itemData.costs, fromAmount) then
			TriggerClientEvent("inventory:client:CraftItems", src, itemData.name, itemData.costs, fromAmount, toSlot, itemData.points)
		else
			TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, true)
			TriggerClientEvent('QBCore:Notify', src, "You don't have the right items..", "error")
		end
	elseif fromInventory == "attachment_crafting" then
		local itemData = Config.AttachmentCrafting["items"][fromSlot]
		if hasCraftItems(src, itemData.costs, fromAmount) then
			TriggerClientEvent("inventory:client:CraftAttachment", src, itemData.name, itemData.costs, fromAmount, toSlot, itemData.points)
		else
			TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, true)
			TriggerClientEvent('QBCore:Notify', src, "You don't have the right items..", "error")
		end
	else
		-- drop
		fromInventory = tonumber(fromInventory)
		local fromItemData = Drops[fromInventory].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				RemoveFromDrop(fromInventory, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						AddToDrop(fromInventory, toSlot, itemInfo["name"], toAmount, toItemData.info)
						if itemInfo["name"] == "radio" then
							TriggerClientEvent('qb-radio:onRadioDrop', src)
						end
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2drop1", toName=toItemData.name, toAmount=toAmount, fromName=fromItemData.name, fromAmount=fromAmount, target=fromInventory})
						TriggerEvent("qb-log:server:CreateLog", "drop", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** - dropid: *" .. fromInventory .. "*")
					else
						TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2drop3", name=toItemData.name, amount=toAmount, target=fromInventory})
						TriggerEvent("qb-log:server:CreateLog", "drop", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** - from dropid: *" .. fromInventory .. "*")
					end
				else
					TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="2drop2", name=fromItemData.name, amount=fromAmount, target=fromInventory})
					TriggerEvent("qb-log:server:CreateLog", "drop", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** -  dropid: *" .. fromInventory .. "*")
				end
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				toInventory = tonumber(toInventory)
				local toItemData = Drops[toInventory].items[toSlot]
				RemoveFromDrop(fromInventory, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = QBCore.Shared.Items[toItemData.name:lower()]
						RemoveFromDrop(toInventory, toSlot, itemInfo["name"], toAmount)
						AddToDrop(fromInventory, fromSlot, itemInfo["name"], toAmount, toItemData.info)
						if itemInfo["name"] == "radio" then
							TriggerClientEvent('qb-radio:onRadioDrop', src)
						end
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = QBCore.Shared.Items[fromItemData.name:lower()]
				AddToDrop(toInventory, toSlot, itemInfo["name"], fromAmount, fromItemData.info)
				if itemInfo["name"] == "radio" then
					TriggerClientEvent('qb-radio:onRadioDrop', src)
				end
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn't exist??", "error")
		end
	end
end)

function hasCraftItems(source, CostItems, amount)
	local Player = QBCore.Functions.GetPlayer(source)
	for k, v in pairs(CostItems) do
		if Player.Functions.GetItemByName(k) ~= nil then
			if Player.Functions.GetItemByName(k).amount < (v * amount) then
				return false
			end
		else
			return false
		end
	end
	return true
end

function IsVehicleOwned(plate)
	local val = false
	QBCore.Functions.ExecuteSql(true, "SELECT * FROM `player_vehicles` WHERE `plate` = '"..plate.."'", function(result)
		if (result[1] ~= nil) then
			val = true
		else
			val = false
		end
	end)
	return val
end

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
	for i, c in ipairs(in_char) do
	  s = s:gsub(c, '\\' .. out_char[i])
	end
	return s
end

-- Shop Items
function SetupShopItems(shop, shopItems)
	local items = {}
	if shopItems ~= nil and next(shopItems) ~= nil then
		for k, item in pairs(shopItems) do
			local itemInfo = QBCore.Shared.Items[item.name:lower()]
			items[item.slot] = {
				name = itemInfo["name"],
				amount = tonumber(item.amount),
				info = item.info ~= nil and item.info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				price = item.price,
				image = itemInfo["image"],
				slot = item.slot,
			}
		end
	end
	return items
end

-- Stash Items
function GetStashItems(stashId)
	local items = {}
	QBCore.Functions.ExecuteSql(true, "SELECT * FROM `stashitems` WHERE `stash` = '"..stashId.."'", function(result)
		if result[1] ~= nil then
			for k, item in pairs(result) do
				local itemInfo = QBCore.Shared.Items[item.name:lower()]
				items[item.slot] = {
					name = itemInfo["name"],
					amount = tonumber(item.amount),
					info = json.decode(item.info) ~= nil and json.decode(item.info) or "",
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"], 
					type = itemInfo["type"], 
					unique = itemInfo["unique"], 
					useable = itemInfo["useable"], 
					image = itemInfo["image"],
					slot = item.slot,
				}
			end
			QBCore.Functions.ExecuteSql(false, "DELETE FROM `stashitems` WHERE `stash` = '"..stashId.."'")
		else
			QBCore.Functions.ExecuteSql(true, "SELECT * FROM `stashitemsnew` WHERE `stash` = '"..stashId.."'", function(result)
				if result[1] ~= nil then 
					if result[1].items ~= nil then
						result[1].items = json.decode(result[1].items)
						if result[1].items ~= nil then 
							for k, item in pairs(result[1].items) do
								local itemInfo = QBCore.Shared.Items[item.name:lower()]
								items[item.slot] = {
									name = itemInfo["name"],
									amount = tonumber(item.amount),
									info = item.info ~= nil and item.info or "",
									label = itemInfo["label"],
									description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
									weight = itemInfo["weight"], 
									type = itemInfo["type"], 
									unique = itemInfo["unique"], 
									useable = itemInfo["useable"], 
									image = itemInfo["image"],
									slot = item.slot,
								}
							end
						end
					end
				end
			end)
		end
	end)
	return items
end

QBCore.Functions.CreateCallback('qb-inventory:server:GetStashItems', function(source, cb, stashId)
	cb(GetStashItems(stashId))
end)

RegisterServerEvent('qb-inventory:server:SaveStashItems')
AddEventHandler('qb-inventory:server:SaveStashItems', function(stashId, items)
	local opti = {}
	for slot, item in pairs(items) do
		table.insert(opti, {
			name = item.name,
			amount = item.amount,
			info = item.info,
			type = item.type,
			slot = item.slot,
		})
	end
	Wait(200)
	local items = opti
	QBCore.Functions.ExecuteSql(false, "SELECT * FROM `stashitemsnew` WHERE `stash` = '"..stashId.."'", function(result)
		if result[1] ~= nil then
			QBCore.Functions.ExecuteSql(false, "UPDATE `stashitemsnew` SET `items` = '"..json.encode(items).."' WHERE `stash` = '"..stashId.."'")
		else
			QBCore.Functions.ExecuteSql(false, "INSERT INTO `stashitemsnew` (`stash`, `items`) VALUES ('"..stashId.."', '"..json.encode(items).."')")
		end
	end)
end)

function SaveStashItems(stashId, items)
	local opti = {}
	if Stashes[stashId].label ~= "Stash-None" then
		if items ~= nil then
			for slot, item in pairs(items) do
				table.insert(opti, {
					name = item.name,
					amount = item.amount,
					info = item.info,
					type = item.type,
					slot = item.slot,
				})
			end
			local items = opti
			QBCore.Functions.ExecuteSql(false, "SELECT * FROM `stashitemsnew` WHERE `stash` = '"..stashId.."'", function(result)
				if result[1] ~= nil then
					QBCore.Functions.ExecuteSql(false, "UPDATE `stashitemsnew` SET `items` = '"..json.encode(items).."' WHERE `stash` = '"..stashId.."'")
					Stashes[stashId].isOpen = false
				else
					QBCore.Functions.ExecuteSql(false, "INSERT INTO `stashitemsnew` (`stash`, `items`) VALUES ('"..stashId.."', '"..json.encode(items).."')")
					Stashes[stashId].isOpen = false
				end
			end)
		end
	end
end

function AddToStash(stashId, slot, otherslot, itemName, amount, info)
	local amount = tonumber(amount)
	local ItemData = QBCore.Shared.Items[itemName]
	if not ItemData.unique then
		if Stashes[stashId].items[slot] ~= nil and Stashes[stashId].items[slot].name == itemName then
			Stashes[stashId].items[slot].amount = Stashes[stashId].items[slot].amount + amount
		else
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Stashes[stashId].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	else
		if Stashes[stashId].items[slot] ~= nil and Stashes[stashId].items[slot].name == itemName then
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Stashes[stashId].items[otherslot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = otherslot,
			}
		else
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Stashes[stashId].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	end
end

function RemoveFromStash(stashId, slot, itemName, amount)
	local amount = tonumber(amount)
	if Stashes[stashId].items[slot] ~= nil and Stashes[stashId].items[slot].name == itemName then
		if Stashes[stashId].items[slot].amount > amount then
			Stashes[stashId].items[slot].amount = Stashes[stashId].items[slot].amount - amount
		else
			Stashes[stashId].items[slot] = nil
			if next(Stashes[stashId].items) == nil then
				Stashes[stashId].items = {}
			end
		end
	else
		Stashes[stashId].items[slot] = nil
		if Stashes[stashId].items == nil then
			Stashes[stashId].items[slot] = nil
		end
	end
end

-- Trunk items
function GetOwnedVehicleItems(plate)
	local items = {}
	QBCore.Functions.ExecuteSql(true, "SELECT * FROM `trunkitems` WHERE `plate` = '"..plate.."'", function(result)
		if result[1] ~= nil then
			for k, item in pairs(result) do
				local itemInfo = QBCore.Shared.Items[item.name:lower()]
				items[item.slot] = {
					name = itemInfo["name"],
					amount = tonumber(item.amount),
					info = json.decode(item.info) ~= nil and json.decode(item.info) or "",
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"], 
					type = itemInfo["type"], 
					unique = itemInfo["unique"], 
					useable = itemInfo["useable"], 
					image = itemInfo["image"],
					slot = item.slot,
				}
			end
			QBCore.Functions.ExecuteSql(false, "DELETE FROM `trunkitems` WHERE `plate` = '"..plate.."'")
		else
			QBCore.Functions.ExecuteSql(true, "SELECT * FROM `trunkitemsnew` WHERE `plate` = '"..plate.."'", function(result)
				if result[1] ~= nil then
					if result[1].items ~= nil then
						result[1].items = json.decode(result[1].items)
						if result[1].items ~= nil then 
							for k, item in pairs(result[1].items) do
								local itemInfo = QBCore.Shared.Items[item.name:lower()]
								items[item.slot] = {
									name = itemInfo["name"],
									amount = tonumber(item.amount),
									info = item.info ~= nil and item.info or "",
									label = itemInfo["label"],
									description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
									weight = itemInfo["weight"], 
									type = itemInfo["type"], 
									unique = itemInfo["unique"], 
									useable = itemInfo["useable"], 
									image = itemInfo["image"],
									slot = item.slot,
								}
							end
						end
					end
				end
			end)
		end
	end)
	return items
end

function SaveOwnedVehicleItems(plate, items)
	local opti = {}
	if Trunks[plate].label ~= "Trunk-None" then
		if items ~= nil then
			for slot, item in pairs(items) do
				table.insert(opti, {
					name = item.name,
					amount = item.amount,
					info = item.info,
					type = item.type,
					slot = item.slot,
				})
			end
			local items = opti
			QBCore.Functions.ExecuteSql(false, "SELECT * FROM `trunkitemsnew` WHERE `plate` = '"..plate.."'", function(result)
				if result[1] ~= nil then
					QBCore.Functions.ExecuteSql(false, "UPDATE `trunkitemsnew` SET `items` = '"..json.encode(items).."' WHERE `plate` = '"..plate.."'", function(result) 
						Trunks[plate].isOpen = false
					end)
				else
					QBCore.Functions.ExecuteSql(false, "INSERT INTO `trunkitemsnew` (`plate`, `items`) VALUES ('"..plate.."', '"..json.encode(items).."')", function(result) 
						Trunks[plate].isOpen = false
					end)
				end
			end)
		end
	end
end

function AddToTrunk(plate, slot, otherslot, itemName, amount, info)
	local amount = tonumber(amount)
	local ItemData = QBCore.Shared.Items[itemName]

	if not ItemData.unique then
		if Trunks[plate].items[slot] ~= nil and Trunks[plate].items[slot].name == itemName then
			Trunks[plate].items[slot].amount = Trunks[plate].items[slot].amount + amount
		else
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Trunks[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	else
		if Trunks[plate].items[slot] ~= nil and Trunks[plate].items[slot].name == itemName then
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Trunks[plate].items[otherslot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = otherslot,
			}
		else
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Trunks[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	end
end

function RemoveFromTrunk(plate, slot, itemName, amount)
	if Trunks[plate].items[slot] ~= nil and Trunks[plate].items[slot].name == itemName then
		if Trunks[plate].items[slot].amount > amount then
			Trunks[plate].items[slot].amount = Trunks[plate].items[slot].amount - amount
		else
			Trunks[plate].items[slot] = nil
			if next(Trunks[plate].items) == nil then
				Trunks[plate].items = {}
			end
		end
	else
		Trunks[plate].items[slot]= nil
		if Trunks[plate].items == nil then
			Trunks[plate].items[slot] = nil
		end
	end
end

-- Glovebox items
function GetOwnedVehicleGloveboxItems(plate)
	local items = {}
	QBCore.Functions.ExecuteSql(true, "SELECT * FROM `gloveboxitems` WHERE `plate` = '"..plate.."'", function(result)
		if result[1] ~= nil then
			for k, item in pairs(result) do
				local itemInfo = QBCore.Shared.Items[item.name:lower()]
				items[item.slot] = {
					name = itemInfo["name"],
					amount = tonumber(item.amount),
					info = json.decode(item.info) ~= nil and json.decode(item.info) or "",
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"], 
					type = itemInfo["type"], 
					unique = itemInfo["unique"], 
					useable = itemInfo["useable"], 
					image = itemInfo["image"],
					slot = item.slot,
				}
			end
			QBCore.Functions.ExecuteSql(false, "DELETE FROM `gloveboxitems` WHERE `plate` = '"..plate.."'")
		else
			QBCore.Functions.ExecuteSql(true, "SELECT * FROM `gloveboxitemsnew` WHERE `plate` = '"..plate.."'", function(result)
				if result[1] ~= nil then 
					if result[1].items ~= nil then
						result[1].items = json.decode(result[1].items)
						if result[1].items ~= nil then 
							for k, item in pairs(result[1].items) do
								local itemInfo = QBCore.Shared.Items[item.name:lower()]
								items[item.slot] = {
									name = itemInfo["name"],
									amount = tonumber(item.amount),
									info = item.info ~= nil and item.info or "",
									label = itemInfo["label"],
									description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
									weight = itemInfo["weight"], 
									type = itemInfo["type"], 
									unique = itemInfo["unique"], 
									useable = itemInfo["useable"], 
									image = itemInfo["image"],
									slot = item.slot,
								}
							end
						end
					end
				end
			end)
		end
	end)
	return items
end

function SaveOwnedGloveboxItems(plate, items)
	local opti = {}
	if Gloveboxes[plate].label ~= "Glovebox-None" then
		if items ~= nil then
			for slot, item in pairs(items) do
				table.insert(opti, {
					name = item.name,
					amount = item.amount,
					info = item.info,
					type = item.type,
					slot = item.slot,
				})
			end
			local items = opti
			QBCore.Functions.ExecuteSql(false, "SELECT * FROM `gloveboxitemsnew` WHERE `plate` = '"..plate.."'", function(result)
				if result[1] ~= nil then
					QBCore.Functions.ExecuteSql(false, "UPDATE `gloveboxitemsnew` SET `items` = '"..json.encode(items).."' WHERE `plate` = '"..plate.."'", function(result) 
						Gloveboxes[plate].isOpen = false
					end)
				else
					QBCore.Functions.ExecuteSql(false, "INSERT INTO `gloveboxitemsnew` (`plate`, `items`) VALUES ('"..plate.."', '"..json.encode(items).."')", function(result) 
						Gloveboxes[plate].isOpen = false
					end)
				end
			end)
		end
	end
end

function AddToGlovebox(plate, slot, otherslot, itemName, amount, info)
	local amount = tonumber(amount)
	local ItemData = QBCore.Shared.Items[itemName]

	if not ItemData.unique then
		if Gloveboxes[plate].items[slot] ~= nil and Gloveboxes[plate].items[slot].name == itemName then
			Gloveboxes[plate].items[slot].amount = Gloveboxes[plate].items[slot].amount + amount
		else
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Gloveboxes[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	else
		if Gloveboxes[plate].items[slot] ~= nil and Gloveboxes[plate].items[slot].name == itemName then
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Gloveboxes[plate].items[otherslot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = otherslot,
			}
		else
			local itemInfo = QBCore.Shared.Items[itemName:lower()]
			Gloveboxes[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	end
end

function RemoveFromGlovebox(plate, slot, itemName, amount)
	if Gloveboxes[plate].items[slot] ~= nil and Gloveboxes[plate].items[slot].name == itemName then
		if Gloveboxes[plate].items[slot].amount > amount then
			Gloveboxes[plate].items[slot].amount = Gloveboxes[plate].items[slot].amount - amount
		else
			Gloveboxes[plate].items[slot] = nil
			if next(Gloveboxes[plate].items) == nil then
				Gloveboxes[plate].items = {}
			end
		end
	else
		Gloveboxes[plate].items[slot]= nil
		if Gloveboxes[plate].items == nil then
			Gloveboxes[plate].items[slot] = nil
		end
	end
end

-- Drop items
function AddToDrop(dropId, slot, itemName, amount, info)
	local amount = tonumber(amount)
	if Drops[dropId].items[slot] ~= nil and Drops[dropId].items[slot].name == itemName then
		Drops[dropId].items[slot].amount = Drops[dropId].items[slot].amount + amount
	else
		local itemInfo = QBCore.Shared.Items[itemName:lower()]
		Drops[dropId].items[slot] = {
			name = itemInfo["name"],
			amount = amount,
			info = info ~= nil and info or "",
			label = itemInfo["label"],
			description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
			weight = itemInfo["weight"], 
			type = itemInfo["type"], 
			unique = itemInfo["unique"], 
			useable = itemInfo["useable"], 
			image = itemInfo["image"],
			slot = slot,
			id = dropId,
		}
	end
end

function RemoveFromDrop(dropId, slot, itemName, amount)
	if Drops[dropId].items[slot] ~= nil and Drops[dropId].items[slot].name == itemName then
		if Drops[dropId].items[slot].amount > amount then
			Drops[dropId].items[slot].amount = Drops[dropId].items[slot].amount - amount
		else
			Drops[dropId].items[slot] = nil
			if next(Drops[dropId].items) == nil then
				Drops[dropId].items = {}
				--TriggerClientEvent("inventory:client:RemoveDropItem", -1, dropId)
			end
		end
	else
		Drops[dropId].items[slot] = nil
		if Drops[dropId].items == nil then
			Drops[dropId].items[slot] = nil
			--TriggerClientEvent("inventory:client:RemoveDropItem", -1, dropId)
		end
	end
end

function CreateDropId()
	if Drops ~= nil then
		local id = math.random(10000, 99999)
		local dropid = id
		while Drops[dropid] ~= nil do
			id = math.random(10000, 99999)
			dropid = id
		end
		return dropid
	else
		local id = math.random(10000, 99999)
		local dropid = id
		return dropid
	end
end

function CreateNewDrop(source, fromSlot, toSlot, itemAmount)
	local Player = QBCore.Functions.GetPlayer(source)
	local itemData = Player.Functions.GetItemBySlot(fromSlot)
	if Player.Functions.RemoveItem(itemData.name, itemAmount, itemData.slot) then
		TriggerClientEvent("inventory:client:CheckWeapon", source, itemData.name)
		local itemInfo = QBCore.Shared.Items[itemData.name:lower()]
		local dropId = CreateDropId()
		Drops[dropId] = {}
		Drops[dropId].items = {}

		Drops[dropId].items[toSlot] = {
			name = itemInfo["name"],
			amount = itemAmount,
			info = itemData.info ~= nil and itemData.info or "",
			label = itemInfo["label"],
			description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
			weight = itemInfo["weight"], 
			type = itemInfo["type"], 
			unique = itemInfo["unique"], 
			useable = itemInfo["useable"], 
			image = itemInfo["image"],
			slot = toSlot,
			id = dropId,
		}
		TriggerEvent("qb-log:server:sendLog", Player.PlayerData.citizenid, "itemswapped", {type="3drop", name=itemData.name, amount=itemAmount})
		TriggerEvent("qb-log:server:CreateLog", "drop", "New Item Drop", "red", "**".. GetPlayerName(source) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..source.."*) dropped new item; name: **"..itemData.name.."**, amount: **" .. itemAmount .. "**")
		TriggerClientEvent("inventory:client:DropItemAnim", source)
		TriggerClientEvent("inventory:client:AddDropItem", -1, dropId, source)
		if itemData.name:lower() == "radio" then
			TriggerClientEvent('qb-radio:onRadioDrop', source)
		end
	else
		TriggerClientEvent("QBCore:Notify", src, "You don't have this item!", "error")
		return
	end
end

QBCore.Commands.Add("inv", "Open your inventory", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
	TriggerClientEvent("inventory:client:OpenInventory", source, Player.PlayerData.items)
end)

QBCore.Commands.Add("resetinv", "Reset inventory (in case of -None)", {{name="type", help="stash/trunk/glovebox"},{name="id/plate", help="ID of stash or license plate"}}, true, function(source, args)
	local invType = args[1]:lower()
	table.remove(args, 1)
	local invId = table.concat(args, " ")
	if invType ~= nil and invId ~= nil then 
		if invType == "trunk" then
			if Trunks[invId] ~= nil then 
				Trunks[invId].isOpen = false
			end
		elseif invType == "glovebox" then
			if Gloveboxes[invId] ~= nil then 
				Gloveboxes[invId].isOpen = false
			end
		elseif invType == "stash" then
			if Stashes[invId] ~= nil then 
				Stashes[invId].isOpen = false
			end
		else
			TriggerClientEvent('QBCore:Notify', source,  "Not a valid type..", "error")
		end
	else
		TriggerClientEvent('QBCore:Notify', source,  "Argumenten not filled out correctly..", "error")
	end
end, "admin")

-- QBCore.Commands.Add("setnui", "Zet nui aan/ui (0/1)", {}, true, function(source, args)
--     if tonumber(args[1]) == 1 then
--         TriggerClientEvent("inventory:client:EnableNui", src)
--     else
--         TriggerClientEvent("inventory:client:DisableNui", src)
--     end
-- end)

QBCore.Commands.Add("trunkpos", "Shows trunk position", {}, false, function(source, args)
	TriggerClientEvent("inventory:client:ShowTrunkPos", source)
end)

QBCore.Commands.Add("steal", "Rob a player", {}, false, function(source, args)
	TriggerClientEvent("police:client:RobPlayer", source)
end)

QBCore.Commands.Add("giveitem", "Give item to a player", {{name="id", help="Plaer ID"},{name="item", help="Name of the item (not a label)"}, {name="amount", help="Amount of items"}}, true, function(source, args)
	local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
	local amount = tonumber(args[3])
	local itemData = QBCore.Shared.Items[tostring(args[2]):lower()]
	if Player ~= nil then
		if amount > 0 then
			if itemData ~= nil then
				-- check iteminfo
				local info = {}
				if itemData["name"] == "id_card" then
					info.citizenid = Player.PlayerData.citizenid
					info.firstname = Player.PlayerData.charinfo.firstname
					info.lastname = Player.PlayerData.charinfo.lastname
					info.birthdate = Player.PlayerData.charinfo.birthdate
					info.gender = Player.PlayerData.charinfo.gender
					info.nationality = Player.PlayerData.charinfo.nationality
					info.job = Player.PlayerData.job.label
				elseif itemData["type"] == "weapon" then
					amount = 1
					info.serie = tostring(Config.RandomInt(2) .. Config.RandomStr(3) .. Config.RandomInt(1) .. Config.RandomStr(2) .. Config.RandomInt(3) .. Config.RandomStr(4))
				elseif itemData["name"] == "harness" then
					info.uses = 20
				elseif itemData["name"] == "markedbills" then
					info.worth = math.random(5000, 10000)
				elseif itemData["name"] == "labkey" then
					info.lab = exports["qb-methlab"]:GenerateRandomLab()
				elseif itemData["name"] == "printerdocument" then
					info.url = "https://cdn.discordapp.com/attachments/645995539208470549/707609551733522482/image0.png"
				end

				if Player.Functions.AddItem(itemData["name"], amount, false, info) then
					TriggerClientEvent('QBCore:Notify', source, "You have givwen " ..GetPlayerName(tonumber(args[1])).." " .. itemData["name"] .. " ("..amount.. ")", "success")
				else
					TriggerClientEvent('QBCore:Notify', source,  "Can't give item!", "error")
				end
			else
				TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Item doesn't exist!")
			end
		else
			TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Amount must be higher than 0!")
		end
	else
		TriggerClientEvent('chatMessage', source, "SYSTEM", "error", "Player is not online!")
	end
end, "admin")

QBCore.Commands.Add("randomitems", "Krijg wat random items (voor testen)", {}, false, function(source, args)
	local Player = QBCore.Functions.GetPlayer(source)
	local filteredItems = {}
	for k, v in pairs(QBCore.Shared.Items) do
		if QBCore.Shared.Items[k]["type"] ~= "weapon" then
			table.insert(filteredItems, v)
		end
	end
	for i = 1, 10, 1 do
		local randitem = filteredItems[math.random(1, #filteredItems)]
		local amount = math.random(1, 10)
		if randitem["unique"] then
			amount = 1
		end
		if Player.Functions.AddItem(randitem["name"], amount) then
			TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[randitem["name"]], 'add')
            Citizen.Wait(500)
		end
	end
end, "god")
QBCore.Functions.CreateUseableItem("id_card", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
	if (Player.PlayerData.job.name == "police" or 
		Player.PlayerData.job.name == "police1" or 
		Player.PlayerData.job.name == "police2" or 
		Player.PlayerData.job.name == "police3" or 
		Player.PlayerData.job.name == "police4" or
		Player.PlayerData.job.name == "police5" or
		Player.PlayerData.job.name == "police6" or
		Player.PlayerData.job.name == "police7" or
		Player.PlayerData.job.name == "police8") then
		if Player.Functions.GetItemBySlot(item.slot) ~= nil then
			TriggerClientEvent("inventory:client:ShowId", -1, source, Player.PlayerData.citizenid, item.info)
			TriggerClientEvent('usebadge:gc',source)
		end
	else
		if Player.Functions.GetItemBySlot(item.slot) ~= nil then
			TriggerClientEvent("inventory:client:ShowId", -1, source, Player.PlayerData.citizenid, item.info)
		end
	end
end)

--[[QBCore.Functions.CreateUseableItem("id_card", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        TriggerClientEvent("inventory:client:ShowId", -1, source, Player.PlayerData.citizenid, item.info)
    end
end)]]

QBCore.Functions.CreateUseableItem("snowball", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
	local itemData = Player.Functions.GetItemBySlot(item.slot)
	if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        TriggerClientEvent("inventory:client:UseSnowball", source, itemData.amount)
    end
end)

QBCore.Functions.CreateUseableItem("driver_license", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        TriggerClientEvent("inventory:client:ShowDriverLicense", -1, source, Player.PlayerData.citizenid, item.info)
    end
end)

AddEventHandler('playerDropped', function(reason) 
	local src = source
	local opti = {}
	local Player = QBCore.Functions.GetPlayer(source)
	if Player then 
	else 
		return 
	end
	Player.Functions.SetInventory(Player.PlayerData.items)
	for k,item in pairs(Player.PlayerData.items) do
		table.insert(opti, {
			name = item.name,
			amount = item.amount,
			info = item.info,
			type = item.type,
			slot = item.slot,
		})
	end
	print('^2'..GetPlayerName(src)..': Saved Inventory')
	QBCore.Functions.ExecuteSql(true, "UPDATE `players` SET `inventory` = '"..QBCore.EscapeSqli(json.encode(opti)).."' WHERE `citizenid` = '"..Player.PlayerData.citizenid.."'")
end)

-- This file was generated using Luraph Obfuscator v13.6.3

return(function(e8,g8,H8,D8,n8,b8,G8,l8,C8,L8,k8,c8,V8,W8,s8,I8,J8,h8,w8,q8,a8,U8,Y8,Q8,R8,E8,m8,X8,p8,j8,z8,T8,v8,x8,f8,N,o,i)local r,N8,P,B,K,a,S,k,z,R=nil,nil,nil,nil,nil,nil,nil,nil,nil,(nil);goto _1215770195_0;::_1215770195_3::;do B=R8;end;goto _1215770195_4;::_1215770195_9::;R=g8;goto _1215770195_10;::_1215770195_6::;S={[0X3]=true,[0X4]=0X1.6B125e8Ade7e8P-4,[w8]="\z    \u{0006C}\z \x5E\z   \082\z    \x5B\u{0079}\x78",[9]=-0X4E63b541,[7]=j8,[0x0006]=false,[9]=5,[0X00001]=0X1.52b9a736FdFF6p-1,[5]=c8,[0X0006]=9,[V8]=true,[0x03]=1,[3]=6,[0x4]=1,[5]="]\z\u{54}\x4F\x4D\x68\z   \u{05E}\z    \x2C\z \x51",[9]=3,[2]=0x7,[V8]=6,[0x0001]=9,[0X8]=0X0};goto _1215770195_7;::_1215770195_4::;K=z8;goto _1215770195_5;::_1215770195_0::;r=v8;goto _1215770195_1;::_1215770195_7::;k=_ENV;goto _1215770195_8;::_1215770195_5::;a=Q8;goto _1215770195_6;::_1215770195_2::;P=a8;goto _1215770195_3;::_1215770195_8::;z=I8;goto _1215770195_9;::_1215770195_1::;N8={};goto _1215770195_2;::_1215770195_10::;local g,d,f,v=nil,nil,nil,nil;local s,q,j=m8,0X000020000000000000,(setmetatable);local V=rawget;local W,Y=f8.unpack,(1);do for S7=0x0,0X3 do do if S7<=0X1 then if S7==0 then g=W8;else d=L8;end;else if S7==0X2 then f=l8.yield;else v=string.byte;end;end;end;end;end;local c,S8,y,L=collectgarbage,0X0001,nil,nil;do repeat if S8==0x00 then S8=0X2;else y=E8;S8=0;end;until S8>1;end;S8=1;local E,J=nil,(nil);do while true do do if not(S8<=0X0001)then if S8==2 then J=function(...)return(...)[...];end;break;break;else do S8=2;end;end;else do if S8~=0X0 then L=function(J7,G7,K7)local Z7=(nil);do for Tl=0X0,0x0001 do do if Tl~=0 then Z7=K7-G7+0x01;else if G7>K7 then do return;end;end;end;end;end;end;if Z7>=8 then return J7[G7],J7[G7+1],J7[G7+2],J7[G7+3],J7[G7+0X4],J7[G7+0X5],J7[G7+0X06],J7[G7+0x7],L(J7,G7+0X8,K7);elseif Z7>=7 then return J7[G7],J7[G7+1],J7[G7+2],J7[G7+0X3],J7[G7+0X004],J7[G7+0X5],J7[G7+6],L(J7,G7+0x7,K7);elseif Z7>=0X06 then do return J7[G7],J7[G7+0X01],J7[G7+k8],J7[G7+3],J7[G7+0X04],J7[G7+0X5],L(J7,G7+0X006,K7);end;elseif Z7>=5 then return J7[G7],J7[G7+0X001],J7[G7+0X02],J7[G7+J8],J7[G7+0X04],L(J7,G7+5,K7);else if Z7>=j8 then return J7[G7],J7[G7+Y8],J7[G7+2],J7[G7+0X3],L(J7,G7+4,K7);else if Z7>=J8 then return J7[G7],J7[G7+0X1],J7[G7+2],L(J7,G7+3,K7);else if not(Z7>=0X2)then do return J7[G7],L(J7,G7+1,K7);end;else do return J7[G7],J7[G7+Y8],L(J7,G7+2,K7);end;end;end;end;end;end;S8=0X0;else do E=s8;end;S8=0X003;end;end;end;end;end;end;local A,b=nil,nil;for nG=0,0X1 do do if nG~=0x0 then b=4294967296;else A=C8;end;end;end;local C=z(K("LPH>0B0002B6424H00A2423H00BB0DB670C14H000720782H009D0007043H000BC0C17E07053H00A76C3D443CBA2H00C03HFFDF41BA6H003041D18H00C87001000248092H0244092H0240092H0217292H0205202H0215642H028207052H02AA070502AE01FE0140AE028A03D202228202B201DE0445B606C201D6044AFA048A07CE0461DA06FA02C6072D8A02FA019606778A043AA60437BE02AE04E6046882079203E6025FAE0472AE0554960502062B3H02182H020A2B2H020E2B060204092H02052006020A2B0A02122B0E0204092H0205200E02016412020D641602123E0A020A2B0E02122B1202056416020D641A0212240E0204092H029A06700E2H025A2H0204092H02A206702H020A2B2H02162B060204092H020520062H02530A0211640E020964120216362H0204092H028A01702H02062B3H02193H021D3H027302063H0041001A0026002900150103A2423H0018BA9A1C954H00091E782H009D00D1017H0007043H00D879363C4801B87001000268092H0264092H0260092H0217292H0201202H020D642H028607052H02AA0705029A03DA040E6652EA062DBE03A20276649605E6016E62FE02CA010A21BE068E035674A2028606EE01702202F206089202FA03DA0741060224092H0209641EC606B20345C603022H400E0208093H02510E0208092H02062B0E02F06HFF0F093H021D3H02530ADE06AE0475BA0406023C0A0201640E2H022B1202056416FA01EE027586032H022A120201641602BC6HFF0F010E1A0A0D2H1E0277B46HFF0F02A86HFF0F092H02001600420100A2423H00E4190971E44H000F24782H0019004D070A3H000465DECD7736DE06CDA3D18H00D100016H0007093H000697C02HAF2636505C074H0007093H007F682971478EF43800D1027H00D1017H0017710100028C01092H028801092H028401092H020F292H0201202H0215642H029607052H02AA070502E603C20732D204C604FA05748E069E03820277C207A606EE0671FA07D605B60354E606EA01AE03558207B605820125560250092H02F80109022A226D1E02280902211A0A1E0204092H0201201E1D1A0A220200092H021A2B260204092H0201202622260D2602080902012H261E02C46HFF0F092H0206452A02C06HFF0F0902110E57B42H02CC02092H02F402090221020A060204092H020120061D022H0A2H022B0E0200092H020645122H02440E0204092H02B204700E050E57AC2H02D0020902CA01A20270B63H0242321232583202000902322E0D2E0204092H0201202E022A2H16023C09022E2A612A0D2A3D2ACA01A602708E2H0294020902CA01920270A62H02122B2E0204092H0201202E02062B320204092H020120320206453602A86HFF0F092H020E2B2E02C46HFF0F092H020A2B2A02000902122A212A02E86HFF0F0902BE03C2076CCE07F606AA06479E06028001092H028CFE5HFF2H0F1202C8FE5HFF0F092H02C02H011A020E2B1A020009021A1661160220092H02062B120204092H02012012F6069E0647AE060221641A022009021216211602D06HFF0F09020D163D16F606AE0647AA06021564160220092H0221642202B46HFF0F092H0221641E02123E120204092H02AA047012020A2B1602C86HFF0F092H021D641A0206471E02D46HFF0F092H02A06HFF0F0902F606AA06479E0602162B120204092H02012012020A4516A601F20670F2060200092H02E4FE5HFF0F111209065704021C092H0206621202D06HFF0F0902190E5798FD5HFF0F02C46HFF0F0902CA019202709602CA01960270822H02C06HFF0F092H0214092H02EC6HFF0F093H021D2H02E8FD5HFF0F401A02F06HFF0F092H029CFE5HFF0F0902CA018202708E2H029C6HFF0F090207001B0022005100530056001C00580100A2423H00DE862135E14H000421782H00C100070B3H001011D227FBE622A57177BD07053H005B9C9D37B02H073H002021E217DDD50307083H00E728299D19C5D90B07083H00EF30318201DDDB02070B3H00F738398E14D2C8139D2533C6700100029C01092H029801092H029401092H0217292H0219202H021D642H028607052H02B2070502AE05A2015492039207E20635B204F601CE03173282049201358207CA0582065596048207EA0170B60192049E0625CE07D603860745BE2H025C092H0209640E2H026F06021809020D3H0A0200093H0267060200092H02062B060208093H022B060208090209022H0A02CC6HFF0F090201022H0A2H0267060204092H02C60170062H022B060204092H0219200615022H0A2H0267062H021D3H022B060204092H0219200611022H0A2H0267062H022B060204092H0219200605022H0A0204092H0219200A02806HFF0F4C0A2H02530A02F8FE5HFF0F092H02004B004D2H00A2423H00AA0A27558B4H000523782H008500070D3H00020BB8C62103BB564E51599F512H073H000FCCFD2D64CD38070A3H00EEA7C48AF53A4EC5C3474800070E3H00BCADE234C7943BA3D5F17BE17C34D1017H00070D3H00166FAC020DF5EDDEA769C050F207093H00B30001D9C0FF6CAEA7C1700100023C092H0238092H0234092H0217292H021D202H0221642H029607052H02B2070502A6018E0468529E07DE0471DE04B203B6055EAA0696028E0117C2058A059E0224BA038A04B60740C606EA05EE01049604CE043230162H02533H022B060204092H021D202H0609063H022B060204092H021D202H0619063H022B060204092H021D202H0605063H022B060204092H021D202H061D063H022B060204092H021D202H060106020D11722H02062B060204092H021D200602062B0A020A470A150A600AF6069A0647A6060E0A6D06CA01FE0170823H022F062H021D2H02004200430200A2423H00819124389F4H00071F782H005500D1017H00D1077H004DD1067H00C27001000248092H0244092H0240092H0217292H0201202H0211642H028E07052H02AE0705028A054A55F207268605348603FE03AA0370AE05DA078E2H0186075E9A0540F207CA05FA0605A605EA02BE0621CA07F601D60601A60506CE0141B605AE02A2045E56FA06B205543E05065B18023009020A020D0E0204092H0201200E021C250E0214093H022B0A0204092H0201200A060A0D0A02D86HFF0F092H0210093H021D020D065BE06HFF0F010657F46HFF0F02D86HFF0F092H02062B12020009020E120D12090A262H0210093H0267160200090206020D168E048A05289605020A2B160204092H02012016F606AA0647B20602DC6HFF0F0902030058005500590900A2423H00CADEC521114H001A6C782H001D00D12021C92D4D9E0600D1BACFF3041A280500D1C2E7D90F5FFD0400D16A1EA6B1802B0300D15CB528DB3D5BF1FFD1017H00D12899D35B1734F8FFD148C30B25EEAD0600D192D5ABB94H00070B3H00789956A1601759BC1C5C2ED1E174269EB23D0A00D1443D6FA28211FAFF070B3H00373CCDEF991B2D0BB1DD05070B3H00928BC03CD0B3F4A49F8ED8D1EAC1E31C6B430B00D19B394499B9BB0B00D1FF036H00D16H001000D167CABB664644F4FFD1A1F1BA89CADF0800D1727A06044H00D12DE4CF66BE340800D109C95AF17FFC0B00D1D94F9D0A8A980D00070B3H0079B69F88C566B097F48617D1F51158EBFB6E0300D1433E1CCFDF1EF6FF2H073H009CAD9A106D800AD10F8B89CEE2E40800D14C36B8994H00D1C7D844E034210400D1027H00D153DFF4205EF7F4FFD190F4F8348DF8F7FFD1108BF0EECA6DF1FFD12AF081E635F3F8FFD17F505FB3B7CCF1FFD1719B9C1845E22H00D1A084A1D396570300D1FE9DAA68AF110C00D1079B68B7E8460700070B3H008F34E5473188CE9BF5CD1DD1A24A51775A4E0100D144CF36FB8A832H00D137FB71C0482HF0FFD166839ABF97310D00D1CF879D4CF3012HFFD1886821F9D423FEFFD151A0E4D6F854F7FF070B3H004A6338817AC757B1605650D17E8FE20403D70A00D1CE40DAE651DB0B00D1D33EC8A4E2E40800D139B9460523280A00D1E12298F50575050007063H0011EEF791E494D1A4F02461DEE5050007063H005368C9A70DE7D1AE87D57BB95E0400070B3H00C5524B67BCA796BBCCA74307063H0098397663AD0DD1DF9EB930E306FCFFD135DB5116781BF5FF07083H00023BB09722B8331FD13BF0596B43852HFFD1D3C699ED87AE0400D15FD652B7FF43F5FFD11D6BA69851DB0B00D11573C24A86500D00D1DDFC84A1960A0D0007053H005A33C8D94F070B3H004FF4A5A6CAA81EBEFD84DDD1E524C3A11EE7F5FF2H073H000A23F874B95B42D15D8ABF7961832HFFD12DD577E6DD77F9FFD1A9E69D6E0D59F7FFD161F6C2A99C092HFF07093H0015621B65BFDED6DF2607063H00BA1328E4E757D17FD273CFEAD0F2FF0774010002D415092H02D015092H02CC15092H0213292H0215202H02C502642H028E07052H02BA070502FA05EE015586028203D60462E207DA038E0564BA01AE026601D601BE03DA034EB6048A053A549601BE07A6065DFA050298150902F606B20647DA0602B4020902CA01A20270BE2H029C04092H02E00509028D023E603E02040902C207860647B606453E6E3E153E603E020009023E3A212H3A150B3A02E46HFF0F0902CD013E3F3E02D46HFF0F092H0269644E02B403092H021A452E02F02H0902F606A20647C20602CC120902CA01920270B62H0280010902850146274602BC072546029C130902F6069E0647D20602A806092H0259644602C00B0902F606BA0647E60602A411092H02B4014C4202F4FE5HFF0F09020E465C460270254602DC02092H02DC0B4C5602E012093H0242460200093H0244420204092H02C60570421A424D4202900725420214093H02444A0204092H028202704AF606A20647E60602CC6HFF0F092H02D80A092H029D01644E02E010092H02B8054C3A02846HFF0F093H021D2H029101643A02E80C092H02B102643E02D806092H02C8024C3A02D42H092H02D8FE5HFF0F4C4602F418092H02C80D4C4E02EC02090295013E563E2H022B420204092H021520426D420A422H022B460204092H021520469902460A460208093H02443E02D06HFF0F093H0244420204092H024A702H423E6A3E2H02443A0204092H02EE04703A653A763A02D007253A02D8110902CA018A0270CA2H0290070902513260322H022B360204092H02152036DD01360A360204092H021520362H022B3A0204092H0215203AE5013A0A3A0204092H0215203A2H022B3E0204092H0215203E6D3E0A3E0204092H0215203E0E26584209420C4202B8FD5HFF0F254202FC100902F606CE0647E60602AC0E092H028502644E029410092H02E002092H0249644202C414092H02D0064C2E02E00B092H025564460288FE5HFF0F092H02F40F4C4E02D46HFF0F0902E101422742020809022642614202F06HFF0F092H02B0122542025C092H02016452028C06092H02AC04253E0210093H02443E02000902323E4D3E02E86HFF0F092H02B4FD5HFF0F0902F6069E0647EA06021C0902263H3A020C253A028401092H022D642E02B414092H02FC094C3A02840B092H02A4034C520284020902F606AA0647EA06024C092H02D8FB5HFF0F092H0239644202C811092H02E002092H02C40A25420214093H0244420204093H026C420E424D4202E46HFF0F092H02C00A092H020E4546028003092H02BC024C3A02DCFA5HFF0F092H02F501642E02A803092H0298FB5HFF0F093H02444E0204092H02F204704EBD014E274E02A8FE5HFF0F254E02C411092H02C013092H02C40D4C2A02906HFF0F0902CA019E0270B62H028015092H02A101642E029415093H022B3A0204092H0215203A6D3A0A3A0204092H0215203A2H022B3E0204092H0215203E99023E0A3E0204092H0215203E2H02443A02C001092H028C024C3602C812092H02BC030902F606B60647CA0602B005092H028CFD5HFF0F092H02062B3602000902B902360A360204092H0215203602F101643A0200092H02A501643E0200093H02423602BC6HFF0F092H02A014092H0229643202F00C093H0242360200093H0244320204092H02E20170321132273202D40C253202080902F606C20647D60602D86HFF0F092H02CC6HFF0F09021E563A5602E8F95HFF0F255602C802092H02FCFD5HFF0F092H02D0F95HFF0F4C4602AC02092H02E46HFF0F4C5602DC11092H02A902643A02F8FC5HFF0F0902CA01960270AE3H02422A062A5C2A02FCFD5HFF0F252A02E00E092H028101644E02EC0709021A3A4D3A0288FA5HFF0F253A0290110902C90152785202B00225520298FC5HFF0F092H02D403254E0214093H02444E0204092H02FE05704E124E3A4E02E46HFF0F092H02C411092H02E4FC5HFF0F4C4602E00B092H028C044C4602C0F85HFF0F092H02FC0D2532020C093H024432890132783202EC6HFF0F092H02F00D092H02E00F4C420290FB5HFF0F092H02E0F75HFF0F4C3E02F411092H02986HFF0F4C520278092H02F4104C2E02C010093H0242360204092H02F607702H36325C3202F00225320224092H0261643E02E06HFF0F092H02F101643A02F06HFF0F092H02062B360204092H02152036B902360A3602E46HFF0F092H028CFD5HFF0F090299012E662E02A00A252E02200902CA01960270B22H0200093H02422E0204092H02B205702E792E022EE9012E602E02D46HFF0F092H02F0020902CA01FE0170CE2H0294FE5HFF0F0902F606A20647E60602A0F85HFF0F0902CA019A0270C22H0298F75HFF0F0902F606AE0647C60602F0F95HFF0F092H024D64560294F75HFF0F09021E4E6A4E2H02444AC1024A564A02B101644E0200093H0242460204092H02A20770462E463A460280FE5HFF0F254602F4FA5HFF0F092H028CFB5HFF0F4C5202B4FA5HFF0F092H02B0104C3A02A4FB5HFF0F0902F606B20647CA062H02422A02D101642E0274090271263F26023C0902BD022E0A2E0204092H0215202E2H022B320204092H021520326D320A3202540902B902360A360204092H0215203602F101643A0220092H029CFB5HFF0F25360240093H022B2ADD012A0A2A0204092H0215202A2H022B2E02AC6HFF0F092H0235643E2H0242360204092H028A05702H36262D3602C86HFF0F093H02422602846HFF0F092H02062B3602A46HFF0F092H0288F85HFF0F092H02ECFB5HFF0F092H02A4FE5HFF0F4C4E0208092H022E453602D404092H02FCF65HFF0F092H0280F75HFF0F4C3202C40809026D420A420204092H021520422H022B460204092H021520469902460A460208093H022B4202D86HFF0F093H0244420204092H02BE01704202DCF75HFF0F092H02E00D092H0280FB5HFF0F2546020C0902A1024660462A464D4602EC6HFF0F092H02A00C092H02D501642E028007093H02442H56523A5202FCFB5HFF0F25520234093H022B5A0204092H0215205A99025A0A5A02DC6HFF0F093H0244520204092H02F60470522H022B560204092H021520566D560A5602CC6HFF0F092H02BC2H0902752E602E02E401093H022B420280010902423E583E021E4542029001093H022B360204092H02152036BD02360A360204092H021520362H022B3A0204092H0215203ABD023A0A3A2H022B3E0204092H0215203EA5023E0A3E0204092H0215203E2H022B420204092H02152042BD02420A420204092H0215204202064546CA018E0270C63H022H420204092H029E0270422H02443E02F8FE5HFF0F09026D420A422H022B46026C092H02F101643A0254092H029CF35HFF0F253A028001093H02423A1A3A5D3A02000902193A783A02E46HFF0F093H0244360204092H02AE0570362H0244320204092H02D603703202062B360204092H02152036B902360A3602B06HFF0F093H022B32FD01320A3202A4FE5HFF0F092H029D02643E0210093H0244420288FE5HFF0F09029902460A4602F06HFF0F093H02422H36326A322H02442E0204092H02AA04702E0A2E002E02D4FD5HFF0F092H02F0F55HFF0F092H02BCF45HFF0F4C42028804092H022HF05HFF0F09022E4E4D4E02A402254E02DCF65HFF0F092H02E806092H0280F25HFF0F093H0244560204092H02FE04705612562D5602C0F75HFF0F255602FC010902CA01920270E22H021409026D4A0A4A0204092H0215204A2H022B4E0250093H02425E0204092H02B602705E2H02445A02B86HFF0F0902CA01FE0170E23H02446202C46HFF0F09021E365D360200090221363F362H022B3AFD013A0A3A0204092H0215203A2H022B3E0204092H0215203EDD013E0A3E027C09026D4E0A4E0204092H0215204E2H022B52FD01520A520204092H021520522H022B560204092H02152056A502560A560204092H021520562H022B5AFD015A0A5A0204092H0215205A2H022B5E02000902DD015E0A5E0204092H0215205E2H022B626D620A6202E0FE5HFF0F093H022B460204092H02152046BD02460A462H022B4A02A0FE5HFF0F093H022B420204092H02152042FD01420A4202D46HFF0F092H02FC06092H02204C4E02F0EE5HFF0F093H02422H524E544E0228254E0220092H02F101645602C501645A02E46HFF0F092H02062B520204092H02152052B902520A5202E06HFF0F092H0298EF5HFF0F092H02FCEE5HFF0F4C4E02D407093H02443A0204092H029E02703A81023A393A02600902FD01320A320204092H021520322H022B360204092H021520366D360A360204092H021520362H022B3A0204092H0215203A6D3A0A3A0204092H0215203A2H022B3E99023E0A3E02A46HFF0F0902B5012A3F2A0200093H022B2EA5022E0A2E2H022B3202A06HFF0F090289023A603A5D3A783A02E4F15HFF0F253A02B007092H02B5026436028407092H02B8054C2E02F8F05HFF0F092H02B8F85HFF0F092H02DCF05HFF0F0902F606A60647CA0602A8F55HFF0F092H02A4F55HFF0F4C3202F06HFF0F090291024E274E0290EE5HFF0F254E0290070902CA019E0270D22H02F0F85HFF0F092H02BC06093H022B46FD01460A460204092H021520462H022B4A0204092H0215204A99024A0A4A0204092H0215204A2H02444602D0F05HFF0F092H02AD01643202B0EE5HFF0F0902F606CA0647D20602ECF55HFF0F092H02F901644202B0EC5HFF0F093H02443E0214093H022B360204092H021520366D360A36028401093H02443A2H0244362H0244320204092H024670322H02442E122E2D2E0200092H02D0F35HFF0F252E029001093H022B260204092H02152026BD02260A260204092H021520262H022B2A0204092H0215202ADD012A0A2A0204092H0215202A2H022B2E0204092H0215202E6D2E0A2E0204092H0215202E2H022B320204092H02152032E501320A3202E8FE5HFF0F093H022B3A02000902A5023A0A3A0204092H0215203A2H022B3E0204092H0215203EA5023E0A3E0204092H0215203E0E065D4202ACFE5HFF0F092H0288F15HFF0F0902CA01A20270AA2H029CF15HFF0F092H0280F35HFF0F4C3202B802092H02C101643202F06HFF0F092H02E803092H02E0ED5HFF0F4C4202B8E95HFF0F0902CA018A0270BE2H02F4F85HFF0F093H022B520204092H02152052FD01520A520204092H021520522H022B56020009029902560A560204092H021520562H0244520204092H028607705202C8F15HFF0F0902F606BA0647CE0602A0F15HFF0F092H02A0E95HFF0F093H0242560204092H027E702H56525452026409023A7D233A2H022B3E0204092H0215203EA5023E0A3E0204092H0215203E2H022B420204092H021520426D420A420200093H022B46BD02460A460214093H022B4E0204092H0215204EFD014E0A4E021C093H022B4A0204092H0215204A6D4A0A4A02D86HFF0F092H02C8EC5HFF0F255202480902060D1B5202240902413A3F3A02846HFF0F092H02D90164462H02423E2H02443A0204092H02DE06703A3D3A603A02DC6HFF0F092H02062B56B902560A560204092H0215205602F101645A0225645E02B8FE5HFF0F092H02F4FA5HFF0F0902F606C60647DE0602C4EE5HFF0F092H02B901643202BCF05HFF0F092H0294FE5HFF0F092H0205645602B8EE5HFF0F092H029502643A02ECE85HFF0F09028D012E132E02F001252E02D0EC5HFF0F092H0216453A02B8EB5HFF0F092H021E455602FCED5HFF0F093H022B2E021409029902320A320204092H021520322H02442E02140902FD012E0A2E0204092H0215202E2H022B3202D86HFF0F09021D2E782E0288EA5HFF0F252E02CCEC5HFF0F0902CA01A20270CA2H02ECF15HFF0F0902B9023A0A3A0204092H0215203A02F101643E023164422H02423A02A0EB5HFF0F092H02062B3A02DC6HFF0F092H020A454202B0EE5HFF0F0902CA018E0270CA2H029CE75HFF0F092H02ED0164322H02422A02ACEB5HFF0F092H02062B2A02000902B9022A0A2A0200092H02F101642E02DC6HFF0F092H0232454602D4ED5HFF0F0902F606B20647D60602E0E55HFF0F092H02E4F55HFF0F4C360284F15HFF0F09020A365E3602F06HFF0F2536020C092H02A901643E2H02423602E86HFF0F092H02D0F85HFF0F092H028C6HFF0F092H02AD02644602D8E55HFF0F092H02C4EC5HFF0F4C2E029CFB5HFF0F092H02D0EE5HFF0F092H021A455202F0EC5HFF0F092H02001F001D2H00A3423H0002A7424H00A2423H00644CD55C684H000823782H00E900D13H00014H00D1087H00D1037H00D1407H00D1107H00D12H00015H00D100016H00D1207H00C67001000234092H0230092H022C092H0217292H0201202H0221642H028207052H02B6070502BA01860141EA078E06B60605B201EA014600E60552AA0540CA05FE01E60354CE0336B6065EBA032H022B2H0204092H0201202H02062B060204092H02012006020A2B0A020A2B0E0204092H0201200E090E600E1612242H020E2B12020E4516020D641A2H02421201126B12020E2B16020A451A021D641E2H02421615166B2H16126112020E2B16F6069E0647B2060211641E2H02421619166B2H16126112020E2B160204092H02012016F6069A0647B2060205641E2H0242160204092H028207702H16126112C2078606478E062H021D02043H0003000200042H00A2423H000BEC5513C34H00121E782H004900D18H00D1017H00D1FF7H006571010002A802092H02A402092H02A002092H020F292H0201202H020D642H028607052H02A2070502B2034E59A606C207B60109AA062ED6015FCA0496013A21BE04EA05E2024D92058A07BA0565CA056EDA036DD2069606EA0770FA0502E801093H02153A0204092H029A04702H3A120D3A0204092H0201203A02D8014C3A0208092H020A2B3A02D86HFF0F092H0258092H0274092H02C005092H0200092H020A2B3A2H02153A0204092H02F203703A02FC02092H02062B3A020A2B3E0204092H0201203E2H02153E0204092H02AA01703E020A2B42020624420204092H02F60370422H022A3A0274092H02D002092H02C46HFF0F093H02151A0204092H029E03701A0205641E0210093H022B1A02E46HFF0F092H0205641602F06HFF0F092H020C011602C004402H02C86HFF0F092H027C402602D002401602ECFE5HFF0F093H022B060204092H020120062H0215060204092H02A20670060205640A0200092H02C86HFF0F012H0205642H02D46HFF0F093H0273023A366D120210093H02153A0200092H02C001253A0220093H022B360204092H020120362H0215360204092H028A017036020A2B3A02D06HFF0F092H0284FE5HFF0F092H02EC01401602F4FD5HFF0F092H020A2B362H0215360204092H02DA06703602D4FD5HFF0F253602B003093H02153A0204092H029606703A2H022B3E0204092H0201203E0206243E0204092H0242703E2H022A360204092H028E0570360206053A020A2B3E2H02153E0204092H02B606703E2H022B420204092H02012042020624420200090206023C2H3A366D12021C092H020E2B360204092H02012036020A2B3A02886HFF0F09023A366D1202E46HFF0F092H02E4FD5HFF0F092H02062B2H020A2B060204092H020120062H0215062H022B0A0204092H0201200A0206240A0204092H02BE03700A2H02632H0205642E0200092H02A8FD5HFF0F0126020164260200092H0209642A02E46HFF0F092H02062B262H022B2A0204092H0201202A2H02152A0204092H02E206702A2H022B2E0206242E2H022A2602062B2A2H022B2E0204092H0201202E2H02152E0204092H02D604702E2H022B32020624320204092H02F60670322H023H2A266D1202062B260204092H020120262H022B2A2H02152A0204092H02B607702A2H022B2E0204092H0201202E0206242E2H022A2602062B2A2H022B2E2H02152E0204092H029E04702E2H022B320204092H02012032020624320204092H027670322H023H2A266D1202CCFC5HFF0F092H0209641A0200092H0205641E02BCFC5HFF0F01162H0253120201641602E46HFF0F093H022B362H0215360294FA5HFF0F093H021D020400060004000700050300A2423H006D7EE0170D4H00071E782H009500D1017H00D18H00D1027H00C47001000238092H0234092H0230092H020F292H0201202H020D642H028207052H02B2070502A602DE0562B603A607A60717BE07EE074A6DA204DE062662AA06BE036600AA07A206CE014DBA02AA026A40B6070274250A01063F2H0E09232H0E024B0E010A3F120200090201063F1602080902120E5D12C606B20345BA0316125D1201126012020009021209232H120E330E010E3D1202DC6HFF0F0902C2078606478E060218092H02F46HFF0F4C120208093H021D2H02F86HFF0F092H0205641202E06HFF0F092H0201641202E06HFF0F09020E123A1202D86HFF0F25120218090201063F0E020009020E09233H0E612H1202331202DC6HFF0F092H02B46HFF0F0902000200A2423H00116FD13DA64H000A1E782H000900D18H00D1017H00D1027H00E2700100025C092H0258092H0254092H020F292H0201202H020D642H028E07052H02BA070502AA05FE010D8207D203EA0740FE029601C2017786029605B6045E86033696035CD206268E0325BA062H4E229602B607BE025EF207021C0902F606A60647AA068E048A0528920509023D2H12012C70028001092H0201640E023C092H0205640A02F06HFF0F092H0260090206012CD00102300902F6069E0647AA0602000902F606AA06479A060200092H0200092H02012CB86HFF0F02BC6HFF0F09020A0E6116F606AE0647A6060228092H02012CA001027C092H027C090209166E16090A6B1ACA01960270862H0204092H02CC6HFF0F0902F606AE06479A0602F46HFF0F090212025D1602DC6HFF0F09020A0E611ACA019602708A2H0204092H02B46HFF0F090212025D1A02280902090A6B2202180902091E6E1E02F06HFF0F0902CA019A0270822H02000902CA01960270FE0102100902CA019E0270862H02E86HFF0F0902091A6E1A0204092H02846HFF0F090216065D1E02CC6HFF0F092H02C8FE5HFF0F090209023D1209063D1602000902161208A86HFF0F02B0FE5HFF0F093H021D2H02B4FE5HFF0F0902060241C4FE5HFF0F02F46HFF0F09023H00A2423H0036D21C432A4H000926782H001500D1147H00D18H00D1157H00D1027H00D1FF036H00BA6H00F041D1017H00D11F7H00D1207H00BA6H003043D1FF076H00EE700100028001092H027C092H0278092H0217292H0201202H022D642H029207052H02A6070502CE07AA0137C207D6010E5CB2021EA603338A06FE01CE050EC207B202CE0641F605B206FA2H04BA070248090219166B1A051A6E1A02D801093H021D0205166B1AC606B20345C203050E131A02C401251A02DC6HFF0F09021A0D232H1A16211A250E6E2H1E0A612H1E1A211A0208090211123F1A02E06HFF0F093H022F1A2H022B2H0204092H0201203H02152H0204092H02BA06703H022B060204092H020120062H0215060219640A02062B0E0204092H0201200E02064512021964160201641A02123E0E0204092H02AE06700E150E6B0E020E610E02062B120204092H02012012020645160209641A021D641E02123E120204092H029203701202062B16CA01820270962H0221641E2H02422H1619231602166216051257240228092H02044C1A02040902C606B20345C20305166B1A02000902051A6E1A0200092H02E86HFF0F0902291257B4FE5HFF0F022C092H0204092H02A8FE5HFF0F0902050E571402F4FD5HFF0F092H0205641A0200092H021A450A0290FE5HFF0F092H0219641AF606B20647AA0602E46HFF0F092H02DCFD5HFF0F092H02000600050001DCD73CDD4H000A21782H00A500D1017H00D1087H0007063H005425DAF1154107043H0096AFCC5D2H073H00921B686BB7B32107093H00D54AB3139574B6D24AC870010002A801092H02A401092H02A001092H0223292H020D202H0219642H028E07052H02BA070502A604A20233A207CE01960305BE04A604D20520DA02EE02E6032516F602E60565DE0412E60662CA03CE06D20509669A07B6042D8A0592059A0447BE01AE04820424EE069E075E25A203025C0902F606BA0647BE062H0215260200092H02042526021C093H021D3H0251260204092H02FA04702602D86HFF0F0902CA019E0270A22H02E86HFF0F092H02F46HFF0F092H0206450E020D6412020564160228090211020A2H021520060204092H020D200609060A060208092H0215202H02E06HFF0F092H0201640A02C86HFF0F093H02420E0204092H02E201700E020F2912020B29160203291A0213291E0207292202F0FE5HFF0F09022H003ED1F746504H00021E782H00A900BA6H001440BA8H00BA6H00F03FB6700100026C092H0268092H0264092H0217292H0205202H0211642H028E07052H02B2070502F204DA064BEA07C204AE04088205AA07AA064C2E8201A20522AE2H02920155EE05EE038A040582050234093H02730206020D3H0253060205640A02140902EE04E2062FDE06020A0E2H0201640602E06HFF0F092H021C010ABA052E703A0209641202F06HFF0F092H0203292H02062402EE04DE062FDA0602D06HFF0F092H0208400A020C093H021D0206166D2H02EC6HFF0F092H02FC6HFF0F0902000100A3422H000100A2423H0082EDA0006D4H00031B782H00DD00A47001000240092H023C092H0238092H0217292H0201202H0205642H028E07052H02A2070502AE06C604419201D203B60217CE03DE02C2060ED602C2077234C601DA05C6045CCE028A01EE0317CA06C207820433EE01FE01CA026AEA02AE03D20445E605CA01FE0170823H0218062H021D020100070015BF3216A74H00101F782H000D00D18H004DD1017H00070A3H00021B60DB46B2C896B3E95B710100029805092H029405092H029005092H021B292H0205202H0211642H028207052H02A20705027E960671CA06568E035C9A02F6059E0309D605E6048E0645A6013EFE0454BE020E9A060EB607E202860440FA01D606AA044BC207C603E2040D8A0502D404092H0284030902F606AE0647D60602E001093H026F3602222B360204092H02052036020A453A02E06HFF0F0902CA01AA0270BA3H026F360230092H022E453AF606CA0647D6062H026F3602000902CA019E0270B22H02CC01093H026F360204092H02A201703602222B36F606BE0647D2060270092H02222B3602C86HFF0F09020116602A0224093H026F360204092H02D602703602222B360204092H02052036F606B20647D206F606B60647D60602200902011A602E011E603202222B360204092H02052036F6069E0647D206CA01860270BA2H02D8FE5HFF0F093H026F3602222B360204092H02052036F606BA0647D206CA01A20270BA2H02F8FE5HFF0F0902F606C20647D6062H026F360204092H029603703602222B36F606C20647D20602B8FE5HFF0F093H026F3602222B360204092H02052036CA01920270B602CA01960270BA2H02E8FE5HFF0F090201066022010A602602D4FE5HFF0F093H022F36020E2B222H025122024C092H020E2B160204092H020520162H0251160204092H02BA067016026C092H020E2B222H0251220204092H02A2027022028803092H020E2B220204092H020520222H0251220204092H02A207702202986HFF0F092H02D8024C0A0218092H029C6HFF0F092H02C402093H02512202F46HFF0F092H020E2B2202F06HFF0F092H020E2B222H0251220204092H020E702202A802092H0205641E0218092H02122B160204092H02052016CA01FE01709602090E601E0238092H021E2B22F6069A0647BE06020D642A0203292E021236220218090209123F2A0208093H022A1A02B86HFF0F092H0212241E02F06HFF0F092H02F8FE5HFF0F4C060230090209123F220200092H02123E160204092H02A202701602162B1A02080902090E602602BC6HFF0F092H021A2B1ECA01FE01709E2H02EC6HFF0F092H02C8FE5HFF0F092H020E2B160204092H020520162H0251160200092H02E4FE5HFF0F4C1202D8FD5HFF0F0902F6069A0647A2060238093H022B0602F06HFF0F093H02420A0204092H02AA04700A2H02150A0204092H029A02700A020A2B0E0204092H0205200EF6069A0647AA06020D64160224092H020D640E2H0242060204092H029601700602062B0A02000902F6069A0647A606020D641202AC6HFF0F09022H0E240E0204092H02CE05700E02846HFF0F4C0E0214092H02144C1A02F4FC5HFF0F092H02F46HFF0F4C1602ACFA5HFF0F093H021D2H02D4FE5HFF0F092H02A8FC5HFF0F4C1E02F0FC5HFF0F0902090028002700260042002400210022002300462H00A5422H000103A2423H004263431F8E4H00051B782H000900A77001000248092H0244092H0240092H0217292H0201202H0205642H029607052H02B2070502E203F6034DBA04BE02D20334AE05FA02C201285EF201560EA204B202DA03778606A601DA075C9A01EA07C20117AA04DE07E60433E601A6068A03618A02BA04A2023AF6010AA2014DCA05E603DA034CDA032H022B0E020E380A2H021D020100030200A2423H00A088EE726F4H00041D782H00110048014800A37001000230092H022C092H0228092H0217292H0209202H020D642H029207052H02A60705024EE20733FA07FA02FA0521B205EE07BA043B8601AA01C20645A2014EA206340A2H02530A0502260A0106260A020A0D0A8E048A05288A052H021D022H0003A2423H00CEB7BC651B4H00031B782H000100A57001000244092H0240092H023C092H0213292H0201202H0205642H029607052H02AE070502BE07DE0365C607D603960124EE04C207820720E6079203EA045CF2018601C20561C601BE06A2024E8E03E604860546AE04BE03B2056AAE06FE04A2035EBA038E01BE0105F6042H0243062H0273062H021D022H00B8BA3A167A4H00192F782H009D0007043H00B8D9164E07083H00E4D5A2048FFC81934D070B3H007C0DFA0CB72AA901772426070E3H004B0001C1B8C118DE226CD814332107093H00B5023B6F2E2DB6B08107083H005A334876793C0147480107083H00B22B60BEA1AA793107083H000A2378C6894FCBE2070D3H00621B900EF1C353BECE61C167E107083H002FD4054D54A1A53A2H073H00A76C3D355CB41C074H00070D3H00361F042A9D2H954667F9F8C8622H073H00F308E9B9505891070A3H0072EB20FEE1EEA279AF9B2H073H00385996A03B3053480007083H00DB5011312898E40C817101000244092H0240092H023C092H0223292H0251202H0245642H029607052H02A60705029A07CE0655CA02CA02B60274FE057A86040EEA01D607F60632EE059E01EA067482028A06CE0246FE01AE07EA024B9A068A049E0762D207CA02423A9607D206E60741EE01020B292H020729062H02530A2H022B2H0E29060A0215060A022D060A0219060A0221060A024D060A0205060A0225060A0245060A023D060A0231060A020D060A0241060A0239060A4911720A02062B0E2H025312F606A20647AE062H02420E020A2B12F6069E0647AE06CA018A02709602F606A60647B606CA018A02709E02F606A60647BE06020E452AF606A60647C6062H02442A0204092H02E607702ACA018A0270AA2H0206242E2H02241E0204092H02B206701E2H022A160204092H02F6017016021D641A2H026F120204092H02E6067012020A2B12F6069E0647AE06020E451AF606A60647B606020E4522F606A60647BE0602221622CA018A0270A22H0235642A022616260235642AF606A60647C606022A162A0212241E0204092H0232701E2H022A16021D641A2H026F120204092H0286057012020A2B12F6069E0647AE06F606A60647B2062H0E611E2H0E21220E224B222H0E302H2622332H221E5D1E2H0242160204092H02CA017016021D641A2H026F12020A2B1202064516CA018A02709602F606A60647B606020E4522CA018A0270A202CA018A0270A63H02152A0204092H028603702AF606A60647C606020E45322H02442ECA018A0270AE02CA018A0270B202F606A60647D206020E24320204092H02820570322H02241E0204092H02A203701E2H022A16021D641A2H026F122H0E5E120214251202B40309022H0E2D1602B40309022H0E3A1A022809022H0E4D1602A403251602E46HFF0F09021E0E6D0E020A2B1EF6069E0647BA06F606A60647BE060268092H0206452202AC01092H020A2B1E0204092H0251201EF6069E0647BA0602CC010902CA019A0270BA2H02E40109022H1E614A02100902CA019A0270B22H02000902CA019A0270B62H02B80209022H1E5D4E2H1E21520218092H020A2B1E02B06HFF0F092H0242164202C8010902F606B60647DA06028C0209022H1E4B5602F401092H0203292AF606A60647C606F606A60647CA06020E242A0204092H02CA04702A2H022A22021D64262H026F1E0200092H0235643H1E5E222H1E2D262H1E4D2A2H1E542E2H1E3A3202806HFF0F0902F606B60647E206025C09022H0E0D26020E452A2H0242220204092H02127022021D642602580902421E6D0EF606B60647DA06025409024A3E593E1E0E0D4202E86HFF0F092H020E4526F606A60647C206024C093H02421E0204092H02DE01702H1E0E6D0E02C0FE5HFF0F0902CA019A0270BE2H0228092H024616460201644A024A451E0284FE5HFF0F092H0235644602846HFF0F093H02421E02BCFD5HFF0F092H023564460298FE5HFF0F0902F606B60647DE060214093H0242220204092H028E067022021D642602A06HFF0F0902CA019A0270C62H02806HFF0F09022H1E305A2H1E335E0929720A2H021D02423A593A02A8FD5HFF0F092H02361636CA019A0270B62H021E453E02D4FD5HFF0F09022H0E5C1202D4FC5HFF0F09022H0E541A02F4FC5HFF0F251A02C0FC5HFF0F0902030042001000460103A2423H0029B7060D844H00051B782H004500BC70010002A401092H02A001092H029C01092H0213292H0201202H0205642H029607052H02A60705025282045FF606FE06A20104CE01BA06FE0122B203A601064DE2040E8A0445EA03A207DE06719A06B605C2024AAE070268093H02670A0204092H02F604700A02340902F6069A0647A60602E86HFF0F092H02062B0A0200093H02450EFA01EE0275FE3H025A0A0204092H02CA02700A020A2B0A02D46HFF0F092H02D86HFF0F092H0204093H021D3H022B0A0204092H0201200A020A0D0A0204092H0201200A02E06HFF0F4C0A02D46HFF0F092H02D86HFF0F252H02D06HFF0F090203004A0048004B0203A2423H0070397761B84H00091D782H00110048014800C5700100028001092H027C092H0278092H020F292H0209202H020D642H029607052H02AE070502FE07E2015FF203CE06AE0335CE07069A056D8205E6078E024112D202F2032DAA01A2048E064CEA03F202F601471E9201DE0124F6039606860165C204DE077659AE030238093H021D3H0273160224092H02062B1A0204092H0209201A0212451E2H0245220200093H02421A02DC6HFF0F092H02DC6HFF0F092H0201641E020E32162H022B0E0204092H0209200ECA018202708E3H024316020009020E02240E0204092H029605700E02062B160218092H020564222H02421A02C06HFF0F251A02100902CA018A02709A2H02E86HFF0F092H02062B1A02F06HFF0F092H02A46HFF0F092H02001A00460700A2423H002C741B12B84H001B59782H002500D1752D2HF67F510600D104C51A9ADA63FBFFD17495FCF077840B00D1F5DD1539B2452HFF07093H00D38081D3912HACC100070B3H007859DE90BE342D67F23516D16H001000D160572D43F77F0800D1C200E7379B35F3FFD11BB3F5C54523F1FFD1076DD9C969CD060007053H002FCC7D62F207063H0068094E2H26A6070B3H00CA3360A363D632E22CCC58D10F55B52C12F20300D1E4825AD46BC2F8FFD1EE234FC448050A00D1651EF43DC178F3FF2H073H00B9BE7757E0530F070B3H005091F6CDF4ED1DCACF6B2ED1027H0007083H00A72435CCFF2F2E14D1E95D2H45943D0700D183D3830E6E350800D11D84F5BC1BBA2HFFD1C0FCB035A19E0600D19E3D6D91531BF7FFD168FED648E97B2H002H073H00BF9C8D0F445C7FD1BE6567D41FCD0C00D1AD4A0C0B9E3DF0FFD10BDF86B4AF7B0800D1A20E19514H00070B3H009ED7141C63AD055048E98CD1918C5AA9E5E30600070B3H003DD25B9D53761BB51F82F3D1CDC87CF101E90A00D1B6665F0AEA7BF8FF07063H0020A146721D95D15AFE2CA1495D2H00D12310CA18F971F6FFD1050A4B3832AA0400D1017H00D11CA9943A4H00070B3H00428B188FD13331AE1F2210D13D3FFC796826F6FF07063H0051B64F50F48AD1F4DC95532H000200D1F38A89F524FFF9FFD108C2999AB92DF1FFD11308606E2086FAFFD1FF036H00D13B3914CC83E40400D1A5388E829CA50E00D1EC9E2395C9B6FEFFD1EDB98F2DA82E0A00070B3H00BB0829D0E22272404C0D01D14E20C8E4DFFDF3FF07063H00267F5C204B85D169D0500DF218F2FFD1904077FEF3630A00D181959229CE55FBFFAD73010002CC03092H02C803092H02C403092H0213292H0211202H02F901642H028E07052H02BA070502D604A20262A202EE04AE030ED205F203A60500F207F206DE060E9A03A607BE0125DE04AA01FE013736D2014A41F60662CE0174B204F60492063AB6069E040235C62H028403092H028810093H0244220200092H0222612202E803093H02422E0208092H021A453602F06HFF0F093H02442A02F80209029901260A2602C802093H0244360200093H02443202D86HFF0F093H022B2A0204092H0211202AE9012A0A2A0204092H0211202A2H022B2E312E0A2E0204092H0211202E02D90164322H02442E0204092H02CA05702E022E612E02ED0164322H02422A0210090299012E0A2E02BC01090226225D2202800109020E2A612A02DD01642E2H0242260204092H02D20470262H0244220204092H02DA01702202226A222H022B260204092H0211202655260A260204092H021120262H022B2A2D2A0A2A0204092H0211202A2H02442602A46HFF0F090249260A2602E001093H022B3271320A320204092H021120322H022B360204092H0211203655360A3602180902CA018E0270A23H02421E0204092H02B605701EF5011E3F1E029001092H0269313A013A393A293A3F3A02F0FD5HFF0F090231220A222H022B2602A06HFF0F093H022B320204092H0211203231320A3202062B3611360A360204092H0211203602B901643A028D01643E029401093H022B2A028001093H022B1E0204092H0211201E99011E0A1E0204092H0211201E2H022B220208093H02442602D8FC5HFF0F090271220A220204092H021120222H022B26E901260A260280FD5HFF0F0902A5011E3F1E2H022B2202F4FE5HFF0F093H022B2602D4FC5HFF0F093H022B2A0204092H0211202A312A0A2A0204092H0211202A2H022B2EE9012E0A2E02FCFD5HFF0F09026D223F2202CC6HFF0F0902E9012A0A2A2H022B2E022HFC5HFF0F093H0242360204092H028A0670362H0244320204092H02F20370320E325E3202840B253202A40F093H022B3A0204092H0211203AE9013A0A3A0204092H0211203A2H022B3E025C093H022B360204092H0211203671360A3602CC6HFF0F093H022B2E021809029901420A420204092H02112042121E2D46028801254602340902312E0A2E0204092H0211202E2H022B320204092H0211203249320A3202AC6HFF0F0902592A602A02B86HFF0F0902713E0A3E2H022B4202B46HFF0F092H029412092H02164552028C2H092H02D80C092H02F4114C3A02E80C093H0242460224093H024446F606C60647E2060200093H022H4202062B4611460A4602B901644A0235644E02D46HFF0F090246425E4202F407254202DC0D092H02B40E4C4602D407092H02C40D092H028C0D092H02062B4A0204092H0211204A114A0A4A0204092H0211204A02B901644E024D64520200093H02424A0204092H028A02704A02B80B092H025D644602B46HFF0F093H02443E0204092H02BA02703E0E3E003E2H02443A0204092H024E703A2H0244360204092H026A70362A363A3602C407253602A02H092H0280024C2E028011092H02DC0D4C4E028011092H02FC0B0902CA01920270BA2H02FC07092H02B0FE5HFF0F4C4A0298FE5HFF0F092H02B807092H02044C3A02AC0309022A3A2D3A0288FE5HFF0F253A02980E092H023D642A02D8FD5HFF0F092H0204092H02840B092H020A454A0204092H02E46HFF0F0902224A544A029C0A254A02ACFE5HFF0F093H02445602B8010902E9014A0A4A0204092H0211204A2H022B4E99014E0A4E0204092H0211204E2H022B520204092H0211205249520A522H022B569901560A562H022B5A99015A0A5A02A101645E025C090271360A362H022B3A313A0A3A2H022B3E0204092H0211203E553E0A3E0204092H0211203E2H022B429901420A420204092H021120422H022B460204092H0211204631460A460204092H021120462H022B4A02E8FE5HFF0F0902AD012E3F2E029801093H022B620240090255320A320200093H022B36028C6HFF0F090256525C520220093H022B660204092H021120662D660A660204092H021120662H0244620210092H02F8042552028001090255620A6202D06HFF0F093H02425A0239645E2H0242562H022B5A0204092H0211205A555A0A5A2H022B5E0204092H0211205E2D5E0A5E0204092H0211205E2H02445A0204092H02DE01702H5A5600560208093H022B3202E8FE5HFF0F093H0244522H022B5649560A560204092H021120562H022B5A0204092H0211205A2D5A0A5A0290FD5HFF0F092H02DC07092H02D4FC5HFF0F093H022B3A0204092H0211203A553A0A3A2H022B3E2D3E0A3E0204092H0211203E2H02443A02D46HFF0F092H023E583E02062B4211420A4202B901644602E101644A2H023H423E6A3E123E2D3E02F003253E02AC08093H02422A0D2A602A021009021A2A5C2A0200092H02B006252A022809020A2A002A02E86HFF0F09020932563202D10164362H02422E0204092H02DA01702E022E582E0221643202BC6HFF0F092H0298FA5HFF0F09029901360A360204092H021120362H022B3A0204092H0211203A713A0A3A2H022B3E0204092H0211203EE9013E0A3E0204092H0211203E2H022B4231420A420204092H021120422H022B4631460A460204092H021120462H022B4A02000902E9014A0A4A0204092H0211204AB50126784E02A4FA5HFF0F254E02280902CD01323F3202000902325123322H022B3602F8FE5HFF0F093H0244320204092H02F6017032810132603202D86HFF0F092H02FCF95HFF0F0902F606AA0647C60602E4F95HFF0F093H022B4A0204092H0211204A554A0A4A0204092H0211204A2H022B4E0204092H0211204E2D4E0A4E0204092H0211204E2H02444A02F82H0902CA019E0270B22H02C008092H02C901644602D406092H02EC6HFF0F092H027D643202E82H092H02D8F85HFF0F4C4202B004092H02DCF95HFF0F4C4A02C4F95HFF0F092H028404090249320A320204092H021120322H022B360204092H021120362D360A360204092H021120362H0244320204092H02AA06703202EC04093H022B3202C46HFF0F092H02B8FE5HFF0F4C3602C801092H02FC074C52028806092H024164360260092H02B403092H02C003093H022B2A0204092H0211202A552A0A2A2H022B2E2D2E0A2E0204092H0211202E2H02442A02D46HFF0F092H02C101644A02E8FE5HFF0F0902F606B60647CA060210092H029C044C3E02D4F05HFF0F0902F606B60647D60602DCFB5HFF0F092H02A4FC5HFF0F4C3202D8F65HFF0F0902CA01920270B22H02886HFF0F0902F606A20647D2062H02423206322D3202DC03253202B8020902493E0A3E0204092H0211203E2H022B420204092H021120422D420A420204092H021120422H02443E0204092H02EE03703E02B803093H022B3E02C46HFF0F0902CA01960270A62H02CC010902F606B20647CE0602E4FC5HFF0F092H02E8054C4A02A8F75HFF0F092H028C6HFF0F092H02F8FE5HFF0F093H02423A0275643E2H024236028001090265263F262H022B2A0204092H0211202A99012A0A2A0204092H0211202A2H022B2E0204092H0211202E312E0A2E0204092H0211202E2H022B320204092H021120329901320A322H022B360204092H02112036E901360A360204092H021120362H022B3A99013A0A3A0204092H0211203A2H02453E020E454202F8FE5HFF0F092H02E804253602380902910136663602F06HFF0F092H02B901643202850164362H02422E0204092H0276702E2H02422602DCFE5HFF0F092H02062B2E0204092H0211202E112E0A2E02D06HFF0F092H02F0FB5HFF0F092H02E46HFF0F4C2A028CFE5HFF0F092H02CC054C4A0298FB5HFF0F092H02B0FC5HFF0F092H02D501644A0288FE5HFF0F092H021D643A0290F55HFF0F092H029501644A02B0F35HFF0F092H02F8F25HFF0F4C2A02ACF55HFF0F092H02256442029CF45HFF0F092H02F003092H02FCF25HFF0F0902114A0A4A0204092H0211204A02B901644E021564520208092H02062B4A02E06HFF0F093H02424A0204092H02DA01704A029C03092H0298F85HFF0F4C3E02B4FD5HFF0F0902114E0A4E0204092H0211204E02B90164520200092H02B10164562H02424E0208092H02062B4E02D86HFF0F092H02ECF35HFF0F092H021E452A02D0FE5HFF0F092H02B0044C3202BCFA5HFF0F093H021D2H02F4F35HFF0F253A0210090289013E563E2H02443A453A0C3A02E86HFF0F092H028CFB5HFF0F092H02C0FB5HFF0F092H0216453202F8F75HFF0F092H02B8F35HFF0F092H0270092H0205643E02806HFF0F092H029CFB5HFF0F092H027964420214093H022H420204092H02CE0370422H02443E02E46HFF0F093H02423A0204092H02A607703A2H0244360204092H02AE0670362H0244320204092H02B60470322H02442E0A2E6A2E020C090212466A46F606BE0647E20602B06HFF0F09020E2E5C2E02B4F25HFF0F252E02C8030902F606B20647DA060298F95HFF0F0902F6069A0647EA0602E8010902F606B20647E20602B4F25HFF0F093H022B5202340902F1014A394A2H0244460204092H02E60670462H0244420204092H029E027042F606B20647DE060200093H02423E063E543E02C8FD5HFF0F253E022C090249520A522H022B562D560A560204092H021120562H0244522H02424A0204092H02E603704A1A4A004A02A06HFF0F092H028CFE5HFF0F092H0200092H02E501643A02E0EF5HFF0F093H022B520204092H021120522D520A520200093H02442H4E4A2D4A02F8F75HFF0F254A0214093H022B4E0204092H0211204E494E0A4E02C86HFF0F092H02CCFD5HFF0F092H0298F95HFF0F4C3602ACF85HFF0F092H029D01643A028C01092H02E8F95HFF0F254A0248093H02424A0204092H02AA07704A164A2D4A02E46HFF0F092H020645562H02424E0200093H022B520204092H0211205249520A522H022B560204092H021120562D560A562H02445202B86HFF0F092H0280F75HFF0F0902363221320210093H022F3219366E36A90136603602E86HFF0F090232A9010B3202E86HFF0F0902F606B60647D6062H0242362E366A362E366136BD0136603602D46HFF0F0902263A6A3A02000902223A003A02D86HFF0F092H02F8EE5HFF0F0902164A4D4A02C8EF5HFF0F254A0288FD5HFF0F093H02442E0204092H02A607702E0261643202080902262A6A2A0208093H02422A02F06HFF0F09020E2A2D2A029CFA5HFF0F252A029CEF5HFF0F0902F606A20647C60602F4F05HFF0F092H02C501644E02D0FC5HFF0F092H02F8F45HFF0F092H02001F001D2H00A2423H008A063B772B4H00051B782H00CD00B77001000244092H0240092H023C092H0213292H0201202H0205642H028607052H02A2070502D607A20328C207EA05EE0225D2022EDA061EC204E207AE07349205BA033E1EAA038A07BE065EF205020C093H02733H021D3H02633H022B2H0204092H0201203H0253060220092H02062B120204092H02012012020624120204092H02920570122H02240A02C86HFF0F093H022B0A0204092H0201200A02062B0E0204092H0201200E2H02150E02C06HFF0F092H02001000440107A2423H00610AE810254H00031B782H000900A57001000248092H0244092H0240092H0213292H0201202H0205642H028207052H02AE070502C60182070ED601DE01F20368B206F606860341C6035A2A21CA028E05920720EE0592039A0734BA01C201FE0762AA03DE029E046DAE06CE02FA042DFE2H0204093H021D2H02F86HFF0F252H02F46HFF0F0902000100A2423H00BF51BD34614H00041C782H0051004DB9700100025C092H0258092H0254092H020F292H0205202H0209642H029A07052H02BA0705029E058A05742AA6061E08EA04CA04E60604B204B601820620C606EE074A4B22D602A2010D9203A206DA055CA604DE01BE03008606AA0482054D8A070218093H022B060204092H0205200602060D06020C4C060228092H022C252H02E06HFF0F0902CA01820270FE0102062B060204092H0205200602060D060200092H020C250602180902F6069A06479E0602D86HFF0F093H021D2H02062B0A0102260A02F06HFF0F092H02F06HFF0F092H02003C004A0100A2423H00980C3004744H00051B782H006D00BD7001000278092H0274092H0270092H0217292H0201202H0205642H029207052H02AE0705028605D20734C205C6043E099A04AA071234A601CE059E01649607EE01FA0677E2040244092H026C093H022B060204092H0201200602060D060204092H02012006022C4C0602DC6HFF0F092H02062B0A0204092H0201200AF6069E0647A6060E026D0A0230093H02530602E06HFF0F092H0224252H02B86HFF0F0902CA01820270FE010208092H02144C06020C092H02062B0602060D0602EC6HFF0F092H020C093H021D02CA01FE0170822H02D46HFF0F092H02C06HFF0F092H02003C004A2H00A2423H007998C625324H00021C782H00A500077E3H00F8D9DE4EBBD02823BCC4770F299364F29AE6202AA13BBE13840EE32C1CC3EDBFF84ACB07C46A4817F07D99EE487D9D89E88541C6C0C6DEE1A9AF01933C790A4ECAFCF8B8E6003ABADF04F68E7ED8F22EC6286C6BE135FE9C8054357ADC21372HF989161007E5DD6FC099E901A342E7EBDEE8A23221264D73EDE0450DB3E3A47001000234092H0230092H022C092H0217292H0205202H0209642H028E07052H02BA070502DE07A20262D604E606C20770CE04F604B6055EF6079602BA023366FE048605589601A2022677E2072H022B2H020164062H02672H0204092H028606703H021D020100190100A2423H00365E32414B4H00051B782H005100B8700100029001092H028C01092H028801092H020F292H0201202H0205642H028607052H02B6070502C205EE06688204C202FA0238DE04FE04A60437BE01CA02E20708EA070AEE07019A058E0386044ABA07BA05CA0461B2055EA60274B603CE03860568C605AA01BA045482050248093H021D02F6069A06479E06C606B20345AE032H022B060204092H02012006F6069A0647A2062H0244060204092H028E03700602062B0A0204092H0201200ACA01FE01708A020E066D0AF6069E0647A206C207860647860602C46HFF0F093H022B0602B46HFF0F250602F06HFF0F092H020039003C0700A2423H00FDCC604DFE4H001B5D782H005100D1AE33BC3729822H00D1F24E7000966E0C00D1BE1877ED18410D0007063H0022C3B494E414070B3H009819EAAF0335BE025763B2D10B9593C92B14F8FFD1F4D7D69258150200D1017H00D14543A6FD32470400D19C6860794H00D119C771B85D3DFCFF070B3H005344853E67ABA9F20408CDD147A9CB9E05E80200D1EF3DDE4FB3DE0900D1DEB20FDF66F82HFF2H073H00DE3FF09C2D87B2D1303EBC52B537F0FFD16F528BC4229D2H00D1876DCFCA31790F0007093H0015A687CD577A4AFF36D1AB5A037308A6FDFFD10096169D99072H00D19B4B682A9AEC0D00D1027H00D140BDE2F69F99FBFFD10971607C4BECFDFFD16H001000070B3H006ECF80F2A373716CE61C48D1A60B5C951BBDFBFFD1E090B3B1689CF9FFD18D7BBBF8C23D2HFF07063H00C99ABB418C86D1B7CF0B23C37CF5FF070B3H005F1011D2B22H980217D959D1211B234F4D8BF4FFD13ABA9862748B0D00D1D38C02CD0E1DF8FFD129675FFAAB08F8FFD1FCBE79F72HFF010007053H002A4BBC0DE7D1DBD8209C0D510E00D1E5E837C28B74F2FF070B3H00EFA0A165625C9E61B262E9070B3H00BADB4CF26D2HD52B6C2114D12AE1D755C0D7FEFFD1899EF9A2F12FF4FF07063H0055E6C7951024D17DF319E74H00D102FA30973C830A00070B3H006BDC9D194C97022542A8E5D15B4990FCEE1EF0FFD142DB4776A6B6020007083H007657886FB694035FD1A37859749D640F0007063H003E9F506DCB7BD15DBA14F0D53EF3FF2H073H00347506847DF006D1D0CE3027CD46F2FF070B3H008BFCBDDF5A948423F9C105D1133DAADD614D0A00D1EABA6D1FE11CF9FFD11FB950488FA6FEFFD184822F4986AAF2FFD11A548BB82230F9FFD154C84AA8C6FA2HFFD1FF036H007573010002E412092H02E012092H02DC12092H020F292H0209202H028902642H029607052H02BA0705029606FE0640EA03C604C2010002EA0266243EFE01C202559E0186038E0401EA05FA06AE0333DE03CA07AA033AE60702A8120902615256520218093H02424A02F001092H02C50164460240090291013E603E029401093H022B56D101560A562H022B5A0204092H0209205A9D015A0A5A0204092H0209205A2H0244560204092H0212702H5652005216526A5202A001093H02423E0204092H029601703E2H0242360204092H02CA0270362A36543602D0142536028C01092H02526A5202FCFE5HFF0F093H02424A2H022H420204092H021A70422H02443E2E3E583E02F8FE5HFF0F093H02424E0204092H02B602704E0219645202D4FE5HFF0F093H02443A02062B3E0204092H0209203E4D3E0A3E0204092H0209203E02D901644202B8FE5HFF0F090226465D4602062B4A4D4A0A4A0204092H0209204A02D901644E0285016452028C6HFF0F092H029501645602A06HFF0F093H02444602D06HFF0F092H02A012093H02455A02AC12092H0284134C5602F808093H022B2E0204092H0209202ED1012E0A2E2H022B329D01320A320204092H020920322H02442E02C0030902F606AA0647CA06028413092H02AC130902CA01820270AA2H02AC0F092H02A80C4C3E02942H092H02062B424D420A420204092H0209204202D90164460254093H02442A02D002093H022B327D320A320204092H020920322H022B3602E402093H02422655266026029001093H022B3AB9013A0A3A0204092H0209203A2H022B3E0204092H0209203EB9013E0A3EF901CD011A42028C02092H02AD01644A2H022H420204092H02CE0770422H02423A0204092H02E207703A020A453E02680902492A602A2H022B2E0204092H0209202EB9012E0A2E2H022B32B901320A32028801092H02FD0164462H02423E02C4FE5HFF0F093H0242460204092H028602702H464200424542024202DC6HFF0F093H022B2A0204092H0209202AE1012A0A2A2H022B2E0204092H0209202EE1012E0A2E02A8FE5HFF0F093H0242360208092H02F4FD5HFF0F253E02A401092H02A101643A2H0242320204092H02F60170322H02442E0204092H02D606702E2H02442A0204092H028602702AB1012A022A02D8FE5HFF0F093H022B360204092H020920363D360A360204092H020920362H022B3A0204092H0209203AB9013A0A3A0204092H0209203A0251033E02906HFF0F0902CA01960270AA2H02C0FD5HFF0F092H02062B460204092H020920464D460A460204092H0209204602D901644A02A901644E02A0FE5HFF0F09027D360A3602A0FD5HFF0F0902392E562E02ECFC5HFF0F092H02DC0B092H02BCFC5HFF0F092H02EC0D4C5A02A810092H02F00B093H022B320204092H02092032E101320A320204092H020920322H022B36020009029D01360A360204092H020920362H02443202C86HFF0F092H0216452202A0010902F606BA0647C60602D00F092H02B501645602A8FB5HFF0F0902F606A60647DE060248092H02F0084C5A028805092H0216455A02F06HFF0F0902792E762E02F007252E02A8040902CA01960270A22H02880A092H02840A4C2602F06HFF0F093H02423622366A360248093H02423AF6069A0647D60602E86HFF0F093H022F32CA019A0270C63H022H420204092H02FA07704202810264460200093H02423EF606AE0647DA0602CC6HFF0F090269366E361D36602H3632212H321D0B3202C46HFF0F0902990136603602E46HFF0F09021A226122020964262H02421E0204092H02CA02701E0E1E581EED011E761E02FC09251E02FC02092H02D006092H02946HFF0F4C4602C0FE5HFF0F092H028101643A02640902E1014A0A4A0204092H0209204A2H022B4E3D4E0A4E0204092H0209204E2H022B520204092H02092052B901520A522H022B56B901560A5602100902325D2332028C01092H026D646A02A801093H022B5A0204092H0209205A0D5A0A5A02B8010902C10132603202A801093H024232027409024D620A620274093H022B460204092H020920460D460A460204092H020920462H022B4A02ECFE5HFF0F09021232613202C06HFF0F093H022B3A028801092H021164662H02422H5E5A3A5A0210092H02062B5E4D5E0A5E02D901646202E06HFF0F092H02B404255A028801093H022B360204092H02092036B901360A3602BC6HFF0F092H0232583202AC6HFF0F092H02D901646602D0FE5HFF0F093H0242620204092H028A027062022964662H02425E2H02445A02A86HFF0F09028502323F3202A4FE5HFF0F093H022B5E0204092H0209205EB9015E0A5E02062B6202C0FE5HFF0F09027D3A0A3A0204092H0209203A2H022B3E7D3E0A3E2H022B420204092H02092042B901420A4202A0FE5HFF0F092H0270092H02F4FA5HFF0F4C2E0288F75HFF0F0902CA018A0270D22H02800A092H02A501641E02F406092H0215643E02BC02092H02B4FB5HFF0F0902F606B60647C60602CCFB5HFF0F0902F6069A0647C60602BC030902CA018A0270D62H02A0040902CA01920270B63H0242320204092H0296067032890132663202B006253202EC03092H0294FB5HFF0F092H0205645202D02H092H02A4030902F606C20647D606028803092H02BC02092H02E46HFF0F092H02B86HFF0F0902CA01FE0170B22H02B82H092H02F8F55HFF0F092H0212451E02E406093H0242320204092H02F603703231320232F606BA0647CE060210092H028809255202E8010902CA01920270B62H02D86HFF0F093H02422E0204092H0216702E252E602E027409027D4E0A4E0204092H0209204E1259125202C86HFF0F09027D320A320204092H020920322H022B360204092H020920367D360A362H022B3A0D3A0A3A0204092H0209203A2H022B3E0204092H0209203ED1013E0A3E2H022B42B901420A42023C092H026564422H02423A0204092H029603703AF5013A603A0208093H022B3202986HFF0F093H0244360204092H022A703675363F3602D4FE5HFF0F0902DD013E393E02C46HFF0F093H022B460204092H02092046D101460A460200093H022B4A0204092H0209204A7D4A0A4A0204092H0209204A2H022B4E02B4FE5HFF0F092H02D8FD5HFF0F0902CA018A02709E2H02F003092H028C064C5A02D8FD5HFF0F092H0254093H022B5A0204092H0209205AD1015A0A5A0204092H0209205A2H022B5E9D015E0A5E0204092H0209205E2H02445A0204092H029E07705A02BC6HFF0F0902F606B60647DE0602A8F95HFF0F092H02B4074C2E02D8F75HFF0F0902C9013E0C3E02EC02253E02A86HFF0F092H0201643E02E002093H022B360204092H02092036D101360A360204092H020920362H022B3A0204092H028CFC5HFF0F09029D013A0A3A0204092H0209203A2H02443602E86HFF0F092H02CCF65HFF0F092H02E501643602D0F85HFF0F09022A5A5C5A02B0F65HFF0F255A020809020E5A585A02EC6HFF0F092H02D8F25HFF0F093H024236029C01093H022B260204092H02092026B901260A260204092H020920262H022B2A0204092H0209202AD1012A0A2A0204092H0209202A2H022B2E0204092H0209202EB9012E0A2E022C093H0242320204092H0282077032027164362H02422E222E002E020009020A2E3A2E0200092H029C01252E0248093H022B320204092H02092032B901320A3202062B364D360A360204092H0209203602D901643A02E901643E02DCFE5HFF0F0902F606B20647D20602A06HFF0F093H02442212225D2202225822BD01223F2202C8FE5HFF0F092H02D8F45HFF0F093H022B3602000902D101360A360204092H0224093H022B3A0204092H0209203A9D013A0A3A0204092H0209203A2H02443602DC6HFF0F092H02C802092H02D4F95HFF0F4C3602F8F95HFF0F092H02ECFB5HFF0F4C3E020C092H02B46HFF0F092H02FCF45HFF0F4C2E02A4F95HFF0F092H0294F95HFF0F092H02BC034C3202ACF05HFF0F092H02644C1E02F4F95HFF0F092H02D8F55HFF0F4C2202ACF45HFF0F093H022B1E0204092H0209201EB9011E0A1E0200093H022B227D220A22021A4526F606AA0647C2062H02422212226A2202225C220200092H02C06HFF0F252202C4FB5HFF0F0902D101260A260204092H020920262H022B2A022809029D01260A2602500902161E611E121E611E2H022B220204092H02092022E101220A222H022B2602D86HFF0F0902E1012A0A2A0204092H0209202A2H022B2E7D2E0A2E0204092H0209202E2H022B327D320A321AF101793602A4FE5HFF0F25360228093H02442202000902221E581E8D011E601E2H022B220D220A220204092H020920222H022B2602ECFE5HFF0F092H0284FE5HFF0F092H0294EE5HFF0F25560224092H0221645E0200093H0242560204092H02A60170561E5658560200090222563A5602D46HFF0F092H0280F75HFF0F092H02D8F75HFF0F0902CA018E0270A22H02E0F25HFF0F0902CA01A20270BA2H0298EE5HFF0F09022E5A2D5A02ACF25HFF0F255A0298F75HFF0F090206465C4602D0F35HFF0F25460264093H0244460204092H02BA0570461E466A4602E06HFF0F092H022D64622H02425A0204092H023E705A2H0242520204092H02C60570522H02444E0204092H028A03704E2H02444A02BC6HFF0F092H02062B5A0204092H0209205A4D5A0A5A0204092H0209205A02D901645E02B06HFF0F092H02E0F25HFF0F092H02B8EB5HFF0F4C520240092H02E0F25HFF0F4C360284FA5HFF0F092H023564362H02422E2H02442A0204092H02CE05702A2H0244260204092H02DE04702602263A2602A0F15HFF0F252602B4FE5HFF0F0902F6069A0647F2060290F05HFF0F093H021D3H022B52E101520A522H022B56020009029D01560A560204092H020920562H0244520204092H02DA02705202C8EA5HFF0F0902D5012E022E062E4D2E02CCF45HFF0F252E0208092H0241645A02B8FD5HFF0F093H02452E02B8F45HFF0F092H02001F001D00B2254928594H00694C792H00F900070C3H0096E7B052C529EB104A26B67CD1017H00D17FC8C98576B00900D1CB91794415A00300070E3H0052C3AC3E92C5696F9D05B346FB7DD1B0E07BBA78E1FDFFD1D5A6084D5129FBFFD19515FA0374700D00D1DA7109EFEBE30700D10FBB27BC0871F8FFD1B9AFF6EACFBC0C00070D3H0028E9A2E0886F5FE937FF389E54D10E3594510AFD0400D1D93278B4D3650100D108DA2DD559000600D11A3C29F2EA5FFCFFD1BC64EB427AAF2H00D1AE909F5CD04D0100D13294CA2H6150FCFFD1067H00070B3H0005DEEF8D2233ECC9228D57D150AACAAB8AB4F7FFD1A8A1073F4H002H073H00A0A19AA811BC42D15B2H26383DD50800D19901AB8756EDF7FFD188655751684A0100D1DF4CF7ACCEB30E00D15AFD148BF9840C00D1CC1C065C26E6F8FFD16FB06H00D1EA7278BE80320C00D1A182140433350100D103F634BFA608020007063H00BFC8892351EFD197DBF44749400200D11FD4460A0DA80700D127F96H00D1C0EC4BA795BFFCFFD17579F741355A0700D1657H00D1A4BA8FBA79B4FEFF07093H00BDD62793038FFAB0C0D1CCD1C39BFED90C002H073H007E8F1835FD6288070D3H008D26F72C2E5B0F6701BC36064E070E3H00E2D33C2E02B5F97FED15022C704B070C3H00B8F932E8DB7596F6B48B944ED13F53B8677B000300D17DB4005089150C00D1C2A232DC4H00D1C542B1C6AA052H00070B3H00B4156EE67E13C24CABF016D1C7A232DC4H00D14BFBC577AA800C0007133H006730B143A86290D0AC2CF0BD2D44A2095C2HE5D1432753B094D2F5FFD172BA19A854CE0300D151F626364H00070B3H007AAB5446A1C0715CC5157CD1BF525B3EE9ABF9FFD1ED0DF0C5F417F7FFD17A0AC651CBFF0F00D170DD586862610D00D1031A2D8475D5F3FFD17305399FF5AB0600D1AE42BA3A8B530600D1B65C85CE01DDF9FFD10727C3633F370F0007123H009DB607B734BE09C5F2330A8C580682AE0163D1EAACAF3AC4E9F5FFD1E6485A996C780600070F3H00D720217D2E8038CB4B297DA3D17058D18129774E0C4D0400D100016H0007093H0056A77097056929448A070A3H000F98D975E6186AC319B6D1EF37ECAEDF222HFFD1E9D7AF2D03940300D12HFCE7424B34F8FF070B3H00C1BAEBF28020BC9CC00D3DD1A652A69F07B1FDFF07063H00BCDDF63465F307103H000ABBE4B6EADD5117D50D6AC2347A0115D128FC0697C0070800D1EAE9C4158EBD0F00D13EE01AEED04AF6FFD1CC6889191553F2FFD119446H00070E3H005A8B34E69A0DE12765DD3F15F795D1077H00D1F5FFD67AFDDA2HFF070B3H00B031AA2FEB164A3DB17735D1538D50143AE2FBFFD101AE6H00D1E34502825794FCFFD13061DED818DCF3FF070E3H00C3AC4D95C37268944CFA57F76B4D07103H00E9A2939F7159E935B73F954771B78016D1036599754H00070B3H00B9F263BAEA0B3B0ACA97CB070B3H0074D52EF6939ED27D2HB6D6D12DE6C3CDC8360C002H073H0027F0718CF2AAC107093H007E8F1830FC7089FF52D199280388CB480600D16E7H00D1497H002H073H00F740415D0A7910D1B899C7AE995B0800D1AE1CA6A2EB68F9FFD1037H00D1A6A351C5327CFEFFD196D78D81D04D0100D1CFF91A1EED04F0FFD1B82946A3F30E0200D116DCE6699775F7FFD1A182DE6CB7DC0D00D1282H70A2684A0100D1027H002H073H00CE5F684787AB48D1C503F0ECA093F5FF07083H005D76C7F563F85416D15EA7726E754B0800D154D446EAAE58FCFF070A3H00451E2FDF9C46D1E943B0D1FC311CADD7CF0B00D1FA39EAC5A4A00300D176DF88604A520200D1A223ACE04592FDFFD1E6ABB2AB4H00D1FF7H00070B3H0097E0E1FCC42BDF50250FC9D10085009883C30600D11BD96H0007DB092H008273DCD03B3C6BBB0AFB24C59EEF78B9F2630CED4617A0A15A85149026B082450C3D52B39829FE71EA5B84A57E41D6175ECFE6422EF405075A0BDA5F8E1F6829E2933C1D768750D14A336E05DE2FB4F63AA0492880518081FAABB2D066F7C7864D7C94F5DE6433B42998C7EDB68012539E0F228D6637404176A41BBDC851826922D37C5DB6C790118A7BAB4F1E61FD591283EC0DA6F74024D60BF41BA63968A9E2B5DA3B10A176910ABB64459EC95B91D84F62C3A8798E8FB4E55EF06EFF88A16C13BC91F509FA51CABBE4855EAF3879B82CCCA300B700017A2B5435E47F4801C7FF1C7D56EDB837AC7B24055E6F9EDC1A89A003E6B7C0C1FA2B94354EDF28E9A25DF0D73E441599009B44C394EF78B3FE490CED4617A0A15A8B77992EB0E82962533CDD9C27FA77E25B88A37840D6155DC0E94B209760613C63D215EE7F084982F35C7D16E730D240376A0BD021B6F53DA52C4DE6378081FAABBCD560FAE28942739CFDD66733B12A98A485DEEF78539D63298D6834454F75A318BBC250A2652DDC7651B8CB9F19801BC4257E0F98591283EC0DA6924041BA6B9475CE5F68CA8CB0BC5D76C710916CD50420D4CF5899D2436CC2A67786E1DA8B34956EFF88A16773BF9DFC01D65BCCDB84E53EAC377FD243ACCD09D2656F164E54358E1F2869A2F6131D36E1B83DAA1B4869320196D71283A60886D7A0C2FA21BE354EDF28EAA253F2DB562770F16A9B44A5FE8F18B5FA6B098D2677C0C1598574952EBF844F62535FDDF621FA71E45DE4C51E2FB81F5ECDEF2D4697600E3C0BB470867F0849E49B33117E815CD145374E05D620B8F932AB2C2B8051E5E7FAABD4D361F3C8852270949DB60750BD2A9BC4E5BE8F185991634C826A3120477AA474D5AE3FC86527D0793DD6A7F071827BA4451E6FF2591283EC0DC09B2524D40BFA3FA13F08CA8DBFDF5D76C776F262D40B269EAF3896D2460CADC671E0E1DAE35AF50E9FE8A56473DC95F80DDF5BCABBE1E53EA53879B226ACCD66B700011F4B3455EE7F4809CA937C7B5EEDBE3FA41E426B140F97D61DE3CC0BEAB7C0C9FC4BF43642DF28E9AD33F3DD3A4D16F16A9B44C6988F18BCF16604E54377A6AB5A8414F54EDFE829043D5CBEF6479072EC3BE4C5784ADD7932A38C2D46F10C0E3261B47A8D356D2CEC955C1E768956B12A5B6705D14FD89952A64A4DE637E6EE94CBB4D562F0C0814D7990FDD6693FB74AFBA485DEEF7839F2632087603F2H4E7FCB74B6C459C80942DB7F55B8C99E1F867DA74F7E60D25977ED8A6BC6992641BA6BF21FAE3F08C98DB5BC5D76C710910ABB64459EAF38F9B2236AADC6748F89BF8B34956EFF88C90273DC9BFA07D059AADB84E53ECF5819D243ACCD09DB00017A2B5456E0794223C4F5107853E7BE37A01B44653E00F8B9728BA20DE6BBC8A19A4BF45548D020E6AD5CF3DE3E471F976A9B44A5FE8F18D992036C8D2677C0A95A8B78934EDFE82962533CDD902BF0798A3B82AF712FD01678CDE94725970801350BB415EE17682382F35C7D16E75FD14A3B6405D42AD89952C32C4DE651EEEDFACDB4D96DF3C8874413FC9DB60750B22A95C7EFBB89175591634CED063D40417AA174D5C850A26F28F97C53B0C89E12EA1BC4257E0F983572E38C67C0F74024D407F275CE3900C582B3DC3D1AAF75916FDD64459EAF38F9B2230CC5A87D8C81BAE434956EFF88C90273DC9BFA07D051CABBE4803ECF5819BC2DE6CD0CD76E647A2B54358E1F2869CAF31C7D56E7B031A41B4465366FF8B972E3CC6D86BFC0C1FA2B94354ED122E1A7559CBD562770F16A9B44A5FE8F7EB1FE630CE34919AAC15F8B749521DFE84C023D53979627907BEA5582C51E2FB87932C5E24D26F700013A6BD4758E1F6829EC9C3A7D16E75ADF4C5B0465BE4FD89934AF4C218C5DECEF9ACBB4D560F3C281447B92F8B60733B12FFBCEE5BE8378399703208E4C3740417AAD18B5C13FC80942B31C57B6C790118A7BA4451E6FF83972E38C6DC6972021D4089475CE5F68A9E2D3D63313C710910ABB0C299EAF38F9B2236ACDAA72888FBAEB54F50E9FE6AF0216BC91F52DD051CABBE48551AF3219D243ACCD05D760611A4B3455EE7F4809C2F31C7D56E7B031AA1B44653E0F98D91283AC0DE6B7C0C1FA2B94354EDF28E9A253FCDD364710910AFB24C59EEF78B9F7030AE34A148AA15A8B74952EB780490C353CDDF647FA71EA5B84A57E4FD81952C3EC4D26F700013A6BD4758E1F6829E2933C1D768750D14A3B6405DE2FB8F932A34C2D8657E0E19ACBB4D56EFFC8894270FCFBD86B339B2A9BC4E5BE8F1857940D2C816057202176AB14B5CE5FA86922D37C5DB6C790118A7BA4451E6FF83972E38C6DC6972021DA0BF415AE3F08C982B3DC3D16A770F16ADB0425FECF5899D24364ADA0798C8290EB54F50E9FE8A96213BC9EF807DE54AADBEE8551CF5876B223CCAD06D760611A4B3455EE7F4809C2F31C7D56E7B031AA1B44653E0F98D91283AC0DE6B7C0C1FA2B94354EDF28E9A253FCD256411E9D02D124C59EEF78B9F2630CED46172HAE5A8B77F52BB1884C623550B1952BF071EA5B84A57E4FD81952C3EC4D26F700013A6BD4758E1F6829E2933C1D768750D14A3B6405DE2FB8F932A34C2D893780ED94C49ED56EFFC88942739CFDD66730B12A91CCE5BE8C785C9C03228D6E5720211ACB11BAC25FA86922D37C5DB6C790118A7BA4451E6FF83972E38C6DC6972021DA0BF415AE3F08C982B3DC3D16A8109166D50E0FFECF5899D2436CCDA6778081BAEB54F50190E8A96773BA91F60DB031AADB84E53ECF3079BA43C9A208D760611A4B3455EE7F4809C2F31C7D56E7B031AA1B44653E0F98D91283AC0DE6B7C3A19A27943D64DF28E9A253FCDD364710910AFB24C59EEF78BAF86302EB2677A3AF5A8314F54EDF8E4708533CDDF64790118A5E8AA57440D61952C3EC4D26F700013A6BD4758E1F6829E2993213738D5ED72A5B6805D105B8F932A34C2D8657E0E19ACBB4D56EFFC8894273FCF7D66935D14AFBC1E9BE8317599C634CED065720211ACB74B9C05AC80942B31C58B6C99671EA1BAE451D0FFE377CE5EC67CA9D2024BA6BF21BAE3522C982B3DC3D16A770F16ADB0425FECF5899D2436CCDA6778F81BAE152956EFF88AC6E13BC9DFC0FD631AADB848350AF3B19D243ACCD0CD763017A2B3155E61F2803C2FF127D56E7BF51CA7B246F3E07B2D91283AC0DE6B7C0C1FA2B94354EDF28E9A253FCDD364710916AF82AC590EC18D992036C8D401FACAF5A8B74952EBF884902335CBD9627F071EA5B84A57E4FD61558CBE94B469760615A6DDA7B86356829E2933C1D768750D14A3B6405DE2FB8F932A34C2D8657E0E19ACBB4D366F1C889427D93F8B60750D14AFBA485DEEF7839F2634CED065720211ACB74D5AE3FC80942B31C3DD6A7981F8A73AC6F1E6FF83972E38C6DC6972021DA0BF415AE3F08C982B3DC3D16A770F16ADB0425FECF549ADD4962CDA6778081BAEB5AFB0293E4A56E1FB091F809DE5FCABBE4855EAF3879B223C0A205FD1D1C17461E07093H0075CE5F1D4792B25F3607733H0076C79031F85E10306C41988A57D7EA48A8E1C887AF65D761079066E1AC5DF2D4361555C55FA96AC59BBC70B7FC6D05ED0359E4AD5AD831C163FADC0856721EF1D32FAB71915981F67C32D80452CDE24326AA0C01616BAB0AC7512C6CBA93211D31C204970F75320DD621B6F73BAA4C708F5EE0D1779895CE6E1D0D00D10AC92570F064F4FFD12E3865D7767FF5FF07093H00C1BAEBE69439AC8DDDD18F6FB8C7C54D0500D1A864EED3E990F0FF070A3H006253BC82A92E7EF56FC3D1895AB29D810EFBFF070F3H00E4C59EC75716D94579C32563090E34D1113E75B63D3C2H00070F3H008B34959D1AFC2467873D09F785DC542H073H00AA5B8411473FBDD19A3799C99937F7FF07093H001952C3DE2C91D06575D1087H00D1ED831430908AFCFF07093H00FA2BD441F76F4D86C4D1CD5C5E9B7BE22HFFD101AA4DEE001C0C00D176B2B33B85CF0B0007093H0093FC1D4EF733B02697D1ECF105C5E047F5FFD1559B298D05E7F8FFD1912A85A22F43F3FFD18FCF53EFD0B5F2FFD14EB4C9C42A762HFFD1F3FF6672557FF3FFD103B284FB4F0E0200D1A7BDE6ABCD700C00D1BDAAF198212F0400070B3H002405DED6F5ACA439EFE986D1EF0AA02B4H00070D3H0057A0A1F3B818B642D0BBFC3056D170F0A3427B410500D1CBD1C39BFED90C00D1A7E17EF5E0FD0B002H073H009CBDD65082109AD135546H0007093H009BC4A519E2792DF16B070B3H00EC8D26B0F7644A5B7D7CCED1AE3CD46C4H0048002H073H005F682986A6512DD1FEE8F3E751A70300D1B89B0C7CFE6BF9FF070A3H0076C79076EF4F17207059D1057H0007123H00B8F932D0E959B4F6978CBF7FD5610F9D64ACD1881380AD9CF6F8FFD1E8C1ED5154330800D1047H00D1B6E06173F64C0200D17DCC41583069090007083H008273DC8D75065CDD07093H002ADB0496DBA33DFAA6D1FEFF2H044H0007103H00432CCD1543F2E814CC7AD263FEDC0A4A07063H00137C9DDB66A8D122C393084H00D16FD393084H00D13D3B919943C00A00D1146F75E5C1C32HFFD1F1DA7BEA903EFCFFD1AEAB92A34H0007053H0051CA7BD4ECD1ED7A196FF5210300D16CD393084H00D19A8319A801490C0007093H005E6FF85A1D8DAF0C72D19CC6AED3A7BCFDFFD16F4DA5FE45F02H00070B3H00D7202184285ECC2E4D4E09D1B0B69874CD650800D1DD6D067B8C0FF6FFD1963945CCECFA2H00070F3H00C2B31C4937C51C9444722A569B7DEC07133H00D912830F62D4182HB5D385F1DB2DAD8DC81636D1A63ADE379DBFF0FFD10C897C5741880400070F3H00BCDDF63371F366DECAA6F1C15B18C6D158BD3AD24H00D1F1260E9E0E0CF3FFD1257H00D1DDD2900CAA26FEFFD16F4AA70C9C6FFDFFD123336H00D18860FF2E8C730B00070D3H00230CAD3563120834EC1AE69B1D2H073H00884902912509F3D1BC20E0DFE924FCFFD1F2C5333421EEF3FFD1483FFB4E48430900D1725150F9A0F8F6FFD1125AB5E3A5F20500D1096AB998E3C40400D13AC22HCB53DD0C00D1E7A5C062933EF5FFD1E87E1B67A25C040007063H00E7B031C732EAD1AE01CD0DDDE6050007083H00653E4FBE753DACDED189275E865D2A0F00070B3H004DE6B7E2EF340312CC881FD13C95BB5C9D330800D1E2F0DB5823A40700D131901DA8B1642HFF070B3H0028E9A2CDF51CE409C7D04A070E3H00FB2405AD9B0AD09C046289F33AD02H073H00A19ACB17BD4FCDD13392C41009F202004DD1A1566H0007093H00C8894240E8CFBF4997D162BDDD3C9B790900D1C8DD120340F8F1FFD10BBBCBA4F1250900070B3H0071EA9BEDC43DAF4D50900307063H00EC8D26852531D1323EB63EDED4FDFFD11560AECA4AE80900D128F975779A8B0C0007123H003A6B1407AB2C1C4690B65A2818A4E478E555D1C6475F7F1F0F0B00D13EB663CC5FBA07002H073H0064451E48CB8C50D118ACD5BB494002002H073H00A38C2DABF69489D18H00D186888B4C25692HFFD1DF17983F42862H00D1097H00D150C1A6739066F8FFD177105E1615D2FDFFD1E80AA02B4H00D1E831E4B85FBA0700D1D84DE3A9FCBD0E00D18C1B692B88BE0500D1EA2BC4B9F3600100D105CD5E8DD03H00D164C1990C51440E00D1DCAD48DEAFBC0600D19A2167BC6E1D0D00D1560880833E132H00D1CD811D247AC90300D1BFA8E65867EB0900070B3H00DA0BB46101917DA4E016AE070D3H00FD166759C249B8688ACDBA2AFCD11505E6755070F7FFD1BB5EDA7590CAF4FF07083H00D2432CB90755ECE4D138CEA7F3831D2H00070B3H007AAB542H6869D5693E1F7CD1C525F89995F50300070B3H009DB60747CA9D72C7D65E6F2H073H00F839728EA30960070F3H00D72021693F863CC0586664A3C77F55D1DED232B7D8850900D143179B790CE80B00D17BFC76DB15DB030007063H0056A770CD0323070B3H004425FEEBE294E3CB7706A607083H0077C0C1D78AE09626D1E8D8470032310B00D1E98CADC6D9F20400D13284B7565F0B0400070F3H00DFE8A91632DEB1936965FF7ADA87AED166D393084H00F678010002E818092H02E418092H02E018092H0263292H0201202H02D109642H028207052H02B2070502526241DA02E201D2012D66BE02820371B6023A820765FA06A6049E0221B204F204860259E20272C20361DA0102AC18092H02BC2E4CE62H02C008092H0298284C1E02E03F093H0244EE3H0244EA2H023409028D067E0AE22H027C0902A9067E0AF22H02E46HFF0F093H0242E62H02C50364EA2H0238093H0244DE2H0204092H02820470DE3H0244DA0245DA023FDA2H0228092H02810164EE2H02D46HFF0F09020DD60260D602B9077E0ADA2H0204092H020120DA02B9077E0ADE2H02AC6HFF0F093H0242E22H02C06HFF0F09028D067E0ADE2H0204092H020120DE02B1077E0AE22H0204092H020120E2029D057548E62H0200092H02A83C25E62H021809028D067E0AE62H0204092H020120E6025D7E0AEA025D7E0AEE2H02ECFE5HFF0F092H029401092H02A02E092H02C50464D62H028C39092H02F02A092H028A0245C23H0251C22H0204092H02AA0470C22H02BC390902E1041E0ACA2H02882C0902C2021E0DC22H0204092H020120C202BD05C2025BD011024809024D1E0AD62H0204092H020120D63H0242CE2H022C0902F1051E0ACE2H0204092H020120CE3H0242C62H0204092H022270C63H0244C22H0204092H02820370C202B105C2023FC22H02AC6HFF0F093H0244CA2H02CC6HFF0F092H02EC2A092H02F42A4CD22H02800A092H02CC3E092H02943C092H02E411092H02C41440C22H02C40D092H02AD0764D22H02D42A0902DD03E90272E202E1054D72E202F12H0572E22H020B29E62H021C0902EE02C10406EA2H020564EE2H02D60247F22H020564F62H02900801EE3H0253E22H02D06HFF0F093H0253EA2H021729EE2H02D86HFF0F092H02AC040FEE2H02842E0902CE02F20261F202A902F2023DF202CA01EE0470DA04026C0902CA02DE0258F202F6069E07478E09CA01DA0470F60402080902DE02C60221F22H02D86HFF0F093H0244F62H0204092H02E60470F602F602F2026DDA2H02E46HFF0F09025D7E0ACE02A9067E0AD23H0244CE2H02B006092H02F0294CCA2H02DCFD5HFF0F092H02C402092H026E45AA2H02A60245AE3H0244AA2H0204092H02F20670AA02FD08AA02579034028834092H02FC384CDA2H02B036092H02906HFF0F40E22H02E0FE5HFF0F092H02C50864E62H02B812093H0244DE029D02DE0266DE2H02B02225DE2H029829092H02D4314CC62H02CC30092H02EC39093H0273C202CA01EE0270EA040214092H02E10764EE2H0200092H020A1FEE2H02E86HFF0F092H02E83A07EE02CA01A60470EE04A2038E04738E0402F06HFF0F092H028C254CD62H028C080902E1041E0AC602C602C2024DC22H02D83825C22H02240902B1081E0AC62H0204092H020120C602C602C20200C22H02DC6HFF0F093H0244C602B1081E0ACA3H0242C22H02DC6HFF0F092H02D036092H02D50364DE2H02C401092H02C4060902CA01FA047082052H0267820302F06HFF0F0902F606FE08479A0902EC6HFF0F092H02CC0E092H0290264CE62H029C35092H02F4290902A104760ACA2H02A50964CE2H02910464D23H0242CA02CA02C6026AC63H0244C22H020009029106C2023FC202C2021E0DC22H0204092H020120C202A505C2025BD83802E805092H02ACFA5HFF0F4CD62H02C4380902A9067E0AD22H0204092H020120D23H0244CE2H0204092H02D20170CE2H02B01A0902B9077E0ACE2H02DC6HFF0F092H02E82C093H0244CA2H02000902051E0ACE02CE02CA026ACA2H0200093H0244C63H0244C202E102C2023FC22H02000902C2021E0DC22H0204092H020120C202E906C2025BF40102E4280902A109DE0260DE0289017E0AE22H021C0902A9067E0AEA3H0244E62H0204092H02BA0270E602B908E60266E62H02CC2325E62H02080902B9077E0AE62H02DC6HFF0F092H02D808092H02D10664E22H02C034092H02B831092H02F60245FE2H0208092H027245FA2H02F06HFF0F0902A601DA0970DA0902A00407FA2H026A45EE02CA01FE0270EE04F606D208478E0902960145FA2H02A50464FE2H02BD0164820302BD0164860302123EFA2H0204092H02920470FA2H02F60216F6022H0E24EE2H02882625EE2H02DC010902B9077E0AE202A9067E0AE62H0204092H020120E63H0244E22H02F8190902CA01860470BE042H0219C22H02F402092H02DC35092H02F823092H02D80625C22H02F40E0902C2021E0DC22H0204092H020120C202C905C2025B8C38026C092H02990264CA3H0242C22H0204092H02FE0770C2028506C2023FC22H02D46HFF0F09028D067E0AC22H020009028D067E0AC62H0204092H020120C6025D7E0ACA2H0204092H020120CA02B9077E0ACE2H0204092H020120CE02E1051E0AD202D202810252D23H0244CE2H0204092H02A60370CE3H0244CA2H028D0564CE2H0200093H0242C62H02946HFF0F092H02AC2F0902B9077E0AD602A9067E0ADA3H0244D62H0204092H020E70D62H02DC0A092H02F01B092H02B82A4CE62H02B001092H02E80509028D067E0AD22H0204092H020120D20289017E0AD62H0204092H020120D60289017E0ADA2H0204092H020120DA025D7E0ADE2H020C090255CE0256CE02ED03CE0260CE2H02C86HFF0F0902A9067E0AE22H0204092H020120E23H0244DE2H0204092H02C20570DE02DE02F10112DE2H0200092H02A80D25DE2H029833092H02CC2D092H02D82E0902A104760AEA2H02A50964EE2H02850964F22H0204092H02D404093H0242EA2H02F46HFF0F092H02910564E23H0242DA02D901DA0260DA0291097E0ADE02A908092EE22H02A02A25E22H028836093H0273C22H02F81940EE2H02A001092H02F425092H0298FD5HFF0F25BA2H0238092H026A45BA02F6069E0647D6080E0A24BA2H026A45C22H020C092H020E45CE020E0A24CA2H02D86HFF0F092H020A45C6020E0A24C22H0204092H02D60570C202CA01E60270C60402DC6HFF0F092H028424092H02B0F75HFF0F092H02D4324CC62H02D4FA5HFF0F0902CA01860470BE042H0219C22H02E02F4FFA2H02E46HFF0F092H02A40B0902DE02C602218203CE02820361820302000902A90282033D820302820345DE2H02F8FE5HFF0F092H02A8330902A9067E0ADE3H0244DA2H02080902B9077E0ADA2H02EC6HFF0F092H02DC30093H0273C22H0294F85HFF0F092H0290F65HFF0F093H0242C22H0204092H02DA0470C2028904C2023FC202C2021E0DC22H0204092H020120C2029506C2025BD426021C0902E9021E0ACE2H0204092H020120CE02CE02CA0200CA3H0244C602BD031E0ACA2H02C06HFF0F092H02B431092H02B50864D62H02F41C0902C901C2023FC202C2021E0DC22H0204092H020120C20259C2025B9C0402A0F55HFF0F092H02CC25092H0284FA5HFF0F0902F606A20847EA082H0251D22H0204092H021E70D22H02F8FA5HFF0F0902DD031E0ACA2H02D033092H02AD0464E22H02500902F505D20276D22H02400902DD06810750DE2H02E86HFF0F0902A904CE0260CE2H02000902DD08CE023FCE2H0208093H0242D22H02D86HFF0F09028D067E0AD22H0204092H020120D2025D7E0AD62H0204092H020120D602B1077E0ADA2H02C06HFF0F092H02942725D22H0220093H0242DA2H0204092H02E20170DA3H0244D62H0204092H028E0370D62H024964DA2H02B06HFF0F092H02BC29093H0244E62H0204092H02FE0170E6029D07E60278E62H0200092H02F8F65HFF0F25E62H02F008093H0273C202CA01EE0270EA0402080902A2038E04738E0402A0F45HFF0F11EE02F606A608478A0902F06HFF0F09025D7E0AE602A9067E0AEA3H0244E62H02AC2E092H02850164E62H02E41B092H02FC2A25CA2H02F41B0902F107EA0278EA2H02F42E25EA2H029408092H022A3EC62H0204092H029A0270C62H020564CA2H02080902F104EA023FEA2H02E46HFF0F092H02F81801C22H02DD0764EA2H02B802092H02B822092H02B81E25F22H02E02A0902B1081E0AC62H0204092H020120C62H02F8FB5HFF0F0902E9021E0AC22H0204092H020120C22H02A41F092H02A815092H02E10864CA2H029C1D092H02C01A092H02D4FE5HFF0F092H02841F092H020564C22H0200092H021B29C602B1077E0ACA2H0204092H020120CA025D7E0ACE2H0204092H020120CE0289017E0AD22H0204092H020120D202B9077E0AD62H0204092H020120D602D908BD0610DA2H02DC2725DA2H029415092H02B90364DE2H028C070902CA01E604709E050204092H02B02D093H026F9A0302F46HFF0F0902058E030A92030208092H029203459E0302DC6HFF0F0902DD038E030A96030204092H02012096039603E2020D9A030204092H0201209A03CA01F604709A05020009029E039A036D9203E1079603269203F606DA0647B20902C86HFF0F092H02C4200902B9077E0AC22H0204092H020120C202B9077E0AC602B9077E0ACA2H0204092H020120CA02B9077E0ACE2H0204092H020120CE02A9067E0AD22H0204092H020120D23H0244CE02F507CE0227CE2H0200092H02A81D25CE2H02F825092H02C0F35HFF0F092H02F4194CEA2H02A01D092H02D8FD5HFF0F0902E1041E0AD22H0204092H020120D23H0242CA2H0204092H02BA0370CA3H0244C62H0204092H02A60570C63H0244C202F103C2023FC202D505C2023FC22H0238090291097E0AC22H0204092H020120C2025D7E0AC62H0204092H020120C6028D067E0ACA2H0204092H020120CA02E1041E0ACE2H0204092H020120CE02B109CE0239CE2H02946HFF0F0902C2021E0DC22H02000902D501C2025BDC2202E82C092H02A50864E22H0250092H02A90364CA2H02F10664CE2H02180902D202C60221DE2H02000902CE02DE0261DE2H0244093H0245C22H021C092H02A10164D22H0200092H020A49D62H0204092H020120D63H0253DA2H02CC6HFF0F093H0215C22H0200092H02AD0364C62H02B06HFF0F092H028D0464E62H0200092H020564EA2H02A0F05HFF0F01E202A902DE023DDE2H02906HFF0F09025D7E0ACE2H0204092H020120CE02A9067E0AD23H0244CE2H0204092H02EE0170CE2H02A4F25HFF0F092H02B50264C62H0290F05HFF0F092H02A42A092H028A0245C23H0219C22H02A4FB5HFF0F09029D01D60278D62H02802625D62H02E8EC5HFF0F0902A104760AE62H02A50964EA2H02C10764EE2H023C09028D03D2023FD22H0250092H02A50964E62H0268092H02F90764E23H0242DA2H0204092H02EE0170DA02DA02D60200D62H02D401092H02D10264E62H02780902A104760AE22H02A50964E62H0210093H0242E62H02000902E602E20258E22H028401092H028D0964EA3H0242E22H02986HFF0F09025D7E0AD62H0204092H020120D60289017E0ADA2H0204092H020120DA02B1077E0ADE2H02B86HFF0F092H02A10564EA3H0242E22H0204092H02EA0270E202E202DE025EDE2H02740902B1077E0ADA02B1077E0ADE2H0204092H020120DE2H02ED0264E22H02806HFF0F093H0242DE02AD05DE2H02DE025D7E0AE22H0204092H020120E202A9067E0AE63H0244E202E202DE025DDE02A104760AE22H02B8FE5HFF0F092H027D64E63H0242DE2H0204092H027E70DE3H0244DA3H0244D602A104760ADA2H0204092H020120DA2H02A50964DE2H0294FE5HFF0F09028502D6023FD62H028C6HFF0F092H02F82825DE2H02D00F093H0244E202B9077E0AE62H0204092H020120E602A9067E0AEA2H0200093H0244E62H02000902E602E2022DE22H0200092H02BC1125E22H02CCF25HFF0F0902CA018E0270CE042H0251D22H0204092H025A70D22H02A4EB5HFF0F0902CA01860470BE042H0219C22H02B0EE5HFF0F4CC62H028821092H0210092H02B8EC5HFF0F092H02AC1B093H0251D22H02CCF75HFF0F0902F606A20847EA0802F06HFF0F0902B9077E0AE62H0204092H020120E602A9067E0AEA3H0244E62H0204092H022E70E62H02E4ED5HFF0F092H02CC194CDE2H02ACF55HFF0F092H02C8F65HFF0F4CEA2H0294200902B9077E0AE602A9067E0AEA2H0204092H020120EA3H0244E62H028C29092H0226742H02F105642202FD06642602F902642A02E507642E027964320295016436029904643A02A102203E02D10420420204092H0201204202ED08204602F102204A0204092H0201204A02B504204E0204092H0201204E02DD0420520204092H0201205202A10420560204092H02012056028106205A0204092H0201205A02F904205E02E90420620204092H0201206202E90320660204092H0201206602FD05206A02D504206E02E10320720204092H0201207202E90720760204092H0201207602FD08207A0204092H0201207A02A108207E02B101208201D907760A86010204092H02012086018907760A8A019908760A8E010204092H0201208E01C902760A9201AD02760A96019D03760A9A010204092H0201209A01C105760A9E010204092H0201209E01AD09760AA2010204092H020120A201FD07760AA601D105760AAA010204092H020120AA01B9067A0AAE010204092H020120AE01A1037A0AB201A1047A0AB6010204092H020120B601020120BA010204092H020120BA01A901BA010ABA010204092H020120BA01020120BE010204092H020120BE01B905BE010ABE010204092H020120BE0102F10820C20102A90520C60102F50320CA0102B10220CE0102DD0520D2010204092H020120D20102950220D60102E50520DA0102DD0120DE010204092H020120DE01028D0820E20102890320E6010204092H020120E60102C90420EA010204092H020120EA0102B10320EE010204092H020120EE012H0253F201024B29F60102CD0564FA0102CD0564FE0102CD0564822H021F29862H0203298A3H02538E2H021329922H023729962H0207299A2H022F299E2H023B29A202CA019E0470A204023E45AA2H02A10264AE3H026FA62H02A20245A62H024245AA2H02D10464AE3H026FA602CA019E0470A204CA01C20270A60402ED0864AE3H026FA602F606BA0847BE08F606E20647C20802F10264AE3H026FA602CA019E0470A204CA01CA0270A60402B50464AE3H026FA62H0204092H021A70A602F606BA0847BE08025245AA2H02DD0464AE3H026FA62H0204092H02E60370A602CA019E0470A204F606EE0647C20802A10464AE3H026FA602F606BA0847BE08F606F20647C20802810664AE3H026FA602F606BA0847BE08025E45AA2H02F90464AE3H026FA602CA019E0470A204F606FA0647C20802E90464AE3H026FA62H0204092H02820470A602F606BA0847BE08F606FE0647C20802E90364AE3H026FA602CA019E0470A204F606820747C20802FD0564AE3H026FA602F606BA0847BE08F6068A0747C20802E10364AE3H026FA602CA019E0470A204F606860747C20802D50464AE3H026FA62H02A20245A602CA01820370A60402D90764AE2H02E50264B22H021236A62H0204092H029E0170A62H02A20245A602CA01860370A60402890764AE2H02850364B22H021236A62H0204092H026A70A602F606BA0847BE08F606A60747C20802990864AE2H021164B22H021236A602CA019E0470A204F606AA0747C20802C90264AE2H02850764B22H021236A602CA019E0470A204F606AE0747C20802AD0264AE2H02CD0264B22H021236A602CA019E0470A204029A0145AA2H029D0364AE2H02B90164B22H021236A602F606BA0847BE08029E0145AA2H02C10564AE2H02890664B22H021236A62H02A20245A62H02A20145AA2H02AD0964AE2H02950964B22H021236A62H02A20245A602F606BE0747C20802FD0764AE2H022D64B22H021236A602F606BA0847BE08F606C20747C20802D10564AE2H02D50764B22H021236A62H0204092H02D60370A602CA019E0470A20402AE0145AA2H02B90664AE2H02E50664B22H021236A602CA019E0470A204F606CA0747C20802A10364AE2H02D50664B22H021236A602CA019E0470A204F606CE0747C20802A10464AE2H02BD0964B22H021236A602F606BA0847BE08CA01B60370A60402A90164AE2H02D90664B22H021236A602F606BA0847BE08F606D60747C20802B90564AE2H02D90664B22H021236A62H0204092H02920770A62H02060EA62H0204092H020120A62H02C01725A62H02D8F65HFF0F092H02B8EE5HFF0F4CEA2H02F001092H02ACE95HFF0F4CCE2H02E8E25HFF0F09028D02E20260E202BD07E20260E22H0218093H0242E602A104760AEA2H0204092H020120EA2H02A50964EE2H02300902B1077E0AE6028D067E0AEA0289017E0AEE2H0204092H020120EE2H02B50364F23H0244EE2H0200092H02950564F22H0218092H02ACDE5HFF0F25E62H0220092H02950364F23H0242EA02EA02E6023AE62H02E86HFF0F093H0242EA0231EA023FEA2H022564EE2H02986HFF0F092H02D8E05HFF0F093H021D2H02D50864D62H02840D09025D7E0ACE2H0204092H020120CE02A9067E0AD22H0204092H020120D23H0244CE2H0204092H02F20170CE2H026809028103E20260E202DD02E20213E22H02F81225E22H02981F092H02A60245B22H02080902E107AE025BA40A0210093H0244AE2H02F06HFF0F092H023E45AE2H02E06HFF0F092H02FCE75HFF0F092H023564E22H02D012092H02B90264EA2H02BCEC5HFF0F09025D7E0ADE02A9067E0AE22H0200093H0244DE2H02E01C092H02E90864D62H02F018092H02850464C62H02A8F45HFF0F092H02D8EA5HFF0F4CCE2H02F0EC5HFF0F092H02D4070902CA01A20470BE040210092H02B50164C62H027C093H0267C22H02E86HFF0F093H0251C22H020564C22H023329C602B1077E0ACA2H0204092H020120CA028D067E0ACE0291097E0AD202A104760AD62H0204092H020120D62H02A50964DA2H0218092H02BA0245BE3H0214C22H0204092H020120C23H0267BE2H0260092H02A90964DE3H0242D62H0204092H026E70D63H0244D22H02C50264D63H0242CE2H024C092H020F29BA2H02C06HFF0F092H02B10164CA2H021236BE2H0204092H02EA0670BE3H0253BE02CA01AA0470BE04CA01EA0270C2040200093H0267C22H0204092H02860570C202CA01AA0470BE04F606FA0647DE0802CCFE5HFF0F092H029D0464BA02F606BA0847D6080218092H026164D23H0242CA2H0204092H02DA0170CA029901CA0278CA2H02080902CA01FE0270BE040298FE5HFF0F092H02A00825CA2H02840C092H0280E35HFF0F0902FA02D6020DFE2H0204092H020120FE02F105DE023D820302000902A508820357941002DCEC5HFF0F092H02D10364CE2H02B0E85HFF0F092H02A00109025D7E0AD22H0204092H020120D202A9067E0AD62H0200093H0244D22H02E4DC5HFF0F092H02990764E22H02F0020902A9067E0AE22H020809025D7E0ADE2H02F06HFF0F093H0244DE2H0280E55HFF0F092H02B50964DA2H02BC120902C108D2023FD202A104760AD62H0204092H020120D62H02A50964DA2H02D10164DE2H0200093H0242D62H0204092H028A0270D602B909D60256D602B505D60213D62H02CC0825D62H028806092H02ACFC5HFF0F0902CA01EE0470F6040200093H0267F62H0204092H02820370F62H0280190902CA01AE0470F20402E06HFF0F0902F1051E0ACA2H0204092H020120CA2H0284DD5HFF0F092H0294E05HFF0F4CDE2H02C4DE5HFF0F093H0273C22H02F007092H02ECE55HFF0F4CCA2H02A80A092H02A817093H0242D602F1051E0ADA2H0204092H020120DA3H0242D22H0204092H026270D23H0244CE2H0204092H02D20270CE3H0244CA2H0204092H02FE0770CA02BD031E0ACE02CE02CA0254CA2H02A8DC5HFF0F25CA2H027809028D067E0AC62H0204092H020120C60289017E0ACA02B9077E0ACE2H0204092H020120CE028D067E0AD2028D067E0AD62H0204092H020120D6028D067E0ADA2H0204092H020120DA0289017E0ADE2H0204092H020120DE2H02E10664E22H0208092H021E47C22H02AC6HFF0F093H0244DE2H0204092H02DA0370DE02E9021E0AE22H0204092H020120E23H0242DA2H026D64DE2H02C4FE5HFF0F092H02F0FC5HFF0F092H02CC0C40C22H02EC19092H02A4F85HFF0F4CE22H02B40B093H0242E62H0204092H027270E63H0244E22H0204092H02FA0670E22H02E90564E62H02C40109028105D22H02D202E501D2023FD22H0210093H0242DA02C106DA0266DA2H0288DB5HFF0F25DA2H02BC010902B9077E0AD62H0204092H020120D602B9077E0ADA2H0204092H020120DA028D067E0ADE0291097E0AE22H02990964E63H0244E22H0204092H02DA0370E22H02E50864E62H0214093H0244D62H0204092H02920570D602D902D60239D62H0220093H0242DE3H0244DA2H02E06HFF0F0902B1077E0ADA2H0204092H020120DA028D067E0ADE2H02140902D108D6023FD62H02E46HFF0F092H02990364DA3H0242D22H02E4FE5HFF0F09025D7E0AE22H0204092H020120E2028D067E0AE62H0204092H020120E62H02C50764EA2H0200092H02B10464EE2H029CFE5HFF0F093H0242DE2H0204092H02EA0670DE2H02C90864E22H02B4FE5HFF0F092H02A4FC5HFF0F0902B9077E0AE602A9067E0AEA2H0204092H020120EA3H0244E62H0208092H02910264CA2H02840D092H02B4164CE62H028CED5HFF0F092H02F8140902FD03E6023FE62H02000902A106E60278E62H02D8DE5HFF0F25E62H02ACDC5HFF0F092H02840F0902CA01860470CE040200093H0251D22H02EC6HFF0F09028D067E0AC202B9077E0AC62H0204092H020120C60289017E0ACA2H0204092H020120CA02BD031E0ACE2H0204092H020120CE3H0244CA02F506CA0278CA2H02A0FB5HFF0F25CA2H02D8DC5HFF0F0902CA01860470BE042H0219C23H0242E22H0208092H02ED0664EA2H02F06HFF0F090229E20260E22H02223EC62H020564CA2H02840201C202A104760AEE2H02A50964F22H02910364F63H0242EE2H0204092H024270EE02EE02EA025DEA029504EA0276EA2H02BCF45HFF0F25EA2H02A8E35HFF0F092H02B50764D22H02B8D55HFF0F092H02ED0464E62H02F401092H02B0F55HFF0F0902A506C2025B88E65HFF0F020C0902BD08C2023FC202C2021E0DC22H02EC6HFF0F092H02F414092H02BCF75HFF0F4CFE010240092H024245AA02CA01A20470AA0402E10764B22H021C0902F606BE0847C2082H0251AA3H0253AA2H024329AE2H023F29B22H022B29B62H02CC6HFF0F093H026FAA2H0204092H02BA0670AA2H022729A62H02D06HFF0F092H028CDB5HFF0F092H0278092H02A40D4CCA2H02FCD35HFF0F092H02C50164D62H0210092H02B0F35HFF0F25CE2H02100902E504CE0213CE2H02F06HFF0F093H0242CE2H02F06HFF0F092H02A0D65HFF0F092H02F008092H02E0D65HFF0F25C62H021C092H02CD0164CE3H0242C62H0204092H028A0570C602F1051E0ACA02CA02C60254C62H02DC6HFF0F092H02D4D75HFF0F0902F1051E0AC22H02840A092H02C80F40C22H02E8D15HFF0F092H02AC13092H024729F602CA01F20470EE0402F06HFF0F0902CA01860470BE042H0219C202F50291081CEA2H021009028109E60260E62H02F06HFF0F092H02D0E35HFF0F25EA2H02080902FD04EA020CEA2H02F06HFF0F092H0280E15HFF0F092H02E803092H02C50564E22H0200093H0242DA2H0204092H02CE0170DA2H02ACD55HFF0F0902A104760ADA2H0204092H020120DA2H02A50964DE2H02D46HFF0F092H02BCE55HFF0F4CD62H02840A0902051E0AC62H0204092H020120C602C602C2022DC22H02F40825C22H02E4FE5HFF0F092H02D50264EA2H02D8E85HFF0F092H02DC6HFF0F4CC22H0234092H0298D75HFF0F4CCE2H02D0E45HFF0F09025D7E0AEA02A9067E0AEE2H0204092H020120EE3H0244EA2H0200092H02B4FC5HFF0F092H02890264CA2H02F80A092H02F90164E22H02CCD45HFF0F092H02B403092H02C0D85HFF0F092H02C4DD5HFF0F093H0244D22H0204092H023A70D23H0244CE2H0204092H02AE0770CE2H029D0664D23H0242CA2H0204092H02C20570CA02CD04CA0260CA2H025C093H0244CE2H0204092H028A0370CE02F501CE0276CE2H02D8F25HFF0F25CE2H0258092H02C50664DE2H021C0902A104760AD62H0204092H020120D62H02A50964DA2H02E46HFF0F093H0244D62H02946HFF0F093H0242D62H0204092H02960370D63H0244D22H0204092H02BA0370D202E503D20239D22H02A46HFF0F09025D7E0ACE2H0204092H020120CE025D7E0AD22H02B06HFF0F092H029410092H02F0DE5HFF0F092H02C90764E62H028403092H02BD0464D22H02B4E35HFF0F092H02B0D65HFF0F0902F1051E0ACA2H02B8DB5HFF0F092H02F50864DA3H0242D22H02000902FD01D2020CD22H0214093H0244DA2H0204092H027670DA3H0244D62H02D86HFF0F092H02EC0B25D22H02BCDA5HFF0F09025D7E0AC602A9067E0ACA2H0204092H020120CA3H0244C62H0204092H02B20570C62H029404092H0280DA5HFF0F09024D1E0AC22H0284DB5HFF0F093H0273C2025D7E0AEA2H0204092H020120EA02A9067E0AEE2H0204092H020120EE3H0244EA2H0204092H02BE0470EA2H02ACEE5HFF0F092H029D0864CA2H02D404092H02BCDC5HFF0F092H02890864EA2H02FCDB5HFF0F09025D7E0AE22H02000902A9067E0AE62H0204092H020120E63H0244E22H0204092H022A70E22H0284EE5HFF0F092H02910764EA2H02A40B0902B9077E0ADE2H0204092H020120DE02A9067E0AE23H0244DE2H0204092H028E0670DE2H02ACFE5HFF0F092H02F90364C22H02E4FB5HFF0F09024D1E0AC22H0204092H020120C22H02B00A092H02A50164C62H02880B0902B9077E0AC22H02280902DD031E0ACA2H0204092H020120CA02CA02C6025EC62H02280902051E0ACA2H0204092H020120CA02CA02C60258C62H02D86HFF0F0902DD031E0AC62H0204092H020120C602CD06C60239C62H02D86HFF0F092H02B0E35HFF0F25C62H02FCEE5HFF0F092H02EC06092H02C0FE5HFF0F092H02AD0164D22H02B80A093H0273C22H02E00725E22H026C092H02BD0264EA3H0242E22H0204092H02FE0770E22H026964E63H0242DE2H0204092H02860170DE02D903DE023FDE025D7E0AE22H0230093H0242E62H0204092H029A0670E602E602C10331E62H0200090265E60256E63H0244E22H0204092H02820570E202F906E20239E202A107E20213E22H029C6HFF0F0902A104760AE62H02A50964EA2H02D10764EE2H02C06HFF0F092H029CD85HFF0F092H02CCFC5HFF0F0902CA01920270CE042H0251D22H0200092H02A0F35HFF0F092H0284CF5HFF0F4CE22H02B4D05HFF0F092H02F0EC5HFF0F4CE22H02D8EF5HFF0F092H02A0DF5HFF0F4CD22H0288080902DD03FE020A8203F6068A07479E090200092H028203458A03A203A60473A60402D00811860302850564E62H0290F65HFF0F092H02EC0825D22H022C0902D905D20276D22H02F06HFF0F09025D7E0AC2028D067E0AC62H0200090291097E0ACA2H0204092H020120CA028D067E0ACE02E1041E0AD22H02D46HFF0F092H02800209024D1E0ACA2H0204092H020120CA02CA02C60254C62H02C0D55HFF0F25C62H028CDE5HFF0F0902F504E2023FE22H0200092H02223EC62H0204092H02AA0370C62H020564CA2H0284CC5HFF0F01C22H028D0764DE2H0298F05HFF0F09028909DA2H02DA2H0220092H0298CE5HFF0F25D62H029001092H02A50764D62H0208093H0242D62H021C093H0242CE2H023C093H0244D62H0204092H02FE0170D63H0244D22H02D46HFF0F09029906D60278D62H02C46HFF0F09028D01CA023FCA02B1077E0ACE2H02000902B9077E0AD22H0204092H020120D2025D7E0AD62H023409028508CE023FCE2H02000902B1077E0AD2028D067E0AD62H0204092H020120D60289017E0ADA2H02CD0864DE3H0244DA2H0204092H028A0670DA2H02810464DE2H02806HFF0F0902B506810869DA2H02E0FE5HFF0F092H02E0D25HFF0F092H029C6HFF0F4CCA2H02D0F65HFF0F092H02F8EA5HFF0F092H02D02H092H02F405092H02B0C95HFF0F092H02B8F45HFF0F4CC22H027C092H02F4FB5HFF0F092H02A8FA5HFF0F092H02A8EA5HFF0F0902F606A20847C2082H0251AA2H0204092H02FA0270AA2H02ACF45HFF0F092H0280ED5HFF0F092H0294F85HFF0F4CDA2H02C0EE5HFF0F0902B1081E0AC62H029CCD5HFF0F093H0273C202A104760AE22H0204092H020120E22H02A50964E62H025164EA2H0200093H0242E22H0204092H02EE0470E22H02B8FD5HFF0F092H02E4F25HFF0F092H02B90464E62H02E4D05HFF0F092H02ED0564E22H029CFC5HFF0F092H02BCD05HFF0F092H02B4D45HFF0F0902B9077E0AC22H02000902A9067E0AC62H0204092H020120C63H0244C22H029CF35HFF0F093H0273C22H021964D62H02BCCB5HFF0F0902CA01CE0470D20402BE0245DA3H0244D602F606EA0847F2080230093H0244DE2H02640902CA01D60470E6042H026FE202CA01960470DE04CA01D60470E204CA01DA0470E6042H026FE22H029A0245E202CA01DA0470E204CA01D20470E6040224092H02C60245DE3H0244DA2H0204092H02CE0770DA02F606EA0847F608F606E60847FA0802B46HFF0F092H022329D22H02986HFF0F093H026FE22H0204092H02F60370E22H02E8E95HFF0F0902CA01D20470E204029C6HFF0F0902CA01960470DE0402F06HFF0F092H0270092H02A8014CD62H02B0FD5HFF0F092H02DCD15HFF0F090215CA2H02CA02A502CA0260CA028D067E0ACE2H0204092H020120CE02AD06A9072ED22H0200092H02C8C75HFF0F25D22H02C0FD5HFF0F092H02950864D22H0280EB5HFF0F092H02D4FA5HFF0F0902CE02CA0254CA2H02940625CA2H02240902B1077E0AC22H0204092H020120C20289017E0AC62H0204092H020120C602E9021E0ACA024D1E0ACE2H02D06HFF0F092H02D8FD5HFF0F0902F6068607478E09F6068A094792090200093H0244F62H0204092H02FA0370F602C102F6025BF00502B0020902F606A20847DA082H0219C202E107FE0226F62H0294D05HFF0F09029507D60266D62H02ACCA5HFF0F25D62H02080902A503D60239D62H02EC6HFF0F092H02B0D85HFF0F092H02ACFA5HFF0F4CE22H02C8FC5HFF0F092H0298F75HFF0F093H0244F22H0204092H028E0770F23H0242EA2H0204092H022270EA029D09EA0278EA2H0224092H024164E63H0244E22H0204092H02E60670E23H0244DE2H0204092H028A0170DE0271DE023FDE2H021C092H02ACDB5HFF0F25EA2H025C0902B9077E0AF22H0204092H020120F202A9067E0AF62H02A06HFF0F0902CD07DE0260DE029905DE0260DE028D067E0AE22H0204092H020120E2025D7E0AE62H0204092H020120E6028D067E0AEA2H02F90864EE2H02C06HFF0F0902F905DA023FDA2H0200090289017E0ADE2H0204092H020120DE02B9077E0AE22H02F8FE5HFF0F092H02E0D25HFF0F092H02C4ED5HFF0F4CE62H02D4D15HFF0F092H02A4D95HFF0F4CE62H02E0C65HFF0F092H02D4F35HFF0F092H02B0E85HFF0F4CD22H02B4F65HFF0F092H02B4F05HFF0F0902CA01960270CE042H0251D22H02F06HFF0F092H02ACCF5HFF0F4CC22H02D4D35HFF0F092H02F4D25HFF0F093H0244D22H02C0F75HFF0F0902A9067E0AD62H02F06HFF0F09025D7E0AD22H02F06HFF0F092H028CF05HFF0F0902A9067E0ACE3H0244CA2H02E4E85HFF0F09025D7E0ACA2H02EC6HFF0F092H02A0D15HFF0F4CEA2H02B4CC5HFF0F092H02D4D25HFF2H0F860302D4F35HFF0F092H02CD0364DA2H029CF25HFF0F0902B1081E0ACA2H02E4C65HFF0F092H02B0CD5HFF0F0902C109C6023FC602C602C20208C4FC5HFF0F02BCF95HFF0F092H029CC35HFF0F4CD22H02E4C25HFF0F092H02E10164D62H02BCC75HFF0F092H022164E62H028CC15HFF0F092H023D64D62H02DCC15HFF0F09025D7E0AC22H023C0902D904C20213C22H02A8F05HFF0F25C22H0244093H0244C22H02EC6HFF0F0902CA02C6025DC602A104760ACA2H0204092H020120CA2H02A50964CE2H02ED0164D23H0242CA2H02000902CA02C60261C62H02D06HFF0F0902E1051E0AC62H0204092H020120C6024D1E0ACA2H02C46HFF0F092H02CCD25HFF0F092H02AD0864D22H02F8FD5HFF0F092H02FCE65HFF0F4FEE2H02B8D05HFF0F092H0298CB5HFF0F4CDE2H0284E65HFF0F0902F606A20847DA082H0251C22H0204092H02CE0570C22H02A0E85HFF0F0902F606A20847DA082H0219C22H02D4FB5HFF0F0902051E0AD63H0242CE2H0204092H02A20270CE2H021D64D23H0242CA3H0244C62H0204092H02DA0670C602B1081E0ACA2H0204092H020120CA3H0242C22H02100902B1077E0ACA2H022C090239D20239D22H02B86HFF0F0902B106C2023FC202C2021E0DC202E901C2025BD0EA5HFF0F0234093H0244D22H02E06HFF0F09028D067E0AC202B9077E0AC62H02CC6HFF0F09028D067E0ACE2H0204092H020120CE025D7E0AD22H0204092H020120D202A9067E0AD62H02CC6HFF0F092H02E8E95HFF0F092H02910164E62H029CFC5HFF0F092H02B8E15HFF0F092H0280C45HFF0F4CCA2H02A0C35HFF0F092H02D0E05HFF0F0902C906E60266E62H028CFC5HFF0F25E62H028CF15HFF0F092H02061FF62H02C20245EE02C207860647EA0802F20245F62H02EC6HFF0F092H02B4F75HFF0F0902CA01860470BE042H0219C22H02FD0264CE2H02D0ED5HFF0F09028905CA0266CA2H022009025D7E0ACA2H0204092H020120CA02B1077E0ACE2H0204092H020120CE02B9077E0AD22H0224092H02ECF55HFF0F25CA2H0238092H02C10164D63H0242CE2H02000902ED07CE0239CE02C903CE0260CE3H0244CA2H02B46HFF0F0902A9067E0AD62H0200093H0244D22H02D46HFF0F092H020564C22H024F29C62H02A06HFF0F092H02C8E05HFF0F090200F1DC5978870AE43F501E2HCD9C94D93FC0CB23742D59D73FCEDD0BC8A394E13FCCCFFED7A54CCA3F9467BC1BD726D13F0405BC7EB620D83F4622542DEC0BDB3FE83982375217EF3FF69EF2A67A0C4C6427FA1472999AF5769B9DD120352AFF15A889B21DED636C330F3D6B247B30E631D0BF00720002A3423H0002A3422H000200A3424H00A2423H00C2555843CD0C3H00013H00083H00013H00093H00093H007098D0110A3H000A3H00D43459550B3H000B3H0051F904770C3H000C3H0016FC8B640D3H000D3H0010648B590E3H000E3H007901BB1B0F3H000F3H0090ADA365103H00103H00F6DB6F35113H00113H00B3544743123H00123H009035AB6F133H001F3H00013H00031D782H00B956070A3H009E2FF85407915D77249E07083H002021DACEA4D3C59CAF7001000244092H0240092H023C092H0213292H0209202H020D642H029A07052H02B2070502B206F60100F6078A04DE034ABA05D205D6055D9202EA019A0733CA059604CE034EA2018607E20755DE04FA02FE04467AC6078E0564BE04B601DE07208204D602FA0737C22H0201202H0204092H0209202H020520060204092H020920062H022B0A020A24062H022A3H02512H0204092H02BA07703H021D02010001008688274CF00A3H00013H00083H00013H00093H00093H004EBAF2190A3H000A3H00F168F8780B3H000B3H0091327F6E0C3H000C3H0066FB62550D3H000D3H00F2BE4E3A0E3H000E3H00463D41240F3H000F3H009E810725103H00103H008B5BF034113H00163H00013H00041C782H00299607093H004889F23620277D0CF4A6700100023C092H0238092H0234092H0217292H0205202H0209642H029607052H02BA070502BA05BE0140BE04EE03CE04307282028A0317EA07B206EE0274CE04E604EA0140EA05DE02B2076486079E06BA010EAE06AA056E170A0201200A0204092H0205200A0203290E2H02670A2H021D022H002E0FB32EBC0A3H00013H00083H00013H00093H00093H00C40CA20C0A3H000A3H00D832E7710B3H000B3H0022B14F7C0C3H000C3H001E2EA90E0D3H000D3H00D364194B0E3H000E3H007AED7E360F3H000F3H00013H00103H00117H00123H00133H00013H00031D782H00091E07233H0031BA8B4AC0F460F4E3B27B3B3AC0F7F172DE01111A6E92F6DF214B40E76DF0CDA80D7007163H0084A5CE2A2425AAE20BEACD1C1024C846316905212734A37001000234092H0230092H022C092H0217292H0209202H020D642H029207052H02B60705023EA6074C9A07F6072A243EC602EA0264BE04A201DA0417FA069602CA024A8E04F207FE046A9A050205202H020164060203290A2H026F3H021D022H00CC44825EC14H00021C782H001DC2D1130D6HFFA87001000240092H023C092H0238092H021B292H0201202H0205642H028A07052H02A6070502A205FE052DAE054AE20277FA02960292060996028606E20230D6069605BA026ABA0396048A0154AA019E01AA056A8E01F6070622BA06AE07CE0470EA2H0203292H0201462H0201202H02014606DE06AE0475B2042H02243H02730200",0X05),U8,function(Ul,Ol)if Ol=="\z\x48"then do s=y(Ul);end;return"";else local Zl=a(y(Ul..Ol,16));if s then local MC=(R(Zl,s));do s=nil;end;return MC;else return Zl;end;end;end);local U=(function()local ls=(v(C,Y,Y));for DO=0x0,0X1 do if DO==0 then do Y=Y+1;end;else return ls;end;end;end);local D=0x80000000;local H=function()local BJ,qJ=E("\z\u{0003C}\z    \x49\z   \x34",C,Y);Y=qJ;return BJ;end;local i8=({[0X2]=N8});S8=0;local l,p=nil,(nil);do repeat do if S8~=0x000 then p=4503599627370496;S8=0X0002;else l=function(Fo,Zo,Ko)local jo=0;repeat do if jo==0 then if not(not Zo)then else Zo=0X1;end;jo=0X1;else if not Ko then Ko=#Fo;end;do jo=2;end;end;end;until jo>=0X2;local Bo=(Ko-Zo+1);do if Bo>7997 then do return L(Fo,Zo,Ko);end;else return W(Fo,Zo,Ko);end;end;end;S8=1;end;end;until S8>1;end;S8=4;local Z,I,T,x=nil,nil,nil,nil;do while S8<0X0005 do if not(S8<=1)then if not(S8<=2)then if S8==0x03 then I=D8;S8=2;else Z=H8;S8=3;end;else do T=function()local MB=(0X0);local JB,wB=nil,nil;repeat if not(MB<=0)then do if MB==0X01 then return JB;else Y=wB;MB=0X1;end;end;else JB,wB=E(b8,C,Y);MB=2;end;until(false);end;end;S8=0X000;end;else if S8~=0 then x=function(Cx,Mx,Yx)return Cx>>Mx&~(~0X0<<Yx);end;S8=5;else do S8=1;end;end;end;end;end;local h=(function()local H0,N0=nil,nil;local I0=2;do while 1413789793 do if not(I0<=0)then if I0==0X001 then do return H0;end;else H0,N0=E("\060\x64",C,Y);I0=0;end;else Y=N0;I0=0X01;end;end;end;end);local e=(function(lh,fh)do return lh~fh;end;end);local w=f8.insert;local Q,X=p8,b-1;local M=function()local yG,KG=0,(0);repeat local E4=(v(C,Y,Y));Y=Y+1;do yG=yG|((E4&0x07F)<<KG);end;if(E4&128)~=0X0 then else return yG;end;KG=KG+7;until false;end;S8=0X6;local G,F,u,o8,Z8,r8,y8,t,P8,O=nil,nil,nil,nil,nil,nil,nil,nil,nil,(nil);do while S8<0xa do if S8<=4 then if S8<=1 then if S8~=0 then do t=function(oQ)local SQ,KQ=nil,(nil);goto _1612670346_0;::_1612670346_0::;SQ=H();goto _1612670346_1;::_1612670346_1::;KQ=q8;goto _1612670346_2;::_1612670346_4::;do do return KQ;end;end;goto _1612670346_5;::_1612670346_2::;for Uv=1,SQ,0X1F3D do local Dv,Wv,kv=0X1,nil,(nil);do repeat if not(Dv<=0X1)then do if Dv<=0X02 then do KQ=KQ..a(l(kv));end;break;break;break;break;else do if Dv==3 then kv={v(C,Y+Uv-0X1,Y+Wv-1)};Dv=0X4;else do for wt=1,#kv do local Xt=1;while Xt<=0x01 do if Xt~=0X0 then do kv[wt]=e(kv[wt],F);end;Xt=0X000;else do F=(oQ*F+1)%0X0000100;end;Xt=2;end;end;end;end;Dv=2;end;end;end;end;else if Dv~=0X0 then Wv=Uv+0x1f3d-1;Dv=0;else if not(Wv>SQ)then else Wv=SQ;end;do Dv=0x3;end;end;end;until(false);end;end;goto _1612670346_3;::_1612670346_3::;Y=Y+SQ;goto _1612670346_4;::_1612670346_5::;end;end;S8=5;else u=function(...)return r("\z  \x23",...),{...};end;S8=0X09;end;else do if not(S8<=0X2)then if S8==3 then r8=Z8;S8=0x8;else O=function()local Ex=(M());do if Ex>=p then return Ex-q;end;end;return Ex;end;do S8=0x000A;end;end;else Z8=function()(A)('\x59\z    \x6Fu\x72\u{0020}\z \x65\z  \x6E\118\z    i\z\x72\z  on\z \109\z \u{00065}\z\110\x74\u{20}\z\100\z  \x6F\z   \101\u{000073}\u{000020}\x6E\x6F\u{0074}\032\115\117\z   \x70\u{00070}o\z  \x72\x74\x20\z \x4C\z    \x75\x61\x4A\z   \x49T\z  \u{0027}\u{00073}\u{20}\x46\z \x46\x49\x20\z    \x6C\z    \x69\x62\z   \u{072}\u{061}\z\x72\x79\x2C\032\z  \u{00074}\z \x68\x65\x72\z   \101\x66\x6F\z   \u{000072}\ze\032\x79\111\z  \x75\u{0020}\z   \u{063}\z   \097\u{00006E}\u{0006E}\z    \x6F\z\x74\x20\z  \u{0075}\z \x73\z   \x65\u{00020}\z\u{4C}\076/\x55\x4C\x4C\x2F\x69 \zs\z   \u{000075}\102\u{66}\u{000069}\z\x78\z   e\z  \115\x2E');end;S8=3;end;end;end;else if not(S8<=6)then if S8<=7 then F=U();S8=0;else do if S8==0X8 then y8=Z8;S8=0X1;else o8=1;S8=0X2;end;end;end;else if S8==0X5 then P8=Z8;S8=4;else G={5,2,j8};S8=0x00007;end;end;end;end;end;local m=(coroutine.wrap);local A8=function(...)return(...)();end;local function d8(z5,t5,l5)local c5,M5=z5[8],(z5[1]);local m5=z5[0X006];local Z5,v5=z5[0X7],z5[0X02];local d5,e5=z5[0x00005],(z5[4]);local k5=j({},{__mode="\z \x76"});local b5=(z5[3]);local T5=nil;T5=function(...)local Dp,Rp,Vp=0x00001,{},(_ENV);local Fp=(0X0);local zp=({[0X0001]=Rp,[2]=z5});local yp=((Vp==k and t5 or Vp));local Xp,Ep=u(...);Xp=Xp-0X1;for M8=0X000,Xp do do if not(c5>M8)then break;break;break;do break;end;break;else Rp[M8]=Ep[M8+1];end;end;end;if not v5 then Ep=nil;else if m5 then do Rp[c5]={n=Xp>=c5 and Xp-c5+0X1 or 0,l(Ep,c5+1,Xp+1)};end;end;end;if yp~=Vp then _ENV=yp;end;local np,vp,tp,qp=P(function()while 0.5700969922938931 do local GO=d5[Dp];local NO=(GO[3]);Dp=Dp+1;if not(NO>=0x3d)then if NO<30 then if NO<15 then if NO>=0x7 then do if not(NO>=0X000B)then if not(NO>=9)then if NO~=0x8 then local Dd=GO[2];local Wd=m(function(...)f();for AR in...do(f)(true,AR);end;end);Wd(Rp[Dd],Rp[Dd+0x1],Rp[Dd+2]);Fp=Dd;do Rp[Dd]=Wd;end;do Dp=GO[5];end;else if Rp[GO[0X5]]==Rp[GO[4]]then Dp=GO[0X002];end;end;else if NO==0Xa then(Rp)[GO[0X2]]=Rp[GO[5]][GO[0x1]];else Dp=GO[0X5];end;end;else do if not(NO>=0Xd)then if NO~=0x0C then Rp[GO[0x02]]=GO[6]*Rp[GO[0X4]];else(Rp)[GO[0X02]]=Rp[GO[5]]>=GO[0X1];end;else if NO~=0Xe then Rp[GO[0X02]]=Rp[GO[5]][Rp[GO[0X0004]]];else(Rp)[GO[2]]=zp[GO[0X5]];end;end;end;end;end;else if not(NO>=0X3)then do if not(NO>=0X1)then(Rp)[GO[0x2]]=Rp[GO[5]]|Rp[GO[0X00004]];else if NO~=0X2 then local Le=(GO[2]);local Ie=(Rp[Le]);local pe=(Rp[Le+0X002]);local se=Rp[Le+1];(Rp)[Le]=m(function()for up=Ie,se,pe do f(true,up);end;end);Dp=GO[5];else Rp[GO[2]]=Rp[GO[0X5]]~GO[0X1];end;end;end;else if NO<0X5 then if NO~=4 then Rp[GO[0X2]]=GO[6]<=Rp[GO[4]];else Rp[GO[0X2]]=Rp[GO[5]]>>Rp[GO[4]];end;else if NO~=6 then(Rp)[GO[2]]={l({},0X1,GO[0X5])};else(Rp[GO[2]])[GO[0X6]]=Rp[GO[0X04]];end;end;end;end;else if NO<22 then do if not(NO>=18)then do if NO<0X10 then local ZQ=GO[0X00002];local yQ,mQ,qQ=Rp[ZQ]();if yQ then do(Rp)[ZQ+1]=mQ;end;(Rp)[ZQ+0X2]=qQ;Dp=GO[0x5];end;else do if NO~=0X000011 then(Rp)[GO[2]]=GO[0X6]~=GO[1];else local qB=GO[2];local XB=(m(function(...)(f)();for Fd,bd in...do(f)(true,Fd,bd);end;end));XB(Rp[qB],Rp[qB+1],Rp[qB+0X2]);Fp=qB;(Rp)[qB]=XB;Dp=GO[5];end;end;end;end;else do if not(NO>=0X14)then if NO==19 then(Rp)[GO[0X02]]=Rp[GO[5]]==GO[1];else Rp[GO[2]]=GO[0x0006]>=Rp[GO[0x4]];end;else if NO~=21 then do(Rp)[GO[0X2]]=_ENV;end;else Fp=GO[2];Rp[Fp]=Rp[Fp]();end;end;end;end;end;else if NO<26 then if not(NO>=0X18)then if NO==23 then local Ly,Zy=GO[2],Rp[GO[0x005]];Rp[Ly+1]=Zy;Rp[Ly]=Zy[GO[0X1]];else local Fz=GO[5];Rp[GO[2]]=Rp[Fz]..Rp[Fz+1];end;else if NO==25 then repeat local f6,c6=k5,(Rp);if#f6>0 then local AP={};for Qo,Yo in g,f6 do do for Iu,Wu in g,Yo do if not(Wu[1]==c6 and Wu[2]>=0)then else local A0=Wu[2];if not(not AP[A0])then else AP[A0]={c6[A0]};end;do Wu[0x1]=AP[A0];end;(Wu)[2]=1;end;end;end;end;end;until true;return true,GO[0X0002],0X1;else local mq=l5[GO[5]];(mq[0X1])[mq[0X002]]=Rp[GO[2]];end;end;else if NO>=0X1c then if NO~=0X01D then(Rp)[GO[2]]=GO[0x0006]~GO[0X1];else repeat local de,ie=k5,(Rp);if#de>0 then local wv={};for cf,sf in g,de do for mp,ap in g,sf do if not(ap[1]==ie and ap[0X2]>=0)then else local l4=(ap[2]);if not wv[l4]then(wv)[l4]={ie[l4]};end;ap[1]=wv[l4];(ap)[0X2]=0X01;end;end;end;end;until true;do return;end;end;else if NO~=27 then(Rp)[GO[0X2]]=GO[6]&GO[1];else Rp[GO[0X002]]=GO[6]-Rp[GO[0X004]];end;end;end;end;end;else if NO>=45 then if NO>=0X00035 then if NO>=57 then if not(NO<0X3B)then do if NO==0X3c then local La=(GO[2]);local za=(GO[4]-1)*50;local Ja=Rp[La];for Qc=0X0001,Fp-La do do Ja[za+Qc]=Rp[La+Qc];end;end;else local bX=(GO[2]);local lX,pX=Rp[bX]();do if not(lX)then else for Zy=0X1,GO[4]do do(Rp)[bX+Zy]=pX[Zy];end;end;Dp=GO[5];end;end;end;end;else do if NO==0x3A then do(Rp)[GO[0x2]]=Rp[GO[0X5]]>=Rp[GO[4]];end;else Rp[GO[0x2]]=Rp[GO[5]]&GO[0X00001];end;end;end;else if not(NO<55)then do if NO~=56 then do Rp[GO[0x0002]]=true;end;else repeat local dI,MI=k5,(Rp);if#dI>0 then local cO={};for Jr,cr in g,dI do for ZH,fH in g,cr do if fH[1]==MI and fH[0X002]>=0 then local sd=(fH[2]);if not cO[sd]then(cO)[sd]={MI[sd]};end;fH[0x001]=cO[sd];do fH[2]=0x1;end;end;end;end;end;until true;local LW=(GO[2]);return false,LW,LW+GO[5]-0x2;end;end;else if NO~=0X36 then if Rp[GO[5]]<=Rp[GO[4]]then Dp=GO[0x2];end;else local uo=GO[0X2];Fp=uo+GO[0x0005]-1;Rp[uo](l(Rp,uo+0X1,Fp));Fp=uo-0x1;end;end;end;else do if NO>=49 then if not(NO<0x00033)then if NO==52 then Rp[GO[2]]=Rp[GO[0X5]]<<Rp[GO[4]];else(Rp)[GO[0X0002]]=Rp[GO[0X005]]%Rp[GO[4]];end;else if NO==50 then local KK=(GO[5]);local pK=(GO[2]);Fp=pK+KK-1;repeat local xo,mo=k5,(Rp);if#xo>0x0 then local jp={};for wj,bj in g,xo do for Zn,Fn in g,bj do if not(Fn[1]==mo and Fn[2]>=0)then else local cF=Fn[2];if not(not jp[cF])then else jp[cF]={mo[cF]};end;do(Fn)[1]=jp[cF];end;(Fn)[0X00002]=0X0001;end;end;end;end;until true;do return true,pK,KK;end;else(Rp)[GO[2]]=GO[0X00006]|Rp[GO[0X004]];end;end;else if NO<0x0002F then if NO~=0X00002e then(Rp)[GO[0X2]]=Rp[GO[5]]>Rp[GO[4]];else do(Rp)[GO[0X2]]=GO[6]>=GO[1];end;end;else if NO~=48 then if GO[4]~=155 then repeat local G6,e6=k5,(Rp);if not(#G6>0)then else local N4={};do for AZ,zZ in g,G6 do for qq,iq in g,zZ do if not(iq[1]==e6 and iq[0X2]>=0)then else local lD=(iq[0X2]);if not N4[lD]then N4[lD]={e6[lD]};end;do iq[1]=N4[lD];end;iq[0x2]=0x1;end;end;end;end;end;until true;local kp=(GO[2]);do return false,kp,kp;end;else Dp=Dp-0X001;d5[Dp]={[5]=(GO[5]-0xD6),[2]=(GO[0x02]-0Xd6),[0x0003]=0X70};end;else do Rp[GO[0X00002]]=Rp[GO[0X0005]]^Rp[GO[0X00004]];end;end;end;end;end;end;else if NO>=0X000025 then if not(NO>=0X00029)then if not(NO>=39)then if NO==38 then Rp[GO[0x2]][Rp[GO[0X005]]]=GO[1];else if not(not Rp[GO[2]])then else Dp=GO[0x5];end;end;else if NO~=0X000028 then Rp[GO[0X2]]=Rp[GO[0x005]]<GO[0X1];else if GO[4]~=0X83 then do(Rp)[GO[0x00002]]=not Rp[GO[0X00005]];end;else Dp=Dp-0X1;(d5)[Dp]={[2]=(GO[2]-0Xa0),[3]=56,[0X5]=(GO[5]-160)};end;end;end;else do if not(NO<43)then if NO~=44 then local pV=l5[GO[5]];Rp[GO[2]]=pV[0X1][pV[0X2]];else if not(not(GO[0X6]<Rp[GO[4]]))then else do Dp=GO[0X002];end;end;end;else do if NO==42 then local nJ=(GO[0x002]);Rp[nJ]=Rp[nJ](l(Rp,nJ+0X1,Fp));Fp=nJ;else local al=e5[GO[0X0005]];local hl=nil;local gl=al[9];local Al=#gl;if Al>0 then hl={};for Dy=1,Al do local Xy=gl[Dy];if Xy[1]~=0 then hl[Dy-1]=l5[Xy[0X2]];else hl[Dy-0X1]={Rp,Xy[2]};end;end;(w)(k5,hl);end;Rp[GO[2]]=d8(al,yp,hl);end;end;end;end;end;else if NO>=33 then do if not(NO<35)then do if NO~=0X0024 then do Rp[GO[0X0002]]=GO[0X6]^Rp[GO[4]];end;else local Z1=(GO[0X2]);local F1=GO[4];local u1=GO[0X5];do if u1~=0X0 then Fp=Z1+u1-0x1;end;end;local D1,c1=nil,(nil);do if u1==0x00001 then do D1,c1=u(Rp[Z1]());end;else D1,c1=u(Rp[Z1](l(Rp,Z1+1,Fp)));end;end;if F1~=0X1 then if F1~=0X0 then D1=Z1+F1-2;Fp=D1+0x1;else D1=D1+Z1-0X0001;Fp=D1;end;local FQ=0;do for Jz=Z1,D1 do FQ=FQ+0X01;Rp[Jz]=c1[FQ];end;end;else Fp=Z1-1;end;end;end;else if NO==34 then if not(Rp[GO[0X5]]<=Rp[GO[4]])then Dp=GO[0X2];end;else(Rp)[GO[2]]=Rp[GO[5]]*Rp[GO[4]];end;end;end;else if not(NO<0X1f)then if NO==32 then Rp[GO[0X02]]=yp[GO[6]];else i8[GO[0x5]]=Rp[GO[0x02]];end;else local mK=nil;local sK=(e5[GO[0x5]]);local jK=(sK[9]);local kK=#jK;do if kK>0X0 then mK={};for um=1,kK do local Cm=(jK[um]);if Cm[1]~=0 then mK[um-1]=l5[Cm[0x002]];else(mK)[um-0X001]={Rp,Cm[0x00002]};end;end;w(k5,mK);end;end;Rp[GO[0x2]]=o[GO[0X004]](mK);end;end;end;end;end;elseif NO>=91 then do if not(NO>=106)then if NO>=0x062 then do if not(NO<0X000066)then do if not(NO<0x000068)then if NO==0X0069 then do(Rp)[GO[0X2]]=GO[6]+GO[1];end;else repeat local QU,iU,TU=k5,Rp,(GO[2]);if#QU>0 then local m7=({});do for N7,f7 in g,QU do for F2,T2 in g,f7 do do if not(T2[0x01]==iU and T2[0X002]>=TU)then else local a2=T2[0x2];if not(not m7[a2])then else m7[a2]={iU[a2]};end;(T2)[1]=m7[a2];(T2)[0X2]=1;end;end;end;end;end;end;until true;end;else if NO~=103 then Rp[GO[0X2]]=Rp[GO[5]]>GO[0X1];else local cF=(GO[2]);Rp[cF](Rp[cF+0X00001]);do Fp=cF-0X1;end;end;end;end;else do if not(NO<0x064)then if NO==101 then zp[GO[0x005]]=Rp[GO[0x2]];else do Rp[GO[2]]=GO[6];end;end;else do if NO==99 then repeat local SD,BD=k5,(Rp);if not(#SD>0X00000)then else local lx=({});for M6,G6 in g,SD do for aB,KB in g,G6 do if KB[0X01]==BD and KB[0x2]>=0 then local PN=KB[2];if not lx[PN]then lx[PN]={BD[PN]};end;(KB)[1]=lx[PN];KB[2]=0X00001;end;end;end;end;until true;do return true,GO[0X00002],0;end;else(Rp)[GO[0X002]]=-Rp[GO[0X5]];end;end;end;end;end;end;else if not(NO>=0X00005E)then if not(NO<0x5C)then do if NO==93 then(Rp)[GO[2]]=Rp[GO[5]]-Rp[GO[0X4]];else(Rp)[GO[0X2]]=Rp[GO[0X5]]~=Rp[GO[0X4]];end;end;else if Rp[GO[5]]==GO[1]then do Dp=GO[2];end;end;end;else if not(NO<0x000060)then if NO==97 then Rp[GO[0X002]]=Rp[GO[0X5]]+Rp[GO[4]];else(Rp)[GO[0X00002]]=Rp[GO[0X005]]+GO[1];end;else if NO~=0X5f then(Rp)[GO[0x2]]=Rp[GO[5]]==Rp[GO[4]];else if Rp[GO[5]]<Rp[GO[4]]then do Dp=GO[0X2];end;end;end;end;end;end;else if NO>=114 then if NO<118 then do if NO>=116 then if NO~=117 then local lL=GO[2];for S1=lL,lL+(GO[0X5]-0X1)do Rp[S1]=Ep[c5+(S1-lL)+0X01];end;else if GO[4]==0xd7 then Dp=Dp-0X1;d5[Dp]={[3]=0X43,[2]=(GO[0X00002]-0X0008b),[0X0005]=(GO[0X00005]-0X08B)};elseif GO[4]==0X003E then Dp=Dp-1;(d5)[Dp]={[0x2]=(GO[0X2]-0x00005B),[5]=(GO[0x005]-0X5b),[3]=0X43};else(Rp)[GO[0x00002]]=Ep[c5+0x00001];end;end;else if NO~=115 then do(Rp[GO[2]])[GO[0X0006]]=GO[1];end;else if GO[4]~=0x68 then repeat local Z1,H1=k5,(Rp);if#Z1>0X0 then local CZ={};for At,zt in g,Z1 do for qm,Um in g,zt do if Um[0X1]==H1 and Um[2]>=0x0000 then local nL=Um[0X2];if not CZ[nL]then(CZ)[nL]={H1[nL]};end;Um[1]=CZ[nL];do(Um)[2]=0X001;end;end;end;end;end;until true;return false,GO[0X2],Fp;else do Dp=Dp-0X1;end;do(d5)[Dp]={[0X0003]=0x0006C,[5]=(GO[0X5]-38),[2]=(GO[2]-38)};end;end;end;end;end;else if not(NO<0X78)then if NO~=0X079 then(Rp)[GO[2]]=Rp[GO[0x5]]<=GO[0X1];else do(Rp)[GO[2]]=GO[6]>Rp[GO[4]];end;end;else do if NO==0X77 then if Rp[GO[5]]==Rp[GO[4]]then else Dp=GO[0X02];end;else do Rp[GO[2]]=Rp[GO[0X5]]~=GO[0X1];end;end;end;end;end;else if NO<0X0006e then if NO<0X006C then if NO==0X00006B then Rp[GO[2]]=Rp[GO[0X005]]*GO[1];else Rp[GO[0x02]]=Rp[GO[0X5]]&Rp[GO[0X4]];end;else do if NO~=109 then do if GO[4]==0X6f then do Dp=Dp-0X00001;end;do d5[Dp]={[5]=(GO[0X5]-239),[0X2]=(GO[2]-0XeF),[0x0003]=0X28};end;else(Rp)[GO[2]]=nil;end;end;else Rp[GO[2]][Rp[GO[0X005]]]=Rp[GO[4]];end;end;end;else if NO<0X0070 then if NO~=0X0006f then(Rp)[GO[0X02]]=Rp[GO[5]]/GO[0X1];else local vI=(GO[0X2]);(Rp[vI])(Rp[vI+0X001],Rp[vI+2]);Fp=vI-0X1;end;else if NO~=0X000071 then if GO[0X004]==174 then do Dp=Dp-0X1;end;(d5)[Dp]={[5]=(GO[0X5]-0xb),[0X3]=0X47,[2]=(GO[2]-11)};elseif GO[4]==0X32 then Dp=Dp-0x1;d5[Dp]={[2]=(GO[0X0002]-0X3f),[0X005]=(GO[0X5]-63),[3]=0X45};elseif GO[0X4]==0x29 then Dp=Dp-0X001;(d5)[Dp]={[5]=(GO[0x5]-0Xd6),[0X2]=(GO[2]-0X0000D6),[3]=108};else do for Ll=GO[0X2],GO[5]do do(Rp)[Ll]=nil;end;end;end;end;else local NT=(GO[2]);local ZT=m(function(...)f();do for VP,rP,UP,QP,wP,CP,iP,fP,pP,DP in...do(f)(true,{VP,rP,UP,QP,wP,CP,iP,fP,pP,DP});end;end;end);ZT(Rp[NT],Rp[NT+1],Rp[NT+0X2]);Fp=NT;do Rp[NT]=ZT;end;do Dp=GO[5];end;end;end;end;end;end;end;else do if not(NO>=0x4c)then do if not(NO<68)then if not(NO<0X48)then if NO<0X4a then if NO==73 then Rp[GO[0X2]]=i8[GO[0X5]];else(Rp)[GO[2]]=GO[6]<=GO[1];end;else do if NO~=75 then Rp[GO[2]]=~Rp[GO[0X00005]];else Rp[GO[2]]=Rp[GO[0x5]]/Rp[GO[4]];end;end;end;else if not(NO>=70)then if NO~=0X0045 then local fR=(GO[2]);Rp[fR]=Rp[fR](Rp[fR+0X1]);do Fp=fR;end;else if GO[0X4]~=209 then Rp[GO[0X2]]=Rp[GO[0X00005]];else Dp=Dp-0X0001;do d5[Dp]={[2]=(GO[0X002]-106),[0X3]=0X0002F,[5]=(GO[5]-0X6A)};end;end;end;else if NO==71 then if GO[0X0004]==221 then Dp=Dp-1;d5[Dp]={[2]=(GO[0X2]-0xc6),[5]=(GO[0X05]-0X0000c6),[0X3]=0X00045};elseif GO[4]~=0X000f0 then(Rp)[GO[2]]=#Rp[GO[0X005]];else do Dp=Dp-0X0001;end;(d5)[Dp]={[0X2]=(GO[0x2]-191),[0x5]=(GO[5]-0xBf),[3]=0X38};end;else(yp)[GO[0X6]]=Rp[GO[2]];end;end;end;else if NO>=64 then if not(NO<0X42)then if NO==0X00043 then local Ru,iu=Xp-c5,(GO[0X2]);if Ru<0 then Ru=-0x1;end;do for o3=iu,iu+Ru do Rp[o3]=Ep[c5+(o3-iu)+1];end;end;Fp=iu+Ru;else local Lz=(GO[0X2]);(Rp)[Lz]=Rp[Lz](Rp[Lz+0x1],Rp[Lz+0X2]);Fp=Lz;end;else do if NO~=0X00041 then local gX=GO[2];local hX,eX=Rp[gX]();do if not(hX)then else Dp=GO[5];(Rp)[gX+3]=eX;end;end;else if not(not(Rp[GO[0x00005]]<Rp[GO[0x4]]))then else Dp=GO[2];end;end;end;end;else do if NO>=62 then if NO~=0x3f then local V1=GO[2];do Fp=V1+GO[0X005]-1;end;do Rp[V1]=Rp[V1](l(Rp,V1+0X1,Fp));end;Fp=V1;else Rp[GO[0X2]]=Rp[GO[0X0005]]-GO[0X1];end;else Rp[GO[0X00002]]=Rp[GO[0X5]]%GO[0X001];end;end;end;end;end;else do if not(NO<83)then do if not(NO<0x057)then do if NO>=89 then if NO~=0X5A then local vF=(GO[0X0005]);local QF=(Rp[vF]);do for ix=vF+1,GO[4]do QF=QF..Rp[ix];end;end;(Rp)[GO[2]]=QF;else local bL=GO[0X2];Rp[bL](l(Rp,bL+0x1,Fp));do Fp=bL-1;end;end;else if NO==88 then Rp[GO[0X2]]=Rp[GO[5]]~Rp[GO[4]];else do if Rp[GO[0x00005]]~=GO[0X00001]then Dp=GO[0X02];end;end;end;end;end;else if NO>=0X00055 then if NO==86 then Rp[GO[2]]=Rp[GO[5]]|GO[0x0001];else local io=(GO[2]);local So=(GO[0X4]-0X0001)*50;local lo=(Rp[io]);for zC=0X001,GO[5]do do(lo)[So+zC]=Rp[io+zC];end;end;end;else if NO==0X54 then Rp[GO[0X0002]]=Rp[GO[5]]<=Rp[GO[0X004]];else do Rp[GO[2]]={};end;end;end;end;end;else if NO<0x4f then do if NO>=0X4D then if NO~=78 then do Rp[GO[2]]=Rp[GO[0x5]]<Rp[GO[0X00004]];end;else(Rp)[GO[2]]=Rp[GO[0x05]]//Rp[GO[0X4]];end;else do if GO[0X4]~=0x0079 then if Rp[GO[0x02]]then Dp=GO[5];end;else Dp=Dp-1;(d5)[Dp]={[2]=(GO[0x2]-0X74),[5]=(GO[5]-0X74),[0x3]=117};end;end;end;end;else if not(NO>=81)then if NO==0X050 then do(Rp)[GO[2]]=GO[6]|GO[0X1];end;else local tv=GO[0X2];local ev,gv=Rp[tv]();if ev then Rp[tv+0X0001]=gv;Dp=GO[5];end;end;else if NO==82 then do Rp[GO[0x2]]=GO[6]&Rp[GO[0x4]];end;else Fp=GO[0X2];Rp[Fp]();do Fp=Fp-0X1;end;end;end;end;end;end;end;end;end;end;end);if not(np)then do if d(vp)=="string"then if not(Q(vp,"^.-:%d+: "))then A(vp,0);else(A)("Luraph Script:"..(Z5[Dp-0X1]or"(internal)")..": "..B(vp),0X0);end;else(A)(vp,0X0);end;end;elseif vp then if qp~=1 then do return Rp[tp](l(Rp,tp+1,Fp));end;else return Rp[tp]();end;else if tp then return l(Rp,tp,qp);end;end;end;return T5;end;local function B8()local u8,F8,O8={},{nil,nil,m8,{},{},nil,{},nil,m8},(0X1);F8[8]=M();local t8=(U());(F8)[0X02]=x(t8,0X1,0X001)~=0X0;local ZI=(0X0);local YI=(nil);while ZI<0X002 do if ZI==0x0 then(F8)[0X006]=x(t8,2,0X1)~=0X00000;ZI=1;else YI=H()-X8;ZI=2;end;end;local LI=F8[4];for xi=0x0,YI-0X1 do do(LI)[xi]=B8();end;end;(F8)[3]=M();do(F8)[16]=H();end;F8[17]=U();local HI,cI,AI=nil,nil,nil;for Wh=0,4 do if Wh<=0X1 then if Wh~=0X000 then cI=H();else HI=F8[0X7];end;else if not(Wh<=0X2)then if Wh==3 then AI={};else F8[1]=M();end;else for jD=1,cI do local AD,TD,bD=nil,nil,nil;local BD=(3);while BD<=0X3 do if not(BD<=0X1)then do if BD==0X00002 then for Cc=AD,TD do(HI)[Cc]=bD;end;BD=0x00004;else AD=H();do BD=1;end;end;end;elseif BD==0X000 then bD=H();do BD=0X2;end;else TD=H();BD=0x0;end;end;end;end;end;end;ZI=0X1;local RI,M8,TI,pI,qI=nil,nil,nil,nil,(nil);do while 763109200 do if not(ZI<=2)then if ZI<=0X03 then pI=F8[0x00005];do ZI=4;end;elseif ZI==0X0004 then do qI=U()~=0X0;end;ZI=0X00002;else M8={};ZI=0;end;else if not(ZI<=0X0)then if ZI==1 then RI=H()-0X0781b;ZI=5;else do for uq=0X1,RI do local Lq=(m8);local Zq=U();do if Zq==n8 then Lq=H()+r8(H())*b;elseif Zq==72 then Lq=U()==1;elseif Zq==0x60 then Lq=K(t(TI),H());elseif Zq==0x8E then Lq=P8(0x0,h());elseif Zq==14 then do Lq=K(t(TI),U());end;elseif Zq==0X7 then Lq=K(t(TI),0X00004);else if Zq==209 then do Lq=T();end;elseif Zq==0xBD then Lq=T();elseif Zq==0X7A then do Lq=h()+H();end;else if Zq==x8 then do Lq=h();end;else if Zq==0X17 then do Lq=K(t(TI),h()+H());end;else if Zq==T8 then Lq=H()+y8(H())*b;end;end;end;end;end;end;local dq=nil;goto _718491095_0;::_718491095_1::;(u8)[uq-Y8]=O8;goto _718491095_2;::_718491095_0::;dq={Lq,{}};goto _718491095_1;::_718491095_2::;(M8)[O8]=dq;local wq=1;while wq~=0X2 do if wq~=0X0 then do O8=O8+1;end;wq=0X0;else if not(qI)then else N8[o8]=dq;o8=o8+0X001;end;wq=0X00002;end;end;end;end;break;break;do break;end;end;else TI=U();ZI=3;end;end;end;end;local XI=H()-0X17090;for hf=0,0x1 do if hf~=0 then do for mW=0x1,XI do local wW=0X0001;local XW=(nil);repeat if wW~=0X0 then XW=F8[0x00005][mW];wW=0;else for XY,NY in g,G do local IY,qY=S[NY],0X0;local RY=(nil);while qY~=2 do if qY==0 then RY=XW[IY];qY=1;else if RY==0X1 then local pV,RV,rV=0X1,nil,nil;repeat if pV==0 then rV=M8[RV];pV=2;else RV=u8[XW[NY]];pV=0;end;until pV>0X1;if rV then local LQ=nil;goto _418278549_0;::_418278549_0::;XW[IY]=rV[0X0001];goto _418278549_1;::_418278549_1::;LQ=rV[0X2];goto _418278549_2;::_418278549_2::;LQ[#LQ+1]={XW,IY};goto _418278549_3;::_418278549_3::;end;else if RY~=0X0 then else XW[NY]=mW+XW[NY]+0X1;end;end;do qY=2;end;end;end;end;break;break;end;until(false);end;end;else do for PJ=0X1,XI do local UJ,wJ,QJ,tJ=O(),O(),O(),O();local NJ,iJ,DJ=nil,nil,(nil);goto _82589205_0;::_82589205_0::;NJ,iJ,DJ=tJ%j8,UJ%0x4,wJ%0x4;goto _82589205_1;::_82589205_1::;pI[PJ]={[V8]=806672471,[0X00003]=1986405699,[0X2]='\x59\z  \x50\zv\z \x47\z \x78|\z\u{00004F}\x2A\x4B',[h8]=-1245497017,[1]=iJ,[6]="\u{00032}\z  \x5B\z \u{006C}",[7]='\z  \x29\z    \x52\u{2A}\z   \072\z \x56\z\x4E\z  \081',[2]=(tJ-NJ)/0x4,[0X6]=e8,[J8]=QJ,[5]=(wJ-DJ)/0x4,[6]=DJ,[G8]=NJ,[4]=(UJ-iJ)/0x4};goto _82589205_2;::_82589205_2::;end;end;end;end;ZI=0;do while true do if not(ZI<=0X00)then if ZI==0X0001 then do return F8;end;else for VA=1,M()do AI[VA]={U(),M()};end;ZI=1;end;else(F8)[w8]=AI;ZI=2;end;end;end;end;S8=1;local K8=nil;repeat if S8<=0 then K8=d8(K8,k,nil)(B8,N,J,A8,h,U,H,i);S8=2;else if S8==0X1 then K8=B8();do S8=0;end;else do return d8(K8,k,nil);end;end;end;until(false);end)(0.4321187290100964,string.rep,assert,rawset,0XFc,"\u{0003C}\u{000069}\z\x38",7,coroutine,error,type,0X2,true,0X5,next,string.unpack,string.gsub,3,0x06,0X9,"",pcall,'\z  \u{28}\x2E\u{029}\x28\z    \x2E\z    \u{029}',1,string.char,tostring,tonumber,nil,0x42A2,string.match,0X4,string.sub,0X2B,select,0XBa,table,function(...)do((...))[...]=nil;end;end,{},{21557,1825848494,908523089,731908847,0X003f07a1A8,3694305991,0Xa392aBAe,3527064920,0X000893D36F})(...);