--!nonstrict
-- Point d'entree client : contexte partage, evenements serveur, initialisation des controleurs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Net = require(Shared:WaitForChild("Net"))
local Controllers = script.Parent:WaitForChild("Controllers")
local UI = require(Controllers:WaitForChild("UI"))

UI.init(playerGui)

local ctx = {
	Player = player,
	PlayerGui = playerGui,
	UI = UI,
	Config = require(Shared.Config),
	Economy = require(Shared.Economy),
	MonsterData = require(Shared.MonsterData),
	CoffinData = require(Shared.CoffinData),
	Rarity = require(Shared.Rarity),
	GachaMath = require(Shared.GachaMath),
	SeasonPass = require(Shared.SeasonPass),
	DailyRewards = require(Shared.DailyRewards),
	Offers = require(Shared.Offers),
	MonsterBuilder = require(Shared.MonsterBuilder),
	MonetizationIds = require(Shared.MonetizationIds),
	state = nil,
}

local eventHandlers = {}
local stateHandlers = {}

function ctx.on(name, fn)
	eventHandlers[name] = eventHandlers[name] or {}
	table.insert(eventHandlers[name], fn)
end

function ctx.onState(fn)
	table.insert(stateHandlers, fn)
	if ctx.state then
		task.spawn(fn, ctx.state)
	end
end

function ctx.attr(name)
	return player:GetAttribute(name)
end

function ctx.onAttr(name, fn)
	local connection = player:GetAttributeChangedSignal(name):Connect(function()
		fn(player:GetAttribute(name))
	end)
	task.spawn(fn, player:GetAttribute(name))
	return connection
end

function ctx.request(action, payload)
	local ok, result = pcall(function()
		return Net.request():InvokeServer(action, payload)
	end)
	if not ok then
		UI.toast("Connexion au serveur impossible, réessaie.", "error")
		return { ok = false }
	end
	if type(result) ~= "table" then
		return { ok = false }
	end
	if result.message then
		UI.toast(result.message, result.ok and "success" or "error")
	end
	return result
end

function ctx.requestSilent(action, payload)
	local ok, result = pcall(function()
		return Net.request():InvokeServer(action, payload)
	end)
	if not ok or type(result) ~= "table" then
		return { ok = false }
	end
	return result
end

function ctx.prompt(kind, key)
	return ctx.request("Prompt", { Kind = kind, Key = key })
end

function ctx.ownsPass(key)
	return ctx.state ~= nil and ctx.state.Passes ~= nil and ctx.state.Passes[key] == true
end

function ctx.systemMessage(text)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then
			general:DisplaySystemMessage(text)
		end
	end)
end

Net.serverEvent().OnClientEvent:Connect(function(name, payload)
	local handlers = eventHandlers[name]
	if not handlers then
		return
	end
	for _, fn in ipairs(handlers) do
		task.spawn(fn, payload)
	end
end)

ctx.on("State", function(payload)
	ctx.state = payload
	for _, fn in ipairs(stateHandlers) do
		task.spawn(fn, payload)
	end
end)
ctx.on("Notify", function(payload)
	UI.toast(payload.Text, payload.Kind)
end)
ctx.on("Announce", function(payload)
	UI.toast(payload.Text, payload.Kind, 6)
	ctx.systemMessage(payload.Text)
end)
ctx.on("OpenUI", function(payload)
	UI.open(payload.Ui, payload)
end)

-- Ecran de chargement
local loading = UI.new("Frame", { Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.Colors.Bg, ZIndex = 100, Parent = UI.screen() })
UI.label({ Text = "👻 Haunt a House", Font = UI.Font, TextSize = 48, TextScaled = true, Size = UDim2.new(0.8, 0, 0.2, 0), Position = UDim2.fromScale(0.1, 0.3), ZIndex = 101, Parent = loading })
local loadingText = UI.label({ Text = "Chargement de ton manoir...", TextSize = 22, TextScaled = true, Size = UDim2.new(0.8, 0, 0.08, 0), Position = UDim2.fromScale(0.1, 0.52), ZIndex = 101, TextColor3 = UI.Colors.Muted, Parent = loading })

local controllerOrder = { "HudController", "AnimController", "ShopController", "OffersController", "CoffinController", "InventoryController", "IndexController", "RebirthController", "DailyController", "SeasonController", "CodesController", "PlaytimeController", "BossController" }
for _, name in ipairs(controllerOrder) do
	local module = Controllers:WaitForChild(name)
	local ok, err = pcall(function()
		require(module).init(ctx)
	end)
	if not ok then
		warn("[Client] Erreur d'initialisation de " .. name .. " : " .. tostring(err))
	end
end

task.spawn(function()
	local waited = 0
	while player:GetAttribute("DataLoaded") ~= true do
		task.wait(0.25)
		waited += 0.25
		if waited > 20 then
			loadingText.Text = "Le chargement prend plus de temps que prévu... patience !"
		end
	end
	ctx.requestSilent("GetState")
	local tries = 0
	while ctx.state == nil and tries < 20 do
		task.wait(0.5)
		tries += 1
		if ctx.state == nil then
			ctx.requestSilent("GetState")
		end
	end
	UI.tween(loading, { BackgroundTransparency = 1 }, 0.4)
	for _, child in ipairs(loading:GetChildren()) do
		if child:IsA("TextLabel") then
			UI.tween(child, { TextTransparency = 1 }, 0.3)
		end
	end
	task.wait(0.45)
	loading:Destroy()
	if ctx.state and ctx.state.MemoryMode then
		UI.toast("Mode Studio : les données ne sont pas sauvegardées (active l'accès API dans Game Settings > Security).", "error", 8)
	end
end)
