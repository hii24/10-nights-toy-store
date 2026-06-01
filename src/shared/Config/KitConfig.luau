--!strict
-- KitConfig — данные модульного кита магазина (P2-02). Только значения + чистый хелпер.
-- Стиль по docs/08 (арт-библия): палитра-роли (§2) + материал-семейства (§4). Один template-тип → клоны.
-- Part-based (graybox→content); кастом-меши — drop-in позже (P2-05/P2-07): MeshPart вместо part-спека.

export type PartSpec = {
	offset: Vector3, -- центр части относительно origin модуля
	size: Vector3,
	role: string, -- ключ palette
	material: string, -- ключ materials
}
export type Module = {
	mount: string, -- "floor" | "ceiling" | "wall"
	parts: { PartSpec },
}
export type Placement = {
	module: string,
	position: Vector3, -- origin модуля в мире (XZ; Y — пол/потолок/высота стены)
	rotationY: number, -- градусы вокруг Y
}

-- Палитра-роли (docs/08 §2/§3) → Color3.
local palette: { [string]: Color3 } = {
	neutralLight = Color3.fromRGB(184, 184, 188),
	neutralMid = Color3.fromRGB(138, 138, 144),
	neutralDark = Color3.fromRGB(74, 74, 82),
	warmYellow = Color3.fromRGB(245, 197, 66),
	candyRed = Color3.fromRGB(229, 68, 59),
	toyBlue = Color3.fromRGB(63, 143, 214),
	softGreen = Color3.fromRGB(91, 179, 106),
	plasticPink = Color3.fromRGB(238, 133, 172),
	toyOrange = Color3.fromRGB(224, 138, 58),
	powerCyan = Color3.fromRGB(79, 195, 230),
	steelBlue = Color3.fromRGB(70, 110, 160),
}

-- Материал-семейства (docs/08 §4) → Enum.Material.
local materials: { [string]: Enum.Material } = {
	plastic = Enum.Material.SmoothPlastic,
	cardboard = Enum.Material.Cardboard,
	metal = Enum.Material.Metal,
	neon = Enum.Material.Neon,
}

-- Шелл магазина (стилизованный, из размеров MapConfig — строится в MapBuilder, не клон).
local shell = {
	floorRole = "neutralMid",
	floorMaterial = "plastic",
	wallRole = "neutralLight",
	wallMaterial = "plastic",
	ceilingRole = "neutralDark",
	ceilingMaterial = "plastic",
	stripeRole = "toyBlue", -- декор-полоса по низу стен (узнаваемость магазина)
}

