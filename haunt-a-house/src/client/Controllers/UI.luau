--!nonstrict
-- Bibliotheque d'interface : styles, fenetres, boutons, listes, notifications.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local UI = {}

UI.Colors = {
	Bg = Color3.fromRGB(24, 18, 44),
	Panel = Color3.fromRGB(36, 28, 62),
	Panel2 = Color3.fromRGB(48, 38, 80),
	Header = Color3.fromRGB(70, 40, 130),
	Accent = Color3.fromRGB(255, 140, 30),
	Accent2 = Color3.fromRGB(155, 92, 255),
	Green = Color3.fromRGB(94, 224, 122),
	Red = Color3.fromRGB(255, 92, 92),
	Gold = Color3.fromRGB(255, 209, 102),
	Blue = Color3.fromRGB(80, 160, 255),
	Text = Color3.fromRGB(244, 240, 255),
	Muted = Color3.fromRGB(184, 176, 208),
	Robux = Color3.fromRGB(0, 176, 111),
}

UI.Font = Enum.Font.FredokaOne
UI.FontBody = Enum.Font.GothamBold
UI.IsTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local screenGui = nil
local windows = {}
local currentWindow = nil
local toastContainer = nil
local modalLayer = nil

function UI.new(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function UI.corner(radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function UI.stroke(color, thickness, transparency)
	return UI.new("UIStroke", { Color = color or Color3.fromRGB(0, 0, 0), Thickness = thickness or 2, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function UI.padding(px, py)
	py = py or px
	return UI.new("UIPadding", { PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px), PaddingTop = UDim.new(0, py), PaddingBottom = UDim.new(0, py) })
end

function UI.gradient(c1, c2, rotation)
	return UI.new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 90 })
end

function UI.label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = UI.FontBody,
		TextColor3 = UI.Colors.Text,
		TextScaled = false,
		TextSize = 16,
		TextWrapped = true,
		RichText = true,
		Size = UDim2.fromScale(1, 1),
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	return UI.new("TextLabel", defaults)
end

function UI.tween(instance, props, duration, style)
	local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- Bouton stylise. props : Text, Color, Size, Position, Parent, TextSize, OnClick
-- L'etat (couleur de base, actif) est stocke dans des attributs de l'instance.
function UI.button(props)
	local color = props.Color or UI.Colors.Accent
	local textColor = props.TextColor or Color3.fromRGB(255, 255, 255)
	local button = UI.new("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 44),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = color,
		Text = props.Text or "",
		Font = UI.Font,
		TextColor3 = textColor,
		TextScaled = props.TextScaled ~= false,
		TextSize = props.TextSize or 18,
		AutoButtonColor = false,
		LayoutOrder = props.LayoutOrder or 0,
		RichText = true,
		ZIndex = props.ZIndex or 1,
	}, {
		UI.corner(props.Radius or 12),
		UI.stroke(Color3.fromRGB(0, 0, 0), 2, 0.6),
		UI.new("UITextSizeConstraint", { MaxTextSize = props.MaxTextSize or 22, MinTextSize = 10 }),
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})
	UI.gradient(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190), 90).Parent = button
	button:SetAttribute("BaseColor", color)
	button:SetAttribute("BaseTextColor", textColor)
	button:SetAttribute("Enabled", true)
	button.MouseEnter:Connect(function()
		if button:GetAttribute("Enabled") then
			local base = button:GetAttribute("BaseColor")
			UI.tween(button, { BackgroundColor3 = base:Lerp(Color3.fromRGB(255, 255, 255), 0.15) }, 0.1)
		end
	end)
	button.MouseLeave:Connect(function()
		if button:GetAttribute("Enabled") then
			UI.tween(button, { BackgroundColor3 = button:GetAttribute("BaseColor") }, 0.1)
		end
	end)
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Enabled") then
			UI.tween(button, { TextTransparency = 0.35 }, 0.06)
		end
	end)
	button.MouseButton1Up:Connect(function()
		UI.tween(button, { TextTransparency = 0 }, 0.1)
	end)
	if props.OnClick then
		button.MouseButton1Click:Connect(function()
			if button:GetAttribute("Enabled") then
				props.OnClick(button)
			end
		end)
	end
	if props.Parent then
		button.Parent = props.Parent
	end
	return button
