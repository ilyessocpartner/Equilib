--!nonstrict
-- Construit la carte du hub par script : place centrale, crypte, boutique, autel, coffre, tableaux, arene.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Util = require(ReplicatedStorage.Shared.Util)
local CoffinData = require(ReplicatedStorage.Shared.CoffinData)
local Economy = require(ReplicatedStorage.Shared.Economy)

local MapBuilder = {}

MapBuilder.Points = {}
MapBuilder.CoffinDisplays = {}
MapBuilder.Leaderboards = {}

local S
local mapFolder
local rng = Random.new(1337)

local COLORS = {
	Ground = { 34, 52, 38 },
	Plaza = { 70, 66, 80 },
	Path = { 92, 86, 100 },
	Stone = { 96, 96, 108 },
	DarkStone = { 58, 58, 70 },
	Wood = { 88, 58, 36 },
	Orange = { 255, 140, 30 },
	Purple = { 150, 80, 255 },
	Gold = { 255, 200, 60 },
}

local function billboard(parent, text, size, color, offsetY, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = size or UDim2.fromOffset(260, 60)
	gui.StudsOffset = Vector3.new(0, offsetY or 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 120
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(10, 5, 20)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = parent
	return gui
end

local function prompt(parent, actionText, objectText, distance, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText
	p.MaxActivationDistance = distance or 10
	p.HoldDuration = 0
	p.RequiresLineOfSight = false
	p.Style = Enum.ProximityPromptStyle.Default
	p.Parent = parent
	p.Triggered:Connect(function(player)
		callback(player)
	end)
	return p
end

local function lamp(parent, position)
	local post = Util.part({ Name = "LampPost", Shape = "Cylinder", Size = Vector3.new(9, 0.6, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.DarkStone, Material = "Metal", Parent = parent })
	local bulb = Util.part({ Name = "LampBulb", Shape = "Ball", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(position + Vector3.new(0, 9.6, 0)), Color = COLORS.Orange, Material = "Neon", CanCollide = false, Parent = parent })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Range = 28
	light.Brightness = 1.6
	light.Parent = bulb
	return post
end

local function deadTree(parent, position, scale)
	scale = scale or 1
	local trunkHeight = 10 * scale
	Util.part({ Name = "Trunk", Shape = "Cylinder", Size = Vector3.new(trunkHeight, 1.6 * scale, 1.6 * scale), CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 50, 38, 30 }, Material = "Wood", Parent = parent })
	for i = 1, 4 do
		local angle = i * math.pi / 2 + rng:NextNumber(-0.4, 0.4)
		local length = (4 + rng:NextNumber(0, 3)) * scale
		local branch = Util.part({ Name = "Branch", Size = Vector3.new(0.6 * scale, length, 0.6 * scale), Color = { 50, 38, 30 }, Material = "Wood", CanCollide = false, Parent = parent })
		local base = position + Vector3.new(0, trunkHeight * (0.55 + i * 0.1), 0)
		branch.CFrame = CFrame.new(base) * CFrame.Angles(0, angle, math.rad(50)) * CFrame.new(0, length / 2, 0)
	end
end

local function tombstone(parent, cframe)
	Util.part({ Name = "Tomb", Size = Vector3.new(2.2, 2.6, 0.6), CFrame = cframe * CFrame.new(0, 1.3, 0), Color = COLORS.Stone, Material = "Slate", Parent = parent })
	Util.part({ Name = "TombTop", Shape = "Cylinder", Size = Vector3.new(0.6, 2.2, 2.2), CFrame = cframe * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, math.rad(90), 0), Color = COLORS.Stone, Material = "Slate", Parent = parent })
end

local function fenceLine(parent, from, to, height)
	height = height or 3
	local delta = to - from
	local length = delta.Magnitude
	local dir = delta.Unit
	local count = math.max(1, math.floor(length / 6))
	for i = 0, count do
		local pos = from + dir * (length * i / count)
		Util.part({ Name = "FencePost", Size = Vector3.new(0.7, height, 0.7), CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)), Color = COLORS.DarkStone, Material = "Metal", Parent = parent })
	end
	local mid = (from + to) / 2
	for _, y in ipairs({ height * 0.45, height * 0.85 }) do
		Util.part({ Name = "FenceRail", Size = Vector3.new(length, 0.3, 0.3), CFrame = CFrame.lookAt(mid + Vector3.new(0, y, 0), mid + Vector3.new(0, y, 0) + dir) * CFrame.Angles(0, math.rad(90), 0), Color = COLORS.DarkStone, Material = "Metal", CanCollide = false, Parent = parent })
	end
