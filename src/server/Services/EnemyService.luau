--!strict
-- EnemyService — серверная логика врагов (docs/01: вся логика врагов тут; docs/06: при
-- StreamingEnabled держим врага на сервере). НЕ PathfindingService — ноды.
-- * Mr. Huggy Bear (P0-07/08): waypoint-патруль, ловит → Lost. Скорость = f(GeneratorPowered).
-- * Wind-Up Soldier (P1-02): линейный патруль A↔B, толкает (НЕ летально), шумит; с Night 2.

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

local SOLDIER_NAME = "WindUpSoldier"
local ATTR_SOLDIER_ACTIVE = "SoldierActive" -- враг активен (Night >= soldierFirstNight)
local ATTR_SOLDIER_NOISE = "SoldierNoisePulse" -- счётчик шум-пульсов (плейсхолдер аудио)
local ATTR_SOLDIER_PUSH_COUNT = "SoldierPushCount" -- телеметрия толчков (для проверки)
-- Атрибуты на Player (сервер ставит → клиент применяет импульс своему персонажу):
local ATTR_PUSH_TICK = "SoldierPushTick"
local ATTR_PUSH_X = "SoldierPushX"
local ATTR_PUSH_Z = "SoldierPushZ"

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
})

-- Серверное состояние (Service имеет [any]: any — поля чисты под --!strict).
EnemyService._active = false
EnemyService._wpIndex = 1
-- _bear / _bearY задаются в _build().

EnemyService._soldierActive = false
EnemyService._lastPush = {} -- [Player] = os.clock() последнего толчка (rate-limit)
EnemyService._noiseClock = 0
-- _soldier / _soldierY / _soldierTarget задаются в _buildSoldier().

-- Хук для RoundService (P0-08): гейтить патруль по ночам.
function EnemyService:SetActive(active: boolean)
	self._active = active
end

-- Хук для RoundService (P1-02): солдат активен с Night >= soldierFirstNight.
function EnemyService:SetSoldierActive(active: boolean)
	self._soldierActive = active
	Workspace:SetAttribute(ATTR_SOLDIER_ACTIVE, active)
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

-- Чистый предикат толчка (тестируемо): игрок в радиусе И прошёл кулдаун.
function EnemyService._shouldPush(
	distance: number,
	lastPush: number?,
	now: number,
	radius: number,
	cooldown: number
): boolean
	if distance > radius then
		return false
	end
	if lastPush ~= nil and (now - lastPush) < cooldown then
		return false
	end
	return true
end

-- Толчок: сервер — авторитет (когда/кого/куда); атрибуты на Player → клиент применяет импульс.
function EnemyService:_pushPlayer(plr: Player, hrp: BasePart, soldier: BasePart, now: number)
	local flat =
		Vector3.new(hrp.Position.X - soldier.Position.X, 0, hrp.Position.Z - soldier.Position.Z)
	local dir = if flat.Magnitude > 0.05 then flat.Unit else Vector3.new(0, 0, 1)
	self._lastPush[plr] = now
	-- X/Z до Tick: к моменту обработки Tick на клиенте направление уже выставлено.
	plr:SetAttribute(ATTR_PUSH_X, dir.X)
	plr:SetAttribute(ATTR_PUSH_Z, dir.Z)
	plr:SetAttribute(ATTR_PUSH_TICK, (plr:GetAttribute(ATTR_PUSH_TICK) or 0) + 1)
	Workspace:SetAttribute(
		ATTR_SOLDIER_PUSH_COUNT,
		(Workspace:GetAttribute(ATTR_SOLDIER_PUSH_COUNT) or 0) + 1
	)
end

function EnemyService:_stepSoldier(dt: number)
	if not self._soldierActive then
		return
	end
	local soldier = self._soldier
	if not soldier or not soldier.Parent then
		return
	end

	local now = os.clock()

	-- Толчок игроков в радиусе (с кулдауном на игрока).
	for _, plr in Players:GetPlayers() do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local distance = (hrp.Position - soldier.Position).Magnitude
			if
				EnemyService._shouldPush(
					distance,
					self._lastPush[plr],
					now,
					EnemyConfig.soldierPushRadius,
					EnemyConfig.soldierPushCooldown
				)
			then
				self:_pushPlayer(plr, hrp, soldier, now)
			end
		end
	end

	-- Шум-пульс (плейсхолдер аудио): бродкаст по интервалу.
	if now - self._noiseClock >= EnemyConfig.soldierNoiseInterval then
		self._noiseClock = now
		Workspace:SetAttribute(
			ATTR_SOLDIER_NOISE,
			(Workspace:GetAttribute(ATTR_SOLDIER_NOISE) or 0) + 1
		)
	end

	-- Линейный патруль A↔B (ping-pong: на конце линии разворот).
	local target = self._soldierTarget
	local goal = Vector3.new(target.X, self._soldierY, target.Z)
	local delta = goal - soldier.Position
	local dist = delta.Magnitude
	if dist <= EnemyConfig.soldierReachEpsilon then
		self._soldierTarget = if target == EnemyConfig.soldierPathB
			then EnemyConfig.soldierPathA
			else EnemyConfig.soldierPathB
		return
	end
	local dir = delta.Unit
	local newPos = soldier.Position + dir * math.min(EnemyConfig.soldierSpeed * dt, dist)
	soldier.CFrame = CFrame.lookAt(newPos, newPos + dir)
end

function EnemyService:_buildSoldier()
	local startPos = EnemyConfig.soldierPathA
	local soldierY = EnemyConfig.soldierSize.Y / 2

	local soldier = Instance.new("Part")
	soldier.Name = SOLDIER_NAME
	soldier.Size = EnemyConfig.soldierSize
	soldier.Anchored = true
	soldier.CanCollide = false -- пуш серверный по радиусу, без физ. бампа
	soldier.Color = EnemyConfig.soldierColor
	soldier.Material = EnemyConfig.soldierMaterial
	soldier.CFrame = CFrame.new(startPos.X, soldierY, startPos.Z)

	self._soldier = soldier
	self._soldierY = soldierY
	self._soldierTarget = EnemyConfig.soldierPathB
	soldier.Parent = Workspace
end

function EnemyService:KnitStart()
	self:_build()
	self:_setWaypoint(1)
	Workspace:SetAttribute(ATTR_BEAR_SPEED, EnemyConfig.speedDark)

	self:_buildSoldier()
	Workspace:SetAttribute(ATTR_SOLDIER_ACTIVE, false)
	Workspace:SetAttribute(ATTR_SOLDIER_NOISE, 0)
	Workspace:SetAttribute(ATTR_SOLDIER_PUSH_COUNT, 0)

	-- Чистим rate-limit-стейт ушедших игроков (нет утечки ссылок).
	Players.PlayerRemoving:Connect(function(plr: Player)
		self._lastPush[plr] = nil
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		self:_step(dt)
		self:_stepSoldier(dt)
	end)

	print(
		`[EnemyService] Mr. Bear patrolling {#EnemyConfig.waypoints} waypoints; Soldier ready (night {EnemyConfig.soldierFirstNight}+)`
	)
end

return EnemyService
