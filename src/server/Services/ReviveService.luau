--!strict
-- ReviveService — пойманный → InToyBox (анкор у toy box); тиммейт держит коробку → FreeAll (P1-05).
-- Безопасность (docs/02): capture/free/«пойман ли» — серверно. Free валидирует холдера ДО мутации
-- (жив + НЕ в коробке). Анкор HRP держит позицию несмотря на клиентское сетевое владение.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ReviveConfig = require(Config:WaitForChild("ReviveConfig"))

local TOYBOX_NAME = "ToyBox"
local ATTR_INTOYBOX = "InToyBox" -- на Player
local ATTR_BOXED_COUNT = "BoxedCount" -- на Workspace (HUD/проверка)

local ReviveService = Knit.CreateService({
	Name = "ReviveService",
})

-- Серверное состояние (Service имеет [any]: any — поля чисты под --!strict).
ReviveService._boxed = {} -- [Player] = true
ReviveService._holdStart = nil -- os.clock() начала открытия коробки (или nil)
ReviveService._holdRescuer = nil -- Player, который держит (или nil)
-- _toyBox / _prompt задаются в _buildToyBox().

-- Чистый предикат wipe (тестируемо): команда уничтожена, если все живые игроки в коробках.
function ReviveService._isWipe(total: number, boxed: number): boolean
	return total > 0 and boxed >= total
end

local function getHrp(player: Player): BasePart?
	local char = player.Character
	return (char and char:FindFirstChild("HumanoidRootPart")) :: BasePart?
end

function ReviveService:_boxedCount(): number
	local n = 0
	for _ in self._boxed do
		n += 1
	end
	return n
end

function ReviveService:AreAllBoxed(): boolean
	return ReviveService._isWipe(#Players:GetPlayers(), self:_boxedCount())
end

function ReviveService:_broadcastCount()
	local count = self:_boxedCount()
	Workspace:SetAttribute(ATTR_BOXED_COUNT, count)
	if self._prompt then
		self._prompt.Enabled = count > 0 -- открывать коробку можно, только если есть кого спасать
	end
end

-- Заанкорить+посадить текущего персонажа в клетку. HRP может отсутствовать (гонка респауна) →
-- no-op, докрутит CharacterAdded. Анкор держит позицию против клиентского сетевого владения.
function ReviveService:_cageNow(player: Player)
	local hrp = getHrp(player)
	if hrp then
		hrp.Anchored = true -- сначала анкор (клиент перестаёт симулировать), затем позиция держится
		hrp.CFrame = CFrame.new(ReviveConfig.toyBoxPosition + ReviveConfig.cageOffset)
	end
end

-- Пойман: флаг InToyBox + посадка в клетку. Идемпотентно. Флаг ставим даже без HRP (докрутит
-- CharacterAdded) — игрок не «выпадает» из поимки на гонке загрузки персонажа (MED-2).
function ReviveService:Capture(player: Player)
	if self._boxed[player] then
		return
	end
	self._boxed[player] = true
	player:SetAttribute(ATTR_INTOYBOX, true)
	self:_cageNow(player)
	self:_broadcastCount()
end

function ReviveService:_release(player: Player)
	if not self._boxed[player] then
		return
	end
	self._boxed[player] = nil
	player:SetAttribute(ATTR_INTOYBOX, false)
	local hrp = getHrp(player)
	if hrp then
		hrp.CFrame = CFrame.new(ReviveConfig.releasePosition) -- позиция, пока ещё анкорный
		hrp.Anchored = false -- разанкор → клиент продолжает с этой точки
	end
end

-- Открыли коробку → выходят ВСЕ пойманные.
function ReviveService:FreeAll()
	for player in self._boxed do
		self:_release(player)
	end
	self._holdStart = nil
	self._holdRescuer = nil
	self:_broadcastCount()
end

-- Валидный спасатель: жив И НЕ в коробке (пойманный не спасает).
function ReviveService:_canRescue(player: Player): boolean
	if self._boxed[player] then
		return false
	end
	local char = player.Character
	local humanoid = (char and char:FindFirstChildOfClass("Humanoid")) :: Humanoid?
	return humanoid ~= nil and humanoid.Health > 0
end

function ReviveService:_onHoldBegan(player: Player)
	if not self:_canRescue(player) then
		warn(`[ReviveService] reject: {player.Name} cannot rescue (boxed/dead)`)
		return
	end
	if self:_boxedCount() == 0 then
		return -- некого спасать
	end
	self._holdStart = os.clock()
	self._holdRescuer = player
end

function ReviveService:_onHoldEnded(player: Player)
	if self._holdRescuer == player then
		self._holdStart = nil
		self._holdRescuer = nil
	end
end

-- Heartbeat: сервер считает удержание; по freeDuration → FreeAll. Срыв при невалидном холдере.
function ReviveService:_updateHold()
	if not self._holdStart or not self._holdRescuer then
		return
	end
	if not self:_canRescue(self._holdRescuer) or self:_boxedCount() == 0 then
		self._holdStart = nil
		self._holdRescuer = nil
		return
	end
	if (os.clock() - self._holdStart) >= ReviveConfig.freeDuration then
		self:FreeAll()
	end
end

function ReviveService:_buildToyBox()
	local box = Instance.new("Part")
	box.Name = TOYBOX_NAME
	box.Size = ReviveConfig.toyBoxSize
	box.Anchored = true
	box.Color = ReviveConfig.color
	box.Material = ReviveConfig.material
	box.Position = Vector3.new(
		ReviveConfig.toyBoxPosition.X,
		ReviveConfig.toyBoxSize.Y / 2,
		ReviveConfig.toyBoxPosition.Z
	)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = ReviveConfig.prompt.actionText
	prompt.ObjectText = ReviveConfig.prompt.objectText
	prompt.HoldDuration = ReviveConfig.prompt.holdDuration
	prompt.MaxActivationDistance = ReviveConfig.prompt.maxActivationDistance
	prompt.RequiresLineOfSight = ReviveConfig.prompt.requiresLineOfSight
	prompt.Enabled = false
	prompt.Parent = box

	prompt.PromptButtonHoldBegan:Connect(function(player: Player)
		self:_onHoldBegan(player)
	end)
	prompt.PromptButtonHoldEnded:Connect(function(player: Player)
		self:_onHoldEnded(player)
	end)

	self._toyBox = box
	self._prompt = prompt
	box.Parent = Workspace
end

function ReviveService:KnitStart()
	self:_buildToyBox()
	Workspace:SetAttribute(ATTR_BOXED_COUNT, 0)

	RunService.Heartbeat:Connect(function()
		self:_updateHold()
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._boxed[player] = nil
		if self._holdRescuer == player then
			self._holdStart = nil
			self._holdRescuer = nil
		end
		self:_broadcastCount()
	end)

	-- Респаун/смена персонажа боксн­утого игрока → новый HRP не анкорный (escape). Пере-садить
	-- в клетку (анти-escape MED-1 + докрутка Capture без HRP MED-2).
	local function onCharacterAdded(player: Player, character: Model)
		if not self._boxed[player] then
			return
		end
		character:WaitForChild("HumanoidRootPart", 5)
		if self._boxed[player] then -- мог освободиться за время ожидания
			self:_cageNow(player)
		end
	end
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	print(`[ReviveService] ready (toy box at {ReviveConfig.toyBoxPosition})`)
end

return ReviveService
