--!nonstrict
-- Inventaire des monstres : ajout, placement, vente, auto-equipement, rebirth.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local MonsterData = require(ReplicatedStorage.Shared.MonsterData)
local CoffinData = require(ReplicatedStorage.Shared.CoffinData)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local Util = require(ReplicatedStorage.Shared.Util)

local InventoryService = {}
local S

local function findEntry(data, uid)
	for index, entry in ipairs(data.Monsters) do
		if entry.Uid == uid then
			return entry, index
		end
	end
	return nil
end

local function occupiedRooms(data)
	local occupied = {}
	for _, entry in ipairs(data.Monsters) do
		if entry.Room > 0 then
			occupied[entry.Room] = entry
		end
	end
	return occupied
end

local function firstFreeRoom(player, data)
	local count = S.Plot.roomCount(player)
	local occupied = occupiedRooms(data)
	for room = 1, count do
		if not occupied[room] then
			return room
		end
	end
	return nil
end

function InventoryService.count(data)
	return #data.Monsters
end

-- Ajoute un monstre a l'inventaire. Retourne entry, isNewDiscovery (nil si inventaire plein)
function InventoryService.addMonster(player, monsterId, force)
	local data = S.Data.get(player)
	local def = MonsterData.get(monsterId)
	if not data or not def then
		return nil, false
	end
	if not force and #data.Monsters >= Config.Inventory.MaxMonsters then
		return nil, false
	end
	local entry = { Uid = Util.uid(), Id = monsterId, Room = 0 }
	table.insert(data.Monsters, entry)
	local isNew = false
	if not data.Index[monsterId] then
		data.Index[monsterId] = true
		isNew = true
	end
	-- Placement automatique s'il reste une salle libre (gratification immediate)
	local room = firstFreeRoom(player, data)
	if room then
		entry.Room = room
		S.Plot.renderMonster(player, entry)
	end
	S.Economy.recalculate(player)
	S.Plot.refreshPads(player)
	return entry, isNew
end

function InventoryService.removeMonster(player, uid)
	local data = S.Data.get(player)
	if not data then
		return false
	end
	local entry, index = findEntry(data, uid)
	if not entry then
		return false
	end
	if entry.Room > 0 then
		S.Plot.removeModel(player, uid)
	end
	table.remove(data.Monsters, index)
	return true
end

function InventoryService.renderAll(player)
	local data = S.Data.get(player)
	if not data then
		return
	end
	S.Plot.clearModels(player)
	local count = S.Plot.roomCount(player)
	for _, entry in ipairs(data.Monsters) do
		if entry.Room > count then
			entry.Room = 0
		end
		if entry.Room > 0 then
			S.Plot.renderMonster(player, entry)
		end
	end
	S.Plot.refreshPads(player)
end

function InventoryService.sellValue(entry)
	local def = MonsterData.get(entry.Id)
	if not def then
		return 0
	end
	return Economy.sellPrice(def.Rarity, CoffinData.referenceCost(entry.Id))
end

function InventoryService.equip(player, uid)
	local data = S.Data.get(player)
	local entry = findEntry(data, uid)
	if not entry then
		return { ok = false, message = "Monstre introuvable." }
	end
	if entry.Room > 0 then
		return { ok = false, message = "Ce monstre est déjà placé." }
	end
	local room = firstFreeRoom(player, data)
	if not room then
		return { ok = false, message = "Toutes tes salles sont pleines ! Retire un monstre ou achète une salle." }
	end
	entry.Room = room
	S.Plot.renderMonster(player, entry)
	S.Economy.recalculate(player)
	S.Plot.refreshPads(player)
	S.Player.sendState(player)
	return { ok = true }
end

function InventoryService.unequip(player, uid)
	local data = S.Data.get(player)
	local entry = findEntry(data, uid)
	if not entry then
		return { ok = false, message = "Monstre introuvable." }
	end
	if entry.Room == 0 then
		return { ok = false, message = "Ce monstre n'est pas placé." }
	end
	S.Plot.removeModel(player, uid)
	entry.Room = 0
	S.Economy.recalculate(player)
	S.Plot.refreshPads(player)
	S.Player.sendState(player)
	return { ok = true }
