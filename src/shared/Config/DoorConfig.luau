--!strict
-- DoorConfig — данные дверей Фазы 1 (P1-04, graybox). Только значения, без логики.

local repairDuration = 4 -- сек реального удержания для починки

local DoorConfig = {
	-- Двери на ЧОКПОИНТАХ (чинишь → режешь путь медведю): перед центр-плазой + вход в подсобку.
	doors = {
		Vector3.new(0, 0, 16), -- ворота перед плазой генератора (фронт)
		Vector3.new(-22, 0, -24), -- вход в подсобку (защита toy box)
	},
	size = Vector3.new(4, 7, 1),
	colorIntact = Color3.fromRGB(70, 140, 80), -- зелёный «целая»
	colorBroken = Color3.fromRGB(170, 60, 55), -- красный «сломана»
	material = Enum.Material.WoodPlanks,
	repairDuration = repairDuration,
	holdTolerance = 1.0, -- сервер считает реальное время; завершить при удержании >= dur*tol
	prompt = {
		actionText = "Repair door",
		objectText = "Door",
		-- Большой: промпт сам НЕ авто-триггерит; завершение считает сервер (repairDuration).
		holdDuration = 60,
		maxActivationDistance = 9,
		requiresLineOfSight = false,
	},
}

return DoorConfig
