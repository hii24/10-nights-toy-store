--!strict
-- GeneratorConfig — данные генератора Фазы 0 (graybox). Только значения, без логики.

local GeneratorConfig = {
	-- Положение генератора у дальней стены (пол на y=0; высоту по Y задаёт сервис).
	position = Vector3.new(0, 0, -18),
	size = Vector3.new(6, 6, 3),
	-- Отличимый тёмно-серый «корпус» (не финальный арт).
	color = Color3.fromRGB(90, 96, 110),
	material = Enum.Material.SmoothPlastic,
	prompt = {
		actionText = "Insert battery",
		objectText = "Generator",
		holdDuration = 0,
		maxActivationDistance = 9,
		requiresLineOfSight = false,
	},
	-- Модель питания.
	startPower = 0,
	powerPerBattery = 20,
	maxPower = 100,
	-- P0-06: порог «запитан» и серверный drain питания.
	poweredThreshold = 30,
	drainInterval = 1, -- сек между тиками drain
	drainAmount = 4, -- сколько power снимается за тик
}

return GeneratorConfig
