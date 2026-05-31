--!strict
-- GeneratorService — генератор + серверная вставка батарейки (повышает питание).
-- Безопасность (docs/02): валидация ДО мутации; провал → warn + тихий игнор (без кика).
-- Межсервисно: тратит батарейку через BatteryService:TryConsume (Knit.GetService).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local GeneratorConfig = require(Config:WaitForChild("GeneratorConfig"))

local GENERATOR_NAME = "Generator"
local ATTR_POWER = "Power"
local ATTR_MAXPOWER = "MaxPower"
local ATTR_GLOBAL_POWER = "GeneratorPower" -- глобально на Workspace (для света/врага/HUD)
local ATTR_GLOBAL_POWERED = "GeneratorPowered" -- bool: power >= порог (свет/враг читают)
local INSERT_COOLDOWN = 0.25 -- rate-limit на игрока, сек

local GeneratorService = Knit.CreateService({
	Name = "GeneratorService",
})

-- Серверное состояние (Service имеет [any]: any — поля чисты под --!strict).
GeneratorService._power = GeneratorConfig.startPower
GeneratorService._lastInsert = {} -- [Player]: number — rate-limit
-- _generator / _prompt задаются в _build(); _batteryService — в KnitInit().

function GeneratorService:_applyPower()
	local gen = self._generator
	if gen then
		gen:SetAttribute(ATTR_POWER, self._power)
		gen:SetAttribute(ATTR_MAXPOWER, GeneratorConfig.maxPower)
	end
	Workspace:SetAttribute(ATTR_GLOBAL_POWER, self._power)
	Workspace:SetAttribute(ATTR_GLOBAL_POWERED, self._power >= GeneratorConfig.poweredThreshold)
end

-- Слабый серверный drain: питание падает со временем (давление подкидывать батарейки).
function GeneratorService:_startDrain()
	task.spawn(function()
		while true do
			task.wait(GeneratorConfig.drainInterval)
			if self._power > 0 then
				self._power = math.max(0, self._power - GeneratorConfig.drainAmount)
				self:_applyPower()
			end
		end
	end)
end

function GeneratorService:_tryInsert(player: Player)
	-- whitelist: единственный генератор; Triggered приходит только от его промпта.
	-- 1) state: игрок жив
	local char = player.Character
	local humanoid = (char and char:FindFirstChildOfClass("Humanoid")) :: Humanoid?
	if not humanoid or humanoid.Health <= 0 then
		warn(`[GeneratorService] reject: {player.Name} not alive`)
		return
	end

	-- 2) state: генератор не полон
	if self._power >= GeneratorConfig.maxPower then
		warn(`[GeneratorService] reject: generator full`)
		return
	end

	-- 3) state: у игрока есть батарейка
	if self._batteryService:GetCount(player) < 1 then
		warn(`[GeneratorService] reject: {player.Name} has no battery`)
		return
	end

	-- 4) rate-limit на игрока
	local now = os.clock()
	local last = self._lastInsert[player]
	if last and now - last < INSERT_COOLDOWN then
		warn(`[GeneratorService] rate-limit: {player.Name}`)
		return
	end

	-- Мутация: межсервисное списание, затем рост питания.
	if not self._batteryService:TryConsume(player, 1) then
		warn(`[GeneratorService] reject: consume failed for {player.Name}`)
		return
	end
	self._lastInsert[player] = now
	self._power = math.min(GeneratorConfig.maxPower, self._power + GeneratorConfig.powerPerBattery)
	self:_applyPower()
	self._analytics:LogFunnelStep(player, "battery_inserted_generator") -- воронка (P1-09); дедуп → «first»
end

function GeneratorService:_build()
	local gen = Instance.new("Part")
	gen.Name = GENERATOR_NAME
	gen.Size = GeneratorConfig.size
	gen.Anchored = true
	gen.Color = GeneratorConfig.color
	gen.Material = GeneratorConfig.material
	gen.Position = Vector3.new(
		GeneratorConfig.position.X,
		GeneratorConfig.size.Y / 2,
		GeneratorConfig.position.Z
	)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = GeneratorConfig.prompt.actionText
	prompt.ObjectText = GeneratorConfig.prompt.objectText
	prompt.HoldDuration = GeneratorConfig.prompt.holdDuration
	prompt.MaxActivationDistance = GeneratorConfig.prompt.maxActivationDistance
	prompt.RequiresLineOfSight = GeneratorConfig.prompt.requiresLineOfSight
	prompt.Parent = gen

	self._generator = gen
	self._prompt = prompt
	prompt.Triggered:Connect(function(player: Player)
		self:_tryInsert(player)
	end)

	gen.Parent = Workspace
end

function GeneratorService:KnitInit()
	self._batteryService = Knit.GetService("BatteryService")
	self._analytics = Knit.GetService("AnalyticsService")
end

function GeneratorService:KnitStart()
	self:_build()
	self:_applyPower()
	self:_startDrain()

	Players.PlayerRemoving:Connect(function(player)
		self._lastInsert[player] = nil
	end)

	print(`[GeneratorService] ready (power {self._power}/{GeneratorConfig.maxPower})`)
end

return GeneratorService