end

-- Active ou desactive un bouton cree par UI.button
function UI.setEnabled(button, enabled)
	button:SetAttribute("Enabled", enabled == true)
	button.Active = enabled == true
	if enabled then
		button.BackgroundColor3 = button:GetAttribute("BaseColor") or UI.Colors.Accent
		button.TextColor3 = button:GetAttribute("BaseTextColor") or Color3.fromRGB(255, 255, 255)
	else
		button.BackgroundColor3 = Color3.fromRGB(90, 85, 110)
		button.TextColor3 = Color3.fromRGB(190, 185, 205)
	end
end

function UI.setButtonColor(button, color)
	button:SetAttribute("BaseColor", color)
	if button:GetAttribute("Enabled") then
		button.BackgroundColor3 = color
	end
end

function UI.screen()
	return screenGui
end

function UI.init(playerGui)
	screenGui = UI.new("ScreenGui", {
		Name = "HauntAHouseUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
		Parent = playerGui,
	})
	modalLayer = UI.new("Frame", { Name = "Modals", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50, Parent = screenGui })
	toastContainer = UI.new("Frame", {
		Name = "Toasts",
		Size = UDim2.new(0.5, 0, 0, 200),
		Position = UDim2.new(0.5, 0, 1, -30),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		ZIndex = 90,
		Parent = screenGui,
	}, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 200) }),
	})
	return screenGui
end

-- Fenetre modale centrale. Retourne { Frame, Body, Title }
function UI.window(name, title, options)
	options = options or {}
	local frame = UI.new("Frame", {
		Name = name,
		Size = options.Size or UDim2.fromScale(0.68, 0.76),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UI.Colors.Bg,
		Visible = false,
		ZIndex = 20,
		Parent = screenGui,
	}, {
		UI.corner(18),
		UI.stroke(UI.Colors.Accent2, 3, 0.2),
		UI.new("UISizeConstraint", { MaxSize = options.MaxSize or Vector2.new(980, 640), MinSize = Vector2.new(300, 240) }),
	})
	local header = UI.new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = UI.Colors.Header, ZIndex = 21, Parent = frame }, { UI.corner(18) })
	UI.new("Frame", { Name = "HeaderFix", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BackgroundColor3 = UI.Colors.Header, BorderSizePixel = 0, ZIndex = 21, Parent = header })
	local titleLabel = UI.label({ Name = "Title", Text = title, Font = UI.Font, TextSize = 28, TextScaled = true, Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 60, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = header })
	UI.new("UITextSizeConstraint", { MaxTextSize = 30, MinTextSize = 14, Parent = titleLabel })
	if options.Icon then
		UI.label({ Name = "Icon", Text = options.Icon, TextSize = 30, TextScaled = true, Size = UDim2.new(0, 44, 1, 0), Position = UDim2.new(0, 12, 0, 0), ZIndex = 22, Parent = header })
	end
	local close = UI.button({
		Name = "Close",
		Text = "✕",
		Color = UI.Colors.Red,
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -46, 0, 6),
		ZIndex = 23,
		Parent = header,
		OnClick = function()
			UI.close(name)
		end,
	})
	close.TextScaled = true
	local body = UI.new("Frame", { Name = "Body", Size = UDim2.new(1, -20, 1, -64), Position = UDim2.new(0, 10, 0, 58), BackgroundTransparency = 1, ZIndex = 21, Parent = frame })
	local window = { Frame = frame, Body = body, Title = titleLabel, Name = name, OnOpen = nil, OnClose = nil }
	windows[name] = window
	return window
end

function UI.open(name, context)
	local window = windows[name]
	if not window then
		return
	end
	if currentWindow and currentWindow ~= window then
		UI.close(currentWindow.Name)
	end
	currentWindow = window
	window.Frame.Visible = true
	local target = window.Frame.Size
	window.Frame.Size = UDim2.new(target.X.Scale * 0.9, target.X.Offset * 0.9, target.Y.Scale * 0.9, target.Y.Offset * 0.9)
	UI.tween(window.Frame, { Size = target }, 0.18, Enum.EasingStyle.Back)
	if window.OnOpen then
		task.spawn(window.OnOpen, context)
	end
