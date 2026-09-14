--!nonstrict
-- Cycle de vie du joueur : chargement, leaderstats, attributs, synchronisation d'etat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Offers = require(ReplicatedStorage.Shared.Offers)
local MonetizationIds = require(ReplicatedStorage.Shared.MonetizationIds)

local PlayerService = {}
local S

local groupCache = {} -- [player] = bool

local function setupLeaderstats(player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("StringValue")
	coins.Name = "Coins"
	coins.Value = Economy.format(data.Coins)
	coins.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths
	rebirths.Parent = stats
	stats.Parent = player
end

function PlayerService.isInGroup(player)
	return groupCache[player] == true
end

local function checkGroup(player)
	if MonetizationIds.GroupId == 0 then
		groupCache[player] = false
		return
	end
	local ok, result = pcall(function()
		return player:IsInGroup(MonetizationIds.GroupId)
	end)
	groupCache[player] = ok and result == true
end

local function addVipTag(character)
	local head = character:FindFirstChild("Head")
	if not head or head:FindFirstChild("VipTag") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VipTag"
	gui.Size = UDim2.fromOffset(120, 34)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "👑 VIP"
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 215, 60)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = head
end

-- Attributs repliques (le client lit ces valeurs pour le HUD)
function PlayerService.refreshAttributes(player)
	local data = S.Data.get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("TotalCoins", data.TotalCoins)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("RebirthCost", Economy.rebirthCost(data.Rebirths))
	player:SetAttribute("NightmareCoffins", data.NightmareCoffins)
	player:SetAttribute("CoinsBoostEnd", data.Boosts.Coins)
	player:SetAttribute("LuckBoostEnd", data.Boosts.Luck)
	player:SetAttribute("DailyLastClaim", data.Daily.LastClaim)
	player:SetAttribute("DailyStreak", data.Daily.Streak)
	player:SetAttribute("SeasonXp", data.Season.Xp)
	player:SetAttribute("StarterRemaining", Offers.starterRemaining(data.Starter.FirstJoin, data.Starter.Purchased, os.time()))
	player:SetAttribute("StarterFirstJoin", data.Starter.FirstJoin)
	player:SetAttribute("StarterPurchased", data.Starter.Purchased)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = Economy.format(data.Coins)
		stats.Rebirths.Value = data.Rebirths
	end
end

-- Etat complet envoye au client (inventaire, index, passes, catalogue, etc.)
function PlayerService.sendState(player)
	local data = S.Data.get(player)
	if not data then
		return
	end
	local state = {
		Monsters = data.Monsters,
		Index = data.Index,
		Rooms = S.Plot.roomInfo(player),
		Passes = S.Shop.ownedPasses(player),
		Catalog = S.Shop.catalog(),
		Season = { Id = data.Season.Id, Xp = data.Season.Xp, ClaimedFree = data.Season.ClaimedFree, ClaimedPremium = data.Season.ClaimedPremium },
		Playtime = S.Playtime.claimedList(player),
		Codes = data.Codes,
		Stats = data.Stats,
		Restricted = S.Shop.isRandomRestricted(player),
		MemoryMode = S.Data.isMemoryMode(),
		InGroup = PlayerService.isInGroup(player),
	}
	S.Net.fire(player, "State", state)
	PlayerService.refreshAttributes(player)
end

function PlayerService.applyVipTag(player)
	local character = player.Character
	if character and S.Shop.ownsPass(player, "VIP") then
		addVipTag(character)
	end
end

local function onCharacterAdded(player, character)
	task.defer(function()
		if S.Shop.ownsPass(player, "VIP") then
			addVipTag(character)
		end
	end)
end

local function onPlayerAdded(player)
	player:SetAttribute("DataLoaded", false)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	local data = S.Data.load(player)
	if not data or not player.Parent then
		return
	end
	if data.Starter.FirstJoin == 0 then
		data.Starter.FirstJoin = os.time()
	end
	if data.Season.Id ~= Config.Season.Id then
		data.Season = { Id = Config.Season.Id, Xp = 0, ClaimedFree = {}, ClaimedPremium = {} }
	end

	setupLeaderstats(player, data)
	checkGroup(player)
	S.Shop.setupPlayer(player)
	S.Plot.assign(player)
	S.Economy.recalculate(player)
	S.Playtime.start(player)
	player:SetAttribute("SessionStart", os.time())
	player:SetAttribute("DataLoaded", true)
	PlayerService.sendState(player)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	S.Net.notify(player, "Bienvenue " .. player.DisplayName .. " ! Va à la Crypte (bâtiment violet au nord) pour ouvrir ton premier cercueil, puis clique sur les visiteurs de ton manoir pour crier BOO !", "success")
end

function PlayerService.init(services)
	S = services
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		groupCache[player] = nil
	end)

	S.Net.register("TeleportHome", "Default", function(player)
		local cf = S.Plot.homeCFrame(player)
		local character = player.Character
		if cf and character and character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo(cf)
			return { ok = true }
		end
		return { ok = false, message = "Impossible de te téléporter pour l'instant." }
	end)

	S.Net.register("TeleportHub", "Default", function(player)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo(S.Map.Points.Spawn)
			return { ok = true }
		end
		return { ok = false }
	end)

	S.Net.register("GetState", "Default", function(player)
		PlayerService.sendState(player)
		return { ok = true }
	end)
end

return PlayerService
