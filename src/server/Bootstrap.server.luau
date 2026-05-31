--!strict
-- Knit-рантайм (сервер): регистрирует сервисы из Server/Services и стартует Knit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Services = script.Parent:WaitForChild("Services")
Knit.AddServices(Services)

Knit.Start()
	:andThen(function()
		print("[Knit] server started")
	end)
	:catch(function(err)
		warn("[Knit] start failed: " .. tostring(err))
	end)
