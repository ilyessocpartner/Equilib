--!nonstrict
-- Visiteurs PNJ qui traversent les manoirs. Le proprietaire clique dessus pour leur faire peur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)

local VisitorService = {}
local S

local visitors = {} -- [model] = visitor
local plotVisitors = {} -- [plotIndex] = { count, nextSpawn }
local lastScare = {} -- [player] = os.clock

local rng = Random.new(2026)
local SHIRTS = { { 200, 60, 60 }, { 60, 120, 220 }, { 80, 180, 90 }, { 230, 180, 50 }, { 180, 80, 200 }, { 240, 240, 240 } }
local SKINS = { { 255, 220, 180 }, { 220, 170, 130 }, { 160, 110, 80 }, { 110, 70, 50 } }

local function buildVisitor(position)
	local model = Instance.new("Model")
	model.Name = "Visitor"
	local shirt = SHIRTS[rng:NextInteger(1, #SHIRTS)]
	local skin = SKINS[rng:NextInteger(1, #SKINS)]

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 1)
	root.Color = Util.color(shirt)
	root.Material = Enum.Material.Fabric
	root.Anchored = false
	root.CanCollide = false
	root.CanTouch = false
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	local function attach(name, size, offset, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = Util.color(color)
		part.Material = Enum.Material.SmoothPlastic
		if shape then
			part.Shape = Enum.PartType[shape]
		end
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
		part.CFrame = root.CFrame * offset
		part.Parent = model
		Util.weld(root, part)
		return part
	end
	attach("Head", Vector3.new(1.3, 1.3, 1.3), CFrame.new(0, 1.65, 0), skin, "Ball")
	attach("LegL", Vector3.new(0.8, 1.8, 0.8), CFrame.new(-0.5, -1.9, 0), { 50, 50, 70 })
	attach("LegR", Vector3.new(0.8, 1.8, 0.8), CFrame.new(0.5, -1.9, 0), { 50, 50, 70 })
	attach("ArmL", Vector3.new(0.7, 1.8, 0.7), CFrame.new(-1.35, -0.1, 0), skin)
	attach("ArmR", Vector3.new(0.7, 1.8, 0.7), CFrame.new(1.35, -0.1, 0), skin)
	attach("EyeL", Vector3.new(0.25, 0.25, 0.25), CFrame.new(-0.28, 1.75, -0.6), { 20, 20, 20 }, "Ball")
	attach("EyeR", Vector3.new(0.25, 0.25, 0.25), CFrame.new(0.28, 1.75, -0.6), { 20, 20, 20 }, "Ball")
	if rng:NextNumber() < 0.5 then
		attach("Hat", Vector3.new(1.4, 0.5, 1.4), CFrame.new(0, 2.45, 0), { rng:NextInteger(30, 220), rng:NextInteger(30, 220), rng:NextInteger(30, 220) })
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "MoveAttachment"
	attachment.Parent = root

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "Move"
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = attachment
	alignPosition.MaxForce = math.huge
	alignPosition.MaxVelocity = Config.Visitors.Speed
	alignPosition.Responsiveness = 40
	alignPosition.RigidityEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Position = position
	alignPosition.Parent = root

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "Face"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = 40
	alignOrientation.RigidityEnabled = true
	alignOrientation.CFrame = CFrame.new(position)
	alignOrientation.Parent = root

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = Config.Income.ScareRange
	click.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "Emote"
	gui.Size = UDim2.fromOffset(80, 50)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 60
	gui.Enabled = false
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "😱"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = gui
	gui.Parent = root

	return model, root, alignPosition, alignOrientation, click, gui
end

local function setTarget(visitor, target)
	visitor.Target = target
	visitor.AlignPosition.Position = target
	local from = visitor.Root.Position
	local flat = Vector3.new(target.X, from.Y, target.Z)
	if (flat - from).Magnitude > 0.5 then
		visitor.AlignOrientation.CFrame = CFrame.lookAt(from, flat)
	end
end

local function despawn(visitor)
	visitors[visitor.Model] = nil
	local info = plotVisitors[visitor.Plot.Index]
	if info then
		info.Count = math.max(0, info.Count - 1)
		info.NextSpawn = os.clock() + Config.Visitors.SpawnDelay
	end
	visitor.Model:Destroy()
end

local function spawnVisitor(plot)
	local start = plot.Waypoints[1]
	local model, root, alignPosition, alignOrientation, click, emote = buildVisitor(start)
	local visitor = {
		Model = model,
		Root = root,
		AlignPosition = alignPosition,
		AlignOrientation = alignOrientation,
		Emote = emote,
		Plot = plot,
		WaypointIndex = 1,
		Fleeing = false,
		Scared = false,
		Path = plot.Waypoints,
	}
	visitors[model] = visitor
	model.Parent = workspace.Map.Visitors
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	click.MouseClick:Connect(function(player)
		VisitorService.onScare(player, visitor)
	end)
	visitor.WaypointIndex = 2
	setTarget(visitor, plot.Waypoints[2])
	local info = plotVisitors[plot.Index]
	info.Count += 1
end

local function step()
	local now = os.clock()
	for _, plot in ipairs(S.Plot.all()) do
		local info = plotVisitors[plot.Index]
		if not info then
			info = { Count = 0, NextSpawn = 0 }
			plotVisitors[plot.Index] = info
		end
		if plot.Owner and info.Count < Config.Visitors.PerPlot and now >= info.NextSpawn then
			spawnVisitor(plot)
			info.NextSpawn = now + Config.Visitors.SpawnDelay
		end
	end
	for model, visitor in pairs(visitors) do
		if not visitor.Plot.Owner or not model.Parent then
			despawn(visitor)
		else
			local pos = visitor.Root.Position
			if pos.Y < -20 or (pos - visitor.Target).Magnitude > 200 then
				despawn(visitor)
			else
				local flatDistance = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(visitor.Target.X, 0, visitor.Target.Z)).Magnitude
				if flatDistance < 2 then
					visitor.WaypointIndex += 1
					local nextPoint = visitor.Path[visitor.WaypointIndex]
					if nextPoint then
						setTarget(visitor, nextPoint)
					else
						despawn(visitor)
					end
				end
			end
		end
	end
end

function VisitorService.onScare(player, visitor)
	local data = S.Data.get(player)
	if not data or visitor.Scared then
		return
	end
	if visitor.Plot.Owner ~= player then
		S.Net.notify(player, "Fais peur aux visiteurs de TON manoir !", "error")
		return
	end
	local now = os.clock()
	if lastScare[player] and now - lastScare[player] < Config.Income.ScareCooldown then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - visitor.Root.Position).Magnitude > Config.Income.ScareRange + 6 then
		return
	end
	lastScare[player] = now
	visitor.Scared = true
	visitor.Fleeing = true
	visitor.Emote.Enabled = true
	visitor.AlignPosition.MaxVelocity = Config.Visitors.Speed * 2.2
	visitor.Path = { visitor.Plot.DoorPoint, visitor.Plot.ExitPoint }
	visitor.WaypointIndex = 1
	local pos = visitor.Root.Position
	if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(visitor.Plot.DoorPoint.X, 0, visitor.Plot.DoorPoint.Z)).Magnitude < 3 or (pos - visitor.Plot.ExitPoint).Magnitude < (pos - visitor.Plot.DoorPoint).Magnitude then
		visitor.WaypointIndex = 2
	end
	setTarget(visitor, visitor.Path[visitor.WaypointIndex])

	local st = S.Economy.getState(player)
	local coins = math.max(Config.Income.ScareBaseCoins * S.Economy.getState(player).Multiplier, st.Income * Config.Income.ScareIncomeSeconds)
	coins = math.floor(coins)
	S.Economy.addCoins(player, coins)
	data.Stats.Scares += 1
	S.Season.addXp(player, Config.Season.XpScare)
	S.Net.fire(player, "ScarePopup", { Amount = coins, Position = visitor.Root.Position })
end

function VisitorService.init(services)
	S = services
	local folder = Instance.new("Folder")
	folder.Name = "Visitors"
	folder.Parent = workspace.Map
	Players.PlayerRemoving:Connect(function(player)
		lastScare[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(step)
			if not ok then
				warn("[VisitorService] " .. tostring(err))
			end
		end
	end)
end

return VisitorService
