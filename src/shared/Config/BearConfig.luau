--!strict
-- BearConfig — Mr. Huggy Bear (P2-03). РЕАЛЬНЫЙ меш: импортирован из FBX (AI-генерация + авто-риг; 1 skinned-меш,
-- 14.6k трис, 27 костей, PBR base/normal/rough/metal), залит через Studio 3D Importer → asset ID's (блок `mesh` ниже).
-- EnemyService строит MeshPart + SurfaceAppearance по этим ID — ВОСПРОИЗВОДИМО (rojo build / CI / deploy грузят ассеты
-- по ID; как задумано для P2-07). Меш в rest-позе (статичный визуал — кости не реплицируем; риг-анимации drop-in позже).
-- `parts` (ниже) — part-кластер ФОЛБЭК, если меш не загрузится (прежняя AI-экстракция PlushBear; держим как страховку).

export type BearPart = {
	pos: Vector3, -- центр части относительно origin модели (на полу)
	rot: Vector3, -- euler XYZ (рад)
	size: Vector3,
	color: Color3,
	shape: string, -- "Ball" | "Block" | "Cylinder" | …
	material: string, -- "Fabric" | "SmoothPlastic" | …
}

local R0 = Vector3.new(0, 0, 0)

-- 12 силуэт-частей из AI-генерации (точные значения) + 4 конечности по библии.
local parts: { BearPart } = {
	-- Тело/голова (большой плюш-шар).
	{
		pos = Vector3.new(0, 1.530, 0),
		rot = R0,
		size = Vector3.new(3.2, 3.2, 3.2),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	-- Морда-патч (светлее).
	{
		pos = Vector3.new(0, 1.250, -1.150),
		rot = R0,
		size = Vector3.new(1.6, 1.3, 0.9),
		color = Color3.fromRGB(190, 140, 100),
		shape = "Ball",
		material = "Fabric",
	},
	-- Уши: внешние + внутренние.
	{
		pos = Vector3.new(-1.280, 2.570, 0.100),
		rot = R0,
		size = Vector3.new(1.005, 1.005, 1.005),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	{
		pos = Vector3.new(-1.280, 2.570, 0.000),
		rot = R0,
		size = Vector3.new(0.6, 0.6, 0.6),
		color = Color3.fromRGB(190, 140, 100),
		shape = "Ball",
		material = "Fabric",
	},
	{
		pos = Vector3.new(1.280, 2.570, 0.100),
		rot = R0,
		size = Vector3.new(1.005, 1.005, 1.005),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	{
		pos = Vector3.new(1.280, 2.570, 0.000),
		rot = R0,
		size = Vector3.new(0.6, 0.6, 0.6),
		color = Color3.fromRGB(190, 140, 100),
		shape = "Ball",
		material = "Fabric",
	},
	-- Глаза (тёмные пуговицы, глянец).
	{
		pos = Vector3.new(-0.720, 1.850, -1.360),
		rot = R0,
		size = Vector3.new(0.5, 0.5, 0.5),
		color = Color3.fromRGB(20, 20, 20),
		shape = "Ball",
		material = "SmoothPlastic",
	},
	{
		pos = Vector3.new(0.720, 1.850, -1.360),
		rot = R0,
		size = Vector3.new(0.5, 0.5, 0.5),
		color = Color3.fromRGB(20, 20, 20),
		shape = "Ball",
		material = "SmoothPlastic",
	},
	-- Нос (тёмный, глянец).
	{
		pos = Vector3.new(0, 1.500, -1.700),
		rot = R0,
		size = Vector3.new(0.5, 0.4, 0.35),
		color = Color3.fromRGB(35, 30, 30),
		shape = "Ball",
		material = "SmoothPlastic",
	},
	-- Рот (две красные строчки, как в генерации).
	{
		pos = Vector3.new(-0.200, 1.345, -1.590),
		rot = Vector3.new(0, 0, -0.6),
		size = Vector3.new(0.07, 0.07, 0.45),
		color = Color3.fromRGB(130, 40, 40),
		shape = "Block",
		material = "Fabric",
	},
	{
		pos = Vector3.new(0.200, 1.345, -1.590),
		rot = Vector3.new(0, 0, 0.6),
		size = Vector3.new(0.07, 0.07, 0.45),
		color = Color3.fromRGB(130, 40, 40),
		shape = "Block",
		material = "Fabric",
	},
	-- Лапы (нижние шары).
	{
		pos = Vector3.new(-0.660, -2.150, 0),
		rot = R0,
		size = Vector3.new(1.05, 1.05, 1.05),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	{
		pos = Vector3.new(0.660, -2.150, 0),
		rot = R0,
		size = Vector3.new(1.05, 1.05, 1.05),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	-- Руки (по библии — целый силуэт; brown plush).
	{
		pos = Vector3.new(-1.550, 0.700, -0.200),
		rot = R0,
		size = Vector3.new(0.85, 1.5, 0.85),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	{
		pos = Vector3.new(1.550, 0.700, -0.200),
		rot = R0,
		size = Vector3.new(0.85, 1.5, 0.85),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	-- Ноги (между телом и лапами).
	{
		pos = Vector3.new(-0.660, -1.050, 0),
		rot = R0,
		size = Vector3.new(0.95, 1.5, 0.95),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
	{
		pos = Vector3.new(0.660, -1.050, 0),
		rot = R0,
		size = Vector3.new(0.95, 1.5, 0.95),
		color = Color3.fromRGB(150, 95, 60),
		shape = "Ball",
		material = "Fabric",
	},
}

local BearConfig = {
	-- РЕАЛЬНЫЙ меш. EnemyService: геометрия — CreateMeshPartAsync(meshId); ТЕКСТУРЫ (PBR, лицо/мех) — КЛОН
	-- SurfaceAppearance из Rojo-шаблона ReplicatedStorage.Assets.BearMesh (src/assets/BearMesh.model.json; те же
	-- ID — писать ColorMap из game-скрипта запрещено capability). Скейл к высоте EnemyConfig.bearSize.Y. ID ниже —
	-- канонический реестр ассетов (материализован в model.json; spec их валидирует).
	mesh = {
		meshId = "rbxassetid://118956652259780",
		colorMap = "rbxassetid://79130815137165",
		normalMap = "rbxassetid://85704026115859",
		metalnessMap = "rbxassetid://107743567568395",
		roughnessMap = "rbxassetid://130398357961266",
		faceYaw = 0, -- меш смотрит по -Z (= направление движения; подтверждено визуально)
		offsetY = 0, -- доп. вертикальный сдвиг визуала (если стопы не на полу)
		-- Процедурная анимация (EnemyService:_animateBear, без скелетных клипов; всё тюнится).
		-- День (неактивен) = слумп-поза «осел вразвалку»; ночь (активен) = встаёт и медленно переваливается.
		anim = {
			wakeSpeed = 0.9, -- скорость lerp слумп↔стойка (доля/с; ~1.1с на пробуждение/засыпание)
			-- Слумп днём: завалился вперёд/вбок и просел к полу.
			slumpPitch = 0.95, -- рад наклон вперёд (~54°)
			slumpRoll = 0.38, -- рад крен вбок (~22°)
			slumpYaw = 0.5, -- рад доворот (завалился) (~29°)
			slumpDrop = 1.4, -- студы вниз (сел/осел)
			-- Походка ночью (в движении): боб/крен/наклон.
			bobAmplitude = 0.22, -- студы вверх-вниз (переваливание)
			bobPerStud = 0.5, -- фаза синуса на стад пройденного пути (частота шага)
			swayAngle = 0.09, -- рад боковой крен синхронно бобу
			leanBase = 0.06, -- рад базовый наклон вперёд в движении
			leanSpeedBoost = 0.10, -- доп. наклон вперёд масштабом скорости (в темноте → агрессивнее)
			-- Idle ночью (стоит): дыхание.
			idleBobAmplitude = 0.07, -- студы
			idleBobSpeed = 1.5, -- рад/с
		},
	},
	-- === ДВА РИГ-МЕША + ДЕНЬ/НОЧЬ-ТРАНСФОРМАЦИЯ (задумка юзера) ===
	-- День: добрый мишка `good` сидит на старте. Ночь: poof → злой `evil` встаёт и БЕЖИТ (патруль).
	-- Утро: `evil` испаряется где стоит → `good` снова появляется на старте. Модели — InsertService:LoadAsset по ID
	-- (Model-ассеты: меш + кости + AnimationController), анимации — Animator:LoadAnimation по animId. Скелетные
	-- клипы из Mixamo-рига (StandardWalk / TreadmillRunning). Реестр ассетов + параметры (всё тюнится).
	-- ⏳ Интеграция в EnemyService — с восстановленным Studio-мостом (визуал требует живой проверки:
	-- скейл/ориентация/поза-сидя/poof, как было с одиночным мешем).
	rig = {
		good = {
			modelId = "rbxassetid://114125867941672", -- `non` — добрый плюшевый (день, сидит)
			animId = "rbxassetid://83878971247698", -- StandardWalk
		},
		evil = {
			modelId = "rbxassetid://90383731479219", -- `evil` — злой FNAF-style (ночь, бежит)
			animId = "rbxassetid://104289000882591", -- TreadmillRunning
		},
		heightStuds = 6, -- целевая высота рига (скейл LoadAsset-модели)
		-- Поза «сидя» доброго днём (приближённо без sit-клипа: ниже + откинут; точная — Mixamo sit-анимацией позже).
		sitDrop = 1.4, -- студы вниз (осел/сел)
		sitRecline = 0.35, -- рад наклон назад (расслаблен)
		-- Эффект превращения (партикл-вспышка/дым на свапе good↔evil).
		poof = {
			color = Color3.fromRGB(180, 120, 220), -- лилово-дымный (магия превращения)
			count = 40,
			lifetime = 0.6,
		},
		respawnAtStartOnDay = true, -- утром добрый появляется на стартовой (waypoint[1])
	},

	-- ФОЛБЭК part-кластер (если меш/риг не загрузится) — см. `parts` выше.
	parts = parts,
	scale = 0.5, -- bbox 10 → height ~5 (bearSize.Y)
	-- Сдвиг визуала вверх, чтобы стопы стояли на полу (низ был -0.18 → +0.2).
	originOffsetY = 0.2,
}

return BearConfig