end

function UI.close(name)
	local window = windows[name]
	if not window then
		return
	end
	window.Frame.Visible = false
	if currentWindow == window then
		currentWindow = nil
	end
	if window.OnClose then
		task.spawn(window.OnClose)
	end
end

function UI.toggle(name, context)
	local window = windows[name]
	if window and window.Frame.Visible then
		UI.close(name)
	else
		UI.open(name, context)
	end
end

function UI.isOpen(name)
	local window = windows[name]
	return window ~= nil and window.Frame.Visible
end

function UI.closeAll()
	if currentWindow then
		UI.close(currentWindow.Name)
	end
end

-- Onglets : tabs = { { Key, Text } } ; onSelect(key)
function UI.tabs(parent, tabs, onSelect)
	local bar = UI.new("Frame", { Name = "Tabs", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 22, Parent = parent }, {
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local buttons = {}
	local selected = nil
	local function select(key)
		selected = key
		for tabKey, button in pairs(buttons) do
			UI.setButtonColor(button, tabKey == key and UI.Colors.Accent or UI.Colors.Panel2)
		end
		onSelect(key)
	end
	for index, tab in ipairs(tabs) do
		local button = UI.button({
			Name = tab.Key,
			Text = tab.Text,
			Color = UI.Colors.Panel2,
			Size = UDim2.new(1 / #tabs, -6, 1, 0),
			LayoutOrder = index,
			ZIndex = 23,
			Radius = 10,
			Parent = bar,
			OnClick = function()
				select(tab.Key)
			end,
		})
		buttons[tab.Key] = button
	end
	return { Bar = bar, Select = select, Selected = function() return selected end, Buttons = buttons }
end

-- Liste defilante verticale avec disposition automatique
function UI.scroll(parent, options)
	options = options or {}
	local scroll = UI.new("ScrollingFrame", {
		Name = options.Name or "Scroll",
		Size = options.Size or UDim2.fromScale(1, 1),
		Position = options.Position or UDim2.new(),
		BackgroundColor3 = options.Background or UI.Colors.Panel,
		BackgroundTransparency = options.Background and 0 or 0.2,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UI.Colors.Accent2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = options.ZIndex or 22,
		Parent = parent,
	}, { UI.corner(12), UI.padding(8) })
	if options.Grid then
		UI.new("UIGridLayout", { CellSize = options.CellSize or UDim2.fromOffset(150, 150), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = scroll })
	else
		UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = scroll })
	end
	return scroll
end

function UI.clear(container, keepClass)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIBase") and not (keepClass and child:IsA(keepClass)) then
			child:Destroy()
		end
	end
end

-- Barre de progression. Retourne { Frame, Set = function(fraction, text) }
function UI.progress(parent, color, size, position)
	local frame = UI.new("Frame", { Name = "Progress", Size = size or UDim2.new(1, 0, 0, 24), Position = position or UDim2.new(), BackgroundColor3 = Color3.fromRGB(20, 15, 35), ZIndex = 23, Parent = parent }, { UI.corner(12), UI.stroke(Color3.fromRGB(0, 0, 0), 1, 0.5) })
	local fill = UI.new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = color or UI.Colors.Green, ZIndex = 24, Parent = frame }, { UI.corner(12) })
	local text = UI.label({ Name = "Text", Text = "", Font = UI.Font, TextSize = 16, TextScaled = true, ZIndex = 25, Parent = frame })
	UI.new("UITextSizeConstraint", { MaxTextSize = 18, Parent = text })
	local bar = { Frame = frame }
	function bar.Set(fraction, label)
		fraction = math.clamp(fraction or 0, 0, 1)
		UI.tween(fill, { Size = UDim2.fromScale(fraction, 1) }, 0.2)
		text.Text = label or ""
	end
	return bar
