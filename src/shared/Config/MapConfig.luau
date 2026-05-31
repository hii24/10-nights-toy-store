--!strict
-- MapConfig — данные graybox-зала Фазы 0 (серые кубы). Только значения, без логики.
-- Геометрию/цвет менять здесь, не трогая GrayboxBuilder.

local MapConfig = {
	-- Компактный прямоугольный зал (X * Z), толщина пола = Y.
	floorSize = Vector3.new(48, 1, 48),
	wallHeight = 12,
	wallThickness = 1,
	-- Серый stylized-plastic для graybox.
	color = Color3.fromRGB(160, 160, 160),
	material = Enum.Material.SmoothPlastic,
	-- Размер SpawnLocation (ставится в центр зала на полу).
	spawnSize = Vector3.new(6, 1, 6),
}

return MapConfig
