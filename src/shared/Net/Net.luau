--!strict
-- Net — доступ к RemoteEvent'ам реестра. Сервер создаёт инстансы под ReplicatedStorage.Remotes
-- (идемпотентно), клиент ждёт. Валидация — в серверных handler'ах (docs/02), НЕ тут.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteSchema = require(script.Parent.RemoteSchema)

local REMOTES_FOLDER = "Remotes"

local Net = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTES_FOLDER
		folder.Parent = ReplicatedStorage
	end
	for _, name in RemoteSchema do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Net.get(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
	return folder:WaitForChild(name) :: RemoteEvent
end

return Net
