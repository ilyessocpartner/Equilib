--!nonstrict
-- Construit le modele 3D d'un monstre a partir de sa recette visuelle (aucun asset externe).
-- Le modele a pour PrimaryPart "Root", place au niveau des pieds.
local Util = require(script.Parent.Util)
local Rarity = require(script.Parent.Rarity)

local MonsterBuilder = {}

local BODY_HEIGHT = 3

local function addPart(model, root, props)
	props.Parent = model
	props.CanCollide = false
	local part = Util.part(props)
	part.CanQuery = false
	part.CanTouch = false
	Util.weld(root, part)
	return part
end

local function bodyDimensions(visual)
	local s = visual.Scale or 1
	local h = BODY_HEIGHT * s
	if visual.Body == "Ball" then
		return Vector3.new(h, h, h), h
	elseif visual.Body == "Cylinder" then
		return Vector3.new(h, h * 0.85, h * 0.85), h
	elseif visual.Body == "Wedge" then
		return Vector3.new(h * 0.9, h, h * 0.9), h
	end
	return Vector3.new(h * 0.95, h, h * 0.8), h
end

local function buildBody(model, root, visual, origin)
	local size, height = bodyDimensions(visual)
	local center = origin * CFrame.new(0, height / 2, 0)
	local props = {
		Name = "Body",
		Size = size,
		CFrame = center,
		Color = visual.Color,
		Material = visual.Material,
		Transparency = visual.Transparency or 0,
	}
	if visual.Body == "Ball" then
		props.Shape = "Ball"
	elseif visual.Body == "Cylinder" then
		props.Shape = "Cylinder"
		props.CFrame = center * CFrame.Angles(0, 0, math.rad(90))
	elseif visual.Body == "Wedge" then
		props.ClassName = "WedgePart"
	end
	local body = addPart(model, root, props)
	local depth = (visual.Body == "Cylinder") and size.Y / 2 or size.Z / 2
	if visual.Body == "Ball" then
		depth = size.X / 2 * 0.92
	end
	return body, center, size, depth
end

local function buildEyes(model, root, visual, center, size, depth)
	local s = visual.Scale or 1
	local style = visual.Eyes or "dots"
	local accent = visual.Accent or { 255, 255, 255 }
	local y = size.Y * 0.15
	local spacing = size.X * 0.2
	local function eye(x, radius, color, material)
		return addPart(model, root, {
			Name = "Eye",
			Shape = "Ball",
			Size = Vector3.new(radius, radius, radius),
			CFrame = center * CFrame.new(x, y, -depth + radius * 0.35),
			Color = color,
			Material = material or "SmoothPlastic",
		})
	end
	if style == "cyclops" then
		eye(0, 1.1 * s, { 255, 255, 255 })
		eye(0, 0.5 * s, { 20, 20, 20 })
	elseif style == "glow" then
		eye(-spacing, 0.55 * s, accent, "Neon")
		eye(spacing, 0.55 * s, accent, "Neon")
	elseif style == "cute" then
		eye(-spacing, 0.85 * s, { 255, 255, 255 })
		eye(spacing, 0.85 * s, { 255, 255, 255 })
		eye(-spacing, 0.45 * s, { 20, 20, 30 })
		eye(spacing, 0.45 * s, { 20, 20, 30 })
	elseif style == "angry" then
		eye(-spacing, 0.6 * s, { 255, 255, 255 })
		eye(spacing, 0.6 * s, { 255, 255, 255 })
		eye(-spacing, 0.3 * s, { 20, 20, 20 })
		eye(spacing, 0.3 * s, { 20, 20, 20 })
		for _, side in ipairs({ -1, 1 }) do
			addPart(model, root, {
				Name = "Brow",
				Size = Vector3.new(0.9 * s, 0.18 * s, 0.2 * s),
				CFrame = center * CFrame.new(side * spacing, y + 0.5 * s, -depth + 0.1) * CFrame.Angles(0, 0, side * math.rad(-25)),
				Color = { 20, 20, 20 },
			})
		end
	else
		eye(-spacing, 0.4 * s, { 20, 20, 20 })
		eye(spacing, 0.4 * s, { 20, 20, 20 })
	end
end

