--!nonstrict
-- Raid cooperatif de Minuit : tout le serveur clique sur le Capitaine Chasseur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local Economy = require(ReplicatedStorage.Shared.Economy)

local BossService = {}
local S

local state = { Active = false, Hp = 0, MaxHp = 0, EndsAt = 0, Damage = {}, Model = nil, Dirty = false }
local lastHit = {} -- [player] = os.clock

local function buildBoss(origin)
	local model = Instance.new("Model")
	model.Name = Config.Boss.Name
	local root = Util.part({ Name = "Root", Size = Vector3.new(1, 1, 1), CFrame = origin, Transparency = 1, CanCollide = false, Parent = model })
	model.PrimaryPart = root
	local function add(props)
		props.Parent = model
		props.CanCollide = false
		local part = Util.part(props)
		part.CanTouch = false
		Util.weld(root, part)
		return part
	end
	local body = add({ Name = "Body", Size = Vector3.new(7, 8, 4), CFrame = origin * CFrame.new(0, 6, 0), Color = { 40, 70, 45 }, Material = "Fabric" })
	add({ Name = "Belt", Size = Vector3.new(7.2, 1, 4.2), CFrame = origin * CFrame.new(0, 4.5, 0), Color = { 60, 40, 25 }, Material = "Leather" })
	add({ Name = "Head", Shape = "Ball", Size = Vector3.new(4.2, 4.2, 4.2), CFrame = origin * CFrame.new(0, 12, 0), Color = { 220, 180, 150 } })
	add({ Name = "HatBrim", Shape = "Cylinder", Size = Vector3.new(0.3, 6.5, 6.5), CFrame = origin * CFrame.new(0, 13.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 40, 30, 25 } })
	add({ Name = "HatTop", Shape = "Cylinder", Size = Vector3.new(3, 4, 4), CFrame = origin * CFrame.new(0, 15.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 40, 30, 25 } })
	for _, side in ipairs({ -1, 1 }) do
		add({ Name = "Eye", Shape = "Ball", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = origin * CFrame.new(side * 0.8, 12.4, -1.9), Color = { 255, 40, 40 }, Material = "Neon" })
		add({ Name = "Arm", Size = Vector3.new(2, 7, 2), CFrame = origin * CFrame.new(side * 4.6, 6, 0) * CFrame.Angles(0, 0, side * math.rad(-15)), Color = { 40, 70, 45 }, Material = "Fabric" })
		add({ Name = "Leg", Size = Vector3.new(2.4, 4, 2.4), CFrame = origin * CFrame.new(side * 1.8, 2, 0), Color = { 50, 40, 35 } })
	end
	add({ Name = "Vacuum", Shape = "Cylinder", Size = Vector3.new(7, 2.2, 2.2), CFrame = origin * CFrame.new(-6, 4, -2) * CFrame.Angles(0, math.rad(30), 0), Color = { 160, 160, 170 }, Material = "Metal" })
	local tank = add({ Name = "Tank", Shape = "Cylinder", Size = Vector3.new(6, 4, 4), CFrame = origin * CFrame.new(0, 7, 3.5) * CFrame.Angles(0, 0, math.rad(90)), Color = { 120, 60, 200 }, Material = "Glass", Transparency = 0.3 })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(180, 80, 255)
	light.Range = 30
	light.Brightness = 2
	light.Parent = tank
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 80), Color3.fromRGB(120, 0, 40))
	emitter.Rate = 25
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(3, 6)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0) })
	emitter.LightEmission = 1
	emitter.Parent = body

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = Config.Boss.Range
	click.Parent = model
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			part.CanQuery = true
		end
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(340, 90)
	gui.StudsOffset = Vector3.new(0, 19, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 250
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "⚔️ " .. Config.Boss.Name .. "\nCLIQUE POUR ATTAQUER !"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = root
	CollectionService:AddTag(model, "Boss")
	return model, click
end

local function broadcast()
	S.Net.fireAll("Boss", { Active = state.Active, Hp = math.max(0, state.Hp), MaxHp = state.MaxHp, EndsAt = state.EndsAt, Name = Config.Boss.Name })
end

local function finish(victory)
	if not state.Active then
		return
	end
	state.Active = false
	local participants = {}
	for player, damage in pairs(state.Damage) do
		if player.Parent and damage > 0 then
			table.insert(participants, { Player = player, Damage = damage })
		end
	end
	table.sort(participants, function(a, b)
		return a.Damage > b.Damage
	end)
	if victory then
		S.Net.announce("🏆 Le " .. Config.Boss.Name .. " est vaincu ! Récompenses distribuées aux " .. #participants .. " combattants.", "boss")
		for rank, info in ipairs(participants) do
			local player = info.Player
			local data = S.Data.get(player)
			if data then
				local st = S.Economy.getState(player)
				local coins = math.floor(info.Damage * Config.Boss.CoinsPerDamage * st.Multiplier)
				S.Economy.addCoins(player, coins)
				data.Stats.BossKills += 1
				S.Season.addXp(player, Config.Boss.XpReward)
				local coffins = 0
				if rank <= Config.Boss.NightmareCoffinTopCount then
					coffins = 1
				elseif math.random() < Config.Boss.NightmareCoffinChanceOthers then
					coffins = 1
				end
				if coffins > 0 then
					data.NightmareCoffins += coffins
					player:SetAttribute("NightmareCoffins", data.NightmareCoffins)
				end
				S.Net.notify(player, "⚔️ Raid gagné ! +" .. Economy.format(coins) .. " coins" .. (coffins > 0 and " + 1 Cercueil Cauchemar" or "") .. (rank <= 3 and " (Top " .. rank .. " !)" or ""), "success")
				S.Player.sendState(player)
			end
		end
	else
		S.Net.announce("💨 Le " .. Config.Boss.Name .. " s'est enfui... Il reviendra dans " .. math.floor(Config.Boss.IntervalSeconds / 60) .. " min !", "boss")
	end
	state.Damage = {}
	broadcast()
	local model = state.Model
	state.Model = nil
	if model then
		task.delay(1.5, function()
			model:Destroy()
		end)
	end
end

local function onHit(player)
	if not state.Active then
		return
	end
	local data = S.Data.get(player)
	if not data then
		return
	end
	local now = os.clock()
	if lastHit[player] and now - lastHit[player] < Config.Boss.ClickCooldown then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not state.Model or (root.Position - state.Model.PrimaryPart.Position).Magnitude > Config.Boss.Range + 12 then
		return
	end
	lastHit[player] = now
	local st = S.Economy.getState(player)
	local damage = math.max(Config.Boss.MinClickDamage, math.floor(st.BasePower))
	state.Hp -= damage
	state.Damage[player] = (state.Damage[player] or 0) + damage
	state.Dirty = true
	S.Net.fire(player, "BossHit", { Damage = damage })
	if state.Hp <= 0 then
		finish(true)
	end
end

local function startRaid()
	local totalPower = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if S.Data.get(player) then
			totalPower += S.Economy.getState(player).BasePower
		end
	end
	state.MaxHp = math.floor(Config.Boss.BaseHealth + totalPower * Config.Boss.HealthPerPower)
	state.Hp = state.MaxHp
	state.EndsAt = os.time() + Config.Boss.DurationSeconds
	state.Damage = {}
	state.Active = true
	local model, click = buildBoss(S.Map.Points.BossSpawn)
	model.Parent = workspace.Map
	state.Model = model
	click.MouseClick:Connect(onHit)
	S.Net.announce("⚔️ MINUIT ! Le " .. Config.Boss.Name .. " attaque l'Arène ! Tous ensemble, cliquez dessus !", "boss")
	broadcast()
	local startedAt = os.time()
	while state.Active and os.time() < startedAt + Config.Boss.DurationSeconds do
		task.wait(0.25)
		if state.Dirty then
			state.Dirty = false
			broadcast()
		end
	end
	if state.Active then
		finish(false)
	end
end

function BossService.init(services)
	S = services
	Players.PlayerRemoving:Connect(function(player)
		lastHit[player] = nil
		state.Damage[player] = nil
	end)
	S.Net.register("BossState", "Default", function()
		return { ok = true, data = { Active = state.Active, Hp = math.max(0, state.Hp), MaxHp = state.MaxHp, EndsAt = state.EndsAt, Name = Config.Boss.Name } }
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Boss.IntervalSeconds - Config.Boss.WarningSeconds)
			if #Players:GetPlayers() > 0 then
				S.Net.announce("🌙 Minuit approche : le " .. Config.Boss.Name .. " arrive dans " .. Config.Boss.WarningSeconds .. " s à l'Arène !", "boss")
				S.Net.fireAll("BossWarning", { Seconds = Config.Boss.WarningSeconds })
			end
			task.wait(Config.Boss.WarningSeconds)
			if #Players:GetPlayers() > 0 then
				local ok, err = pcall(startRaid)
				if not ok then
					warn("[BossService] " .. tostring(err))
					state.Active = false
					if state.Model then
						state.Model:Destroy()
						state.Model = nil
					end
				end
			end
		end
	end)
end

return BossService
