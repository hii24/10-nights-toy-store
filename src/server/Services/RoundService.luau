--!strict
-- RoundService — серверная стейт-машина матча (Фаза 1: 3 ночи) — ядро.
-- Preparation → [Night N → Morning → Upgrade] ×3 → EndMatch; пойман в ночь → Lost.
-- Гейтит EnemyService; бродкаст RoundState/RoundTimeLeft/RoundNight в Workspace для клиента.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local RoundConfig = require(Config:WaitForChild("RoundConfig"))
local EnemyConfig = require(Config:WaitForChild("EnemyConfig"))

local ATTR_STATE = "RoundState"
local ATTR_TIME = "RoundTimeLeft"
local ATTR_NIGHT = "RoundNight"

local STATE_PREP = "Preparation"
local STATE_NIGHT = "Night"
local STATE_MORNING = "Morning"
local STATE_UPGRADE = "Upgrade"
local STATE_ENDMATCH = "EndMatch"
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

function RoundService:_setNight(night: number)
	Workspace:SetAttribute(ATTR_NIGHT, night)
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

-- Обратный отсчёт фазы с бродкастом RoundTimeLeft.
function RoundService:_countdown(duration: number)
	local t = duration
	while t > 0 do
		self:_setTime(t)
		task.wait(RoundConfig.tickInterval)
		t -= RoundConfig.tickInterval
	end
	self:_setTime(0)
end

-- Ночной отсчёт: выходит досрочно, если игрока поймали.
function RoundService:_nightCountdown(duration: number)
	local t = duration
	while t > 0 and not self._caught do
		self:_setTime(t)
		task.wait(RoundConfig.tickInterval)
		t -= RoundConfig.tickInterval
	end
	self:_setTime(0)
end

function RoundService:_runRound()
	self._enemy:SetActive(false)
	self._enemy:SetSoldierActive(false)
	self:_setNight(0)
	self:_setState(STATE_PREP)
	self:_countdown(RoundConfig.prepDuration)

	for night = 1, RoundConfig.nightCount do
		self:_setNight(night)

		-- Night: враг активен, таймер выживания.
		self._caught = false
		self:_setState(STATE_NIGHT)
		self._enemy:SetActive(true)
		self._enemy:SetSoldierActive(night >= EnemyConfig.soldierFirstNight)
		self:_nightCountdown(RoundConfig.nightDuration)
		self._enemy:SetActive(false)
		self._enemy:SetSoldierActive(false)

		-- Исход ночи: пойман → Lost (терминально).
		if self:_resolveOutcome() == STATE_LOST then
			self:_setState(STATE_LOST)
			return
		end

		-- Пережил ночь → Morning.
		self:_setState(STATE_MORNING)
		self:_countdown(RoundConfig.morningDuration)

		-- Между ночами — Upgrade (плейсхолдер; карточки → P1-06).
		if night < RoundConfig.nightCount then
			self:_setState(STATE_UPGRADE)
			self:_countdown(RoundConfig.upgradeDuration)
		end
	end

	-- Пережил все ночи → победа.
	self:_setState(STATE_ENDMATCH)
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
	print(`[RoundService] match started ({RoundConfig.nightCount} nights)`)
end

return RoundService
