--!strict
-- DataService — персист Coins/Xp/Level через ProfileStore (P1-08). Серверно (docs/03).
-- Жёсткие правила: сбой загрузки (StartSessionAsync→nil) → КИК (НЕ дефолт — перезатёр бы сейв);
-- сейв на PlayerRemoving + BindToClose; pcall+backoff+сессионные локи — внутри ProfileStore.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local DataConfig = require(Config:WaitForChild("DataConfig"))

-- Вендорнутый ProfileStore (сервер-онли, вне линта).
local ProfileStore =
	require(script.Parent.Parent:WaitForChild("Vendor"):WaitForChild("ProfileStore"))

local KICK_MESSAGE = "Data failed to load. Please rejoin."

local DataService = Knit.CreateService({
	Name = "DataService",
})

-- Серверное состояние (Service [any]:any — поля чисты под --!strict).
DataService._profiles = {} -- [Player] = ProfileStore profile
DataService._loading = {} -- [Player] = true пока StartSessionAsync в полёте (анти-гонка двойной сессии)
-- _store задаётся в KnitStart().

-- Чистый предикат (docs/03): не удалось загрузить (nil) → кикаем, НЕ пускаем с дефолтом.
function DataService._shouldKick(profile: any): boolean
	return profile == nil
end

-- Чистый: уровень от Xp (тестируемо). 1-based; каждые xpPerLevel Xp — +1 уровень.
function DataService._levelForXp(xp: number): number
	return math.floor(xp / DataConfig.xpPerLevel) + 1
end

function DataService:_applyAttributes(player: Player)
	local profile = self._profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Coins", profile.Data.Coins)
	player:SetAttribute("Xp", profile.Data.Xp)
	player:SetAttribute("Level", profile.Data.Level)
end

function DataService:_onPlayerAdded(player: Player)
	if self._profiles[player] or self._loading[player] then
		return -- уже загружен/грузится (анти-гонка: PlayerAdded + early-joiners loop)
	end
	self._loading[player] = true

	local profile = self._store:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players -- игрок ушёл — прекратить попытки сессии
		end,
	})
	self._loading[player] = nil -- загрузка завершена; дальше синхронно (без yield) → атомарно

	-- docs/03: сбой загрузки → НЕ пускать с дефолтом → кик.
	if DataService._shouldKick(profile) then
		player:Kick(KICK_MESSAGE)
		return
	end

	profile:AddUserId(player.UserId) -- GDPR
	profile:Reconcile() -- доливаем недостающие ключи из шаблона

	profile.OnSessionEnd:Connect(function()
		-- Лок украден другим сервером / сессия закрыта — данные тут больше не авторитетны.
		self._profiles[player] = nil
		if player.Parent == Players then
			player:Kick(KICK_MESSAGE)
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession() -- ушёл, пока грузились → не держать лок
		return
	end

	self._profiles[player] = profile
	self:_applyAttributes(player)
end

function DataService:_onPlayerRemoving(player: Player)
	self._loading[player] = nil
	local profile = self._profiles[player]
	if profile then
		profile:EndSession() -- сейв + снятие лока
	end
end

-- API для других сервисов (RoundService): начисление. Серверно, после загрузки профиля.
function DataService:AddCoins(player: Player, amount: number)
	local profile = self._profiles[player]
	if not profile then
		return
	end
	profile.Data.Coins += amount
	self:_applyAttributes(player)
end

function DataService:AddXp(player: Player, amount: number)
	local profile = self._profiles[player]
	if not profile then
		return
	end
	profile.Data.Xp += amount
	profile.Data.Level = DataService._levelForXp(profile.Data.Xp)
	self:_applyAttributes(player)
end

function DataService:GetCoins(player: Player): number
	local profile = self._profiles[player]
	return if profile then profile.Data.Coins else 0
end

function DataService:KnitStart()
	self._store = ProfileStore.New(DataConfig.storeName, DataConfig.profileTemplate)

	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)
	-- Ранние джойнеры (если сервис стартанул уже после входа игрока).
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_onPlayerAdded(player)
		end)
	end

	-- docs/03: сейв на shutdown.
	game:BindToClose(function()
		for _, profile in self._profiles do
			profile:EndSession()
		end
	end)

	print(`[DataService] ready (store {DataConfig.storeName})`)
end

return DataService
