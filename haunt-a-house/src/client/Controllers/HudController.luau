--!nonstrict
-- HUD : coins, revenus, menus, boosts, offres, popups.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local HudController = {}

function HudController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local Config = ctx.Config
	local Offers = ctx.Offers
	local screen = UI.screen()

	-- Panneau coins (haut gauche)
	local topLeft = UI.new("Frame", { Name = "TopLeft", Size = UDim2.fromOffset(300, 92), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = UI.Colors.Bg, BackgroundTransparency = 0.15, ZIndex = 5, Parent = screen }, { UI.corner(16), UI.stroke(UI.Colors.Accent2, 2, 0.3), UI.padding(12, 8) })
	local coinsLabel = UI.label({ Name = "Coins", Text = "🪙 0", Font = UI.Font, TextSize = 34, TextScaled = true, Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Gold, ZIndex = 6, Parent = topLeft })
	UI.new("UITextSizeConstraint", { MaxTextSize = 36, MinTextSize = 16, Parent = coinsLabel })
	local incomeLabel = UI.label({ Name = "Income", Text = "+0/s", TextSize = 16, Size = UDim2.new(0.5, 0, 0, 20), Position = UDim2.new(0, 0, 0, 42), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Green, ZIndex = 6, Parent = topLeft })
	local multLabel = UI.label({ Name = "Mult", Text = "x1", TextSize = 16, Size = UDim2.new(0.5, 0, 0, 20), Position = UDim2.new(0.5, 0, 0, 42), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.Colors.Accent2, ZIndex = 6, Parent = topLeft })
	local rebirthLabel = UI.label({ Name = "Rebirth", Text = "♻️ Rebirth 0", TextSize = 14, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 62), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Muted, ZIndex = 6, Parent = topLeft })

	-- Boosts actifs
	local boosts = UI.new("Frame", { Name = "Boosts", Size = UDim2.fromOffset(300, 30), Position = UDim2.fromOffset(12, 110), BackgroundTransparency = 1, ZIndex = 5, Parent = screen }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function chip(name, color)
		local frame = UI.new("Frame", { Name = name, Size = UDim2.fromOffset(96, 28), BackgroundColor3 = color, Visible = false, ZIndex = 6, Parent = boosts }, { UI.corner(8) })
		local label = UI.label({ Text = "", Font = UI.Font, TextSize = 14, TextScaled = true, ZIndex = 7, Parent = frame })
		UI.new("UITextSizeConstraint", { MaxTextSize = 15, Parent = label })
		return frame, label
	end
	local coinsChip, coinsChipLabel = chip("CoinsBoost", Color3.fromRGB(200, 120, 20))
	local luckChip, luckChipLabel = chip("LuckBoost", Color3.fromRGB(40, 140, 70))
	local serverChip, serverChipLabel = chip("ServerLuck", Color3.fromRGB(30, 110, 160))

	-- Menu gauche
	local menu = UI.new("Frame", { Name = "Menu", Size = UDim2.fromOffset(74, 460), Position = UDim2.new(0, 12, 0.5, -200), BackgroundTransparency = 1, ZIndex = 5, Parent = screen }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local menuItems = {
		{ Key = "Shop", Icon = "🛒", Text = "Boutique", Color = UI.Colors.Robux },
		{ Key = "Coffins", Icon = "⚰️", Text = "Cercueils", Color = Color3.fromRGB(120, 70, 40) },
		{ Key = "Inventory", Icon = "👻", Text = "Monstres", Color = UI.Colors.Accent2 },
		{ Key = "Rebirth", Icon = "♻️", Text = "Rebirth", Color = Color3.fromRGB(110, 60, 190) },
		{ Key = "Daily", Icon = "🎁", Text = "Quotidien", Color = Color3.fromRGB(200, 60, 90) },
		{ Key = "Index", Icon = "📖", Text = "Bestiaire", Color = Color3.fromRGB(50, 120, 200) },
		{ Key = "Season", Icon = "🎃", Text = "Passe", Color = UI.Colors.Accent },
		{ Key = "Codes", Icon = "🔑", Text = "Codes", Color = Color3.fromRGB(80, 80, 110) },
	}
	for index, item in ipairs(menuItems) do
		local button = UI.button({ Name = item.Key, Text = item.Icon, Color = item.Color, Size = UDim2.fromOffset(52, 52), LayoutOrder = index, Radius = 14, ZIndex = 6, MaxTextSize = 28, Parent = menu, OnClick = function()
			UI.toggle(item.Key)
		end })
		UI.label({ Text = item.Text, Font = UI.Font, TextSize = 11, Size = UDim2.new(0, 70, 0, 14), Position = UDim2.new(0, -9, 1, -2), TextStrokeTransparency = 0.3, ZIndex = 7, Parent = button })
	end

	-- Boutons bas droite
	local bottomRight = UI.new("Frame", { Name = "BottomRight", Size = UDim2.fromOffset(160, 150), Position = UDim2.new(1, -12, 1, -12), AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = screen }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom }),
	})
	local playtimeButton = UI.button({ Name = "Playtime", Text = "⏱️ Récompenses", Color = Color3.fromRGB(60, 140, 90), Size = UDim2.fromOffset(160, 42), LayoutOrder = 1, ZIndex = 6, MaxTextSize = 18, Parent = bottomRight, OnClick = function()
		UI.toggle("Playtime")
	end })
	UI.button({ Name = "Home", Text = "🏚️ Mon manoir", Color = Color3.fromRGB(120, 70, 40), Size = UDim2.fromOffset(160, 42), LayoutOrder = 2, ZIndex = 6, MaxTextSize = 18, Parent = bottomRight, OnClick = function()
		ctx.requestSilent("TeleportHome")
	end })
	UI.button({ Name = "Hub", Text = "🏛️ Place centrale", Color = Color3.fromRGB(70, 70, 110), Size = UDim2.fromOffset(160, 42), LayoutOrder = 3, ZIndex = 6, MaxTextSize = 18, Parent = bottomRight, OnClick = function()
		ctx.requestSilent("TeleportHub")
	end })

	-- Badges d'offres (haut droite)
	local offersFrame = UI.new("Frame", { Name = "Offers", Size = UDim2.fromOffset(190, 120), Position = UDim2.new(1, -12, 0, 12), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, ZIndex = 5, Parent = screen }, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
	})
	local starterBadge = UI.button({ Name = "Starter", Text = "🎁 PACK DÉMARRAGE\n00:00:00", Color = Color3.fromRGB(220, 60, 100), Size = UDim2.fromOffset(190, 50), LayoutOrder = 1, ZIndex = 6, MaxTextSize = 16, Parent = offersFrame, OnClick = function()
		UI.open("Shop", { Tab = "Offers" })
	end })
	starterBadge.Visible = false
	local flashBadge = UI.button({ Name = "Flash", Text = "⚡ OFFRE FLASH\n00:00:00", Color = Color3.fromRGB(200, 120, 20), Size = UDim2.fromOffset(190, 50), LayoutOrder = 2, ZIndex = 6, MaxTextSize = 16, Parent = offersFrame, OnClick = function()
		UI.open("Shop", { Tab = "Offers" })
	end })

	-- Popup 3D
	function ctx.popup3D(position, text, color)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.CFrame = CFrame.new(position + Vector3.new(math.random(-10, 10) / 10, 2, math.random(-10, 10) / 10))
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(160, 50)
		gui.AlwaysOnTop = true
		gui.StudsOffset = Vector3.new(0, 0, 0)
		local label = UI.label({ Text = text, Font = UI.Font, TextSize = 26, TextScaled = true, TextColor3 = color or UI.Colors.Gold, TextStrokeTransparency = 0.2, Parent = gui })
		gui.Parent = part
		part.Parent = workspace
		UI.tween(gui, { StudsOffset = Vector3.new(0, 4, 0) }, 1.0)
		task.delay(0.6, function()
			UI.tween(label, { TextTransparency = 1, TextStrokeTransparency = 1 }, 0.4)
		end)
		Debris:AddItem(part, 1.2)
	end

	-- Popup de collecte (2D)
	local function collectPopup(amount)
		local label = UI.label({ Text = "+" .. Economy.format(amount) .. " 🪙", Font = UI.Font, TextSize = 40, TextScaled = true, TextColor3 = UI.Colors.Gold, TextStrokeTransparency = 0.2, Size = UDim2.fromOffset(300, 60), Position = UDim2.fromScale(0.5, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 40, Parent = screen })
		UI.tween(label, { Position = UDim2.fromScale(0.5, 0.35) }, 1.2)
		task.delay(0.7, function()
			UI.tween(label, { TextTransparency = 1, TextStrokeTransparency = 1 }, 0.5)
		end)
		Debris:AddItem(label, 1.3)
	end

	ctx.on("Collected", function(payload)
		collectPopup(payload.Amount)
	end)
	ctx.on("ScarePopup", function(payload)
		ctx.popup3D(payload.Position, "BOO ! +" .. Economy.format(payload.Amount) .. " 🪙", UI.Colors.Gold)
	end)
	ctx.on("RebirthDone", function(payload)
		UI.toast("♻️ Rebirth " .. payload.Rebirths .. " ! Tes gains sont maintenant x" .. payload.Multiplier .. ". Nouvelles salles et cercueils débloqués !", "rebirth", 7)
	end)

	-- Compteur anime de coins
	local displayed = 0
	local target = 0
	ctx.onAttr("Coins", function(value)
		target = tonumber(value) or 0
	end)
	ctx.onAttr("Income", function(value)
		incomeLabel.Text = "+" .. Economy.format(tonumber(value) or 0) .. "/s"
	end)
	ctx.onAttr("Multiplier", function(value)
		local mult = tonumber(value) or 1
		multLabel.Text = "x" .. string.format(mult % 1 == 0 and "%d" or "%.2f", mult)
	end)
	ctx.onAttr("Rebirths", function(value)
		rebirthLabel.Text = "♻️ Rebirth " .. tostring(value or 0)
	end)

	local starterConfigured = ctx.MonetizationIds.Products.StarterPack.Id > 0
	local lastSecond = 0
	RunService.RenderStepped:Connect(function(dt)
		if math.abs(target - displayed) > 0.5 then
			displayed += (target - displayed) * math.min(1, dt * 8)
			if math.abs(target - displayed) < 1 then
				displayed = target
			end
			coinsLabel.Text = "🪙 " .. Economy.format(displayed)
		end
		local now = os.time()
		if now ~= lastSecond then
			lastSecond = now
			local coinsEnd = tonumber(ctx.attr("CoinsBoostEnd")) or 0
			local luckEnd = tonumber(ctx.attr("LuckBoostEnd")) or 0
			local serverEnd = tonumber(ReplicatedStorage:GetAttribute("ServerLuckEnd")) or 0
			coinsChip.Visible = coinsEnd > now
			luckChip.Visible = luckEnd > now
			serverChip.Visible = serverEnd > now
			if coinsChip.Visible then
				coinsChipLabel.Text = "⚡2x " .. Economy.formatTime(coinsEnd - now)
			end
			if luckChip.Visible then
				luckChipLabel.Text = "🍀2x " .. Economy.formatTime(luckEnd - now)
			end
			if serverChip.Visible then
				serverChipLabel.Text = "🌐🍀 " .. Economy.formatTime(serverEnd - now)
			end
			local restricted = ctx.attr("PaidRandomRestricted") == true
			local remaining = Offers.starterRemaining(tonumber(ctx.attr("StarterFirstJoin")) or 0, ctx.attr("StarterPurchased") == true, now)
			starterBadge.Visible = starterConfigured and not restricted and remaining > 0 and ctx.attr("DataLoaded") == true
			if starterBadge.Visible then
				starterBadge.Text = "🎁 PACK DÉMARRAGE " .. ctx.MonetizationIds.Products.StarterPack.Price .. " R$\n⏳ " .. Economy.formatTime(remaining)
			end
			local _, deal, rotationLeft = Offers.getFlashDeal(now)
			local dealConfigured = ctx.MonetizationIds.Products[deal.Key].Id > 0
			flashBadge.Visible = dealConfigured and not (restricted and deal.Key ~= "FlashRebirthRush")
			if flashBadge.Visible then
				flashBadge.Text = "⚡ " .. string.upper(deal.Title) .. "\n⏳ " .. Economy.formatTime(rotationLeft)
			end
			-- Prochaine recompense de temps de jeu
			local sessionStart = tonumber(ctx.attr("SessionStart")) or now
			local elapsed = now - sessionStart
			local claimed = ctx.state and ctx.state.Playtime or {}
			local nextText = nil
			for index, entry in ipairs(Config.Playtime) do
				if not claimed[index] then
					local left = entry.Minutes * 60 - elapsed
					if left <= 0 then
						nextText = "⏱️ RÉCOMPENSE PRÊTE !"
					else
						nextText = "⏱️ Bonus dans " .. Economy.formatTime(left)
					end
					break
				end
			end
			playtimeButton.Text = nextText or "⏱️ Récompenses"
			playtimeButton.BackgroundColor3 = (nextText and string.find(nextText, "PRÊTE")) and UI.Colors.Green or Color3.fromRGB(60, 140, 90)
		end
	end)
end

return HudController
