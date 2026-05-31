--!strict
-- AnalyticsService — серверная воронка первой сессии (P1-09). Оборачивает Roblox AnalyticsService.
-- 6 шагов, каждый раз-на-игрока (дедуп). Без RemoteEvent, без мутации экономики — чистое
-- логирование ПОСЛЕ уже-проведённой серверной валидации в сервисах-источниках.
-- Канал: prod → Creator Dashboard (LogFunnelStepEvent); Studio → зеркало в атрибут (проверка мостом).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RobloxAnalytics = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local AnalyticsConfig = require(Config:WaitForChild("AnalyticsConfig"))

local ATTR_FUNNEL = "FunnelFired" -- Studio-only зеркало (csv шагов) — канал проверки мостом
local ATTR_FUNNEL_COUNT = "FunnelCount" -- Studio-only: сколько шагов зафиксировано

local AnalyticsService = Knit.CreateService({
	Name = "AnalyticsService",
})

-- Серверное состояние (Service [any]:any — поля чисты под --!strict).
AnalyticsService._fired = {} -- [Player] = { [stepName] = true } — дедуп
AnalyticsService._session = {} -- [Player] = funnelSessionId (GUID)
AnalyticsService._order = {} -- [Player] = { stepName, ... } — порядок (для Studio-зеркала)

-- Чистый: индекс шага (1..N) или nil, если шаг не из воронки.
function AnalyticsService._stepIndex(stepName: string): number?
	return AnalyticsConfig.stepIndex[stepName]
end

-- Чистый: логировать ли? Известный шаг И ещё не зафиксирован для этого набора (дедуп).
function AnalyticsService._shouldFire(firedSet: { [string]: boolean }, stepName: string): boolean
	return AnalyticsConfig.stepIndex[stepName] ~= nil and not firedSet[stepName]
end

-- Идемпотентная инициализация состояния игрока (PlayerAdded + анти-гонка early-joiners).
function AnalyticsService:_ensurePlayer(player: Player)
	if not self._fired[player] then
		self._fired[player] = {}
		self._order[player] = {}
		self._session[player] = HttpService:GenerateGUID(false)
	end
end

-- Главный API (зовут сервисы-источники): шаг воронки для игрока. Дедуп раз-на-игрока.
function AnalyticsService:LogFunnelStep(player: Player, stepName: string)
	local fired = self._fired[player]
	if not fired then
		return -- игрок не инициализирован (вышел/не зашёл) — молча игнор
	end
	if not AnalyticsService._shouldFire(fired, stepName) then
		return -- неизвестный шаг или дубль
	end
	fired[stepName] = true
	local order = self._order[player]
	table.insert(order, stepName)

	local idx = AnalyticsService._stepIndex(stepName) :: number
	local sessionId = self._session[player]

	-- Реальный бэкенд (Dashboard). pcall: аналитика не должна ронять геймплей.
	pcall(function()
		RobloxAnalytics:LogFunnelStepEvent(
			player,
			AnalyticsConfig.funnelName,
			sessionId,
			idx,
			stepName
		)
	end)

	-- Studio-only зеркало для проверки мостом (в проде канал — Dashboard).
	if RunService:IsStudio() then
		player:SetAttribute(ATTR_FUNNEL, table.concat(order, ","))
		player:SetAttribute(ATTR_FUNNEL_COUNT, #order)
	end

	print(`[Analytics] {player.Name} funnel {idx}/{#AnalyticsConfig.steps}: {stepName}`)
end

function AnalyticsService:_onPlayerAdded(player: Player)
	self:_ensurePlayer(player)
	self:LogFunnelStep(player, "player_joined")
end

function AnalyticsService:_onPlayerRemoving(player: Player)
	self._fired[player] = nil
	self._session[player] = nil
	self._order[player] = nil
end

function AnalyticsService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)
	-- Ранние джойнеры (сервис стартанул уже после входа игрока).
	for _, player in Players:GetPlayers() do
		self:_onPlayerAdded(player)
	end

	print(
		`[AnalyticsService] ready (funnel {AnalyticsConfig.funnelName}, {#AnalyticsConfig.steps} steps)`
	)
end

return AnalyticsService
