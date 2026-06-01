--!strict
-- MapConfig — данные graybox-зала Фазы 0 (серые кубы). Только значения, без логики.
-- Геометрию/цвет менять здесь, не трогая GrayboxBuilder.

local MapConfig = {
	-- Большой спроектированный зал магазина (X * Z), толщина пола = Y. Высокий потолок (анти-клаустрофобия).
	floorSize = Vector3.new(110, 1, 110),
	wallHeight = 28,
	wallThickness = 1,
	-- Серый stylized-plastic для graybox.
	color = Color3.fromRGB(160, 160, 160),
	material = Enum.Material.SmoothPlastic,
	-- SpawnLocation: у ВХОДА (фронт, +Z) — игроки стартуют от входа, идут вглубь магазина.
	spawnSize = Vector3.new(8, 1, 8),
	spawnPosition = Vector3.new(0, 0, 46),
}

return MapConfig
