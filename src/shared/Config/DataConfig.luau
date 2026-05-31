--!strict
-- DataConfig — данные персистентности Фазы 1 (P1-08, ProfileStore). Только значения, без логики.

local DataConfig = {
	storeName = "PlayerData_v1", -- версионируем имя стора (миграции — сменой версии)
	profileTemplate = {
		Coins = 0,
		Xp = 0,
		Level = 1,
	},
	coinsPerNight = 10, -- за выжитую ночь (Morning)
	xpPerNight = 5,
	coinsPerWin = 30, -- бонус за победу (EndMatch)
	xpPerLevel = 100, -- Xp на один уровень
}

return DataConfig
