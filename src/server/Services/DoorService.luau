--!strict
-- DoorService — двери ломаются ночью; hold-to-repair с СЕРВЕРНЫМ счётом прогресса (P1-04).
-- Безопасность (docs/02): repair нельзя доделать мгновенно — сервер сам копит прогресс по
-- РЕАЛЬНОМУ времени удержания (HoldBegan→HoldEnded) и завершает при полном. Промпт лишь сигналит
-- hold (не зависим от Triggered). Двери реагируют на Workspace.RoundState (decoupled).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local DoorConfig = require(Config:WaitForChild("DoorConfig"))

local DOORS_FOLDER = "Doors"
local ATTR_BROKEN = "Broken"
local ATTR_PROGRESS = "RepairProgress"
local ATTR_ROUND_STATE = "RoundState"
local STATE_NIGHT = "Night"

local DoorService = Knit.CreateService({
	Name = "DoorService",
})

-- Серверное состояние (Service имеет [any]: any — поля чисты под --!strict).
DoorService._doors = {} -- список Part-дверей
DoorService._holds = {} -- [door: BasePart] = { player: Player, startClock: number }

-- Чистый предикат «починка засчитана» (тестируемо): удержание >= required*tolerance.
function DoorService._isHoldValid(elapsed: number, required: number, tolerance: number): boolean
	return elapsed >= required * tolerance
end

function DoorService:_setBroken(door: BasePart, broken: boolean)
	door:SetAttribute(ATTR_BROKEN, broken)
	door:SetAttribute(ATTR_PROGRESS, if broken then 0 else 1)
	door.Color = if broken then DoorConfig.colorBroken else DoorConfig.colorIntact
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt?
	if prompt then
		prompt.Enabled = broken
	end
	self._holds[door] = nil
end

function DoorService:_breakAll()
	for _, door in self._doors do
		self:_setBroken(door, true)
	end
end

function DoorService:_resetAll()
	for _, door in self._doors do
		self:_setBroken(door, false)
	end
end

function DoorService:_onHoldBegan(door: BasePart, player: Player)
	if door:GetAttribute(ATTR_BROKEN) ~= true then
		return
	end
	self._holds[door] = { player = player, startClock = os.clock() }
end

function DoorService:_onHoldEnded(door: BasePart, player: Player)
	-- Ранний релиз (дверь ещё сломана) → сброс прогресса/холда.
	local hold = self._holds[door]
	if hold and hold.player == player and door:GetAttribute(ATTR_BROKEN) == true then
		self._holds[door] = nil
		door:SetAttribute(ATTR_PROGRESS, 0)
		player:SetAttribute(ATTR_PROGRESS, 0) -- сброс HUD-бара холдера (P1-07)
	end
end

-- Heartbeat: сервер СЧИТАЕТ прогресс удержаний и САМ завершает починку при полном удержании
-- (НЕ зависит от prompt.Triggered). Анти-мгновенно: прогресс растёт только в реальном времени.
function DoorService:_updateProgress()
	local now = os.clock()
	for door, hold in self._holds do
		local elapsed = now - hold.startClock
		local progress = math.clamp(elapsed / DoorConfig.repairDuration, 0, 1)
		door:SetAttribute(ATTR_PROGRESS, progress)
		hold.player:SetAttribute(ATTR_PROGRESS, progress) -- HUD-бар холдера (P1-07)
		if
			DoorService._isHoldValid(elapsed, DoorConfig.repairDuration, DoorConfig.holdTolerance)
		then
			hold.player:SetAttribute(ATTR_PROGRESS, 0) -- починено → сброс HUD-бара
			self:_setBroken(door, false) -- засчитано полное реальное удержание → починена
		end
	end
end

function DoorService:_buildDoors()
	local folder = Instance.new("Folder")
	folder.Name = DOORS_FOLDER

	for i, pos in DoorConfig.doors do
		local door = Instance.new("Part")
		door.Name = "Door" .. i
		door.Size = DoorConfig.size
		door.Anchored = true
		door.Material = DoorConfig.material
		door.Color = DoorConfig.colorIntact
		door.Position = Vector3.new(pos.X, DoorConfig.size.Y / 2, pos.Z)
		door:SetAttribute(ATTR_BROKEN, false)
		door:SetAttribute(ATTR_PROGRESS, 1)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = DoorConfig.prompt.actionText
		prompt.ObjectText = DoorConfig.prompt.objectText
		prompt.HoldDuration = DoorConfig.prompt.holdDuration
		prompt.MaxActivationDistance = DoorConfig.prompt.maxActivationDistance
		prompt.RequiresLineOfSight = DoorConfig.prompt.requiresLineOfSight
		prompt.Enabled = false
		prompt.Parent = door

		prompt.PromptButtonHoldBegan:Connect(function(player: Player)
			self:_onHoldBegan(door, player)
		end)
		prompt.PromptButtonHoldEnded:Connect(function(player: Player)
			self:_onHoldEnded(door, player)
		end)

		door.Parent = folder
		self._doors[i] = door
	end

	folder.Parent = Workspace
end

function DoorService:_onRoundStateChanged()
	if Workspace:GetAttribute(ATTR_ROUND_STATE) == STATE_NIGHT then
		self:_breakAll()
	else
		self:_resetAll()
	end
end

function DoorService:KnitStart()
	self:_buildDoors()

	Workspace:GetAttributeChangedSignal(ATTR_ROUND_STATE):Connect(function()
		self:_onRoundStateChanged()
	end)
	self:_onRoundStateChanged() -- начальное состояние

	RunService.Heartbeat:Connect(function()
		self:_updateProgress()
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		for door, hold in self._holds do
			if hold.player == player then
				self._holds[door] = nil
				door:SetAttribute(ATTR_PROGRESS, 0)
			end
		end
	end)

	print(`[DoorService] ready ({#self._doors} doors)`)
end

return DoorService
