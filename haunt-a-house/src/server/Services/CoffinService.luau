--!nonstrict
-- Ouverture des cercueils (gacha en monnaie du jeu, probabilites affichees et calculees cote serveur).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local CoffinData = require(ReplicatedStorage.Shared.CoffinData)
local MonsterData = require(ReplicatedStorage.Shared.MonsterData)
local GachaMath = require(ReplicatedStorage.Shared.GachaMath)
local Rarity = require(ReplicatedStorage.Shared.Rarity)

local CoffinService = {}
local S

local rng = Random.new()

local function entriesFor(coffin)
	local entries = {}
	for _, item in ipairs(coffin.Contents) do
		local def = MonsterData.get(item.Id)
		table.insert(entries, { Id = item.Id, Weight = item.Weight, Rank = Rarity.rank(def.Rarity) })
	end
	return entries
end

local function nearCrypt(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	return (root.Position - S.Map.Points.Crypt.Position).Magnitude <= 45
end

-- Ouvre `count` cercueils deja payes. Retourne la liste des resultats.
local function hatch(player, coffin, count)
	local data = S.Data.get(player)
	local st = S.Economy.getState(player)
	local entries = entriesFor(coffin)
	local results = {}
	local bestRank = 0
	local bestDef = nil
	for _ = 1, count do
		local id = GachaMath.roll(entries, st.Luck, function()
			return rng:NextNumber()
		end)
		local entry, isNew = S.Inventory.addMonster(player, id, true)
		local def = MonsterData.get(id)
		table.insert(results, { Uid = entry.Uid, Id = id, New = isNew, Placed = entry.Room > 0 })
		data.Stats.Hatches += 1
		local rank = Rarity.rank(def.Rarity)
		if rank > bestRank then
			bestRank = rank
			bestDef = def
		end
	end
	S.Season.addXp(player, Config.Season.XpHatch * count)
	if bestDef and Rarity.Info[bestDef.Rarity].Announce then
		S.Net.announce("🎉 " .. player.DisplayName .. " a trouvé un monstre " .. string.upper(Rarity.label(bestDef.Rarity)) .. " : " .. bestDef.Name .. " !", "rare")
	end
	S.Player.sendState(player)
	return results
end

function CoffinService.buy(player, coffinId, count)
	local data = S.Data.get(player)
	local coffin = CoffinData.get(coffinId)
	if not coffin or coffin.EventOnly then
		return { ok = false, message = "Cercueil inconnu." }
	end
	count = tonumber(count) or 1
	if count ~= 1 and count ~= 3 then
		return { ok = false, message = "Quantité invalide." }
	end
	if count == 3 and not S.Shop.ownsPass(player, "TripleHatch") then
		return { ok = false, message = "Le pass Triple Cercueil est nécessaire pour ouvrir 3 cercueils d'un coup." }
	end
	if data.Rebirths < coffin.RebirthRequired then
		return { ok = false, message = "Ce cercueil se débloque au rebirth " .. coffin.RebirthRequired .. "." }
	end
	if not nearCrypt(player) then
		return { ok = false, message = "Va à la Crypte pour ouvrir des cercueils." }
	end
	if #data.Monsters + count > Config.Inventory.MaxMonsters then
		return { ok = false, message = "Inventaire plein (" .. Config.Inventory.MaxMonsters .. ") ! Vends des monstres." }
	end
	local total = coffin.Cost * count
	if not S.Economy.spendCoins(player, total) then
		return { ok = false, message = "Il te manque " .. Economy.format(total - data.Coins) .. " coins." }
	end
	local results = hatch(player, coffin, count)
	return { ok = true, data = { Coffin = coffin.Id, Results = results } }
end

function CoffinService.openNightmare(player, count)
	local data = S.Data.get(player)
	count = tonumber(count) or 1
	if count ~= 1 and count ~= 3 then
		return { ok = false, message = "Quantité invalide." }
	end
	if count == 3 and not S.Shop.ownsPass(player, "TripleHatch") then
		return { ok = false, message = "Le pass Triple Cercueil est nécessaire pour ouvrir 3 cercueils d'un coup." }
	end
	if data.NightmareCoffins < count then
		return { ok = false, message = "Tu n'as pas assez de Cercueils Cauchemar. Gagne-les lors des raids de Minuit, la série quotidienne et le Passe Spooky." }
	end
	if #data.Monsters + count > Config.Inventory.MaxMonsters then
		return { ok = false, message = "Inventaire plein ! Vends des monstres." }
	end
	data.NightmareCoffins -= count
	player:SetAttribute("NightmareCoffins", data.NightmareCoffins)
	local results = hatch(player, CoffinData.get("nightmare"), count)
	return { ok = true, data = { Coffin = "nightmare", Results = results } }
end

function CoffinService.init(services)
	S = services
	S.Net.register("BuyCoffin", "Hatch", function(player, payload)
		return CoffinService.buy(player, payload.CoffinId, payload.Count)
	end)
	S.Net.register("OpenNightmare", "Hatch", function(player, payload)
		return CoffinService.openNightmare(player, payload.Count)
	end)
end

return CoffinService