end

function InventoryService.sell(player, uid)
	local data = S.Data.get(player)
	local entry = findEntry(data, uid)
	if not entry then
		return { ok = false, message = "Monstre introuvable." }
	end
	local def = MonsterData.get(entry.Id)
	if def.Exclusive then
		return { ok = false, message = "Les monstres exclusifs ne peuvent pas être vendus." }
	end
	local value = InventoryService.sellValue(entry)
	InventoryService.removeMonster(player, uid)
	S.Economy.addCoins(player, value)
	S.Economy.recalculate(player)
	S.Plot.refreshPads(player)
	S.Player.sendState(player)
	return { ok = true, message = def.Name .. " vendu pour " .. Economy.format(value) .. " coins.", data = { Value = value } }
end

-- Vend tous les monstres non places de rarete Rare ou moins (jamais les exclusifs)
function InventoryService.sellUnplaced(player)
	local data = S.Data.get(player)
	local total = 0
	local sold = 0
	for index = #data.Monsters, 1, -1 do
		local entry = data.Monsters[index]
		local def = MonsterData.get(entry.Id)
		if entry.Room == 0 and def and not def.Exclusive and Rarity.rank(def.Rarity) <= Rarity.rank("Rare") then
			total += InventoryService.sellValue(entry)
			table.remove(data.Monsters, index)
			sold += 1
		end
	end
	if sold == 0 then
		return { ok = false, message = "Aucun monstre commun, peu commun ou rare à vendre." }
	end
	S.Economy.addCoins(player, total)
	S.Economy.recalculate(player)
	S.Player.sendState(player)
	return { ok = true, message = sold .. " monstres vendus pour " .. Economy.format(total) .. " coins.", data = { Value = total, Count = sold } }
end

-- Place automatiquement les meilleurs monstres
function InventoryService.autoEquip(player)
	local data = S.Data.get(player)
	local count = S.Plot.roomCount(player)
	local sorted = table.clone(data.Monsters)
	table.sort(sorted, function(a, b)
		local pa = MonsterData.get(a.Id).Power
		local pb = MonsterData.get(b.Id).Power
		if pa == pb then
			return a.Uid < b.Uid
		end
		return pa > pb
	end)
	for index, entry in ipairs(sorted) do
		entry.Room = index <= count and index or 0
	end
	InventoryService.renderAll(player)
	S.Economy.recalculate(player)
	S.Player.sendState(player)
	return { ok = true, message = "Tes meilleurs monstres sont en place !" }
end

-- Retire les monstres non conserves lors d'un rebirth
function InventoryService.wipeForRebirth(player)
	local data = S.Data.get(player)
	for index = #data.Monsters, 1, -1 do
		local entry = data.Monsters[index]
		local def = MonsterData.get(entry.Id)
		if not (def and def.KeepOnRebirth) then
			table.remove(data.Monsters, index)
		end
	end
	local room = 0
	for _, entry in ipairs(data.Monsters) do
		room += 1
		entry.Room = room
	end
	InventoryService.renderAll(player)
end

function InventoryService.init(services)
	S = services
	S.Net.register("Equip", "Default", function(player, payload)
		if type(payload.Uid) ~= "string" then
			return { ok = false, message = "Requête invalide." }
		end
		return InventoryService.equip(player, payload.Uid)
	end)
	S.Net.register("Unequip", "Default", function(player, payload)
		if type(payload.Uid) ~= "string" then
			return { ok = false, message = "Requête invalide." }
		end
		return InventoryService.unequip(player, payload.Uid)
	end)
	S.Net.register("Sell", "Default", function(player, payload)
		if type(payload.Uid) ~= "string" then
			return { ok = false, message = "Requête invalide." }
		end
		return InventoryService.sell(player, payload.Uid)
	end)
	S.Net.register("SellUnplaced", "Shop", function(player)
		return InventoryService.sellUnplaced(player)
	end)
	S.Net.register("AutoEquip", "Shop", function(player)
		return InventoryService.autoEquip(player)
	end)
end

return InventoryService
