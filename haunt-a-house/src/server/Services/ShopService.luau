--!nonstrict
-- Boutique : Game Passes, Developer Products, recus, politique des objets aleatoires payants.
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Offers = require(ReplicatedStorage.Shared.Offers)
local MonetizationIds = require(ReplicatedStorage.Shared.MonetizationIds)

local ShopService = {}
local S

local PASS_ORDER = { "DoubleCoins", "AutoCollect", "TripleHatch", "ExtraRooms", "Lucky", "VIP", "Ultimate", "SeasonPremium" }
local PRODUCT_ORDER = { "CoinsSmall", "CoinsMedium", "CoinsLarge", "CoinsHuge", "BoostCoins", "BoostLuck", "ServerLuck", "InstantRebirth", "StarterPack", "FlashCoinVault", "FlashBoostBundle", "FlashRebirthRush" }
local ULTIMATE_INCLUDES = { DoubleCoins = true, AutoCollect = true, TripleHatch = true, ExtraRooms = true, Lucky = true, VIP = true }
-- Articles lies aux objets aleatoires payants (masques dans les regions ou la politique l'exige)
local RANDOM_RELATED = { Lucky = true, Ultimate = true, BoostLuck = true, ServerLuck = true, CoinsSmall = true, CoinsMedium = true, CoinsLarge = true, CoinsHuge = true, StarterPack = true, FlashCoinVault = true, FlashBoostBundle = true }

local passCache = {} -- [player] = { [key] = bool }
local policyCache = {} -- [player] = bool (restreint)
local catalog = { Passes = {}, Products = {} }
local passKeyById = {}
local productKeyById = {}

local function buildCatalog()
	local missing = {}
	for _, key in ipairs(PASS_ORDER) do
		local def = MonetizationIds.GamePasses[key]
		table.insert(catalog.Passes, { Key = key, Id = def.Id, Price = def.Price, Name = def.Name, Desc = def.Desc, Icon = def.Icon, Configured = def.Id > 0, Random = RANDOM_RELATED[key] == true })
		if def.Id > 0 then
			passKeyById[def.Id] = key
		else
			table.insert(missing, "GamePasses." .. key)
		end
	end
	for _, key in ipairs(PRODUCT_ORDER) do
		local def = MonetizationIds.Products[key]
		table.insert(catalog.Products, { Key = key, Id = def.Id, Price = def.Price, Name = def.Name, Configured = def.Id > 0, Random = RANDOM_RELATED[key] == true })
		if def.Id > 0 then
			productKeyById[def.Id] = key
		else
			table.insert(missing, "Products." .. key)
		end
	end
	if #missing > 0 then
		warn("[ShopService] Identifiants non configurés dans ReplicatedStorage/Shared/MonetizationIds : " .. table.concat(missing, ", ") .. ". Ces articles sont désactivés en boutique.")
	end
end

local function fetchRealPrices()
	for _, entry in ipairs(catalog.Passes) do
		if entry.Configured then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(entry.Id, Enum.InfoType.GamePass)
			end)
			if ok and info and info.PriceInRobux then
				entry.Price = info.PriceInRobux
			end
		end
	end
	for _, entry in ipairs(catalog.Products) do
		if entry.Configured then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(entry.Id, Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux then
				entry.Price = info.PriceInRobux
			end
		end
	end
end

function ShopService.catalog()
	return catalog
end

function ShopService.ownsPass(player, key)
	local cache = passCache[player]
	if not cache then
		return false
	end
	if cache[key] then
		return true
	end
	if ULTIMATE_INCLUDES[key] and cache.Ultimate then
		return true
	end
	return false
end

function ShopService.ownedPasses(player)
	local result = {}
	for _, key in ipairs(PASS_ORDER) do
		result[key] = ShopService.ownsPass(player, key)
	end
	return result
end

function ShopService.isRandomRestricted(player)
	return policyCache[player] == true
end

local function grantVipMonster(player)
	local data = S.Data.get(player)
	if data and not data.VipMonsterGranted then
		data.VipMonsterGranted = true
		S.Inventory.addMonster(player, "vip_phantom", true)
		S.Net.notify(player, "👑 Ton Phantom VIP exclusif a rejoint ton manoir !", "success")
	end
end

function ShopService.setupPlayer(player)
	local cache = {}
	passCache[player] = cache
	for _, key in ipairs(PASS_ORDER) do
		local def = MonetizationIds.GamePasses[key]
		if def.Id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.Id)
			end)
			cache[key] = ok and owns == true
		else
			cache[key] = false
		end
	end
	local okPolicy, policy = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if okPolicy and type(policy) == "table" then
		policyCache[player] = policy.ArePaidRandomItemsRestricted == true
	else
		policyCache[player] = true
	end
	player:SetAttribute("PaidRandomRestricted", policyCache[player])
	player:SetAttribute("VIP", ShopService.ownsPass(player, "VIP"))
	if ShopService.ownsPass(player, "VIP") then
		grantVipMonster(player)
	end
end

local function onPassPurchased(player, key)
	local cache = passCache[player]
	if not cache then
		return
	end
	cache[key] = true
	player:SetAttribute("VIP", ShopService.ownsPass(player, "VIP"))
	if ShopService.ownsPass(player, "VIP") then
		grantVipMonster(player)
		S.Player.applyVipTag(player)
	end
	S.Economy.recalculate(player)
	S.Plot.refreshPads(player)
	S.Inventory.renderAll(player)
	S.Player.sendState(player)
	local def = MonetizationIds.GamePasses[key]
	S.Net.notify(player, "✅ Pass " .. def.Name .. " activé ! Merci pour ton soutien.", "success")
	S.Net.announce("🛒 " .. player.DisplayName .. " a acheté le pass " .. def.Name .. " !", "shop")
	S.Data.save(player)
