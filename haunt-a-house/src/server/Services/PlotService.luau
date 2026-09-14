--!nonstrict
-- Manoirs des joueurs : construction, attribution, salles, affichage des monstres.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Util = require(ReplicatedStorage.Shared.Util)
local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local MonsterData = require(ReplicatedStorage.Shared.MonsterData)
local MonsterBuilder = require(ReplicatedStorage.Shared.MonsterBuilder)
local Rarity = require(ReplicatedStorage.Shared.Rarity)

local PlotService = {}
local S

local plots = {} -- [index] = plot
local playerPlot = {} -- [player] = plot

local COLORS = {
	Base = { 48, 44, 60 },
	Floor = { 70, 60, 80 },
	Carpet = { 120, 30, 50 },
	Wall = { 92, 78, 110 },
	WallTrim = { 60, 45, 80 },
	PadOpen = { 90, 60, 140 },
	PadLocked = { 40, 35, 50 },
	Wood = { 88, 58, 36 },
	Gold = { 255, 200, 60 },
}

local function billboard(parent, text, size, color, offsetY, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = size or UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, offsetY or 3, 0)
	gui.MaxDistance = maxDistance or 90
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.RichText = true
	label.Parent = gui
	gui.Parent = parent
	return gui
end

local function setLabel(gui, text, color)
	local label = gui:FindFirstChild("Text")
	if label then
		label.Text = text
		if color then
			label.TextColor3 = color
		end
	end
end

