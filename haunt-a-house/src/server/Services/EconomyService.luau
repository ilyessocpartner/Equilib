--!nonstrict
-- Revenus passifs, collecte, boosts et multiplicateurs.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local MonsterData = require(ReplicatedStorage.Shared.MonsterData)
local Util = require(ReplicatedStorage.Shared.Util)

local EconomyService = {}
local S

local states = {} -- [player] = { BasePower, Multiplier, Income, Luck, Uncollected, CoinsBoost, LuckBoost, ServerLuck }
EconomyService.ServerLuckUntil = 0

local function countIndex(index)
	local n = 0
	for _ in pairs(index) do
		n += 1
	end
	return n
end

local function getState(player)
	local st = states[player]
	if not st then
		st = { BasePower = 0, Multiplier = 1, Income = 0, Luck = 1, Uncollected = 0, CoinsBoost = false, LuckBoost = false, ServerLuck = false }
		states[player] = st
	end
	return st
end

local function refreshCoinAttributes(player, data)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("TotalCoins", data.TotalCoins)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local coins = stats:FindFirstChild("Coins")
		if coins then
			coins.Value = Economy.format(data.Coins)
		end
	end
end

function EconomyService.getState(player)
	return getState(player)
end

function EconomyService.recalculate(player)
	local data = S.Data.get(player)
	if not data then
		return
	end
	local st = getState(player)
	local base = 0
	for _, entry in ipairs(data.Monsters) do
		if entry.Room > 0 then
			local def = MonsterData.get(entry.Id)
			if def then
				base += def.Power
			end
		end
	end
	local now = os.time()
	st.CoinsBoost = data.Boosts.Coins > now
	st.LuckBoost = data.Boosts.Luck > now
	st.ServerLuck = EconomyService.ServerLuckUntil > now
	local flags = {
		Rebirths = data.Rebirths,
		DoubleCoins = S.Shop.ownsPass(player, "DoubleCoins"),
		VIP = S.Shop.ownsPass(player, "VIP"),
		CoinsBoost = st.CoinsBoost,
		IndexCount = countIndex(data.Index),
		InGroup = S.Player.isInGroup(player),
	}
	st.BasePower = base
	st.Multiplier = Economy.incomeMultiplier(flags)
	st.Income = base * st.Multiplier
	st.Luck = Economy.luckMultiplier({
		LuckyPass = S.Shop.ownsPass(player, "Lucky"),
		LuckBoost = st.LuckBoost,
		ServerLuck = st.ServerLuck,
	})
	if base > (data.Stats.BestPower or 0) then
		data.Stats.BestPower = base
	end
	player:SetAttribute("BasePower", base)
	player:SetAttribute("Multiplier", st.Multiplier)
	player:SetAttribute("Income", st.Income)
	player:SetAttribute("Luck", st.Luck)
	player:SetAttribute("CoinsBoostEnd", data.Boosts.Coins)
	player:SetAttribute("LuckBoostEnd", data.Boosts.Luck)
	player:SetAttribute("AutoCollect", S.Shop.ownsPass(player, "AutoCollect"))
end

function EconomyService.addCoins(player, amount)
	local data = S.Data.get(player)
	if not data or not Util.isFinite(amount) or amount <= 0 then
		return false
	end
	amount = math.floor(amount)
	data.Coins += amount
	data.TotalCoins += amount
	refreshCoinAttributes(player, data)
	return true
end

function EconomyService.spendCoins(player, amount)
	local data = S.Data.get(player)
	if not data or not Util.isFinite(amount) or amount < 0 then
		return false
	end
	if data.Coins < amount then
		return false
	end
	data.Coins -= amount
	refreshCoinAttributes(player, data)
	return true
end

function EconomyService.collect(player)
	local st = getState(player)
	local amount = math.floor(st.Uncollected)
	if amount < 1 then
		S.Net.notify(player, "Rien à collecter pour l'instant. Place des monstres !", "info")
		return
	end
	st.Uncollected = 0
	EconomyService.addCoins(player, amount)
	S.Plot.updateBooth(player, 0)
	S.Net.fire(player, "Collected", { Amount = amount })
end

-- kind : "Coins" | "Luck"
function EconomyService.addBoost(player, kind, seconds)
	local data = S.Data.get(player)
	if not data then
		return
	end
	local now = os.time()
	local current = data.Boosts[kind] or 0
	data.Boosts[kind] = math.max(now, current) + seconds
	EconomyService.recalculate(player)
end

function EconomyService.activateServerLuck(seconds, byPlayer)
	local now = os.time()
	EconomyService.ServerLuckUntil = math.max(now, EconomyService.ServerLuckUntil) + seconds
	ReplicatedStorage:SetAttribute("ServerLuckEnd", EconomyService.ServerLuckUntil)
	local who = byPlayer and byPlayer.DisplayName or "Quelqu'un"
	S.Net.announce("🍀 " .. who .. " a activé CHANCE x2 pour tout le serveur pendant " .. math.floor(seconds / 60) .. " min !", "luck")
	for _, player in ipairs(Players:GetPlayers()) do
		EconomyService.recalculate(player)
	end
end

local function tick()
	local now = os.time()
	local serverLuckActive = EconomyService.ServerLuckUntil > now
	for _, player in ipairs(Players:GetPlayers()) do
		local data = S.Data.get(player)
		if data then
			local st = getState(player)
			local coinsBoostActive = data.Boosts.Coins > now
			local luckBoostActive = data.Boosts.Luck > now
			if coinsBoostActive ~= st.CoinsBoost or luckBoostActive ~= st.LuckBoost or serverLuckActive ~= st.ServerLuck then
				local coinsEnded = st.CoinsBoost and not coinsBoostActive
				local luckEnded = st.LuckBoost and not luckBoostActive
				EconomyService.recalculate(player)
				if coinsEnded then
					S.Net.notify(player, "Ton boost 2x Coins est terminé.", "info")
				end
				if luckEnded then
					S.Net.notify(player, "Ton boost 2x Chance est terminé.", "info")
				end
			end
			local income = st.Income * Config.Income.TickSeconds
			if income > 0 then
				if S.Shop.ownsPass(player, "AutoCollect") then
					EconomyService.addCoins(player, income)
				else
					local cap = st.Income * Config.Income.MaxUncollectedSeconds
					st.Uncollected = math.min(st.Uncollected + income, cap)
					S.Plot.updateBooth(player, st.Uncollected)
				end
			end
			data.Stats.PlayTime += Config.Income.TickSeconds
		end
	end
end

function EconomyService.init(services)
	S = services
	ReplicatedStorage:SetAttribute("ServerLuckEnd", 0)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Income.TickSeconds)
			local ok, err = pcall(tick)
			if not ok then
				warn("[EconomyService] " .. tostring(err))
			end
		end
	end)
	S.Net.register("Collect", "Default", function(player)
		local plot = S.Plot.get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not plot or not root or (root.Position - plot.Booth.Position).Magnitude > 20 then
			return { ok = false, message = "Approche-toi de ta caisse pour collecter." }
		end
		EconomyService.collect(player)
		return { ok = true }
	end)
end

return EconomyService