-- Модули кита. Каждый — low-poly Part-набор; origin на полу (floor) / у потолка (ceiling) / у стены (wall).
local modules: { [string]: Module } = {
	-- Полка-стеллаж: 2 стойки + 3 доски + 2 товара-акцента.
	shelf = {
		mount = "floor",
		parts = {
			{
				offset = Vector3.new(-1.4, 2, 0),
				size = Vector3.new(0.2, 4, 1.6),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(1.4, 2, 0),
				size = Vector3.new(0.2, 4, 1.6),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(0, 0.7, 0),
				size = Vector3.new(3, 0.15, 1.6),
				role = "neutralLight",
				material = "plastic",
			},
			{
				offset = Vector3.new(0, 2.0, 0),
				size = Vector3.new(3, 0.15, 1.6),
				role = "neutralLight",
				material = "plastic",
			},
			{
				offset = Vector3.new(0, 3.3, 0),
				size = Vector3.new(3, 0.15, 1.6),
				role = "neutralLight",
				material = "plastic",
			},
			{
				offset = Vector3.new(-0.8, 2.35, 0),
				size = Vector3.new(0.5, 0.5, 0.5),
				role = "warmYellow",
				material = "plastic",
			},
			{
				offset = Vector3.new(0.7, 1.05, 0),
				size = Vector3.new(0.5, 0.5, 0.5),
				role = "toyBlue",
				material = "plastic",
			},
		},
	},
	-- Касса-стойка: тумба + столешница.
	counter = {
		mount = "floor",
		parts = {
			{
				offset = Vector3.new(0, 1.1, 0),
				size = Vector3.new(4, 2.2, 1.4),
				role = "neutralLight",
				material = "plastic",
			},
			{
				offset = Vector3.new(0, 2.3, 0),
				size = Vector3.new(4.4, 0.2, 1.8),
				role = "toyOrange",
				material = "plastic",
			},
		},
	},
	-- Кассовый аппарат: корпус + неон-экран (на столешнице).
	register = {
		mount = "floor",
		parts = {
			{
				offset = Vector3.new(0, 2.8, 0), -- стоит НА столешнице (верх counter ~2.4), не клипит
				size = Vector3.new(1, 0.8, 0.8),
				role = "neutralDark",
				material = "plastic",
			},
			{
				offset = Vector3.new(0, 3.1, 0.3),
				size = Vector3.new(0.7, 0.4, 0.1),
				role = "powerCyan",
				material = "neon",
			},
		},
	},
	-- Стеллаж-рама (высокий): рама из 4 балок.
	rack = {
		mount = "floor",
		parts = {
			{
				offset = Vector3.new(-1.6, 3, 0.7),
				size = Vector3.new(0.2, 6, 0.2),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(1.6, 3, 0.7),
				size = Vector3.new(0.2, 6, 0.2),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(-1.6, 3, -0.7),
				size = Vector3.new(0.2, 6, 0.2),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(1.6, 3, -0.7),
				size = Vector3.new(0.2, 6, 0.2),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(0, 1.5, 0),
				size = Vector3.new(3.4, 0.15, 1.6),
				role = "neutralMid",
				material = "metal",
			},
			{
				offset = Vector3.new(0, 4.5, 0),
				size = Vector3.new(3.4, 0.15, 1.6),
				role = "neutralMid",
				material = "metal",
			},
		},
	},
	-- Ящик (картон): куб + крышка-кант.
	crate = {
		mount = "floor",
		parts = {
			{
				offset = Vector3.new(0, 1, 0),
				size = Vector3.new(2, 2, 2),
				role = "toyOrange",
				material = "cardboard",
			},
			{
				offset = Vector3.new(0, 2.05, 0),
				size = Vector3.new(2.1, 0.2, 2.1),
				role = "neutralDark",
				material = "cardboard",
			},
		},
	},
	-- Коробка (мелкая, картон).
	box = {
		mount = "floor",
		parts = {
			{
				offset = Vector3.new(0, 0.6, 0),
				size = Vector3.new(1.2, 1.2, 1.2),
				role = "toyOrange",
				material = "cardboard",
			},
		},
	},
	-- Вентиляция (на стене): рамка + 3 ламели.
	vent = {
		mount = "wall",
		parts = {
			{
				offset = Vector3.new(0, 0, 0),
				size = Vector3.new(2.4, 1.6, 0.2),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(0, 0.4, 0.05),
				size = Vector3.new(2, 0.18, 0.18),
				role = "neutralMid",
				material = "metal",
			},
			{
				offset = Vector3.new(0, 0, 0.05),
				size = Vector3.new(2, 0.18, 0.18),
				role = "neutralMid",
				material = "metal",
			},
			{
				offset = Vector3.new(0, -0.4, 0.05),
				size = Vector3.new(2, 0.18, 0.18),
				role = "neutralMid",
				material = "metal",
			},
		},
	},
	-- Камера наблюдения (на стене): кронштейн + корпус + объектив.
	camera = {
		mount = "wall",
		parts = {
			{
				offset = Vector3.new(0, 0, -0.1),
				size = Vector3.new(0.3, 0.3, 0.6),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(0, -0.2, 0.5),
				size = Vector3.new(0.7, 0.6, 1),
				role = "neutralLight",
				material = "plastic",
			},
			{
				offset = Vector3.new(0, -0.2, 1.0),
				size = Vector3.new(0.35, 0.35, 0.2),
				role = "powerCyan", -- LED камеры: НЕ candyRed (тот = alarm, §3.2) — системный сигнал «вкл»
				material = "neon",
			},
		},
	},
	-- Потолочная лампа: корпус + неон-панель.
	lamp = {
		mount = "ceiling",
		parts = {
			{
				offset = Vector3.new(0, -0.7, 0), -- свисает ниже потолка (потолок-низ ~11.5), видна
				size = Vector3.new(3, 0.2, 1),
				role = "neutralDark",
				material = "metal",
			},
			{
				offset = Vector3.new(0, -0.85, 0), -- неон-панель под корпусом, видна снизу
				size = Vector3.new(2.7, 0.12, 0.8),
				role = "warmYellow",
				material = "neon",
			},
		},
	},
	-- Неон-вывеска (на стене): подложка + неон-бар.
	neonSign = {
		mount = "wall",
		parts = {
			{
				offset = Vector3.new(0, 0, -0.1),
				size = Vector3.new(5, 1.4, 0.2),
				role = "neutralDark",
				material = "plastic",
			},
			{
				offset = Vector3.new(0, 0, 0.05),
				size = Vector3.new(4.4, 0.8, 0.15),
				role = "candyRed",
				material = "neon",
			},
			{
				offset = Vector3.new(0, -0.5, 0.05),
				size = Vector3.new(4.4, 0.12, 0.15),
				role = "powerCyan",
				material = "neon",
			},
		},
	},
}

