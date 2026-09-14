--!nonstrict
-- Bestiaire : collection des monstres decouverts (teasing des monstres verrouilles).
local IndexController = {}

function IndexController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local MonsterData = ctx.MonsterData
	local CoffinData = ctx.CoffinData
	local Rarity = ctx.Rarity
	local Config = ctx.Config

	local window = UI.window("Index", "Bestiaire", { Icon = "📖" })
	local body = window.Body
	local header = UI.label({ Text = "", Font = UI.Font, TextSize = 20, TextScaled = true, Size = UDim2.new(1, 0, 0, 34), ZIndex = 23, Parent = body })
	UI.new("UITextSizeConstraint", { MaxTextSize = 22, Parent = header })
	local grid = UI.scroll(body, { Size = UDim2.new(1, 0, 1, -40), Position = UDim2.new(0, 0, 0, 40), Grid = true, CellSize = UDim2.fromOffset(150, 110) })

	local function sourceOf(def)
		local coffinId = CoffinData.CoffinOfMonster[def.Id]
		if coffinId then
			return CoffinData.get(coffinId).Name
		end
		return def.Exclusive or "Exclusif"
	end

	local function refresh()
		local state = ctx.state
		if not state then
			return
		end
		local discovered = 0
		for _ in pairs(state.Index or {}) do
			discovered += 1
		end
		local total = #MonsterData.List
		header.Text = string.format("📖 %d / %d monstres découverts  ·  Bonus : +%d%% coins", discovered, total, math.floor(discovered * Config.Income.IndexBonusPerMonster * 100 + 0.5))
		UI.clear(grid)
		for index, def in ipairs(MonsterData.List) do
			local known = state.Index and state.Index[def.Id]
			local r, g, b = Rarity.color(def.Rarity)
			local rarityColor = Color3.fromRGB(r, g, b)
			local card = UI.new("Frame", { BackgroundColor3 = known and UI.Colors.Panel2 or Color3.fromRGB(20, 16, 34), LayoutOrder = index, ZIndex = 23, Parent = grid }, { UI.corner(10), UI.stroke(known and rarityColor or Color3.fromRGB(60, 55, 80), 2, 0.2), UI.padding(8, 6) })
			local face = UI.new("Frame", { Size = UDim2.fromOffset(32, 32), BackgroundColor3 = known and Color3.fromRGB(def.Visual.Color[1], def.Visual.Color[2], def.Visual.Color[3]) or Color3.fromRGB(40, 35, 60), ZIndex = 24, Parent = card }, { UI.corner(16) })
			UI.label({ Text = known and "👀" or "❔", TextSize = 16, ZIndex = 25, Parent = face })
			UI.label({ Text = known and def.Name or "???", Font = UI.Font, TextSize = 14, TextScaled = true, Size = UDim2.new(1, -38, 0, 20), Position = UDim2.new(0, 38, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = known and UI.Colors.Text or UI.Colors.Muted, ZIndex = 24, Parent = card })
			UI.label({ Text = Rarity.label(def.Rarity), TextSize = 12, Size = UDim2.new(1, -38, 0, 16), Position = UDim2.new(0, 38, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rarityColor, ZIndex = 24, Parent = card })
			UI.label({ Text = "⚡ " .. Economy.format(def.Power) .. "/s", TextSize = 12, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 42), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Green, ZIndex = 24, Parent = card })
			UI.label({ Text = "📦 " .. sourceOf(def), TextSize = 11, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 60), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = UI.Colors.Muted, ZIndex = 24, Parent = card })
		end
	end

	window.OnOpen = refresh
	ctx.onState(function()
		if window.Frame.Visible then
			refresh()
		end
	end)
end

return IndexController
