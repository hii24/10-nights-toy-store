--!strict
-- BatteryConfig — данные пикапов-батареек Фазы 0 (graybox). Только значения, без логики.

local BatteryConfig = {
	-- Позиции на полу зала (пол на y=0); высоту по Y задаёт BatteryService.
	positions = {
		Vector3.new(10, 0, 10),
		Vector3.new(-12, 0, 8),
		Vector3.new(6, 0, -14),
		Vector3.new(-9, 0, -10),
		Vector3.new(0, 0, 16),
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
