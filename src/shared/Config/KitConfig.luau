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
	Vector3.new(0, 0, -18), -- generator
	Vector3.new(-20, 0, 20), -- toy box
	Vector3.new(-18, 0, 8), -- door L
	Vector3.new(18, 0, 8), -- door R
	Vector3.new(10, 0, 10), -- batteries…
	Vector3.new(-12, 0, 8),
	Vector3.new(6, 0, -14),
	Vector3.new(-9, 0, -10),
	Vector3.new(0, 0, 16),
	Vector3.new(0, 0, 0), -- spawn
}
local clearanceRadius = 5 -- floor-модули не ближе этого (XZ) к геймплей-точкам

-- Раскладка магазина. Floor — у стен/в чистых зонах (проверяется isClearOf); wall — на высоте; ceiling — сетка.
local layout: { Placement } = {
	-- Полки вдоль +X стены (x≈21), обходя дверь (18,8) и батарейку (10,10).
	{ module = "shelf", position = Vector3.new(21, 0, -20), rotationY = 90 },
	{ module = "shelf", position = Vector3.new(21, 0, -12), rotationY = 90 },
	{ module = "shelf", position = Vector3.new(21, 0, 0), rotationY = 90 },
	{ module = "shelf", position = Vector3.new(21, 0, 18), rotationY = 90 },
	-- Полки вдоль -X стены (x≈-21), обходя toybox (-20,20) и дверь (-18,8).
	{ module = "shelf", position = Vector3.new(-21, 0, -20), rotationY = 90 },
	{ module = "shelf", position = Vector3.new(-21, 0, -10), rotationY = 90 },
	{ module = "shelf", position = Vector3.new(-21, 0, 0), rotationY = 90 },
	-- Полки вдоль -Z стены (z≈-21), обходя generator (0,-18) и батарейки.
	{ module = "shelf", position = Vector3.new(-16, 0, -22), rotationY = 0 },
	{ module = "shelf", position = Vector3.new(16, 0, -22), rotationY = 0 },
	-- Полки вдоль +Z стены (z≈21), обходя батарейку (0,16).
	{ module = "shelf", position = Vector3.new(-8, 0, 22), rotationY = 0 },
	{ module = "shelf", position = Vector3.new(8, 0, 22), rotationY = 0 },
	-- Касса + аппарат (угол +X/+Z, чисто).
	{ module = "counter", position = Vector3.new(20, 0, 21), rotationY = 0 },
	{ module = "register", position = Vector3.new(20, 0, 21), rotationY = 0 },
	-- Стеллажи-рамы (интерьер, чистые зоны).
	{ module = "rack", position = Vector3.new(13, 0, -8), rotationY = 0 },
	{ module = "rack", position = Vector3.new(-13, 0, 14), rotationY = 0 },
	-- Ящики/коробки (чистые зоны).
	{ module = "crate", position = Vector3.new(14, 0, 18), rotationY = 0 },
	{ module = "crate", position = Vector3.new(-15, 0, -16), rotationY = 20 },
	{ module = "box", position = Vector3.new(-15, 0, -13), rotationY = -15 },
	{ module = "box", position = Vector3.new(13, 0, 20), rotationY = 10 },
	-- Стены: вент, камеры, вывеска (mount=wall, на высоте — не блокируют пол).
	{ module = "vent", position = Vector3.new(-23.4, 9, -6), rotationY = -90 },
	{ module = "vent", position = Vector3.new(23.4, 9, 6), rotationY = 90 },
	{ module = "camera", position = Vector3.new(22, 9, -22), rotationY = 225 },
	{ module = "camera", position = Vector3.new(-22, 9, -22), rotationY = 135 },
	{ module = "neonSign", position = Vector3.new(0, 9, -23.5), rotationY = 0 },
	-- Потолочные лампы (сетка, mount=ceiling).
	{ module = "lamp", position = Vector3.new(-12, 0, -12), rotationY = 0 },
	{ module = "lamp", position = Vector3.new(12, 0, -12), rotationY = 0 },
	{ module = "lamp", position = Vector3.new(-12, 0, 12), rotationY = 0 },
	{ module = "lamp", position = Vector3.new(12, 0, 12), rotationY = 0 },
	{ module = "lamp", position = Vector3.new(0, 0, 0), rotationY = 0 },
}

local KitConfig = {
	palette = palette,
	materials = materials,
	shell = shell,
	modules = modules,
	layout = layout,
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

return KitConfig
