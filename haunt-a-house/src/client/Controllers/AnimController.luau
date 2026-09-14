--!nonstrict
-- Animations locales : flottement des monstres et du boss (aucun cout reseau).
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local AnimController = {}

function AnimController.init(ctx)
	local tracked = {} -- [model] = { Base = CFrame, Phase = number, Boss = bool }
	local function track(model, isBoss)
		if tracked[model] then
			return
		end
		local root = model.PrimaryPart or model:FindFirstChild("Root")
		if not root then
			task.delay(0.2, function()
				if model.Parent then
					track(model, isBoss)
				end
			end)
			return
		end
		tracked[model] = { Base = model:GetPivot(), Phase = math.random() * math.pi * 2, Boss = isBoss }
	end
	local function untrack(model)
		tracked[model] = nil
	end
	for _, model in ipairs(CollectionService:GetTagged("Monster")) do
		track(model, false)
	end
	for _, model in ipairs(CollectionService:GetTagged("Boss")) do
		track(model, true)
	end
	CollectionService:GetInstanceAddedSignal("Monster"):Connect(function(model)
		track(model, false)
	end)
	CollectionService:GetInstanceRemovedSignal("Monster"):Connect(untrack)
	CollectionService:GetInstanceAddedSignal("Boss"):Connect(function(model)
		track(model, true)
	end)
	CollectionService:GetInstanceRemovedSignal("Boss"):Connect(untrack)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		accumulator = 0
		local camera = workspace.CurrentCamera
		local cameraPosition = camera and camera.CFrame.Position or Vector3.new()
		local t = os.clock()
		for model, info in pairs(tracked) do
			if not model.Parent then
				tracked[model] = nil
			else
				local distance = (info.Base.Position - cameraPosition).Magnitude
				if distance < 160 then
					local offset
					if info.Boss then
						offset = CFrame.new(0, math.sin(t * 1.5 + info.Phase) * 0.6, 0) * CFrame.Angles(0, math.sin(t * 0.7) * 0.15, 0)
					else
						offset = CFrame.new(0, 0.25 + math.sin(t * 2.2 + info.Phase) * 0.25, 0) * CFrame.Angles(0, math.sin(t * 1.1 + info.Phase) * 0.12, 0)
					end
					model:PivotTo(info.Base * offset)
				end
			end
		end
	end)
end

return AnimController