local function buildMouth(model, root, visual, center, size, depth)
	local s = visual.Scale or 1
	local style = visual.Mouth or "smile"
	local y = -size.Y * 0.18
	if style == "none" then
		return
	end
	if style == "o" then
		addPart(model, root, {
			Name = "Mouth",
			Shape = "Cylinder",
			Size = Vector3.new(0.15, 0.6 * s, 0.6 * s),
			CFrame = center * CFrame.new(0, y, -depth + 0.05) * CFrame.Angles(0, math.rad(90), 0),
			Color = { 15, 15, 20 },
		})
		return
	end
	if style == "zigzag" then
		for i = -1, 1 do
			addPart(model, root, {
				Name = "Mouth",
				Size = Vector3.new(0.45 * s, 0.14 * s, 0.12),
				CFrame = center * CFrame.new(i * 0.38 * s, y + (i % 2 == 0 and 0.1 or -0.1) * s, -depth + 0.06) * CFrame.Angles(0, 0, math.rad(i * 35)),
				Color = { 15, 15, 20 },
			})
		end
		return
	end
	addPart(model, root, {
		Name = "Mouth",
		Size = Vector3.new(1.1 * s, 0.16 * s, 0.12),
		CFrame = center * CFrame.new(0, y, -depth + 0.06),
		Color = (style == "smile" and visual.Accent and visual.Accent[1] == 255 and visual.Accent[2] == 40) and visual.Accent or { 15, 15, 20 },
	})
	if style == "fangs" then
		for _, side in ipairs({ -1, 1 }) do
			addPart(model, root, {
				Name = "Fang",
				ClassName = "WedgePart",
				Size = Vector3.new(0.25 * s, 0.35 * s, 0.2 * s),
				CFrame = center * CFrame.new(side * 0.35 * s, y - 0.22 * s, -depth + 0.08) * CFrame.Angles(math.rad(180), 0, 0),
				Color = { 255, 255, 255 },
			})
		end
	end
end

