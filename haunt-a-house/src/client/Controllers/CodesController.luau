--!nonstrict
-- Codes promotionnels.
local CodesController = {}

function CodesController.init(ctx)
	local UI = ctx.UI
	local window = UI.window("Codes", "Codes", { Icon = "🔑", Size = UDim2.fromScale(0.42, 0.42), MaxSize = Vector2.new(520, 320) })
	local body = window.Body
	UI.label({ Text = "Entre un code pour recevoir des coins ou des boosts. Suis les réseaux du jeu pour découvrir les nouveaux codes !", TextSize = 15, Size = UDim2.new(1, 0, 0, 60), TextColor3 = UI.Colors.Muted, ZIndex = 23, Parent = body })
	local box = UI.new("TextBox", { Size = UDim2.new(1, 0, 0, 48), Position = UDim2.new(0, 0, 0, 70), BackgroundColor3 = UI.Colors.Panel2, Text = "", PlaceholderText = "TAPE TON CODE ICI", PlaceholderColor3 = UI.Colors.Muted, TextColor3 = UI.Colors.Text, Font = UI.Font, TextSize = 22, ClearTextOnFocus = false, ZIndex = 23, Parent = body }, { UI.corner(10), UI.stroke(UI.Colors.Accent2, 2), UI.padding(10, 4) })
	local function submit()
		local code = box.Text
		if #code == 0 then
			return
		end
		local result = ctx.request("RedeemCode", { Code = code })
		if result.ok then
			box.Text = ""
		end
	end
	UI.button({ Text = "✅ Valider", Color = UI.Colors.Green, Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 0, 128), ZIndex = 24, Parent = body, OnClick = submit })
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end)
end

return CodesController
