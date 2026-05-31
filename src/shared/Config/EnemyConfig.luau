--!strict
-- EnemyConfig — данные врагов (graybox). Только значения, без логики.
-- Mr. Huggy Bear (Фаза 0) + Wind-Up Soldier (Фаза 1, P1-02).

local EnemyConfig = {
	-- === Mr. Huggy Bear (P0-07/08): waypoint-петля внутри зала (пол y=0; стены ±24) ===
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

	-- === Wind-Up Soldier (P1-02): линейный патруль, толкает (НЕ летально), шумит ===
	soldierFirstNight = 2, -- появляется со 2-й ночи (раньше — припаркован/неактивен)
	soldierPathA = Vector3.new(0, 0, -16), -- линия патруля через центр зала (ось Z)
	soldierPathB = Vector3.new(0, 0, 16),
	soldierSize = Vector3.new(2, 4, 2), -- меньше медведя, отличимый силуэт
	soldierColor = Color3.fromRGB(70, 110, 160), -- синеватый «жестяной», не медвежий
	soldierMaterial = Enum.Material.Metal,
	soldierSpeed = 12, -- ровная скорость (не зависит от света)
	soldierReachEpsilon = 2, -- дистанция «конец линии достигнут» → разворот
	soldierPushRadius = 6, -- толкает игрока в этом радиусе
	soldierPushForce = 55, -- сила импульса (× масса персонажа), клиент-сторона
	soldierPushUp = 14, -- доп. вертикальный «подброс» импульса
	soldierPushCooldown = 1.5, -- сек между толчками одного игрока (rate-limit)
	soldierNoiseInterval = 0.8, -- сек между шум-пульсами (плейсхолдер аудио)
}

return EnemyConfig