end

local function sign(parent, cframe, text, width, color)
	local board = Util.part({ Name = "Sign", Size = Vector3.new(width or 12, 3, 0.5), CFrame = cframe, Color = COLORS.Wood, Material = "Wood", CanCollide = false, Parent = parent })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.fromRGB(255, 220, 160)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = board
	return board
end

local function leaderboard(parent, cframe, title)
	local board = Util.part({ Name = "Leaderboard_" .. title, Size = Vector3.new(20, 14, 1), CFrame = cframe, Color = COLORS.DarkStone, Material = "Slate", Parent = parent })
	Util.part({ Name = "Frame", Size = Vector3.new(21, 15, 0.6), CFrame = cframe * CFrame.new(0, 0, 0.1), Color = COLORS.Wood, Material = "Wood", Parent = parent })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	local header = Instance.new("TextLabel")
	header.Name = "Title"
	header.Size = UDim2.fromScale(1, 0.14)
	header.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
	header.BorderSizePixel = 0
	header.Text = title
	header.Font = Enum.Font.FredokaOne
	header.TextScaled = true
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.Parent = gui
	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.fromScale(0.94, 0.84)
	body.Position = UDim2.fromScale(0.03, 0.15)
	body.BackgroundTransparency = 1
	body.Text = "Chargement..."
	body.Font = Enum.Font.GothamBold
	body.TextSize = 34
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(240, 235, 255)
	body.RichText = true
	body.Parent = gui
	gui.Parent = board
	return board, body
end

local function buildAtmosphere()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.38
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(120, 95, 170)
	atmosphere.Decay = Color3.fromRGB(60, 30, 110)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 2.2
	atmosphere.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local color = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	color.Saturation = 0.1
	color.Contrast = 0.08
	color.TintColor = Color3.fromRGB(235, 225, 255)
	color.Parent = Lighting
end

local function buildGround(parent)
	Util.part({ Name = "Ground", Size = Vector3.new(1600, 4, 1600), CFrame = CFrame.new(0, -2, 0), Color = COLORS.Ground, Material = "Grass", Parent = parent })
	Util.part({ Name = "Plaza", Shape = "Cylinder", Size = Vector3.new(0.6, 150, 150), CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.Plaza, Material = "Cobblestone", Parent = parent })
	Util.part({ Name = "PlazaRing", Shape = "Cylinder", Size = Vector3.new(0.4, 156, 156), CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.DarkStone, Material = "Slate", Parent = parent })
	for i = 0, 7 do
		local angle = i * math.pi / 4 + math.pi / 8
		lamp(parent, Vector3.new(math.cos(angle) * 66, 0.6, math.sin(angle) * 66))
	end
	for _ = 1, 60 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(320, 700)
		deadTree(parent, Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), rng:NextNumber(0.8, 1.6))
	end
end

local function buildSpawn(parent)
	local spawnPart = Instance.new("SpawnLocation")
	spawnPart.Name = "MainSpawn"
	spawnPart.Size = Vector3.new(12, 1, 12)
	spawnPart.CFrame = CFrame.new(0, 0.9, 28)
	spawnPart.Anchored = true
	spawnPart.Color = Color3.fromRGB(110, 70, 170)
	spawnPart.Material = Enum.Material.Neon
	spawnPart.Transparency = 0.3
	spawnPart.Neutral = true
	spawnPart.Duration = 0
	spawnPart.TopSurface = Enum.SurfaceType.Smooth
	spawnPart.Parent = parent
	MapBuilder.Points.Spawn = spawnPart.CFrame * CFrame.new(0, 3, 0)
	sign(parent, CFrame.new(0, 6, 38) * CFrame.Angles(0, math.rad(180), 0), "👻 Bienvenue dans Haunt a House !", 26, Color3.fromRGB(255, 240, 200))
	sign(parent, CFrame.new(0, 3.2, 38) * CFrame.Angles(0, math.rad(180), 0), "Ouvre des cercueils, place tes monstres, fais peur aux visiteurs !", 26, Color3.fromRGB(220, 200, 255))