local function buildPlot(index)
	local angle = math.rad(15 + 30 * (index - 1))
	local center = Vector3.new(math.cos(angle) * Config.Plot.RingRadius, 0, math.sin(angle) * Config.Plot.RingRadius)
	local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local cf = CFrame.lookAt(center, center + outward)

	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	local monsters = Instance.new("Folder")
	monsters.Name = "Monsters"
	monsters.Parent = folder

	Util.part({ Name = "Base", Size = Vector3.new(Config.Plot.Width, 1, Config.Plot.Length), CFrame = cf * CFrame.new(0, 0.5, -15), Color = COLORS.Base, Material = "Slate", Parent = folder })
	Util.part({ Name = "MansionFloor", Size = Vector3.new(48, 0.4, 80), CFrame = cf * CFrame.new(0, 1.2, -30), Color = COLORS.Floor, Material = "WoodPlanks", Parent = folder })
	Util.part({ Name = "Carpet", Size = Vector3.new(12, 0.2, 78), CFrame = cf * CFrame.new(0, 1.5, -30), Color = COLORS.Carpet, Material = "Fabric", CanCollide = false, Parent = folder })
	Util.part({ Name = "YardPath", Size = Vector3.new(8, 0.3, 36), CFrame = cf * CFrame.new(0, 1.15, 28), Color = { 92, 86, 100 }, Material = "Cobblestone", Parent = folder })

	local wallHeight = 8
	local function wall(size, offset)
		Util.part({ Name = "Wall", Size = size, CFrame = cf * CFrame.new(offset.X, 1.4 + wallHeight / 2, offset.Z), Color = COLORS.Wall, Material = "Brick", Parent = folder })
		Util.part({ Name = "Trim", Size = Vector3.new(size.X + 0.4, 0.6, size.Z + 0.4), CFrame = cf * CFrame.new(offset.X, 1.4 + wallHeight + 0.3, offset.Z), Color = COLORS.WallTrim, Material = "Slate", CanCollide = false, Parent = folder })
	end
	wall(Vector3.new(48, wallHeight, 1), Vector3.new(0, 0, -70))
	wall(Vector3.new(1, wallHeight, 80), Vector3.new(-24, 0, -30))
	wall(Vector3.new(1, wallHeight, 80), Vector3.new(24, 0, -30))
	wall(Vector3.new(19, wallHeight, 1), Vector3.new(-14.5, 0, 10))
	wall(Vector3.new(19, wallHeight, 1), Vector3.new(14.5, 0, 10))
	Util.part({ Name = "DoorTop", Size = Vector3.new(10, 2, 1), CFrame = cf * CFrame.new(0, 1.4 + wallHeight - 1, 10), Color = COLORS.Wall, Material = "Brick", Parent = folder })
	local doorGlow = Util.part({ Name = "DoorGlow", Size = Vector3.new(9, 5.5, 0.2), CFrame = cf * CFrame.new(0, 4.2, 10), Color = { 150, 80, 255 }, Material = "Neon", Transparency = 0.5, CanCollide = false, Parent = folder })
	local doorLight = Instance.new("PointLight")
	doorLight.Color = Color3.fromRGB(170, 100, 255)
	doorLight.Range = 22
	doorLight.Brightness = 1.5
	doorLight.Parent = doorGlow
	for _, x in ipairs({ -22, 22 }) do
		for _, z in ipairs({ -66, -40, -14 }) do
			local torch = Util.part({ Name = "Torch", Shape = "Ball", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = cf * CFrame.new(x, 7.5, z), Color = { 255, 140, 30 }, Material = "Neon", CanCollide = false, Parent = folder })
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 160, 60)
			light.Range = 18
			light.Brightness = 1.2
			light.Parent = torch
		end
	end

	-- Portail et panneau
	for _, x in ipairs({ -8, 8 }) do
		Util.part({ Name = "GatePost", Size = Vector3.new(1.4, 7, 1.4), CFrame = cf * CFrame.new(x, 4.5, 45), Color = { 58, 58, 70 }, Material = "Slate", Parent = folder })
	end
	local gateSign = Util.part({ Name = "GateSign", Size = Vector3.new(18, 2.4, 0.6), CFrame = cf * CFrame.new(0, 9, 45), Color = COLORS.Wood, Material = "Wood", CanCollide = false, Parent = folder })
	local gateLabel = billboard(gateSign, "Manoir libre", UDim2.fromOffset(300, 60), Color3.fromRGB(230, 220, 255), 2.5, 200)
	for _, x in ipairs({ -29, 29 }) do
		for _, z in ipairs({ 44, 30, 16 }) do
			Util.part({ Name = "FencePost", Size = Vector3.new(0.7, 3, 0.7), CFrame = cf * CFrame.new(x, 2.5, z), Color = { 58, 58, 70 }, Material = "Metal", Parent = folder })
		end
		Util.part({ Name = "FenceRail", Size = Vector3.new(0.3, 0.3, 30), CFrame = cf * CFrame.new(x, 3.4, 30), Color = { 58, 58, 70 }, Material = "Metal", CanCollide = false, Parent = folder })
	end

	-- Caisse (collecte des coins)
	local booth = Util.part({ Name = "Booth", Size = Vector3.new(6, 4, 4), CFrame = cf * CFrame.new(18, 3, 28), Color = COLORS.Wood, Material = "Wood", Parent = folder })
	Util.part({ Name = "BoothRoof", Size = Vector3.new(7, 0.5, 5), CFrame = cf * CFrame.new(18, 5.5, 28), Color = { 255, 140, 30 }, Material = "Fabric", Parent = folder })
	Util.part({ Name = "BoothCoin", Shape = "Cylinder", Size = Vector3.new(0.4, 2.2, 2.2), CFrame = cf * CFrame.new(18, 7, 28) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.Gold, Material = "Neon", CanCollide = false, Parent = folder })
	local boothLabel = billboard(booth, "💰 Caisse\n0 coins", UDim2.fromOffset(220, 70), Color3.fromRGB(255, 220, 120), 6, 120)
	local boothPrompt = Instance.new("ProximityPrompt")
	boothPrompt.ActionText = "Collecter"
	boothPrompt.ObjectText = "Caisse"
	boothPrompt.MaxActivationDistance = 12
	boothPrompt.HoldDuration = 0
	boothPrompt.RequiresLineOfSight = false
	boothPrompt.Parent = booth

	-- Salles (pads)
	local pads = {}
	for row = 0, 8 do
		for col = 0, 1 do
			local padIndex = row * 2 + col + 1
			local x = col == 0 and -14 or 14
			local z = 2 - row * 8
			local pad = Util.part({ Name = "Pad" .. padIndex, Size = Vector3.new(9, 0.4, 7), CFrame = cf * CFrame.new(x, 1.6, z), Color = COLORS.PadLocked, Material = "Slate", Parent = folder })
			pad:SetAttribute("PadIndex", padIndex)
			Util.part({ Name = "PadEdge", Size = Vector3.new(9.6, 0.2, 7.6), CFrame = cf * CFrame.new(x, 1.45, z), Color = { 150, 80, 255 }, Material = "Neon", Transparency = 0.6, CanCollide = false, Parent = folder })
			local label = billboard(pad, "🔒", UDim2.fromOffset(200, 60), Color3.fromRGB(200, 190, 220), 3.2, 80)
			local padPrompt = Instance.new("ProximityPrompt")
			padPrompt.ActionText = "Acheter"
			padPrompt.ObjectText = "Salle"
			padPrompt.MaxActivationDistance = 10
			padPrompt.HoldDuration = 0
			padPrompt.RequiresLineOfSight = false
			padPrompt.Enabled = false
			padPrompt.Parent = pad
			pads[padIndex] = { Part = pad, Label = label, Prompt = padPrompt, Face = cf:VectorToWorldSpace(Vector3.new(col == 0 and 1 or -1, 0, 0)) }
		end
	end

	local plot = {
		Index = index,
		CFrame = cf,
		Folder = folder,
		Pads = pads,
		Booth = booth,
		BoothLabel = boothLabel,
		BoothPrompt = boothPrompt,
		GateLabel = gateLabel,
		MonsterFolder = monsters,
		Models = {},
		Owner = nil,
		HomeCFrame = cf * CFrame.new(0, 4, 32),
		Waypoints = {
			cf:PointToWorldSpace(Vector3.new(0, 2.6, 48)),
			cf:PointToWorldSpace(Vector3.new(0, 2.6, 10)),
			cf:PointToWorldSpace(Vector3.new(0, 2.6, -64)),
			cf:PointToWorldSpace(Vector3.new(0, 2.6, 10)),
			cf:PointToWorldSpace(Vector3.new(0, 2.6, 50)),
		},
		DoorPoint = cf:PointToWorldSpace(Vector3.new(0, 2.6, 10)),
		ExitPoint = cf:PointToWorldSpace(Vector3.new(0, 2.6, 50)),
	}

	boothPrompt.Triggered:Connect(function(player)
		if plot.Owner ~= player then
			S.Net.notify(player, "Ce n'est pas ton manoir !", "error")
			return
		end
		S.Economy.collect(player)
	end)
	for padIndex, padInfo in ipairs(pads) do
		padInfo.Prompt.Triggered:Connect(function(player)
			if plot.Owner ~= player then
				return
			end
			PlotService.buyRoom(player)
		end)
	end

	folder.Parent = workspace.Map.Plots
	return plot