-- Геймплей-точки (держать чистыми; синхронно с Battery/Generator/Door/Revive-конфигами).
local gameplayPoints: { Vector3 } = {
	Vector3.new(0, 0, -6), -- generator (центр-плаза)
	Vector3.new(-44, 0, -44), -- toy box (подсобка, дальний угол)
	Vector3.new(0, 0, 16), -- дверь: ворота перед плазой
	Vector3.new(-22, 0, -24), -- дверь: вход в подсобку
	Vector3.new(40, 0, 28), -- батарейки (разнос по зонам)…
	Vector3.new(-40, 0, 24),
	Vector3.new(32, 0, -36),
	Vector3.new(-30, 0, -30),
	Vector3.new(0, 0, 30),
	Vector3.new(0, 0, 46), -- spawn (вход, фронт)
}
local clearanceRadius = 5 -- floor-модули не ближе этого (XZ) к геймплей-точкам

local KitConfig = {
	palette = palette,
	materials = materials,
	shell = shell,
	modules = modules,
	gameplayPoints = gameplayPoints,
	clearanceRadius = clearanceRadius,
}

-- Чистый предикат (тестируемо): pos дальше radius (в плоскости XZ) от ВСЕХ points?
function KitConfig.isClearOf(pos: Vector3, points: { Vector3 }, radius: number): boolean
	for _, p in points do
		local dx = pos.X - p.X
		local dz = pos.Z - p.Z
		if (dx * dx + dz * dz) < radius * radius then
			return false
		end
	end
	return true
end

