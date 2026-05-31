--!strict
-- ReviveConfig — данные toy box / revive Фазы 1 (P1-05, graybox). Только значения, без логики.

local ReviveConfig = {
	toyBoxPosition = Vector3.new(-20, 0, 20), -- угол зала, в стороне от генератора/куклы/дверей
	toyBoxSize = Vector3.new(6, 6, 6),
	color = Color3.fromRGB(200, 120, 40), -- «ящик-игрушка», отличимый
	material = Enum.Material.WoodPlanks,
	cageOffset = Vector3.new(0, 3, -5), -- куда телепортить пойманного (перед коробкой, на полу)
	releasePosition = Vector3.new(0, 5, 0), -- куда возвращать освобождённого (центр/спавн)
	freeDuration = 2, -- сек реального удержания, чтобы открыть коробку
	prompt = {
		actionText = "Free teammates",
		objectText = "Toy Box",
		holdDuration = 60, -- большой: промпт не авто-триггерит; завершение считает сервер
		maxActivationDistance = 10,
		requiresLineOfSight = false,
	},
}

return ReviveConfig