end

local function buildCrypt(parent)
	local center = Vector3.new(0, 0, -55)
	local folder = Instance.new("Folder")
	folder.Name = "Crypt"
	folder.Parent = parent
	Util.part({ Name = "Floor", Size = Vector3.new(36, 1, 26), CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0)), Color = COLORS.DarkStone, Material = "Slate", Parent = folder })
	local wallHeight = 14
	local function wall(size, offset)
		Util.part({ Name = "Wall", Size = size, CFrame = CFrame.new(center + offset + Vector3.new(0, wallHeight / 2, 0)), Color = COLORS.Stone, Material = "Slate", Parent = folder })
	end
	wall(Vector3.new(36, wallHeight, 1.5), Vector3.new(0, 0, -12.25))
	wall(Vector3.new(1.5, wallHeight, 26), Vector3.new(-17.25, 0, 0))
	wall(Vector3.new(1.5, wallHeight, 26), Vector3.new(17.25, 0, 0))
	wall(Vector3.new(13, wallHeight, 1.5), Vector3.new(-11.5, 0, 12.25))
	wall(Vector3.new(13, wallHeight, 1.5), Vector3.new(11.5, 0, 12.25))
	Util.part({ Name = "DoorTop", Size = Vector3.new(10, 4, 1.5), CFrame = CFrame.new(center + Vector3.new(0, wallHeight - 2, 12.25)), Color = COLORS.Stone, Material = "Slate", Parent = folder })
	Util.part({ Name = "Roof", ClassName = "WedgePart", Size = Vector3.new(38, 8, 14), CFrame = CFrame.new(center + Vector3.new(0, wallHeight + 4, -7)) * CFrame.Angles(0, math.rad(180), 0), Color = COLORS.DarkStone, Material = "Slate", Parent = folder })
	Util.part({ Name = "Roof", ClassName = "WedgePart", Size = Vector3.new(38, 8, 14), CFrame = CFrame.new(center + Vector3.new(0, wallHeight + 4, 7)), Color = COLORS.DarkStone, Material = "Slate", Parent = folder })
	local glow = Util.part({ Name = "DoorGlow", Size = Vector3.new(9, 9.5, 0.3), CFrame = CFrame.new(center + Vector3.new(0, 4.9, 12.2)), Color = COLORS.Purple, Material = "Neon", Transparency = 0.35, CanCollide = false, Parent = folder })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 100, 255)
	light.Range = 30
	light.Brightness = 2
	light.Parent = glow
	sign(folder, CFrame.new(center + Vector3.new(0, wallHeight + 1.5, 13.2)), "⚰️ LA CRYPTE : cercueils", 24, Color3.fromRGB(230, 200, 255))

	local counter = Util.part({ Name = "CryptCounter", Size = Vector3.new(8, 3, 2), CFrame = CFrame.new(center + Vector3.new(0, 1.5, 16)), Color = COLORS.Wood, Material = "Wood", Parent = folder })
	billboard(counter, "Ouvrir des cercueils", UDim2.fromOffset(240, 50), Color3.fromRGB(230, 200, 255), 3.5, 60)
	prompt(counter, "Ouvrir", "La Crypte", 12, function(player)
		S.Net.fire(player, "OpenUI", { Ui = "Coffins" })
	end)
	MapBuilder.Points.Crypt = counter.CFrame

	local displayCount = 0
	for _, coffin in ipairs(CoffinData.List) do
		if not coffin.EventOnly then
			displayCount += 1
		end
	end
	local index = 0
	for _, coffin in ipairs(CoffinData.List) do
		if not coffin.EventOnly then
			local x = (index - (displayCount - 1) / 2) * 9
			index += 1
			local base = center + Vector3.new(x, 0, 24)
			local box = Util.part({ Name = "Coffin_" .. coffin.Id, Size = Vector3.new(4, 7, 2), CFrame = CFrame.new(base + Vector3.new(0, 3.4, 0)) * CFrame.Angles(math.rad(-15), 0, 0), Color = coffin.Color, Material = "Wood", Parent = folder })
			box:SetAttribute("CoffinId", coffin.Id)
			Util.part({ Name = "Lid", Size = Vector3.new(3.2, 6, 0.4), CFrame = box.CFrame * CFrame.new(0, 0, -1.2), Color = coffin.Accent, Material = "Metal", CanCollide = false, Parent = folder })
			local lockText = coffin.RebirthRequired > 0 and ("🔒 Rebirth " .. coffin.RebirthRequired) or ""
			billboard(box, coffin.Name .. "\n" .. Economy.format(coffin.Cost) .. " coins " .. lockText, UDim2.fromOffset(220, 70), Util.color(coffin.Accent), 5.2, 70)
			prompt(box, "Voir", coffin.Name, 10, function(player)
				S.Net.fire(player, "OpenUI", { Ui = "Coffins", Coffin = coffin.Id })
			end)
			MapBuilder.CoffinDisplays[coffin.Id] = box
		end
	end
