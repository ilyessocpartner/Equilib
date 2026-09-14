--!nonstrict
-- Passe de saison : piste gratuite et premium, XP, reclamation.
local SeasonController = {}

function SeasonController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local Config = ctx.Config
	local SeasonPass = ctx.SeasonPass

	local window = UI.window("Season", Config.Season.Name, { Icon = "🎃" })
	local body = window.Body
	local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 84), BackgroundColor3 = UI.Colors.Panel, ZIndex = 22, Parent = body }, { UI.corner(12), UI.padding(10, 8) })
	local tierLabel = UI.label({ Text = "", Font = UI.Font, TextSize = 20, Size = UDim2.new(0.6, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23, Parent = header })
	local endLabel = UI.label({ Text = "", TextSize = 14, Size = UDim2.new(0.4, 0, 0, 26), Position = UDim2.new(0.6, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.Colors.Muted, ZIndex = 23, Parent = header })
	local bar = UI.progress(header, UI.Colors.Accent, UDim2.new(0.62, 0, 0, 26), UDim2.new(0, 0, 0, 36))
	local premiumButton = UI.button({ Text = "🎃 Passe Premium  R$ " .. ctx.MonetizationIds.GamePasses.SeasonPremium.Price, Color = UI.Colors.Robux, Size = UDim2.new(0.36, 0, 0, 40), Position = UDim2.new(0.64, 0, 0, 30), ZIndex = 24, MaxTextSize = 16, Parent = header, OnClick = function()
		ctx.prompt("Pass", "SeasonPremium")
	end })
	local track = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -92), Position = UDim2.new(0, 0, 0, 92), BackgroundColor3 = UI.Colors.Panel, BackgroundTransparency = 0.2, BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = UI.Colors.Accent2, AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(), ZIndex = 22, Parent = body }, {
		UI.corner(12), UI.padding(8),
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local function rewardCard(parent, tier, reward, premium, reached, claimed, hasPremium, order)
		local locked = premium and not hasPremium
		local color = claimed and Color3.fromRGB(45, 40, 65) or (premium and Color3.fromRGB(80, 40, 30) or UI.Colors.Panel2)
		local card = UI.new("Frame", { Size = UDim2.new(1, 0, 0.5, -4), BackgroundColor3 = color, LayoutOrder = order, ZIndex = 23, Parent = parent }, { UI.corner(10), UI.stroke(premium and UI.Colors.Accent or Color3.fromRGB(0, 0, 0), premium and 2 or 1, 0.3), UI.padding(6, 4) })
		local text = SeasonPass.describe(reward)
		if reward.Type == "Monster" then
			local def = ctx.MonsterData.get(reward.Id)
			text = "👻 " .. (def and def.Name or "Monstre") .. " (exclusif)"
		elseif reward.Type == "Coins" then
			text = "🪙 " .. Economy.format(reward.Amount) .. " coins"
		elseif reward.Type == "NightmareCoffin" then
			text = "⚰️ " .. reward.Amount .. " Cauchemar"
		elseif reward.Type == "CoinsBoost" then
			text = "⚡ 2x Coins " .. reward.Minutes .. " min"
		elseif reward.Type == "LuckBoost" then
			text = "🍀 2x Chance " .. reward.Minutes .. " min"
		end
		UI.label({ Text = (premium and "PREMIUM\n" or "GRATUIT\n") .. text, TextSize = 13, TextScaled = true, Size = UDim2.new(1, 0, 0.6, 0), TextColor3 = premium and UI.Colors.Gold or UI.Colors.Text, ZIndex = 24, Parent = card })
		local buttonText = claimed and "✅" or (locked and "🔒 Premium" or (reached and "Récupérer" or "🔒"))
		local button = UI.button({ Text = buttonText, Color = (reached and not claimed and not locked) and UI.Colors.Green or Color3.fromRGB(90, 85, 110), Size = UDim2.new(1, 0, 0.36, 0), Position = UDim2.fromScale(0, 0.64), ZIndex = 24, MaxTextSize = 14, Parent = card, OnClick = function()
			if locked then
				ctx.prompt("Pass", "SeasonPremium")
			elseif reached and not claimed then
				ctx.request("ClaimSeason", { Tier = tier, Premium = premium })
			end
		end })
		UI.setEnabled(button, not claimed and (locked or reached))
	end

	local function refresh()
		local state = ctx.state
		if not state then
			return
		end
		local xp = tonumber(ctx.attr("SeasonXp")) or 0
		local tier, cur, need = SeasonPass.progress(xp)
		local hasPremium = ctx.ownsPass("SeasonPremium")
		tierLabel.Text = "🎃 Palier " .. tier .. " / " .. SeasonPass.TierCount .. "   ·   XP total : " .. Economy.format(xp)
		local left = Config.Season.EndsAt - os.time()
		endLabel.Text = left > 0 and ("Fin dans " .. math.floor(left / 86400) .. "j " .. Economy.formatTime(left % 86400)) or "Saison terminée"
		if tier >= SeasonPass.TierCount then
			bar.Set(1, "Passe terminé ! 🎉")
		else
			bar.Set(cur / need, Economy.format(cur) .. " / " .. Economy.format(need) .. " XP")
		end
		premiumButton.Visible = not hasPremium
		UI.setEnabled(premiumButton, ctx.MonetizationIds.GamePasses.SeasonPremium.Id > 0)
		UI.clear(track)
		for t = 1, SeasonPass.TierCount do
			local column = UI.new("Frame", { Size = UDim2.new(0, 150, 1, 0), BackgroundTransparency = 1, LayoutOrder = t, ZIndex = 23, Parent = track }, {
				UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			})
			local reached = tier >= t
			UI.label({ Text = "Palier " .. t, Font = UI.Font, TextSize = 15, Size = UDim2.new(1, 0, 0, 20), TextColor3 = reached and UI.Colors.Green or UI.Colors.Muted, LayoutOrder = 0, ZIndex = 24, Parent = column })
			local rewards = SeasonPass.Rewards[t]
			local cards = UI.new("Frame", { Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 23, Parent = column }, {
				UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			})
			rewardCard(cards, t, rewards.Free, false, reached, state.Season.ClaimedFree[tostring(t)] == true, hasPremium, 1)
			rewardCard(cards, t, rewards.Premium, true, reached, state.Season.ClaimedPremium[tostring(t)] == true, hasPremium, 2)
		end
	end

	window.OnOpen = refresh
	ctx.onState(function()
		if window.Frame.Visible then
			refresh()
		end
	end)
	ctx.onAttr("SeasonXp", function()
		if window.Frame.Visible then
			refresh()
		end
	end)
end

return SeasonController
