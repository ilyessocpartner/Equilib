--!nonstrict
-- Recompenses de temps de jeu (session).
local PlaytimeController = {}

function PlaytimeController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local Config = ctx.Config

	local window = UI.window("Playtime", "Récompenses de temps de jeu", { Icon = "⏱️", Size = UDim2.fromScale(0.5, 0.7), MaxSize = Vector2.new(640, 560) })
	local body = window.Body
	UI.label({ Text = "Reste connecté pour débloquer ces bonus (réinitialisés à chaque session).", TextSize = 14, Size = UDim2.new(1, 0, 0, 30), TextColor3 = UI.Colors.Muted, ZIndex = 23, Parent = body })
	local list = UI.scroll(body, { Size = UDim2.new(1, 0, 1, -36), Position = UDim2.new(0, 0, 0, 36) })

	local function describe(entry)
		if entry.Type == "Coins" then
			return "🪙 " .. Economy.format(entry.Amount) .. " coins (x rebirth)"
		elseif entry.Type == "CoinsBoost" then
			return "⚡ 2x Coins " .. entry.Minutes2 .. " min"
		elseif entry.Type == "LuckBoost" then
			return "🍀 2x Chance " .. entry.Minutes2 .. " min"
		elseif entry.Type == "NightmareCoffin" then
			return "⚰️ " .. entry.Amount .. " Cercueil Cauchemar"
		end
		return "?"
	end

	local function refresh()
		UI.clear(list)
		local now = os.time()
		local sessionStart = tonumber(ctx.attr("SessionStart")) or now
		local elapsed = now - sessionStart
		local claimed = ctx.state and ctx.state.Playtime or {}
		for index, entry in ipairs(Config.Playtime) do
			local done = claimed[index] == true
			local ready = elapsed >= entry.Minutes * 60
			local card = UI.card(list, { Size = UDim2.new(1, 0, 0, 62), LayoutOrder = index, Color = done and Color3.fromRGB(45, 40, 65) or UI.Colors.Panel2 })
			UI.label({ Text = "⏱️ " .. entry.Minutes .. " min", Font = UI.Font, TextSize = 18, Size = UDim2.new(0.25, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24, Parent = card })
			UI.label({ Text = describe(entry), TextSize = 15, Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.new(0.25, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24, Parent = card })
			local button = UI.button({ Text = done and "✅" or (ready and "Récupérer" or Economy.formatTime(entry.Minutes * 60 - elapsed)), Color = (ready and not done) and UI.Colors.Green or Color3.fromRGB(90, 85, 110), Size = UDim2.new(0.28, 0, 0, 40), Position = UDim2.new(0.72, 0, 0.5, -20), ZIndex = 24, MaxTextSize = 16, Parent = card, OnClick = function()
				ctx.request("ClaimPlaytime", { Index = index })
			end })
			UI.setEnabled(button, ready and not done)
		end
	end

	window.OnOpen = refresh
	ctx.onState(function()
		if window.Frame.Visible then
			refresh()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if window.Frame.Visible then
				refresh()
			end
		end
	end)
end

return PlaytimeController
