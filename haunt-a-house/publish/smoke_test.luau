-- Test de fumee execute dans le moteur Roblox (Open Cloud Luau Execution) apres publication.
-- Il charge tous les modules, construit la carte et les monstres, initialise les services
-- et verifie l'interface. Chaque ligne "ECHEC" indique un probleme a corriger.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local failures = 0
local function step(name, fn)
	local ok, err = pcall(fn)
	local line = (ok and "OK    " or "ECHEC ") .. name .. (ok and "" or (" : " .. tostring(err)))
	print(line)
	if not ok then
		failures += 1
	end
	return ok
end

local Shared = ReplicatedStorage:FindFirstChild("Shared")
assert(Shared, "ReplicatedStorage.Shared introuvable : la place publiee n'est pas celle du jeu")
for _, module in ipairs(Shared:GetChildren()) do
	step("Module partage " .. module.Name, function()
		require(module)
	end)
end

step("Construction des monstres", function()
	local MonsterBuilder = require(Shared.MonsterBuilder)
	local MonsterData = require(Shared.MonsterData)
	local count = 0
	for _, def in ipairs(MonsterData.List) do
		local model = MonsterBuilder.build(def, CFrame.new())
		assert(model.PrimaryPart, "pas de PrimaryPart pour " .. def.Id)
		assert(#model:GetChildren() >= 3, "modele vide pour " .. def.Id)
		model:Destroy()
		count += 1
	end
	print("Monstres construits : " .. count)
end)

local Server = ServerScriptService:FindFirstChild("Server")
assert(Server, "ServerScriptService.Server introuvable")
local Services = Server:FindFirstChild("Services")
local S = { Config = require(Shared.Config) }
step("Chargement des services serveur", function()
	S.Net = require(Server.NetServer)
	S.Data = require(Services.DataService)
	S.Player = require(Services.PlayerService)
	S.Map = require(Services.MapBuilder)
	S.Plot = require(Services.PlotService)
	S.Inventory = require(Services.InventoryService)
	S.Economy = require(Services.EconomyService)
	S.Reward = require(Services.RewardService)
	S.Shop = require(Services.ShopService)
	S.Coffin = require(Services.CoffinService)
	S.Rebirth = require(Services.RebirthService)
	S.Daily = require(Services.DailyRewardService)
	S.Playtime = require(Services.PlaytimeService)
	S.Season = require(Services.SeasonPassService)
	S.Codes = require(Services.CodesService)
	S.Leaderboard = require(Services.LeaderboardService)
	S.Boss = require(Services.BossService)
	S.Visitor = require(Services.VisitorService)
end)

local Net = require(Shared.Net)
step("Creation des remotes", function()
	Net.request()
	Net.serverEvent()
	Net.clientEvent()
end)

local order = { { "Net" }, { "Data" }, { "Map", "build" }, { "Plot" }, { "Inventory" }, { "Economy" }, { "Reward" }, { "Shop" }, { "Coffin" }, { "Rebirth" }, { "Daily" }, { "Playtime" }, { "Season" }, { "Codes" }, { "Leaderboard" }, { "Boss" }, { "Visitor" }, { "Player" } }
for _, entry in ipairs(order) do
	local key, fnName = entry[1], entry[2] or "init"
	step("Initialisation " .. key, function()
		assert(S[key], "service manquant " .. key)
		S[key][fnName](S)
	end)
end

step("Carte generee", function()
	local map = workspace:FindFirstChild("Map")
	assert(map, "workspace.Map absent")
	assert(map:FindFirstChild("Hub"), "Hub absent")
	local plots = map:FindFirstChild("Plots")
	assert(plots, "Plots absent")
	assert(#plots:GetChildren() == S.Config.Plot.Count, "nombre de manoirs incorrect : " .. #plots:GetChildren())
	local parts = 0
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	print("Parts de la carte : " .. parts)
	assert(parts > 500, "carte trop petite")
	assert(S.Map.Points.Crypt and S.Map.Points.Shop and S.Map.Points.BossSpawn and S.Map.Points.Spawn, "points de la carte manquants")
end)

step("Cercueils exposes et classements", function()
	local n = 0
	for _ in pairs(S.Map.CoffinDisplays) do
		n += 1
	end
	assert(n == 6, "6 cercueils attendus, " .. n .. " trouves")
	assert(S.Map.Leaderboards.Coins and S.Map.Leaderboards.Rebirths and S.Map.Leaderboards.Power, "tableaux manquants")
end)

step("Gacha et economie", function()
	local GachaMath = require(Shared.GachaMath)
	local CoffinData = require(Shared.CoffinData)
	local MonsterData = require(Shared.MonsterData)
	local Rarity = require(Shared.Rarity)
	local Economy = require(Shared.Economy)
	for _, coffin in ipairs(CoffinData.List) do
		local entries = {}
		for _, item in ipairs(coffin.Contents) do
			table.insert(entries, { Id = item.Id, Weight = item.Weight, Rank = Rarity.rank(MonsterData.get(item.Id).Rarity) })
		end
		local id = GachaMath.roll(entries, 2, nil)
		assert(MonsterData.get(id), "tirage invalide pour " .. coffin.Id)
	end
	assert(Economy.format(1234567) == "1.23M", "format")
	assert(Economy.rebirthCost(0) == 25000, "rebirth cost")
end)

local Client = StarterPlayer:FindFirstChild("StarterPlayerScripts") and StarterPlayer.StarterPlayerScripts:FindFirstChild("Client")
assert(Client, "StarterPlayerScripts.Client introuvable")
for _, module in ipairs(Client.Controllers:GetChildren()) do
	step("Module client " .. module.Name, function()
		require(module)
	end)
end

step("Construction de l'interface", function()
	local UI = require(Client.Controllers.UI)
	local holder = Instance.new("Folder")
	UI.init(holder)
	local window = UI.window("SmokeTest", "Test", { Icon = "👻" })
	local button = UI.button({ Text = "Test", Parent = window.Body })
	UI.setEnabled(button, false)
	UI.setEnabled(button, true)
	UI.setButtonColor(button, Color3.new(1, 0, 0))
	UI.open("SmokeTest")
	UI.close("SmokeTest")
	UI.toast("test", "info", 0.1)
	local bar = UI.progress(window.Body, nil)
	bar.Set(0.5, "x")
	UI.scroll(window.Body, { Grid = true })
	UI.scroll(window.Body, {})
	local tabs = UI.tabs(window.Body, { { Key = "a", Text = "A" }, { Key = "b", Text = "B" } }, function() end)
	tabs.Select("a")
	UI.card(window.Body, { Size = UDim2.new(1, 0, 0, 50) })
	UI.confirm("t", "t", function() end)
	holder:Destroy()
end)

local summary = failures == 0 and "RESULTAT : tous les tests passent" or ("RESULTAT : " .. failures .. " echec(s), envoie ce journal pour correction")
print(summary)
return { failures = failures }
