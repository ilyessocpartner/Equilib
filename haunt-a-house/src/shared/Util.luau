--!nonstrict
-- Petits utilitaires partages.
local HttpService = game:GetService("HttpService")

local Util = {}

function Util.deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = Util.deepCopy(v)
	end
	return copy
end

function Util.uid()
	return HttpService:GenerateGUID(false)
end

function Util.now()
	return os.time()
end

function Util.isFinite(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function Util.color(rgb)
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Reessaie une fonction avec attente exponentielle. Retourne ok, resultat/erreur.
function Util.retry(attempts, baseDelay, fn, ...)
	local lastError
	for attempt = 1, attempts do
		local ok, result = pcall(fn, ...)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < attempts then
			task.wait(baseDelay * (2 ^ (attempt - 1)))
		end
	end
	return false, lastError
end

-- Cree une Part avec des proprietes en une ligne.
function Util.part(props)
	local className = props.ClassName or "Part"
	local part = Instance.new(className)
	part.Anchored = true
	part.CanCollide = props.CanCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape and className == "Part" then
		part.Shape = Enum.PartType[props.Shape]
	end
	part.Size = props.Size or Vector3.new(1, 1, 1)
	part.CFrame = props.CFrame or CFrame.new()
	if props.Color then
		part.Color = typeof(props.Color) == "Color3" and props.Color or Util.color(props.Color)
	end
	part.Material = Enum.Material[props.Material or "SmoothPlastic"]
	part.Transparency = props.Transparency or 0
	part.Name = props.Name or className
	part.CastShadow = props.CastShadow ~= false
	if props.Parent then
		part.Parent = props.Parent
	end
	return part
end

function Util.weld(a, b)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = a
	weld.Part1 = b
	weld.Parent = a
	return weld
end

function Util.clamp(n, lo, hi)
	return math.max(lo, math.min(hi, n))
end

function Util.round(n)
	return math.floor(n + 0.5)
end

return Util
