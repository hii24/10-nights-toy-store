--!strict
-- BatteryService — спавн батареек + серверный подбор через ProximityPrompt.
-- Безопасность (docs/02): валидация ДО мутации; при провале — warn + тихий игнор (без кика).
-- Дистанцию гейтит движок (ProximityPrompt.MaxActivationDistance) ДО Triggered.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BatteryConfig = require(Config:WaitForChild("BatteryConfig"))

local PICKUPS_FOLDER = "Pickups"
local ATTR_BATTERIES = "Batteries"
local PICKUP_COOLDOWN = 0.2 -- rate-limit на игрока, сек

local BatteryService = Knit.CreateService({
	Name = "BatteryService",
})

-- Серверное состояние (Service имеет [any]: any, поля чисты под --!strict).
BatteryService._inventory = {} -- [Player]: number — сессионный счётчик
BatteryService._batteries = {} -- [ProximityPrompt]: BasePart — реестр живых пикапов
BatteryService._lastPickup = {} -- [Player]: number — для rate-limit

function BatteryService:_tryPickup(prompt: ProximityPrompt, player: Player)
	-- 1) whitelist: промпт зарегистрирован и батарейка ещё существует
	local battery = self._batteries[prompt]
	if not battery or not battery.Parent then
		warn(`[BatteryService] reject: unknown/taken prompt from {player.Name}`)
		return
	end

	-- 2) state: игрок жив
	local char = player.Character
	local humanoid = (char and char:FindFirstChildOfClass("Humanoid")) :: Humanoid?
	if not humanoid or humanoid.Health <= 0 then
		warn(`[BatteryService] reject: {player.Name} not alive`)
		return
	end

	-- 3) rate-limit на игрока
	local now = os.clock()
	local last = self._lastPickup[player]
	if last and now - last < PICKUP_COOLDOWN then
		warn(`[BatteryService] rate-limit: {player.Name}`)
		return
	end

	-- Мутация только после успешной валидации.
	self._lastPickup[player] = now
	self._batteries[prompt] = nil
	battery:Destroy()

	local count = (self._inventory[player] or 0) + 1
	self._inventory[player] = count
	player:SetAttribute(ATTR_BATTERIES, count)
	-- TODO(P1-09): аналитика first_battery_picked
end

function BatteryService:_spawnBattery(position: Vector3, folder: Folder)
	local part = Instance.new("Part")
	part.Name = "Battery"
	part.Size = BatteryConfig.partSize
	part.Anchored = true
	part.Color = BatteryConfig.color
	part.Material = BatteryConfig.material
	part.Position = Vector3.new(position.X, BatteryConfig.partSize.Y / 2, position.Z)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = BatteryConfig.prompt.actionText
	prompt.ObjectText = BatteryConfig.prompt.objectText
	prompt.HoldDuration = BatteryConfig.prompt.holdDuration
	prompt.MaxActivationDistance = BatteryConfig.prompt.maxActivationDistance
	prompt.RequiresLineOfSight = BatteryConfig.prompt.requiresLineOfSight
	prompt.Parent = part

	self._batteries[prompt] = part
	prompt.Triggered:Connect(function(player: Player)
		self:_tryPickup(prompt, player)
	end)

	part.Parent = folder
end

function BatteryService:KnitStart()
	local folder = Instance.new("Folder")
	folder.Name = PICKUPS_FOLDER
	folder.Parent = Workspace

	for _, position in ipairs(BatteryConfig.positions) do
		self:_spawnBattery(position, folder)
	end

	Players.PlayerRemoving:Connect(function(player)
		self._inventory[player] = nil
		self._lastPickup[player] = nil
	end)

	print(`[BatteryService] spawned {#BatteryConfig.positions} batteries`)
end

return BatteryService