end

-- Notifications (toasts)
local TOAST_COLORS = { info = Color3.fromRGB(70, 60, 120), success = Color3.fromRGB(40, 130, 80), error = Color3.fromRGB(160, 50, 60), rare = Color3.fromRGB(190, 120, 20), boss = Color3.fromRGB(150, 40, 60), luck = Color3.fromRGB(40, 130, 60), shop = Color3.fromRGB(0, 120, 90), rebirth = Color3.fromRGB(110, 60, 190) }

function UI.toast(text, kind, duration)
	if not toastContainer then
		return
	end
	local color = TOAST_COLORS[kind or "info"] or TOAST_COLORS.info
	local frame = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.1,
		ZIndex = 91,
		LayoutOrder = math.floor(os.clock() * 1000),
		Parent = toastContainer,
	}, { UI.corner(10), UI.stroke(Color3.fromRGB(0, 0, 0), 1, 0.5), UI.padding(12, 8) })
	local label = UI.label({ Text = text, Font = UI.FontBody, TextSize = 16, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 92, Parent = frame })
	label.TextXAlignment = Enum.TextXAlignment.Center
	frame.BackgroundTransparency = 1
	label.TextTransparency = 1
	UI.tween(frame, { BackgroundTransparency = 0.1 }, 0.2)
	UI.tween(label, { TextTransparency = 0 }, 0.2)
	task.delay(duration or 4, function()
		UI.tween(frame, { BackgroundTransparency = 1 }, 0.3)
		UI.tween(label, { TextTransparency = 1 }, 0.3)
		task.wait(0.35)
		frame:Destroy()
	end)
	local children = toastContainer:GetChildren()
	local count = 0
	for _, child in ipairs(children) do
		if child:IsA("Frame") then
			count += 1
		end
	end
	if count > 5 then
		for _, child in ipairs(children) do
			if child:IsA("Frame") then
				child:Destroy()
				break
			end
		end
	end
end

-- Boite de confirmation
function UI.confirm(title, text, onYes, yesText)
	local overlay = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, ZIndex = 60, Parent = modalLayer })
	local box = UI.new("Frame", { Size = UDim2.fromOffset(380, 220), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.Colors.Panel, ZIndex = 61, Parent = overlay }, { UI.corner(16), UI.stroke(UI.Colors.Accent, 3), UI.padding(16) })
	UI.label({ Text = title, Font = UI.Font, TextSize = 26, Size = UDim2.new(1, 0, 0, 40), ZIndex = 62, Parent = box })
	UI.label({ Text = text, TextSize = 16, Size = UDim2.new(1, 0, 0, 90), Position = UDim2.new(0, 0, 0, 44), ZIndex = 62, Parent = box })
	UI.button({ Text = "Annuler", Color = Color3.fromRGB(90, 85, 110), Size = UDim2.new(0.48, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44), ZIndex = 62, Parent = box, OnClick = function()
		overlay:Destroy()
	end })
	UI.button({ Text = yesText or "Confirmer", Color = UI.Colors.Green, Size = UDim2.new(0.48, 0, 0, 44), Position = UDim2.new(0.52, 0, 1, -44), ZIndex = 62, Parent = box, OnClick = function()
		overlay:Destroy()
		onYes()
	end })
	return overlay
end

function UI.modalLayer()
	return modalLayer
end

-- Carte d'article generique (fond, titre, description). Retourne le frame.
function UI.card(parent, options)
	local frame = UI.new("Frame", {
		Name = options.Name or "Card",
		Size = options.Size or UDim2.new(1, 0, 0, 96),
		BackgroundColor3 = options.Color or UI.Colors.Panel2,
		LayoutOrder = options.LayoutOrder or 0,
		ZIndex = options.ZIndex or 23,
		Parent = parent,
	}, { UI.corner(12), UI.stroke(options.Stroke or Color3.fromRGB(0, 0, 0), 2, 0.5), UI.padding(10, 8) })
	return frame
end

function UI.safeInsetTop()
	local inset = GuiService:GetGuiInset()
	return inset.Y
end

return UI