end

local function buildShop(parent)
	local center = Vector3.new(56, 0, -24)
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	local folder = Instance.new("Folder")
	folder.Name = "Shop"
	folder.Parent = parent
	Util.part({ Name = "Floor", Size = Vector3.new(16, 0.8, 12), CFrame = cf * CFrame.new(0, 0.4, 0), Color = COLORS.Wood, Material = "WoodPlanks", Parent = folder })
	local counter = Util.part({ Name = "ShopCounter", Size = Vector3.new(12, 3.5, 3), CFrame = cf * CFrame.new(0, 1.75, -3), Color = { 120, 60, 40 }, Material = "Wood", Parent = folder })
	for _, x in ipairs({ -7, 7 }) do
		Util.part({ Name = "Post", Size = Vector3.new(0.8, 10, 0.8), CFrame = cf * CFrame.new(x, 5, 2), Color = COLORS.Wood, Material = "Wood", Parent = folder })
		Util.part({ Name = "Post", Size = Vector3.new(0.8, 10, 0.8), CFrame = cf * CFrame.new(x, 5, -5), Color = COLORS.Wood, Material = "Wood", Parent = folder })
	end
	Util.part({ Name = "Roof", Size = Vector3.new(17, 0.6, 9), CFrame = cf * CFrame.new(0, 10.3, -1.5) * CFrame.Angles(math.rad(8), 0, 0), Color = COLORS.Orange, Material = "Fabric", Parent = folder })
	Util.part({ Name = "RoofStripe", Size = Vector3.new(17.2, 0.4, 3), CFrame = cf * CFrame.new(0, 10.4, 1) * CFrame.Angles(math.rad(8), 0, 0), Color = { 40, 20, 60 }, Material = "Fabric", CanCollide = false, Parent = folder })
	sign(folder, cf * CFrame.new(0, 12.5, 1.5), "🛒 BOUTIQUE", 14, Color3.fromRGB(255, 230, 180))
	billboard(counter, "Passes, boosts, coins, offres", UDim2.fromOffset(240, 50), Color3.fromRGB(255, 220, 160), 3.5, 60)
	prompt(counter, "Ouvrir", "Boutique", 12, function(player)
		S.Net.fire(player, "OpenUI", { Ui = "Shop" })
	end)
	MapBuilder.Points.Shop = counter.CFrame
end