local function buildHat(model, root, visual, center, size)
	local s = visual.Scale or 1
	local style = visual.Hat or "none"
	local accent = visual.Accent or { 255, 255, 255 }
	local top = size.Y / 2
	if style == "none" then
		return
	end
	if style == "witch" then
		addPart(model, root, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(0.2, 2.6 * s, 2.6 * s), CFrame = center * CFrame.new(0, top, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 25, 20, 35 } })
		addPart(model, root, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(1.0 * s, 1.5 * s, 1.5 * s), CFrame = center * CFrame.new(0, top + 0.55 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 25, 20, 35 } })
		addPart(model, root, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(0.9 * s, 0.9 * s, 0.9 * s), CFrame = center * CFrame.new(0, top + 1.45 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 25, 20, 35 } })
		addPart(model, root, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(0.8 * s, 0.4 * s, 0.4 * s), CFrame = center * CFrame.new(0.1, top + 2.2 * s, 0) * CFrame.Angles(0, 0, math.rad(75)), Color = { 25, 20, 35 } })
		addPart(model, root, { Name = "Band", Shape = "Cylinder", Size = Vector3.new(0.25 * s, 1.6 * s, 1.6 * s), CFrame = center * CFrame.new(0, top + 0.2 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = accent })
	elseif style == "top" then
		addPart(model, root, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(0.2, 2.2 * s, 2.2 * s), CFrame = center * CFrame.new(0, top, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = accent })
		addPart(model, root, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(1.4 * s, 1.5 * s, 1.5 * s), CFrame = center * CFrame.new(0, top + 0.75 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = accent })
	elseif style == "horns" then
		for _, side in ipairs({ -1, 1 }) do
			addPart(model, root, { Name = "Horn", ClassName = "WedgePart", Size = Vector3.new(0.4 * s, 1.1 * s, 0.6 * s), CFrame = center * CFrame.new(side * size.X * 0.3, top + 0.4 * s, 0) * CFrame.Angles(0, 0, side * math.rad(-25)), Color = accent })
		end
	elseif style == "halo" then
		addPart(model, root, { Name = "Halo", Shape = "Cylinder", Size = Vector3.new(0.12, 2.0 * s, 2.0 * s), CFrame = center * CFrame.new(0, top + 0.9 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = accent, Material = "Neon", Transparency = 0.15 })
	elseif style == "crown" then
		addPart(model, root, { Name = "Crown", Shape = "Cylinder", Size = Vector3.new(0.5 * s, 1.6 * s, 1.6 * s), CFrame = center * CFrame.new(0, top + 0.2 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 255, 200, 40 }, Material = "Metal" })
		for i = 0, 3 do
			local angle = i * math.pi / 2
			addPart(model, root, { Name = "Spike", Size = Vector3.new(0.3 * s, 0.6 * s, 0.3 * s), CFrame = center * CFrame.new(math.cos(angle) * 0.65 * s, top + 0.7 * s, math.sin(angle) * 0.65 * s), Color = { 255, 200, 40 }, Material = "Metal" })
		end
	elseif style == "bolt" then
		for _, side in ipairs({ -1, 1 }) do
			addPart(model, root, { Name = "Bolt", Shape = "Cylinder", Size = Vector3.new(0.7 * s, 0.4 * s, 0.4 * s), CFrame = center * CFrame.new(side * (size.X / 2 + 0.2 * s), 0, 0), Color = accent, Material = "Metal" })
		end
	elseif style == "bandage" then
		for i = -1, 1 do
			addPart(model, root, { Name = "Bandage", Size = Vector3.new(size.X * 1.02, 0.3 * s, size.Z * 1.02), CFrame = center * CFrame.new(0, i * 0.7 * s, 0) * CFrame.Angles(0, 0, math.rad(i * 12)), Color = accent, Material = "Fabric" })
		end
	elseif style == "stem" then
		addPart(model, root, { Name = "Stem", Shape = "Cylinder", Size = Vector3.new(0.8 * s, 0.4 * s, 0.4 * s), CFrame = center * CFrame.new(0, top + 0.3 * s, 0) * CFrame.Angles(0, 0, math.rad(80)), Color = accent })
	elseif style == "hood" then
		addPart(model, root, { Name = "Hood", ClassName = "WedgePart", Size = Vector3.new(size.X * 1.15, 1.6 * s, size.Z * 1.1), CFrame = center * CFrame.new(0, top + 0.5 * s, 0.2 * s) * CFrame.Angles(0, math.rad(180), 0), Color = visual.Color, Material = visual.Material })
	elseif style == "ears" then
		for _, side in ipairs({ -1, 1 }) do
			addPart(model, root, { Name = "Ear", ClassName = "WedgePart", Size = Vector3.new(0.6 * s, 0.9 * s, 0.5 * s), CFrame = center * CFrame.new(side * size.X * 0.32, top + 0.35 * s, 0) * CFrame.Angles(0, math.rad(90), 0), Color = visual.Color, Material = visual.Material })
		end
	elseif style == "helm" then
		addPart(model, root, { Name = "Helm", Size = Vector3.new(size.X * 1.12, 0.8 * s, size.Z * 1.12), CFrame = center * CFrame.new(0, top - 0.1 * s, 0), Color = { 150, 155, 170 }, Material = "Metal" })
		addPart(model, root, { Name = "Plume", Size = Vector3.new(0.2 * s, 0.9 * s, 0.9 * s), CFrame = center * CFrame.new(0, top + 0.6 * s, 0), Color = accent })
	elseif style == "jester" then
		for i = -1, 1 do
			addPart(model, root, { Name = "Jester", Shape = "Cylinder", Size = Vector3.new(1.2 * s, 0.35 * s, 0.35 * s), CFrame = center * CFrame.new(i * 0.6 * s, top + 0.5 * s, 0) * CFrame.Angles(0, 0, math.rad(90 - i * 30)), Color = accent })
			addPart(model, root, { Name = "Bell", Shape = "Ball", Size = Vector3.new(0.35 * s, 0.35 * s, 0.35 * s), CFrame = center * CFrame.new(i * 0.95 * s, top + 1.05 * s, 0), Color = { 255, 220, 60 }, Material = "Metal" })
		end
	end
end

local AURA_COLORS = {
	fire = { { 255, 140, 30 }, { 255, 40, 20 } },
	ice = { { 200, 240, 255 }, { 120, 180, 255 } },
	void = { { 140, 60, 255 }, { 30, 0, 60 } },
	sparkle = { { 255, 255, 220 }, { 255, 230, 120 } },
}

local function buildAura(model, root, visual, body)
	local style = visual.Aura or "none"
	if style == "none" then
		return
	end
	local accent = Util.color(visual.Accent or { 255, 255, 255 })
	if style == "glow" then
		local light = Instance.new("PointLight")
		light.Color = accent
		light.Brightness = 1.5
		light.Range = 10
		light.Parent = body
		return
	end
	local colors = AURA_COLORS[style]
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Util.color(colors[1]), Util.color(colors[2]))
	emitter.LightEmission = 0.8
	emitter.Rate = style == "sparkle" and 6 or 12
	emitter.Lifetime = NumberRange.new(0.8, 1.6)
	emitter.Speed = NumberRange.new(1, 2.5)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.SpreadAngle = Vector2.new(40, 40)
	emitter.Acceleration = Vector3.new(0, style == "void" and -1 or 2, 0)
	emitter.Parent = body
	local light = Instance.new("PointLight")
	light.Color = Util.color(colors[1])
	light.Brightness = 1.2
	light.Range = 9
	light.Parent = body
end

-- Construit et retourne le Model (non parente). origin : CFrame des pieds.
function MonsterBuilder.build(def, origin)
	origin = origin or CFrame.new()
	local visual = def.Visual
	local model = Instance.new("Model")
	model.Name = def.Name
	model:SetAttribute("MonsterId", def.Id)
	model:SetAttribute("Rarity", def.Rarity)

	local root = Util.part({
		Name = "Root",
		Size = Vector3.new(1, 1, 1),
		CFrame = origin,
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	root.CanQuery = false
	root.CanTouch = false
	model.PrimaryPart = root

	local body, center, size, depth = buildBody(model, root, visual, origin)
	buildEyes(model, root, visual, center, size, depth)
	buildMouth(model, root, visual, center, size, depth)
	buildHat(model, root, visual, center, size)
	buildAura(model, root, visual, body)

	return model
end

-- Hauteur totale approximative (pour placer les etiquettes)
function MonsterBuilder.height(def)
	local _, h = bodyDimensions(def.Visual)
	return h + 2
end

function MonsterBuilder.rarityColor(def)
	local r, g, b = Rarity.color(def.Rarity)
	return Color3.fromRGB(r, g, b)
end

return MonsterBuilder
