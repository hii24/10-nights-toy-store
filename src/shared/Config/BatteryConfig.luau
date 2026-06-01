--!strict
-- BatteryConfig — данные пикапов-батареек Фазы 0 (graybox). Только значения, без логики.

local BatteryConfig = {
	-- Разнесены по ЗОНАМ магазина (игроки веерятся; пол на y=0; высоту задаёт BatteryService).
	positions = {
		Vector3.new(40, 0, 28), -- +X+Z: электроника (фронт-право)
		Vector3.new(-40, 0, 24), -- -X+Z: плюш (фронт-лево)
		Vector3.new(32, 0, -36), -- +X-Z: дальний ряд (бэк-право)
		Vector3.new(-30, 0, -30), -- -X-Z: у подсобки (бэк-лево)
		Vector3.new(0, 0, 30), -- центр-фронт: по пути от спавна
	},
	partSize = Vector3.new(1.6, 1.6, 1.6),
	-- Отдельный читаемый graybox-цвет для интерактивов (не финальный арт).
	color = Color3.fromRGB(196, 184, 64),
	material = Enum.Material.SmoothPlastic,
	prompt = {
		actionText = "Pick up",
		objectText = "Battery",
		holdDuration = 0,
		maxActivationDistance = 8,
		requiresLineOfSight = false,
	},
}

return BatteryConfig
