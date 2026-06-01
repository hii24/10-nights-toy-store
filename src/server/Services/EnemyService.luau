--!strict
-- EnemyService — серверная логика врагов (docs/01: вся логика врагов тут; docs/06: при
-- StreamingEnabled держим врага на сервере). НЕ PathfindingService — ноды.
-- * Mr. Huggy Bear (P0-07/08): waypoint-патруль, ловит → Lost. Скорость = f(GeneratorPowered).
-- * Wind-Up Soldier (P1-02): линейный патруль A↔B, толкает (НЕ летально), шумит; с Night 2.
-- * Doll Blinker (P1-03): крадётся в «слепые» тики (look-вектор+LOS), замирает под взглядом; с Night 3.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local EnemyConfig = require(Config:WaitForChild("EnemyConfig"))
local BearConfig = require(Config:WaitForChild("BearConfig"))

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

local DOLL_NAME = "DollBlinker"
local ATTR_DOLL_ACTIVE = "DollActive" -- кукла активна (Night >= dollFirstNight)
local ATTR_DOLL_OBSERVED = "DollObserved" -- сейчас под взглядом (заморожена)

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

EnemyService._dollActive = false
-- _doll / _dollY задаются в _buildDoll().

-- Хук для RoundService (P0-08): гейтить патруль по ночам.
function EnemyService:SetActive(active: boolean)
	self._active = active
end

-- Хук для RoundService (P1-02): солдат активен с Night >= soldierFirstNight.
function EnemyService:SetSoldierActive(active: boolean)
	self._soldierActive = active
	Workspace:SetAttribute(ATTR_SOLDIER_ACTIVE, active)
end