end

local function grantProduct(player, key)
	local data = S.Data.get(player)
	local def = MonetizationIds.Products[key]
	for _, bundle in ipairs(Config.CoinBundles) do
		if bundle.Key == key then
			local amount = Economy.bundleAmount(bundle.Coins, data.Rebirths)
			S.Economy.addCoins(player, amount)
			S.Net.notify(player, "💰 +" .. Economy.format(amount) .. " coins ! Merci pour ton achat.", "success")
			return
		end
	end
	if key == "BoostCoins" then
		S.Economy.addBoost(player, "Coins", Config.Boosts.CoinsBoostSeconds)
		S.Net.notify(player, "⚡ Boost 2x Coins activé pendant 30 min !", "success")
	elseif key == "BoostLuck" then
		S.Economy.addBoost(player, "Luck", Config.Boosts.LuckBoostSeconds)
		S.Net.notify(player, "🍀 Boost 2x Chance activé pendant 30 min !", "success")
	elseif key == "ServerLuck" then
		S.Economy.activateServerLuck(Config.Boosts.ServerLuckSeconds, player)
	elseif key == "InstantRebirth" then
		S.Rebirth.perform(player, true)
		S.Net.notify(player, "♻️ Rebirth instantané effectué !", "success")
	elseif key == "StarterPack" then
		local starter = Config.StarterPack
		S.Economy.addCoins(player, starter.Coins)
		S.Inventory.addMonster(player, starter.MonsterId, true)
		S.Economy.addBoost(player, "Coins", starter.CoinsBoostSeconds)
		data.Starter.Purchased = true
		S.Net.notify(player, "🎁 Pack de démarrage reçu : coins, Ghosty Doré et boost 2x !", "success")
	else
		for _, deal in ipairs(Config.FlashDeals.Deals) do
			if deal.Key == key then
				if deal.Coins then
					S.Economy.addCoins(player, Economy.bundleAmount(deal.Coins, data.Rebirths))
				end
				if deal.CoinsBoostSeconds then
					S.Economy.addBoost(player, "Coins", deal.CoinsBoostSeconds)
				end
				if deal.LuckBoostSeconds then
					S.Economy.addBoost(player, "Luck", deal.LuckBoostSeconds)
				end
				if deal.InstantRebirth then
					S.Rebirth.perform(player, true)
				end
				S.Net.notify(player, "⚡ Offre flash reçue : " .. deal.Title .. " !", "success")
				return
			end
		end
		error("Produit sans effet : " .. tostring(key))
	end
	if def then
		S.Net.announce("🛒 " .. player.DisplayName .. " a acheté " .. def.Name .. " !", "shop")
	end
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = S.Data.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local key = productKeyById[receiptInfo.ProductId]
	if not key then
		warn("[ShopService] Produit inconnu : " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if S.Data.hasReceipt(data, receiptInfo.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local ok, err = pcall(grantProduct, player, key)
	if not ok then
		warn("[ShopService] Échec d'attribution du produit " .. key .. " : " .. tostring(err))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	S.Data.recordReceipt(data, receiptInfo.PurchaseId)
	S.Player.sendState(player)
	pcall(S.Data.save, player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function promptHandler(player, payload)
	local kind = payload.Kind
	local key = payload.Key
	if type(kind) ~= "string" or type(key) ~= "string" then
		return { ok = false, message = "Requête invalide." }
	end
	local data = S.Data.get(player)
	if RANDOM_RELATED[key] and ShopService.isRandomRestricted(player) then
		return { ok = false, message = "Cet article n'est pas disponible dans ta région." }
	end
	if kind == "Pass" then
		local def = MonetizationIds.GamePasses[key]
		if not def then
			return { ok = false, message = "Article inconnu." }
		end
		if def.Id <= 0 then
			return { ok = false, message = "Cet article n'est pas encore disponible." }
		end
		if ShopService.ownsPass(player, key) then
			return { ok = false, message = "Tu possèdes déjà ce pass !" }
		end
		local ok = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, def.Id)
		end)
		return { ok = ok }
	elseif kind == "Product" then
		local def = MonetizationIds.Products[key]
		if not def then
			return { ok = false, message = "Article inconnu." }
		end
		if def.Id <= 0 then
			return { ok = false, message = "Cet article n'est pas encore disponible." }
		end
		if key == "StarterPack" and Offers.starterRemaining(data.Starter.FirstJoin, data.Starter.Purchased, os.time()) <= 0 then
			return { ok = false, message = "Cette offre a expiré." }
		end
		if string.sub(key, 1, 5) == "Flash" then
			local _, deal = Offers.getFlashDeal(os.time())
			if deal.Key ~= key then
				return { ok = false, message = "Cette offre flash n'est plus active." }
			end
		end
		local ok = pcall(function()
			MarketplaceService:PromptProductPurchase(player, def.Id)
		end)
		return { ok = ok }
	end
	return { ok = false, message = "Requête invalide." }
end

function ShopService.init(services)
	S = services
	buildCatalog()
	task.spawn(fetchRealPrices)
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = passKeyById[passId]
		if key and S.Data.get(player) then
			onPassPurchased(player, key)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		passCache[player] = nil
		policyCache[player] = nil
	end)
	S.Net.register("Prompt", "Shop", promptHandler)
end

return ShopService
