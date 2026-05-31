--!strict
-- RoundService — серверная стейт-машина матча (Фаза 1: 3 ночи) — ядро.
-- Preparation → [Night N → Morning → Upgrade] ×3 → EndMatch; wipe (все в toy box) → Lost.
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
-- _enemy / _revive задаются в KnitInit().

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

function RoundService:_onCaught(player: Player)
	-- Поимка только в ночь → игрок в toy box (НЕ мгновенный Lost; revive — P1-05).
	if self._state == STATE_NIGHT then
		self._revive:Capture(player)
	end
end

-- Исход ночи: wipe (все игроки в коробках) → Lost, иначе → Morning.
function RoundService:_resolveOutcome(): string
	return if self._revive:AreAllBoxed() then STATE_LOST else STATE_MORNING
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

-- Ночной отсчёт: выходит досрочно при wipe (все игроки в коробках).
function RoundService:_nightCountdown(duration: number)
	local t = duration
	while t > 0 and not self._revive:AreAllBoxed() do
		self:_setTime(t)
		task.wait(RoundConfig.tickInterval)
		t -= RoundConfig.tickInterval
	end
	self:_setTime(0)
end

function RoundService:_runRound()
	self._enemy:SetActive(false)
	self._enemy:SetSoldierActive(false)
	self._enemy:SetDollActive(false)
	self:_setNight(0)
	self:_setState(STATE_PREP)
	self:_countdown(RoundConfig.prepDuration)

	for night = 1, RoundConfig.nightCount do
		self:_setNight(night)

		-- Night: враг активен, таймер выживания.
		self:_setState(STATE_NIGHT)
		self._enemy:SetActive(true)
		self._enemy:SetSoldierActive(night >= EnemyConfig.soldierFirstNight)
		self._enemy:SetDollActive(night >= EnemyConfig.dollFirstNight)
		self:_nightCountdown(RoundConfig.nightDuration)
		self._enemy:SetActive(false)
		self._enemy:SetSoldierActive(false)
		self._enemy:SetDollActive(false)

		-- Исход ночи: пойман → Lost (терминально).
		if self:_resolveOutcome() == STATE_LOST then
			self:_setState(STATE_LOST)
			return
		end

		-- Пережил ночь → Morning (освобождаем всех из коробок — чистый старт).
		self:_setState(STATE_MORNING)
		self._revive:FreeAll()
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
	self._revive = Knit.GetService("ReviveService")
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