local function buildRebirthAltar(parent)
	local center = Vector3.new(-56, 0, -24)
	local folder = Instance.new("Folder")
	folder.Name = "RebirthAltar"
	folder.Parent = parent
	Util.part({ Name = "Base", Shape = "Cylinder", Size = Vector3.new(1, 16, 16), CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.DarkStone, Material = "Slate", Parent = folder })
	local pedestal = Util.part({ Name = "Pedestal", Shape = "Cylinder", Size = Vector3.new(4, 5, 5), CFrame = CFrame.new(center + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.Stone, Material = "Slate", Parent = folder })
	local orb = Util.part({ Name = "Orb", Shape = "Ball", Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(center + Vector3.new(0, 7.5, 0)), Color = COLORS.Purple, Material = "Neon", CanCollide = false, Parent = folder })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(170, 100, 255)
	light.Range = 30
	light.Brightness = 2.5
	light.Parent = orb
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255), Color3.fromRGB(120, 60, 255))
	emitter.Rate = 20
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(2, 4)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	emitter.LightEmission = 1
	emitter.Parent = orb
	for i = 0, 5 do
		local angle = i * math.pi / 3
		Util.part({ Name = "Stone", Size = Vector3.new(1.6, 4 + (i % 2) * 1.5, 1.6), CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * 7, 2.5, math.sin(angle) * 7)) * CFrame.Angles(0, -angle, 0), Color = COLORS.Stone, Material = "Slate", Parent = folder })
	end
	billboard(pedestal, "♻️ AUTEL DE REBIRTH\nRecommence plus fort", UDim2.fromOffset(260, 70), Color3.fromRGB(220, 180, 255), 9, 80)
	prompt(pedestal, "Ouvrir", "Rebirth", 12, function(player)
		S.Net.fire(player, "OpenUI", { Ui = "Rebirth" })
	end)
	MapBuilder.Points.Rebirth = pedestal.CFrame
end