-- Хук для RoundService (P1-03): кукла активна с Night >= dollFirstNight.
function EnemyService:SetDollActive(active: boolean)
	self._dollActive = active
	Workspace:SetAttribute(ATTR_DOLL_ACTIVE, active)
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
	local bearPos = bear:GetPivot().Position -- Bear теперь Model — позиция через pivot (root)

	-- Ловля: игрок в catchRadius → колбэк (RoundService → Lost).
	local caughtCb = self._caughtCallback
	if caughtCb then
		for _, plr in Players:GetPlayers() do
			local hrp = plr.Character
				and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and (hrp.Position - bearPos).Magnitude <= EnemyConfig.catchRadius then
				caughtCb(plr)
			end
		end
	end

	local powered = Workspace:GetAttribute(ATTR_POWERED) == true
	local speed = if powered then EnemyConfig.speedPowered else EnemyConfig.speedDark
	self:_setSpeed(speed)

	local target = EnemyConfig.waypoints[self._wpIndex]
	local goal = Vector3.new(target.X, self._bearY, target.Z)
	local delta = goal - bearPos
	local dist = delta.Magnitude

	if dist <= EnemyConfig.reachEpsilon then
		self:_setWaypoint((self._wpIndex % #EnemyConfig.waypoints) + 1)
		return
	end

	local dir = delta.Unit
	local newPos = bearPos + dir * math.min(speed * dt, dist)
	bear:PivotTo(CFrame.lookAt(newPos, newPos + dir))
end

function EnemyService:_build()
	local startWp = EnemyConfig.waypoints[1]
	local bearY = EnemyConfig.bearSize.Y / 2

	-- Bear = Model: невидимый root (позиция/ловля, PrimaryPart) + визуал (реальный меш или фолбэк-кластер) (P2-03).
	local model = Instance.new("Model")
	model.Name = BEAR_NAME

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = EnemyConfig.bearSize
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false -- невидимый якорь позиции/ловли; коллизия НЕ нужна (ловля по радиусу, движение PivotTo)
	root.CFrame = CFrame.new(startWp.X, bearY, startWp.Z)
	root.Parent = model
	model.PrimaryPart = root

	self._bear = model
	self._bearY = bearY
	model.Parent = Workspace

	-- Визуал — АСИНХРОННО (меш грузится по сети; НЕ блокируем и НЕ роняем KnitStart). Патруль идёт по root сразу;
	-- меш «вплывает» когда загрузится. Любой сбой visual → фолбэк-кластер (внутри, под pcall), init не падает.
	task.spawn(function()
		self:_buildVisual(model, root)
	end)
end

-- Визуал медведя: РЕАЛЬНЫЙ меш (MeshPart+SurfaceAppearance по asset ID из BearConfig.mesh, скейл к bearSize.Y),
-- либо ФОЛБЭК part-кластер (BearConfig.parts), если меш не загрузился. Всё Anchored CanCollide=false (двигаем PivotTo).
function EnemyService:_buildVisual(model: Model, root: BasePart)
	-- Геометрию даёт AssetService:CreateMeshPartAsync (по meshId). PBR-текстуры писать из game-скрипта НЕЛЬЗЯ
	-- (capability Plugin) — но можно КЛОНИРОВАТЬ готовый SurfaceAppearance из Rojo-шаблона Assets.BearMesh
	-- (материализован в src/assets/BearMesh.model.json). Комбинируем геометрию + клон-текстуры → реальный медведь.
	local meshCfg = BearConfig.mesh
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local template = assets and assets:FindFirstChild("BearMesh")
	local saTemplate = template and template:FindFirstChildWhichIsA("SurfaceAppearance")
	if meshCfg and saTemplate then
		local ok, err = pcall(function()
			local mp = AssetService:CreateMeshPartAsync(meshCfg.meshId, {
				CollisionFidelity = Enum.CollisionFidelity.Box,
				RenderFidelity = Enum.RenderFidelity.Precise,
			})
			local native = mp.Size
			local scale = if native.Y > 0 then EnemyConfig.bearSize.Y / native.Y else 1
			mp.Size = native * scale -- height → bearSize.Y, пропорции из импорта сохранены
			mp.Name = "BearMesh"
			mp.Anchored = true
			mp.CanCollide = false
			mp.CFrame = root.CFrame
				* CFrame.Angles(0, meshCfg.faceYaw or 0, 0)
				* CFrame.new(0, meshCfg.offsetY or 0, 0)
			saTemplate:Clone().Parent = mp -- клон (НЕ write ColorMap) → PBR-текстуры (лицо/мех)
			mp.Parent = model
		end)
		if ok then
			return
		end
		warn(
			"[EnemyService] Bear mesh build failed → фолбэк-кластер: "
				.. tostring(err)
		)
	end
	-- Фолбэк: part-кластер плейсхолдер (прежний PlushBear из BearConfig.parts).
	local offY = BearConfig.originOffsetY or 0
	for i, spec in BearConfig.parts do
		local p = Instance.new("Part")
		p.Name = "Bear_" .. i
		p.Shape = (Enum.PartType :: any)[spec.shape] or Enum.PartType.Block
		p.Size = spec.size
		p.Color = spec.color
		p.Material = (Enum.Material :: any)[spec.material] or Enum.Material.Fabric
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = p.Material ~= Enum.Material.Neon
		p.CFrame = root.CFrame
			* CFrame.new(spec.pos + Vector3.new(0, offY, 0))
			* CFrame.Angles(spec.rot.X, spec.rot.Y, spec.rot.Z)
		p.Parent = model
	end
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

-- Чистый предикат «смотрит на куклу» (тестируемо): угол взгляда в пределах конуса.
function EnemyService._isLookedAt(
	lookVector: Vector3,
	dirToDoll: Vector3,
	dotThreshold: number
): boolean
	if lookVector.Magnitude < 1e-4 or dirToDoll.Magnitude < 1e-4 then
		return false
	end
	return lookVector.Unit:Dot(dirToDoll.Unit) >= dotThreshold
end

-- LOS кукла→игрок: луч не должен упереться в препятствие (исключаем куклу и персонажа).
function EnemyService:_dollHasLOS(dollPos: Vector3, character: Model): boolean
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self._doll, character }
	local result = Workspace:Raycast(dollPos, hrp.Position - dollPos, params)
	return result == nil -- ничего между куклой и игроком → видно
end

-- Наблюдаема ли кукла хоть одним игроком (угол взгляда + LOS). Серверно, анти-чит.
function EnemyService:_isDollObserved(dollPos: Vector3): boolean
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local dirToDoll = dollPos - hrp.Position
			if
				EnemyService._isLookedAt(
					hrp.CFrame.LookVector,
					dirToDoll,
					EnemyConfig.dollViewDotThreshold
				) and self:_dollHasLOS(dollPos, char)
			then
				return true
			end
		end
	end
	return false
end

-- Ближайший к кукле HRP (цель движения в слепой тик).
function EnemyService:_nearestPlayerHrp(dollPos: Vector3): BasePart?
	local nearest: BasePart? = nil
	local nearestDist = math.huge
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local d = (hrp.Position - dollPos).Magnitude
			if d < nearestDist then
				nearestDist = d
				nearest = hrp
			end
		end
	end
	return nearest
end

function EnemyService:_stepDoll(dt: number)
	if not self._dollActive then
		return
	end
	local doll = self._doll
	if not doll or not doll.Parent then
		return
	end

	-- Под взглядом → freeze; в «слепой» тик → крадётся к ближайшему игроку.
	local observed = self:_isDollObserved(doll.Position)
	Workspace:SetAttribute(ATTR_DOLL_OBSERVED, observed)
	if observed then
		return
	end

	local targetHrp = self:_nearestPlayerHrp(doll.Position)
	if not targetHrp then
		return
	end
	local goal = Vector3.new(targetHrp.Position.X, self._dollY, targetHrp.Position.Z)
	local delta = goal - doll.Position
	local dist = delta.Magnitude
	if dist <= EnemyConfig.dollReachEpsilon then
		return -- дошла — безвредно стоит (НЕ ловит)
	end
	local dir = delta.Unit
	local newPos = doll.Position + dir * math.min(EnemyConfig.dollSpeed * dt, dist)
	doll.CFrame = CFrame.lookAt(newPos, newPos + dir)
end

function EnemyService:_buildDoll()
	local startPos = EnemyConfig.dollStart
	local dollY = EnemyConfig.dollSize.Y / 2

	local doll = Instance.new("Part")
	doll.Name = DOLL_NAME
	doll.Size = EnemyConfig.dollSize
	doll.Anchored = true
	doll.CanCollide = false -- безвредна: проходит сквозь, без физ-блока
	doll.Color = EnemyConfig.dollColor
	doll.Material = EnemyConfig.dollMaterial
	doll.CFrame = CFrame.new(startPos.X, dollY, startPos.Z)

	self._doll = doll
	self._dollY = dollY
	doll.Parent = Workspace
end

function EnemyService:KnitStart()
	self:_build()
	self:_setWaypoint(1)
	Workspace:SetAttribute(ATTR_BEAR_SPEED, EnemyConfig.speedDark)

	self:_buildSoldier()
	Workspace:SetAttribute(ATTR_SOLDIER_ACTIVE, false)
	Workspace:SetAttribute(ATTR_SOLDIER_NOISE, 0)
	Workspace:SetAttribute(ATTR_SOLDIER_PUSH_COUNT, 0)

	self:_buildDoll()
	Workspace:SetAttribute(ATTR_DOLL_ACTIVE, false)
	Workspace:SetAttribute(ATTR_DOLL_OBSERVED, false)

	-- Чистим rate-limit-стейт ушедших игроков (нет утечки ссылок).
	Players.PlayerRemoving:Connect(function(plr: Player)
		self._lastPush[plr] = nil
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		self:_step(dt)
		self:_stepSoldier(dt)
		self:_stepDoll(dt)
	end)

	print(
		`[EnemyService] Bear + Soldier (night {EnemyConfig.soldierFirstNight}+) + Doll (night {EnemyConfig.dollFirstNight}+) ready`
	)
end

return EnemyService
