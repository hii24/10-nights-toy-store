--!strict
-- EnemyConfig — данные Mr. Huggy Bear (Фаза 0, graybox). Только значения, без логики.

local EnemyConfig = {
	-- Waypoint-петля внутри зала (пол y=0; стены на ±24).
	waypoints = {
		Vector3.new(16, 0, 16),
		Vector3.new(-16, 0, 16),
		Vector3.new(-16, 0, -16),
		Vector3.new(16, 0, -16),
	},
	bearSize = Vector3.new(4, 5, 3),
	bearColor = Color3.fromRGB(120, 74, 56), -- отличимый «медвежий», не финальный арт
	bearMaterial = Enum.Material.SmoothPlastic,
	speedPowered = 9, -- медленнее на свету
	speedDark = 16, -- быстрее в темноте
	reachEpsilon = 2, -- дистанция «нода достигнута»
	catchRadius = 5, -- ловит игрока в этом радиусе (P0-08)
}

return EnemyConfig