-- Строит СПРОЕКТИРОВАННЫЙ уровень-магазин (геймдизайн-проход) под зал ~110×110 (±55). Не «коробка с кольцом»,
-- а survival-арена: вход/кассы (фронт) → чокпоинт-ворота → центр-плаза генератора (острова-укрытия) →
-- квадрант-аислы (параллельные ряды = лейны/слепые углы) → подсобка (toy box) в дальнем углу. Floor-модули
-- проходят isClearOf (обходят цели/двери/спавн); сетки (периметр/лампы) адаптивны, зон-позиции — тюнинг.
function KitConfig.buildLayout(halfX: number, halfZ: number, wallHeight: number): { Placement }
	local out: { Placement } = {}
	local function addFloor(module: string, x: number, z: number, rotY: number)
		if KitConfig.isClearOf(Vector3.new(x, 0, z), gameplayPoints, clearanceRadius) then
			table.insert(
				out,
				{ module = module, position = Vector3.new(x, 0, z), rotationY = rotY }
			)
		end
	end
	local function add(module: string, x: number, y: number, z: number, rotY: number)
		table.insert(out, { module = module, position = Vector3.new(x, y, z), rotationY = rotY })
	end
	-- Ряд однотипных floor-модулей вдоль вектора (аисл-сторона / стена-департамент / стена-подсобки).
	local function row(
		module: string,
		x0: number,
		z0: number,
		dx: number,
		dz: number,
		count: number,
		rotY: number
	)
		for i = 0, count - 1 do
			addFloor(module, x0 + dx * i, z0 + dz * i, rotY)
		end
	end

	-- === ПЕРИМЕТР-ДЕПАРТАМЕНТЫ: полки вдоль 4 стен лицом внутрь. clearance авто-режет у целей/дверей/спавна. ===
	local z = -(halfZ - 8)
	while z <= halfZ - 8 do
		addFloor("shelf", halfX - 3, z, 90)
		addFloor("shelf", -(halfX - 3), z, 90)
		z += 12
	end
	local x = -(halfX - 8)
	while x <= halfX - 8 do
		addFloor("shelf", x, halfZ - 3, 0)
		addFloor("shelf", x, -(halfZ - 3), 0)
		x += 12
	end

	-- === ВХОД/КАССЫ (фронт +Z): касса+аппарат по бокам; центр — входной коридор к спавну (0,0,~46). ===
	for _, sx in { -30, -16, 16, 30 } do
		addFloor("counter", sx, halfZ - 9, 0)
		addFloor("register", sx, halfZ - 9, 0)
	end

	-- === ЧОКПОИНТ-СТЕНА перед плазой: полки поперёк z=16, проём в центре = дверь (0,0,16) («ворота»). ===
	for _, sx in { -20, -14, -8, 8, 14, 20 } do
		addFloor("shelf", sx, 16, 0)
	end

	-- === ЦЕНТР-ПЛАЗА генератора (0,0,-6): кольцо островов-укрытий (r≈12) + спилл-коробки (r≈16), лейны между. ===
	local gx, gz = 0, -6
	for idx, deg in { 0, 60, 120, 180, 240, 300 } do
		local rad = math.rad(deg)
		local mod = if idx % 2 == 1 then "rack" else "crate"
		addFloor(mod, gx + 12 * math.cos(rad), gz + 12 * math.sin(rad), deg)
	end
	for _, deg in { 30, 150, 270 } do
		local rad = math.rad(deg)
		addFloor("box", gx + 16 * math.cos(rad), gz + 16 * math.sin(rad), deg)
	end

	-- === КВАДРАНТ-АИСЛЫ: параллельные ряды (лейн между = слепые углы; охота медведя). rotY=90 → длинная ось Z. ===
	for _, ax in { 24, 36 } do
		row("shelf", ax, 24, 0, 7, 3, 90) -- правый-фронт (+X,+Z)
		row("shelf", ax, -18, 0, -9, 4, 90) -- правый-бэк (+X,-Z)
	end
	for _, ax in { -24, -36 } do
		row("shelf", ax, 24, 0, 7, 3, 90) -- левый-фронт (-X,+Z)
	end
	row("shelf", -36, -12, 0, -8, 2, 90) -- левый-бэк (короткий; ниже — подсобка)

	-- === ПОДСОБКА (бэк-лево; toy box (-44,0,-44), вход-дверь (-22,0,-24)): Г-стена + склад-стеллажи. ===
	row("shelf", -30, -26, -6, 0, 4, 0) -- фронт-стена подсобки (проём у двери)
	row("shelf", -26, -32, 0, -6, 4, 90) -- боковая стена
	addFloor("rack", -36, -44, 90)
	addFloor("rack", -50, -34, 0)
	addFloor("crate", -50, -50, 0)
	addFloor("crate", -38, -52, 0)
	addFloor("box", -50, -44, 0)

	-- === ПОТОЛОК: сетка ламп + венты/камеры/неон-вывески (на высоте — пол свободен). ===
	local lx = -(halfX - 10)
	while lx <= halfX - 10 do
		local lz = -(halfZ - 10)
		while lz <= halfZ - 10 do
			add("lamp", lx, 0, lz, 0)
			lz += 22
		end
		lx += 22
	end
	add("vent", -(halfX - 0.6), wallHeight * 0.4, -12, -90)
	add("vent", halfX - 0.6, wallHeight * 0.4, 12, 90)
	add("camera", halfX - 2, wallHeight * 0.7, -(halfZ - 2), 225)
	add("camera", -(halfX - 2), wallHeight * 0.7, -(halfZ - 2), 135)
	add("neonSign", 0, wallHeight * 0.55, -(halfZ - 0.6), 0)
	add("neonSign", 0, wallHeight * 0.55, halfZ - 0.6, 180)

	return out
end

return KitConfig
