--!strict
-- AnalyticsConfig — данные воронки первой сессии (P1-09). Только значения + предвычисленный map.
-- Порядок `steps` = funnelStepNumber (1..N). Менять порядок = менять смысл воронки в Dashboard.

local steps = {
	"player_joined", -- 1: зашёл в игру
	"first_battery_picked", -- 2: поднял первую батарейку
	"battery_inserted_generator", -- 3: вставил батарейку в генератор
	"first_night_survived", -- 4: пережил первую ночь
	"upgrade_selected", -- 5: выбрал апгрейд
	"second_night_started", -- 6: началась вторая ночь
}

-- Предвычисленный map name -> индекс (1-based). Чистая производная от `steps`.
local stepIndex: { [string]: number } = {}
for i, name in steps do
	stepIndex[name] = i
end

local AnalyticsConfig = {
	funnelName = "first_session", -- имя кастомной воронки (Creator Dashboard)
	steps = steps, -- упорядоченные шаги
	stepIndex = stepIndex, -- name -> 1..N
}

return AnalyticsConfig