end

function PlotService.init(services)
	S = services
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace.Map
	for i = 1, Config.Plot.Count do
		plots[i] = buildPlot(i)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlotService.release(player)
	end)

	S.Net.register("BuyRoom", "Shop", function(player)
		return PlotService.buyRoom(player)
	end)
end

function PlotService.get(player)
	return playerPlot[player]
end

function PlotService.all()
	return plots
end

function PlotService.homeCFrame(player)
	local plot = playerPlot[player]
	return plot and plot.HomeCFrame or nil
end

function PlotService.roomCount(player)
	local data = S.Data.get(player)
	if not data then
		return 0
	end
	return Economy.roomCount(data.Rebirths, data.RoomsPurchased, S.Shop.ownsPass(player, "VIP"), S.Shop.ownsPass(player, "ExtraRooms"))
end

function PlotService.roomInfo(player)
	local data = S.Data.get(player)
	if not data then
		return nil
	end
	local count = PlotService.roomCount(player)
	local nextCost = nil
	if data.RoomsPurchased < Config.Plot.MaxPurchasedRooms then
		nextCost = Economy.roomCost(data.RoomsPurchased + 1)
	end
	return {
		Count = count,
		Purchased = data.RoomsPurchased,
		MaxPurchased = Config.Plot.MaxPurchasedRooms,
		NextCost = nextCost,
		Total = Config.Plot.TotalPads,
	}
end

function PlotService.assign(player)
	if playerPlot[player] then
		return playerPlot[player]
	end
	for _, plot in ipairs(plots) do
		if plot.Owner == nil then
			plot.Owner = player
			playerPlot[player] = plot
			setLabel(plot.GateLabel, "🏚️ Manoir de " .. player.DisplayName, Color3.fromRGB(255, 230, 160))
			player:SetAttribute("PlotIndex", plot.Index)
			PlotService.refreshPads(player)
			S.Inventory.renderAll(player)
			return plot
		end
	end
	S.Net.notify(player, "Tous les manoirs sont occupés, réessaie dans un autre serveur.", "error")
	return nil
end

function PlotService.release(player)
	local plot = playerPlot[player]
	if not plot then
		return
	end
	PlotService.clearModels(player)
	plot.Owner = nil
	playerPlot[player] = nil
	setLabel(plot.GateLabel, "Manoir libre", Color3.fromRGB(230, 220, 255))
	setLabel(plot.BoothLabel, "💰 Caisse\n0 coins")
	for _, padInfo in ipairs(plot.Pads) do
		padInfo.Part.Color = Util.color(COLORS.PadLocked)
		padInfo.Prompt.Enabled = false
		setLabel(padInfo.Label, "🔒")
	end
end

function PlotService.updateBooth(player, uncollected)
	local plot = playerPlot[player]
	if plot then
		setLabel(plot.BoothLabel, "💰 Caisse\n" .. Economy.format(uncollected) .. " coins")
	end
end