local function buildDailyChest(parent)
	local center = Vector3.new(42, 0, 34)
	local folder = Instance.new("Folder")
	folder.Name = "DailyChest"
	folder.Parent = parent
	local chest = Util.part({ Name = "Chest", Size = Vector3.new(6, 3.5, 4), CFrame = CFrame.new(center + Vector3.new(0, 2.25, 0)) * CFrame.Angles(0, math.rad(-35), 0), Color = COLORS.Wood, Material = "Wood", Parent = folder })
	Util.part({ Name = "Lid", Size = Vector3.new(6.2, 1.2, 4.2), CFrame = chest.CFrame * CFrame.new(0, 2.2, 0), Color = { 110, 75, 45 }, Material = "Wood", Parent = folder })
	Util.part({ Name = "Lock", Size = Vector3.new(1.2, 1.2, 0.5), CFrame = chest.CFrame * CFrame.new(0, 0.6, -2.2), Color = COLORS.Gold, Material = "Metal", CanCollide = false, Parent = folder })
	Util.part({ Name = "Base", Shape = "Cylinder", Size = Vector3.new(0.5, 12, 12), CFrame = CFrame.new(center + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.DarkStone, Material = "Slate", Parent = folder })
	billboard(chest, "🎁 RÉCOMPENSE QUOTIDIENNE\nReviens chaque jour !", UDim2.fromOffset(280, 70), Color3.fromRGB(255, 220, 120), 4.5, 80)
	prompt(chest, "Ouvrir", "Coffre quotidien", 12, function(player)
		S.Net.fire(player, "OpenUI", { Ui = "Daily" })
	end)
	MapBuilder.Points.Daily = chest.CFrame
end

local function buildIndexBoard(parent)
	local center = Vector3.new(-42, 0, 34)
	local folder = Instance.new("Folder")
	folder.Name = "IndexBoard"
	folder.Parent = parent
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	local board = Util.part({ Name = "Board", Size = Vector3.new(10, 7, 0.8), CFrame = cf * CFrame.new(0, 5, 0), Color = COLORS.Wood, Material = "Wood", Parent = folder })
	Util.part({ Name = "Post", Size = Vector3.new(0.8, 6, 0.8), CFrame = cf * CFrame.new(-4, 3, 0), Color = COLORS.DarkStone, Material = "Metal", Parent = folder })
	Util.part({ Name = "Post", Size = Vector3.new(0.8, 6, 0.8), CFrame = cf * CFrame.new(4, 3, 0), Color = COLORS.DarkStone, Material = "Metal", Parent = folder })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "📖 BESTIAIRE\nCollectionne les 48 monstres\n+1% coins par découverte"
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(230, 220, 255)
	label.Parent = gui
	gui.Parent = board
	prompt(board, "Ouvrir", "Bestiaire", 12, function(player)
		S.Net.fire(player, "OpenUI", { Ui = "Index" })
	end)
	MapBuilder.Points.Index = board.CFrame
end

local function buildLeaderboards(parent)
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = parent
	local defs = {
		{ Key = "Coins", Title = "🏆 Top Coins gagnés", X = -26 },
		{ Key = "Rebirths", Title = "♻️ Top Rebirths", X = 0 },
		{ Key = "Power", Title = "👻 Top Puissance", X = 26 },
	}
	for _, def in ipairs(defs) do
		local cf = CFrame.new(def.X, 8, 66) * CFrame.Angles(0, math.rad(180), 0)
		local _, body = leaderboard(folder, cf, def.Title)
		MapBuilder.Leaderboards[def.Key] = body
	end
end

local function buildBossArena(parent)
	local center = Vector3.new(0, 0, -150)
	local folder = Instance.new("Folder")
	folder.Name = "BossArena"
	folder.Parent = parent
	Util.part({ Name = "Floor", Size = Vector3.new(64, 1, 64), CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0)), Color = { 40, 44, 40 }, Material = "Ground", Parent = folder })
	local half = 32
	local corners = {
		center + Vector3.new(-half, 0.5, -half),
		center + Vector3.new(half, 0.5, -half),
		center + Vector3.new(half, 0.5, half),
		center + Vector3.new(-half, 0.5, half),
	}
	fenceLine(folder, corners[1], corners[2], 4)
	fenceLine(folder, corners[2], corners[3], 4)
	fenceLine(folder, corners[4], corners[1], 4)
	fenceLine(folder, corners[3], corners[3] + Vector3.new(-22, 0, 0), 4)
	fenceLine(folder, corners[4], corners[4] + Vector3.new(22, 0, 0), 4)
	for _, c in ipairs(corners) do
		deadTree(folder, c + Vector3.new(0, 0, 0), 1.4)
	end
	for _ = 1, 18 do
		local x = rng:NextNumber(-26, 26)
		local z = rng:NextNumber(-26, 26)
		if math.abs(x) > 9 or math.abs(z) > 9 then
			tombstone(folder, CFrame.new(center + Vector3.new(x, 0.8, z)) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0))
		end
	end
	local platform = Util.part({ Name = "BossSpawn", Shape = "Cylinder", Size = Vector3.new(1, 18, 18), CFrame = CFrame.new(center + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 80, 30, 110 }, Material = "Slate", Parent = folder })
	local ring = Util.part({ Name = "Ring", Shape = "Cylinder", Size = Vector3.new(0.4, 20, 20), CFrame = CFrame.new(center + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = COLORS.Purple, Material = "Neon", Transparency = 0.4, CanCollide = false, Parent = folder })
	ring.Name = "BossRing"
	sign(folder, CFrame.new(center + Vector3.new(0, 7, 34)), "⚔️ ARÈNE DE MINUIT : le Capitaine Chasseur attaque toutes les 10 min !", 40, Color3.fromRGB(255, 120, 120))
	lamp(folder, center + Vector3.new(-30, 0.6, 30))
	lamp(folder, center + Vector3.new(30, 0.6, 30))
	MapBuilder.Points.BossSpawn = CFrame.new(center + Vector3.new(0, 1.8, 0))
end

local function buildPaths(parent, plotCount, ringRadius)
	for i = 1, plotCount do
		local angle = math.rad(15 + 30 * (i - 1))
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local from = dir * 74
		local to = dir * (ringRadius - 62)
		local mid = (from + to) / 2
		local length = (to - from).Magnitude
		Util.part({ Name = "Path", Size = Vector3.new(8, 0.4, length), CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.2, 0), to + Vector3.new(0, 0.2, 0)), Color = COLORS.Path, Material = "Cobblestone", Parent = parent })
	end
end

function MapBuilder.build(services)
	S = services
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = mapFolder

	buildAtmosphere()
	buildGround(hub)
	buildSpawn(hub)
	buildCrypt(hub)
	buildShop(hub)
	buildRebirthAltar(hub)
	buildDailyChest(hub)
	buildIndexBoard(hub)
	buildLeaderboards(hub)
	buildBossArena(hub)
	buildPaths(hub, S.Config.Plot.Count, S.Config.Plot.RingRadius)

	mapFolder.Parent = workspace
	return mapFolder
end

function MapBuilder.folder()
	return mapFolder
end

return MapBuilder
