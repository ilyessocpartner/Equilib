--!nonstrict
-- Crypte : liste des cercueils, probabilites affichees, ouverture et animation de resultat.
local CoffinController = {}

function CoffinController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local CoffinData = ctx.CoffinData
	local MonsterData = ctx.MonsterData
	local Rarity = ctx.Rarity
	local GachaMath = ctx.GachaMath
	local MonsterBuilder = ctx.MonsterBuilder

	local window = UI.window("Coffins", "La Crypte : cercueils", { Icon = "⚰️" })
	local body = window.Body
	local selected = "wooden"
	local busy = false

	local listFrame = UI.scroll(body, { Size = UDim2.new(0.36, -6, 1, 0) })
	local detail = UI.new("Frame", { Name = "Detail", Size = UDim2.new(0.64, -6, 1, 0), Position = UDim2.new(0.36, 6, 0, 0), BackgroundColor3 = UI.Colors.Panel, ZIndex = 22, Parent = body }, { UI.corner(12), UI.padding(12, 10) })
	local title = UI.label({ Text = "", Font = UI.Font, TextSize = 26, TextScaled = true, Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23, Parent = detail })
	UI.new("UITextSizeConstraint", { MaxTextSize = 28, Parent = title })
	local subtitle = UI.label({ Text = "", TextSize = 15, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = UI.Colors.Muted, ZIndex = 23, Parent = detail })
	local luckLabel = UI.label({ Text = "", TextSize = 14, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 76), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Green, ZIndex = 23, Parent = detail })
	local contents = UI.scroll(detail, { Size = UDim2.new(1, 0, 1, -170), Position = UDim2.new(0, 0, 0, 100), Background = UI.Colors.Bg })
	local buttonRow = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 56), Position = UDim2.new(0, 0, 1, -58), BackgroundTransparency = 1, ZIndex = 23, Parent = detail })
	local openOne = UI.button({ Text = "Ouvrir x1", Color = UI.Colors.Green, Size = UDim2.new(0.48, 0, 1, 0), ZIndex = 24, Parent = buttonRow })
	local openThree = UI.button({ Text = "Ouvrir x3", Color = UI.Colors.Accent2, Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0), ZIndex = 24, Parent = buttonRow })

	local function rarityText(def)
		local r, g, b = Rarity.color(def.Rarity)
		return string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, Rarity.label(def.Rarity))
	end

	local function coffinLocked(coffin)
		local rebirths = tonumber(ctx.attr("Rebirths")) or 0
		return rebirths < (coffin.RebirthRequired or 0)
	end

	local function nightmareCount()
		return tonumber(ctx.attr("NightmareCoffins")) or 0
	end

	local function buildList()
		UI.clear(listFrame)
		local order = 0
		for _, coffin in ipairs(CoffinData.List) do
			order += 1
			local locked = coffinLocked(coffin)
			local color = Color3.fromRGB(coffin.Color[1], coffin.Color[2], coffin.Color[3])
			local button = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = selected == coffin.Id and UI.Colors.Panel2 or UI.Colors.Bg, Text = "", AutoButtonColor = true, LayoutOrder = order, ZIndex = 23, Parent = listFrame }, { UI.corner(10), UI.stroke(selected == coffin.Id and UI.Colors.Accent or Color3.fromRGB(0, 0, 0), 2, 0.3), UI.padding(8, 6) })
			UI.new("Frame", { Size = UDim2.fromOffset(34, 48), BackgroundColor3 = color, ZIndex = 24, Parent = button }, { UI.corner(6), UI.stroke(Color3.fromRGB(0, 0, 0), 1, 0.4) })
			UI.label({ Text = coffin.Name, Font = UI.Font, TextSize = 16, Size = UDim2.new(1, -44, 0, 22), Position = UDim2.new(0, 44, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24, Parent = button })
			local info
			if coffin.EventOnly then
				info = "🎟️ " .. nightmareCount() .. " ticket(s)"
			elseif locked then
				info = "🔒 Rebirth " .. coffin.RebirthRequired
			else
				info = "🪙 " .. Economy.format(coffin.Cost)
			end
			UI.label({ Text = info, TextSize = 14, Size = UDim2.new(1, -44, 0, 20), Position = UDim2.new(0, 44, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = locked and UI.Colors.Red or UI.Colors.Gold, ZIndex = 24, Parent = button })
			button.MouseButton1Click:Connect(function()
				selected = coffin.Id
				buildList()
				CoffinController.refreshDetail()
			end)
		end
	end

	function CoffinController.refreshDetail()
		local coffin = CoffinData.get(selected)
		if not coffin then
			return
		end
		local luck = tonumber(ctx.attr("Luck")) or 1
		local locked = coffinLocked(coffin)
		title.Text = coffin.Name
		if coffin.EventOnly then
			subtitle.Text = "Non achetable. Gagne des tickets lors des raids de Minuit, au jour 7 de ta série quotidienne, dans le Passe Spooky et les récompenses de temps de jeu."
		elseif locked then
			subtitle.Text = "🔒 Se débloque au rebirth " .. coffin.RebirthRequired .. ". Continue à progresser !"
		else
			subtitle.Text = "Coût : " .. Economy.format(coffin.Cost) .. " coins. Les monstres obtenus sont placés automatiquement s'il reste une salle libre."
		end
		luckLabel.Text = luck > 1 and ("🍀 Chance actuelle : x" .. luck .. " (probabilités des raretés Rare et + multipliées)") or "🍀 Chance : x1 (les boosts et le pass Chance augmentent les raretés Rare et +)"
		UI.clear(contents)
		local entries = {}
		for _, item in ipairs(coffin.Contents) do
			local def = MonsterData.get(item.Id)
			table.insert(entries, { Id = item.Id, Weight = item.Weight, Rank = Rarity.rank(def.Rarity) })
		end
		local weighted = GachaMath.weighted(entries, luck)
		for index, entry in ipairs(weighted) do
			local def = MonsterData.get(entry.Id)
			local discovered = ctx.state and ctx.state.Index and ctx.state.Index[entry.Id]
			local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = UI.Colors.Panel2, LayoutOrder = index, ZIndex = 23, Parent = contents }, { UI.corner(8), UI.padding(8, 4) })
			UI.label({ Text = (discovered and "" or "❔ ") .. def.Name .. "  <font size=\"12\">" .. rarityText(def) .. "</font>", TextSize = 15, Size = UDim2.new(0.6, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24, Parent = row })
			UI.label({ Text = "⚡ " .. Economy.format(def.Power) .. "/s", TextSize = 14, Size = UDim2.new(0.2, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), TextColor3 = UI.Colors.Green, ZIndex = 24, Parent = row })
			UI.label({ Text = GachaMath.formatChance(entry.Chance), Font = UI.Font, TextSize = 15, Size = UDim2.new(0.2, 0, 1, 0), Position = UDim2.new(0.8, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.Colors.Gold, ZIndex = 24, Parent = row })
		end
		local hasTriple = ctx.ownsPass("TripleHatch")
		if coffin.EventOnly then
			openOne.Text = "Ouvrir x1 (1 ticket)"
			openThree.Text = hasTriple and "Ouvrir x3 (3 tickets)" or "🔒 x3 : pass Triple"
			UI.setEnabled(openOne, nightmareCount() >= 1)
		else
			openOne.Text = "Ouvrir x1 (" .. Economy.format(coffin.Cost) .. ")"
			openThree.Text = hasTriple and ("Ouvrir x3 (" .. Economy.format(coffin.Cost * 3) .. ")") or "🔒 x3 : pass Triple"
			UI.setEnabled(openOne, not locked)
		end
		UI.setEnabled(openThree, not locked)
	end

	-- Animation d'ouverture
	local function showResults(coffin, results)
		local overlay = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 70, Parent = UI.modalLayer() })
		local coffinFrame = UI.new("Frame", { Size = UDim2.fromOffset(120, 200), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(coffin.Color[1], coffin.Color[2], coffin.Color[3]), ZIndex = 71, Parent = overlay }, { UI.corner(14), UI.stroke(Color3.fromRGB(coffin.Accent[1], coffin.Accent[2], coffin.Accent[3]), 4) })
		UI.label({ Text = "⚰️", TextSize = 64, TextScaled = true, ZIndex = 72, Parent = coffinFrame })
		for i = 1, 6 do
			UI.tween(coffinFrame, { Rotation = (i % 2 == 0 and 8 or -8) }, 0.09)
			task.wait(0.1)
		end
		UI.tween(coffinFrame, { Rotation = 0, Size = UDim2.fromOffset(150, 240) }, 0.15)
		task.wait(0.2)
		coffinFrame:Destroy()
		local container = UI.new("Frame", { Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 71, Parent = overlay }, {
			UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 14) }),
		})
		for _, result in ipairs(results) do
			local def = MonsterData.get(result.Id)
			local r, g, b = Rarity.color(def.Rarity)
			local card = UI.new("Frame", { Size = UDim2.new(0.28, 0, 1, 0), BackgroundColor3 = UI.Colors.Panel, ZIndex = 72, Parent = container }, { UI.corner(16), UI.stroke(Color3.fromRGB(r, g, b), 4), UI.padding(10, 8), UI.new("UISizeConstraint", { MaxSize = Vector2.new(300, 420) }) })
			local viewport = UI.new("ViewportFrame", { Size = UDim2.new(1, 0, 0.55, 0), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 220), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-1, -1, -1), ZIndex = 73, Parent = card })
			local model = MonsterBuilder.build(def, CFrame.new())
			model.Parent = viewport
			local height = MonsterBuilder.height(def)
			local camera = Instance.new("Camera")
			camera.FieldOfView = 50
			camera.CFrame = CFrame.lookAt(Vector3.new(2.5, height * 0.55, -height * 1.8 - 2), Vector3.new(0, height * 0.45, 0))
			camera.Parent = viewport
			viewport.CurrentCamera = camera
			task.spawn(function()
				local t = 0
				while viewport.Parent do
					t += 0.03
					model:PivotTo(CFrame.new(0, math.sin(t * 3) * 0.15, 0) * CFrame.Angles(0, math.sin(t) * 0.5, 0))
					task.wait(0.03)
				end
			end)
			UI.label({ Text = def.Name, Font = UI.Font, TextSize = 22, TextScaled = true, Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, 0.56), ZIndex = 73, Parent = card })
			UI.label({ Text = rarityText(def) .. "  ⚡ " .. Economy.format(def.Power) .. "/s", TextSize = 16, TextScaled = true, Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, 0.68), ZIndex = 73, Parent = card })
			local status = result.New and "✨ NOUVEAU ! Ajouté au Bestiaire" or (result.Placed and "Placé dans une salle" or "Dans ton inventaire (salles pleines)")
			UI.label({ Text = status, TextSize = 14, TextScaled = true, Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, 0.8), TextColor3 = result.New and UI.Colors.Gold or UI.Colors.Muted, ZIndex = 73, Parent = card })
			card.Size = UDim2.new(0.28, 0, 0.9, 0)
			UI.tween(card, { Size = UDim2.new(0.28, 0, 1, 0) }, 0.2, Enum.EasingStyle.Back)
		end
		local buttons = UI.new("Frame", { Size = UDim2.fromOffset(420, 50), Position = UDim2.fromScale(0.5, 0.88), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 72, Parent = overlay })
		UI.button({ Text = "Continuer", Color = Color3.fromRGB(90, 85, 110), Size = UDim2.new(0.48, 0, 1, 0), ZIndex = 73, Parent = buttons, OnClick = function()
			overlay:Destroy()
		end })
		UI.button({ Text = "Ouvrir encore x" .. #results, Color = UI.Colors.Green, Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0), ZIndex = 73, Parent = buttons, OnClick = function()
			overlay:Destroy()
			CoffinController.open(coffin.Id, #results)
		end })
	end

	function CoffinController.open(coffinId, count)
		if busy then
			return
		end
		local coffin = CoffinData.get(coffinId)
		if not coffin then
			return
		end
		if count == 3 and not ctx.ownsPass("TripleHatch") then
			UI.toast("Le pass Triple Cercueil permet d'ouvrir 3 cercueils d'un coup !", "info")
			ctx.prompt("Pass", "TripleHatch")
			return
		end
		busy = true
		local result
		if coffin.EventOnly then
			result = ctx.request("OpenNightmare", { Count = count })
		else
			result = ctx.request("BuyCoffin", { CoffinId = coffinId, Count = count })
		end
		busy = false
		if result.ok and result.data and result.data.Results then
			task.spawn(showResults, coffin, result.data.Results)
		end
	end

	openOne.MouseButton1Click:Connect(function()
		CoffinController.open(selected, 1)
	end)
	openThree.MouseButton1Click:Connect(function()
		CoffinController.open(selected, 3)
	end)

	window.OnOpen = function(context)
		if context and context.Coffin then
			selected = context.Coffin
		end
		buildList()
		CoffinController.refreshDetail()
	end
	ctx.onState(function()
		if window.Frame.Visible then
			buildList()
			CoffinController.refreshDetail()
		end
	end)
	ctx.onAttr("Luck", function()
		if window.Frame.Visible then
			CoffinController.refreshDetail()
		end
	end)
	ctx.onAttr("NightmareCoffins", function()
		if window.Frame.Visible then
			buildList()
			CoffinController.refreshDetail()
		end
	end)
end

return CoffinController
