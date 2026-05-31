--!strict
-- RoundConfig — данные раунда Фазы 0 (одна ночь). Только значения, без логики.

local RoundConfig = {
	prepDuration = 5, -- Preparation, сек
	nightDuration = 30, -- Night, сек (graybox; 3 мин = поздний баланс)
	tickInterval = 0.2, -- гранулярность таймера/проверок, сек
}

return RoundConfig
