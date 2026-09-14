--!nonstrict
-- Barre de vie du boss et avertissements.
local CollectionService = game:GetService("CollectionService")

local BossController = {}

function BossController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local screen = UI.screen()

	local frame = UI.new("Frame", { Name = "BossBar", Size = UDim2.fromOffset(460, 76), Position = UDim2.new(0.5, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(60, 20, 30), Visible = false, ZIndex = 8, Parent = screen }, { UI.corner(14), UI.stroke(UI.Colors.Red, 3), UI.padding(10, 6) })
	local nameLabel = UI.label({ Text = "", Font = UI.Font, TextSize = 18, Size = UDim2.new(0.7, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Red, ZIndex = 9, Parent = frame })
	local timerLabel = UI.label({ Text = "", Font = UI.Font, TextSize = 16, Size = UDim2.new(0.3, 0, 0, 24), Position = UDim2.new(0.7, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 9, Parent = frame })
	local bar = UI.progress(frame, UI.Colors.Red, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 30))
	local state = { Active = false, Hp = 0, MaxHp = 1, EndsAt = 0 }

	local function apply(payload)
		state = payload
		frame.Visible = payload.Active
		if payload.Active then
			nameLabel.Text = "⚔️ " .. payload.Name .. "  (clique dessus à l'Arène !)"
			bar.Set(payload.Hp / math.max(1, payload.MaxHp), Economy.format(payload.Hp) .. " / " .. Economy.format(payload.MaxHp) .. " PV")
		end
	end

	ctx.on("Boss", apply)
	ctx.on("BossWarning", function(payload)
		UI.toast("🌙 Minuit dans " .. payload.Seconds .. " s : rejoins l'Arène (au nord de la place) pour le raid !", "boss", 8)
	end)
	ctx.on("BossHit", function(payload)
		local bossModel = CollectionService:GetTagged("Boss")[1]
		if bossModel and bossModel.PrimaryPart then
			ctx.popup3D(bossModel.PrimaryPart.Position + Vector3.new(0, 8, 0), "-" .. Economy.format(payload.Damage), UI.Colors.Red)
		end
	end)
	task.spawn(function()
		local synced = false
		while true do
			task.wait(1)
			if not synced and ctx.attr("DataLoaded") == true then
				local result = ctx.requestSilent("BossState")
				if result.ok and result.data then
					synced = true
					apply(result.data)
				end
			end
			if state.Active then
				timerLabel.Text = "⏳ " .. Economy.formatTime(state.EndsAt - os.time())
				if os.time() > state.EndsAt + 3 then
					frame.Visible = false
					state.Active = false
				end
			end
		end
	end)
end

return BossController
