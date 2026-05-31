--!strict
-- RoundConfig — данные матча (Фаза 1: 3 ночи). Только значения, без логики.

local RoundConfig = {
	nightCount = 3, -- ночей в матче
	prepDuration = 5, -- Preparation, сек
	nightDuration = 30, -- Night (за ночь), сек (graybox; 3 мин = поздний баланс)
	morningDuration = 4, -- Morning между ночами, сек
	upgradeDuration = 5, -- Upgrade-фаза (плейсхолдер; карточки → P1-06), сек
	tickInterval = 0.2, -- гранулярность таймера/проверок, сек
}

return RoundConfig
