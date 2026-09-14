--!nonstrict
-- Rebirth : progression, benefices et confirmation.
local RebirthController = {}

function RebirthController.init(ctx)
	local UI = ctx.UI
	local Economy = ctx.Economy
	local Config = ctx.Config
	local CoffinData = ctx.CoffinData

	local window = UI.window("Rebirth", "Autel de Rebirth", { Icon = "♻️", Size = UDim2.fromScale(0.55, 0.7), MaxSize = Vector2.new(700, 560) })
	local body = window.Body
	local current = UI.label({ Text = "", Font = UI.Font, TextSize = 24, TextScaled = true, Size = UDim2.new(1, 0, 0, 34), ZIndex = 23, Parent = body })
	UI.new("UITextSizeConstraint", { MaxTextSize = 26, Parent = current })
	local benefits = UI.label({ Text = "", TextSize = 16, Size = UDim2.new(1, 0, 0, 150), Position = UDim2.new(0, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 23, Parent = body })
	local bar = UI.progress(body, UI.Colors.Accent2, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 200))
	local rebirthButton = UI.button({ Text = "♻️ REBIRTH", Color = Color3.fromRGB(110, 60, 190), Size = UDim2.new(1, 0, 0, 54), Position = UDim2.new(0, 0, 0, 244), ZIndex = 24, MaxTextSize = 26, Parent = body, OnClick = function()
		UI.confirm("Faire un rebirth ?", "Tes coins et tes monstres issus des cercueils seront réinitialisés. Tu gardes : monstres exclusifs et Cauchemar, salles achetées, bestiaire, boosts et passes. Tu gagnes un multiplicateur permanent, une salle et de nouveaux cercueils.", function()
			ctx.request("Rebirth")
		end, "Rebirth !")
	end })
	local instant = UI.button({ Text = "⚡ Rebirth instantané  R$ " .. ctx.MonetizationIds.Products.InstantRebirth.Price, Color = UI.Colors.Robux, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 0, 306), ZIndex = 24, MaxTextSize = 18, Parent = body, OnClick = function()
		ctx.prompt("Product", "InstantRebirth")
	end })
	UI.setEnabled(instant, ctx.MonetizationIds.Products.InstantRebirth.Id > 0)

	local function nextUnlock(rebirths)
		local unlocks = {}
		for _, coffin in ipairs(CoffinData.List) do
			if coffin.RebirthRequired == rebirths + 1 then
				table.insert(unlocks, coffin.Name)
			end
		end
		return unlocks
	end

	local function refresh()
		local rebirths = tonumber(ctx.attr("Rebirths")) or 0
		local coins = tonumber(ctx.attr("Coins")) or 0
		local cost = Economy.rebirthCost(rebirths)
		current.Text = "Rebirth actuel : " .. rebirths .. "  (gains x" .. Economy.rebirthMultiplier(rebirths) .. ")"
		local lines = {
			"✅ Multiplicateur : x" .. Economy.rebirthMultiplier(rebirths) .. "  →  <b>x" .. Economy.rebirthMultiplier(rebirths + 1) .. "</b>",
		}
		if rebirths < Config.Plot.MaxRebirthRooms then
			table.insert(lines, "✅ +1 salle permanente dans ton manoir")
		end
		local unlocks = nextUnlock(rebirths)
		if #unlocks > 0 then
			table.insert(lines, "✅ Débloque : <b>" .. table.concat(unlocks, ", ") .. "</b>")
		else
			local futureNames = {}
			for _, coffin in ipairs(CoffinData.List) do
				if coffin.RebirthRequired > rebirths + 1 then
					table.insert(futureNames, coffin.Name .. " (rebirth " .. coffin.RebirthRequired .. ")")
				end
			end
			if #futureNames > 0 then
				table.insert(lines, "🔒 Bientôt : " .. table.concat(futureNames, ", "))
			end
		end
		table.insert(lines, "✅ Les bundles de coins de la boutique deviennent plus gros")
		table.insert(lines, "❌ Coins remis à 0 et monstres des cercueils retirés (les exclusifs restent)")
		benefits.Text = table.concat(lines, "\n")
		bar.Set(coins / cost, Economy.format(coins) .. " / " .. Economy.format(cost) .. " coins")
		UI.setEnabled(rebirthButton, coins >= cost)
		rebirthButton.Text = coins >= cost and "♻️ REBIRTH MAINTENANT !" or ("♻️ REBIRTH (" .. Economy.format(cost) .. " coins)")
	end

	window.OnOpen = refresh
	ctx.onAttr("Coins", function()
		if window.Frame.Visible then
			refresh()
		end
	end)
	ctx.onAttr("Rebirths", function()
		if window.Frame.Visible then
			refresh()
		end
	end)
end

return RebirthController
