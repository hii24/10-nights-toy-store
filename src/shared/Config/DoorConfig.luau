--!strict
-- DoorConfig — данные дверей Фазы 1 (P1-04, graybox). Только значения, без логики.

local repairDuration = 4 -- сек реального удержания для починки

local DoorConfig = {
	-- Двери в зале (пол y=0; высоту по Y задаёт сервис). В стороне от генератора(0,-18)/куклы(18,-18).
	doors = {
		Vector3.new(-18, 0, 8),
		Vector3.new(18, 0, 8),
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
