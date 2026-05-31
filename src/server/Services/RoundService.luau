--!strict
-- RoundService — серверная стейт-машина одной ночи Фазы 0 (ядро).
-- Preparation → Night(таймер) → Morning(победа) | пойман → Lost(поражение).
-- Гейтит EnemyService; бродкаст состояния в Workspace для клиента.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local RoundConfig = require(Config:WaitForChild("RoundConfig"))

local ATTR_STATE = "RoundState"
local ATTR_TIME = "RoundTimeLeft"

local STATE_PREP = "Preparation"
local STATE_NIGHT = "Night"
local STATE_MORNING = "Morning"
local STATE_LOST = "Lost"

local RoundService = Knit.CreateService({
	Name = "RoundService",
})

RoundService._state = STATE_PREP
RoundService._caught = false
-- _enemy задаётся в KnitInit().

function RoundService:_setState(state: string)
	self._state = state
	Workspace:SetAttribute(ATTR_STATE, state)
end

function RoundService:_setTime(seconds: number)
	Workspace:SetAttribute(ATTR_TIME, math.max(0, math.ceil(seconds)))
end

function RoundService:_onCaught(_player: Player)
	-- Засчитываем только во время ночи (идемпотентно).
	if self._state == STATE_NIGHT then
		self._caught = true
	end
end

-- Исход ночи (чистая логика, тестируемо): пойман → Lost, выжил → Morning.
function RoundService:_resolveOutcome(): string
	return if self._caught then STATE_LOST else STATE_MORNING
end

function RoundService:_runRound()
	-- Preparation: враг спит.
	self._caught = false
	self._enemy:SetActive(false)
	self:_setState(STATE_PREP)
	local prep = RoundConfig.prepDuration
	while prep > 0 do
		self:_setTime(prep)
		task.wait(RoundConfig.tickInterval)
		prep -= RoundConfig.tickInterval
	end

	-- Night: враг активен, таймер выживания.
	self:_setState(STATE_NIGHT)
	self._enemy:SetActive(true)
	local remaining = RoundConfig.nightDuration
	while remaining > 0 and not self._caught do
		self:_setTime(remaining)
		task.wait(RoundConfig.tickInterval)
		remaining -= RoundConfig.tickInterval
	end

	-- Исход.
	self._enemy:SetActive(false)
	self:_setTime(0)
	self:_setState(self:_resolveOutcome())
end

function RoundService:KnitInit()
	self._enemy = Knit.GetService("EnemyService")
end

function RoundService:KnitStart()
	self._enemy:SetCaughtCallback(function(player: Player)
		self:_onCaught(player)
	end)
	task.spawn(function()
		self:_runRound()
	end)
	print("[RoundService] round started")
end

return RoundService
