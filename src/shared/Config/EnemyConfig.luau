--!strict
-- EnemyConfig — данные врагов (graybox). Только значения, без логики.
-- Mr. Huggy Bear (Фаза 0) + Wind-Up Soldier (P1-02) + Doll Blinker (P1-03).

local EnemyConfig = {
	-- === Mr. Huggy Bear (P0-07/08): большая петля по магазину, ВПЛЕТАЯ проходы у генератора (угроза ядру).
	-- Зал ±55; петля покрывает квадранты + дважды режет центр (плаза генератора), создавая динамичную угрозу.
	waypoints = {
		Vector3.new(38, 0, 38),
		Vector3.new(0, 0, -6), -- проход у генератора
		Vector3.new(-38, 0, 38),
		Vector3.new(-38, 0, -38),
		Vector3.new(0, 0, -6), -- ещё проход у генератора
		Vector3.new(38, 0, -38),
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
	soldierPathA = Vector3.new(0, 0, -40), -- длинный коридор-патруль через центр (ось Z, мимо генератора)
	soldierPathB = Vector3.new(0, 0, 40),
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

	-- === Doll Blinker (P1-03): крадётся в «слепые» тики, замирает под взглядом; безвредна ===
	dollFirstNight = 3, -- появляется с 3-й ночи (раньше — припаркована/неактивна)
	dollStart = Vector3.new(44, 0, -44), -- дальний угол (напротив подсобки)
	dollSize = Vector3.new(2, 3.5, 2), -- «кукольный» силуэт
	dollColor = Color3.fromRGB(225, 215, 205), -- бледный «фарфор», отличимый от медведя/солдата
	dollMaterial = Enum.Material.SmoothPlastic,
	dollSpeed = 16, -- быстро крадётся в слепой тик
	dollViewDotThreshold = 0.5, -- наблюдаема, если look·dir(player→doll) >= 0.5 (конус ~120°)
	dollReachEpsilon = 1.5, -- стоп в этом радиусе от игрока (безвредно, без джиттера)
}

return EnemyConfig
