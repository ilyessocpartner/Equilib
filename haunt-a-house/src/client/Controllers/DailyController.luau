--!nonstrict
-- Recompense quotidienne avec serie de 7 jours.
local DailyController = {}

function DailyController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local DailyRewards = ctx.DailyRewards

	local window = UI.window("Daily", "Récompense quotidienne", { Icon = "🎁", Size = UDim2.fromScale(0.62, 0.66), MaxSize = Vector2.new(820, 520) })
	local body = window.Body
	local streakLabel = UI.label({ Text = "", Font = UI.Font, TextSize = 22, TextScaled = true, Size = UDim2.new(1, 0, 0, 30), ZIndex = 23, Parent = body })
	UI.new("UITextSizeConstraint", { MaxTextSize = 24, Parent = streakLabel })
	local grid = UI.new("Frame", { Size = UDim2.new(1, 0, 1, -110), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 22, Parent = body }, {
		UI.new("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0.5, -8), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	local claimButton = UI.button({ Text = "Récupérer", Color = UI.Colors.Green, Size = UDim2.new(0.6, 0, 0, 50), Position = UDim2.new(0.2, 0, 1, -54), ZIndex = 24, MaxTextSize = 22, Parent = body, OnClick = function()
		ctx.request("ClaimDaily")
	end })

	local function refresh()
		local lastClaim = tonumber(ctx.attr("DailyLastClaim")) or 0
		local streak = tonumber(ctx.attr("DailyStreak")) or 0
		local now = os.time()
		local eval = DailyRewards.evaluate(lastClaim, streak, now)
		local todayDay = DailyRewards.dayForStreak(eval.CanClaim and eval.Streak or streak)
		local effectiveStreak = eval.CanClaim and eval.Streak or streak
		streakLabel.Text = "🔥 Série : " .. effectiveStreak .. " jour(s)" .. (eval.Reset and "  (série perdue, on recommence !)" or "")
		UI.clear(grid)
		for _, reward in ipairs(DailyRewards.Cycle) do
			local state
			if eval.CanClaim then
				state = reward.Day == todayDay and "today" or (reward.Day < todayDay and "done" or "locked")
			else
				local currentDay = DailyRewards.dayForStreak(streak)
				state = reward.Day <= currentDay and "done" or "locked"
			end
			local color = state == "today" and Color3.fromRGB(60, 140, 80) or (state == "done" and Color3.fromRGB(50, 45, 70) or UI.Colors.Panel2)
			local card = UI.new("Frame", { BackgroundColor3 = color, LayoutOrder = reward.Day, ZIndex = 23, Parent = grid }, { UI.corner(12), UI.stroke(state == "today" and UI.Colors.Gold or Color3.fromRGB(0, 0, 0), state == "today" and 3 or 1, 0.3), UI.padding(8, 6) })
			UI.label({ Text = "Jour " .. reward.Day .. (reward.Day == 7 and " 👑" or ""), Font = UI.Font, TextSize = 16, TextScaled = true, Size = UDim2.new(1, 0, 0.3, 0), ZIndex = 24, Parent = card })
			UI.label({ Text = reward.Label, TextSize = 14, TextScaled = true, Size = UDim2.new(1, 0, 0.45, 0), Position = UDim2.fromScale(0, 0.3), TextColor3 = state == "done" and UI.Colors.Muted or UI.Colors.Text, ZIndex = 24, Parent = card })
			UI.label({ Text = state == "done" and "✅" or (state == "today" and "🎁 AUJOURD'HUI" or "🔒"), TextSize = 13, TextScaled = true, Size = UDim2.new(1, 0, 0.22, 0), Position = UDim2.fromScale(0, 0.76), ZIndex = 24, Parent = card })
		end
		if eval.CanClaim then
			claimButton.Text = "🎁 Récupérer (jour " .. todayDay .. ")"
			UI.setEnabled(claimButton, true)
		else
			claimButton.Text = "⏳ Prochaine dans " .. Economy.formatTime(eval.SecondsUntil)
			UI.setEnabled(claimButton, false)
		end
	end

	window.OnOpen = refresh
	ctx.onAttr("DailyLastClaim", function()
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

return DailyController