-- Met a jour l'apparence des salles (ouvertes, verrouillees, achetable)
function PlotService.refreshPads(player)
	local plot = playerPlot[player]
	local data = S.Data.get(player)
	if not plot or not data then
		return
	end
	local count = PlotService.roomCount(player)
	local occupied = {}
	for _, entry in ipairs(data.Monsters) do
		if entry.Room > 0 then
			occupied[entry.Room] = true
		end
	end
	for padIndex, padInfo in ipairs(plot.Pads) do
		padInfo.Prompt.Enabled = false
		if padIndex <= count then
			padInfo.Part.Color = Util.color(COLORS.PadOpen)
			padInfo.Part.Transparency = 0
			if occupied[padIndex] then
				setLabel(padInfo.Label, "", Color3.fromRGB(255, 255, 255))
			else
				setLabel(padInfo.Label, "Salle libre", Color3.fromRGB(200, 190, 230))
			end
		else
			padInfo.Part.Color = Util.color(COLORS.PadLocked)
			padInfo.Part.Transparency = 0.2
			if padIndex == count + 1 then
				if data.RoomsPurchased < Config.Plot.MaxPurchasedRooms then
					local cost = Economy.roomCost(data.RoomsPurchased + 1)
					setLabel(padInfo.Label, "🔒 Acheter : " .. Economy.format(cost) .. " coins", Color3.fromRGB(255, 220, 120))
					padInfo.Prompt.ActionText = "Acheter (" .. Economy.format(cost) .. ")"
					padInfo.Prompt.Enabled = true
				elseif data.Rebirths < Config.Plot.MaxRebirthRooms then
					setLabel(padInfo.Label, "🔒 Prochain rebirth", Color3.fromRGB(220, 180, 255))
				elseif not S.Shop.ownsPass(player, "VIP") then
					setLabel(padInfo.Label, "🔒 Pass VIP (boutique)", Color3.fromRGB(255, 215, 60))
				elseif not S.Shop.ownsPass(player, "ExtraRooms") then
					setLabel(padInfo.Label, "🔒 Pass +3 Salles (boutique)", Color3.fromRGB(255, 215, 60))
				else
					setLabel(padInfo.Label, "🔒", Color3.fromRGB(200, 190, 220))
				end
			else
				setLabel(padInfo.Label, "🔒", Color3.fromRGB(200, 190, 220))
			end
		end
	end
end

function PlotService.buyRoom(player)
	local data = S.Data.get(player)
	if not data then
		return { ok = false, message = "Données non chargées." }
	end
	if data.RoomsPurchased >= Config.Plot.MaxPurchasedRooms then
		return { ok = false, message = "Tu as acheté toutes les salles disponibles ! Les suivantes viennent du rebirth et des passes." }
	end
	local cost = Economy.roomCost(data.RoomsPurchased + 1)
	if not S.Economy.spendCoins(player, cost) then
		return { ok = false, message = "Il te manque " .. Economy.format(cost - data.Coins) .. " coins." }
	end
	data.RoomsPurchased += 1
	PlotService.refreshPads(player)
	S.Player.sendState(player)
	S.Net.notify(player, "Nouvelle salle débloquée ! (" .. PlotService.roomCount(player) .. " salles)", "success")
	return { ok = true }
end

-- Affiche le modele d'un monstre place
function PlotService.renderMonster(player, entry)
	local plot = playerPlot[player]
	if not plot or entry.Room <= 0 then
		return
	end
	local padInfo = plot.Pads[entry.Room]
	local def = MonsterData.get(entry.Id)
	if not padInfo or not def then
		return
	end
	PlotService.removeModel(player, entry.Uid)
	local top = padInfo.Part.Position + Vector3.new(0, padInfo.Part.Size.Y / 2, 0)
	local origin = CFrame.lookAt(top, top + padInfo.Face)
	local model = MonsterBuilder.build(def, origin)
	model:SetAttribute("Uid", entry.Uid)
	local r, g, b = Rarity.color(def.Rarity)
	local label = billboard(model.PrimaryPart, string.format('<font color="rgb(%d,%d,%d)">%s</font>\n⚡ %s/s', r, g, b, def.Name, Economy.format(def.Power)), UDim2.fromOffset(200, 56), Color3.fromRGB(255, 255, 255), MonsterBuilder.height(def) + 0.5, 70)
	label.Name = "NameTag"
	CollectionService:AddTag(model, "Monster")
	model.Parent = plot.MonsterFolder
	plot.Models[entry.Uid] = model
end

function PlotService.removeModel(player, uid)
	local plot = playerPlot[player]
	if not plot then
		return
	end
	local model = plot.Models[uid]
	if model then
		model:Destroy()
		plot.Models[uid] = nil
	end
end

function PlotService.clearModels(player)
	local plot = playerPlot[player]
	if not plot then
		return
	end
	for uid, model in pairs(plot.Models) do
		model:Destroy()
		plot.Models[uid] = nil
	end
end

return PlotService
