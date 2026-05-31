--!strict
-- UpgradeService — сессионные апгрейды: валидированный RemoteEvent SelectUpgrade → эффект на
-- Humanoid игрока (per-player, на сессию). Безопасность (docs/02): middleware ДО мутации
-- (type-assert → whitelist → rate-limit → state-gate). Гейт Upgrade-фазы — по Workspace.RoundState.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local UpgradeConfig = require(Config:WaitForChild("UpgradeConfig"))
local Net = require(Shared:WaitForChild("Net"):WaitForChild("Net"))

local ATTR_ROUND_STATE = "RoundState"
local STATE_UPGRADE = "Upgrade"
local SELECT_COOLDOWN = 0.5 -- rate-limit на игрока, сек

local UpgradeService = Knit.CreateService({
	Name = "UpgradeService",
})

-- Серверное состояние (Service [any]:any — поля чисты под --!strict).
UpgradeService._mult = {} -- [Player] = { walkSpeed: number, jumpPower: number }
UpgradeService._chosenThisPhase = {} -- [Player] = true (выбрал в текущей Upgrade-фазе)
UpgradeService._lastSelect = {} -- [Player] = os.clock() (rate-limit)

-- Чистый предикат type-assert + whitelist (тестируемо): id строка И есть в UpgradeConfig.cards.
function UpgradeService._isValidUpgradeId(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	for _, card in UpgradeConfig.cards do
		if card.id == id then
			return true
		end
	end
	return false
end

local function getCard(id: string)
	for _, card in UpgradeConfig.cards do
		if card.id == id then
			return card
		end
	end
	return nil
end

function UpgradeService:_getMult(player: Player)
	local m = self._mult[player]
	if not m then
		m = { walkSpeed = 1, jumpPower = 1 }
		self._mult[player] = m
	end
	return m
end

function UpgradeService:_applyToCharacter(player: Player)
	local char = player.Character
	local humanoid = (char and char:FindFirstChildOfClass("Humanoid")) :: Humanoid?
	if not humanoid then
		return
	end
	local m = self:_getMult(player)
	humanoid.WalkSpeed = UpgradeConfig.baseWalkSpeed * m.walkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = UpgradeConfig.baseJumpPower * m.jumpPower
end

-- Серверный handler выбора. Middleware ДО мутации (docs/02): type→whitelist→rate-limit→state-gate.
function UpgradeService:_onSelect(player: Player, id: any)
	if not UpgradeService._isValidUpgradeId(id) then -- 1) type-assert + 2) whitelist
		warn(`[UpgradeService] reject: {player.Name} invalid upgrade id`)
		return
	end
	local now = os.clock() -- 3) rate-limit на игрока
	local last = self._lastSelect[player]
	if last and now - last < SELECT_COOLDOWN then
		warn(`[UpgradeService] rate-limit: {player.Name}`)
		return
	end
	if Workspace:GetAttribute(ATTR_ROUND_STATE) ~= STATE_UPGRADE then -- 4) state-gate: только Upgrade
		warn(`[UpgradeService] reject: {player.Name} not in Upgrade phase`)
		return
	end
	if self._chosenThisPhase[player] then -- 5) одна карта за фазу
		warn(`[UpgradeService] reject: {player.Name} already chose this phase`)
		return
	end

	-- Мутация: накопить множители + применить.
	local card = getCard(id :: string)
	if not card then
		return
	end
	self._lastSelect[player] = now
	self._chosenThisPhase[player] = true
	local m = self:_getMult(player)
	m.walkSpeed *= card.walkSpeedMult
	m.jumpPower *= card.jumpPowerMult
	self:_applyToCharacter(player)
	self._analytics:LogFunnelStep(player, "upgrade_selected") -- воронка (P1-09); только на ВАЛИДный выбор
end

function UpgradeService:_onRoundStateChanged()
	-- Новая Upgrade-фаза → можно выбирать снова (сброс «выбрал в этой фазе»).
	if Workspace:GetAttribute(ATTR_ROUND_STATE) == STATE_UPGRADE then
		self._chosenThisPhase = {}
	end
end

function UpgradeService:KnitInit()
	self._analytics = Knit.GetService("AnalyticsService")
end

function UpgradeService:KnitStart()
	local remote = Net.get("SelectUpgrade")
	remote.OnServerEvent:Connect(function(player: Player, id: any)
		self:_onSelect(player, id)
	end)

	Workspace:GetAttributeChangedSignal(ATTR_ROUND_STATE):Connect(function()
		self:_onRoundStateChanged()
	end)

	-- Пере-применить апгрейды на респаун (сессия держится через множители).
	local function hookCharacter(player: Player)
		player.CharacterAdded:Connect(function()
			if self._mult[player] then
				task.defer(function()
					self:_applyToCharacter(player)
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(hookCharacter)
	for _, player in Players:GetPlayers() do
		hookCharacter(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		self._mult[player] = nil
		self._chosenThisPhase[player] = nil
		self._lastSelect[player] = nil
	end)

	print(`[UpgradeService] ready ({#UpgradeConfig.cards} cards)`)
end

return UpgradeService
