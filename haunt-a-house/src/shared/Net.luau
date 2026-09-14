--!nonstrict
-- Acces aux objets distants. Le serveur les cree, le client les attend.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.FolderName = "Remotes"
Net.Names = {
	Request = "Request", -- RemoteFunction client -> serveur (action, payload)
	ServerEvent = "ServerEvent", -- RemoteEvent serveur -> client (nom, payload)
	ClientEvent = "ClientEvent", -- RemoteEvent client -> serveur (nom, payload)
}

local function getFolder()
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(Net.FolderName)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Net.FolderName
			folder.Parent = ReplicatedStorage
		end
		return folder
	end
	return ReplicatedStorage:WaitForChild(Net.FolderName)
end

local function getRemote(name, className)
	local folder = getFolder()
	if RunService:IsServer() then
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
		return remote
	end
	return folder:WaitForChild(name)
end

function Net.request()
	return getRemote(Net.Names.Request, "RemoteFunction")
end

function Net.serverEvent()
	return getRemote(Net.Names.ServerEvent, "RemoteEvent")
end

function Net.clientEvent()
	return getRemote(Net.Names.ClientEvent, "RemoteEvent")
end

return Net
