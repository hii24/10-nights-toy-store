--!strict
-- EnemyService — Mr. Huggy Bear: серверный waypoint-патруль.
-- Логика серверная (docs/06: при StreamingEnabled держим врага на сервере). НЕ PathfindingService — ноды.
-- Скорость зависит от Workspace.GeneratorPowered (быстрее в темноте). Зеркалит BearSpeed/BearWaypoint.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local EnemyConfig = require(Config:WaitForChild("EnemyConfig"))

local BEAR_NAME = "Bear"
local ATTR_POWERED = "GeneratorPowered"
local ATTR_BEAR_SPEED = "BearSpeed"
local ATTR_BEAR_WAYPOINT = "BearWaypoint"

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
})

-- Серверное состояние (Service имеет [any]: any — поля чисты под --!strict).
EnemyService._active = false
EnemyService._wpIndex = 1
-- _bear / _bearY задаются в _build().

-- Хук для RoundService (P0-08): гейтить патруль по ночам.
function EnemyService:SetActive(active: boolean)
	self._active = active
end

-- Колбэк ловли (ставит RoundService): зовётся при игроке в catchRadius.
function EnemyService:SetCaughtCallback(callback)
	self._caughtCallback = callback
end

function EnemyService:_setWaypoint(index: number)
	self._wpIndex = index
	Workspace:SetAttribute(ATTR_BEAR_WAYPOINT, index)
end

function EnemyService:_setSpeed(speed: number)
	if Workspace:GetAttribute(ATTR_BEAR_SPEED) ~= speed then
		Workspace:SetAttribute(ATTR_BEAR_SPEED, speed)
	end
end

function EnemyService:_step(dt: number)
	if not self._active then
		return
	end
	local bear = self._bear
	if not bear or not bear.Parent then
		return
	end

	-- Ловля: игрок в catchRadius → колбэк (RoundService → Lost).
	local caughtCb = self._caughtCallback
	if caughtCb then
		for _, plr in Players:GetPlayers() do
			local hrp = plr.Character
				and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and (hrp.Position - bear.Position).Magnitude <= EnemyConfig.catchRadius then
				caughtCb(plr)
			end
		end
	end

	local powered = Workspace:GetAttribute(ATTR_POWERED) == true
	local speed = if powered then EnemyConfig.speedPowered else EnemyConfig.speedDark
	self:_setSpeed(speed)

	local target = EnemyConfig.waypoints[self._wpIndex]
	local goal = Vector3.new(target.X, self._bearY, target.Z)
	local delta = goal - bear.Position
	local dist = delta.Magnitude

	if dist <= EnemyConfig.reachEpsilon then
		self:_setWaypoint((self._wpIndex % #EnemyConfig.waypoints) + 1)
		return
	end

	local dir = delta.Unit
	local newPos = bear.Position + dir * math.min(speed * dt, dist)
	bear.CFrame = CFrame.lookAt(newPos, newPos + dir)
end

function EnemyService:_build()
	local startWp = EnemyConfig.waypoints[1]
	local bearY = EnemyConfig.bearSize.Y / 2

	local bear = Instance.new("Part")
	bear.Name = BEAR_NAME
	bear.Size = EnemyConfig.bearSize
	bear.Anchored = true
	bear.Color = EnemyConfig.bearColor
	bear.Material = EnemyConfig.bearMaterial
	bear.CFrame = CFrame.new(startWp.X, bearY, startWp.Z)

	self._bear = bear
	self._bearY = bearY
	bear.Parent = Workspace
end

function EnemyService:KnitStart()
	self:_build()
	self:_setWaypoint(1)
	Workspace:SetAttribute(ATTR_BEAR_SPEED, EnemyConfig.speedDark)

	RunService.Heartbeat:Connect(function(dt: number)
		self:_step(dt)
	end)

	print(`[EnemyService] Mr. Bear patrolling {#EnemyConfig.waypoints} waypoints`)
end

return EnemyService
