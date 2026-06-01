--!strict
-- MapBuilder — строит модульный магазин Фазы 2 (P2-02): стилизованный шелл + кит-модули КЛОНАМИ.
-- Заменяет GrayboxBuilder (шелл + SpawnLocation сохранены — P0-03 не регрессит). Серверно, идемпотентно
-- (пересоздаёт Workspace.Store). Размеры шелла — MapConfig; геометрия/стиль модулей — KitConfig (docs/08).
-- «Один меш → клоны»: каждый тип модуля строится как template Model РАЗ → клонируется по layout.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local MapConfig = require(Config:WaitForChild("MapConfig"))
local KitConfig = require(Config:WaitForChild("KitConfig"))

local STORE_NAME = "Store"

local function colorOf(role: string): Color3
	return KitConfig.palette[role] or KitConfig.palette.neutralMid
end
local function materialOf(mat: string): Enum.Material
	return KitConfig.materials[mat] or Enum.Material.SmoothPlastic
end

local function makePart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.CastShadow = material ~= Enum.Material.Neon -- неон-эмиттеры не кастят тени (физически + перф мобиль)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Шелл: пол + потолок + 4 стены (стилизованы) + декор-полоса по низу стен (идентичность магазина).
local function buildShell(folder: Folder)
	local fs = MapConfig.floorSize
	local h = MapConfig.wallHeight
	local t = MapConfig.wallThickness
	local halfX, halfZ = fs.X / 2, fs.Z / 2

	makePart(
		"Floor",
		fs,
		CFrame.new(0, -fs.Y / 2, 0),
		colorOf(KitConfig.shell.floorRole),
		materialOf(KitConfig.shell.floorMaterial)
	).Parent =
		folder
	makePart(
		"Ceiling",
		Vector3.new(fs.X, t, fs.Z),
		CFrame.new(0, h, 0),
		colorOf(KitConfig.shell.ceilingRole),
		materialOf(KitConfig.shell.ceilingMaterial)
	).Parent =
		folder

	local wallColor = colorOf(KitConfig.shell.wallRole)
	local wallMat = materialOf(KitConfig.shell.wallMaterial)
	local stripeColor = colorOf(KitConfig.shell.stripeRole)
	local stripeMat = materialOf("plastic")
	local walls = {
		{ size = Vector3.new(t, h, fs.Z), cf = CFrame.new(halfX, h / 2, 0) },
		{ size = Vector3.new(t, h, fs.Z), cf = CFrame.new(-halfX, h / 2, 0) },
		{ size = Vector3.new(fs.X, h, t), cf = CFrame.new(0, h / 2, halfZ) },
		{ size = Vector3.new(fs.X, h, t), cf = CFrame.new(0, h / 2, -halfZ) },
	}
	for i, w in ipairs(walls) do
		makePart("Wall" .. i, w.size, w.cf, wallColor, wallMat).Parent = folder
		local stripeSize = if w.size.X > w.size.Z
			then Vector3.new(w.size.X, 0.6, t + 0.05)
			else Vector3.new(t + 0.05, 0.6, w.size.Z)
		makePart(
			"Stripe" .. i,
			stripeSize,
			CFrame.new(w.cf.Position.X, 1.2, w.cf.Position.Z),
			stripeColor,
			stripeMat
		).Parent =
			folder
	end
end

-- Template Model модуля (parts на локальных offset; WorldPivot=identity → PivotTo кладёт parts в origin*offset).
local function buildTemplate(name: string, parts: { any }): Model
	local model = Instance.new("Model")
	model.Name = name
	for i, spec in parts do
		makePart(
			name .. "_" .. i,
			spec.size,
			CFrame.new(spec.offset),
			colorOf(spec.role),
			materialOf(spec.material)
		).Parent =
			model
	end
	model.WorldPivot = CFrame.new()
	return model
end

local function build(): Folder
	local previous = Workspace:FindFirstChild(STORE_NAME)
	if previous then
		previous:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = STORE_NAME

	buildShell(folder)

	-- SpawnLocation у входа (фронт) — MapConfig.spawnPosition.
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "SpawnLocation"
	spawnPad.Size = MapConfig.spawnSize
	local sp = MapConfig.spawnPosition or Vector3.new(0, 0, 0)
	spawnPad.CFrame = CFrame.new(sp.X, MapConfig.spawnSize.Y / 2, sp.Z)
	spawnPad.Anchored = true
	spawnPad.Neutral = true
	spawnPad.Color = colorOf("neutralLight")
	spawnPad.Material = materialOf("plastic")
	spawnPad.Parent = folder

	-- Каждый тип модуля — template РАЗ.
	local templates: { [string]: Model } = {}
	for name, module in KitConfig.modules do
		templates[name] = buildTemplate(name, module.parts)
	end

	-- Клоны по сгенерированной раскладке (адаптивно под размер комнаты). Подпапки по типу модуля.
	local fs = MapConfig.floorSize
	local layout = KitConfig.buildLayout(fs.X / 2, fs.Z / 2, MapConfig.wallHeight)
	local groups: { [string]: Folder } = {}
	for _, placement in layout do
		local module = KitConfig.modules[placement.module]
		local template = templates[placement.module]
		if not module or not template then
			continue
		end
		-- Рантайм-guard (docs/02-стиль): floor-модуль не должен блокировать геймплей-точку.
		if
			module.mount == "floor"
			and not KitConfig.isClearOf(
				placement.position,
				KitConfig.gameplayPoints,
				KitConfig.clearanceRadius
			)
		then
			warn(
				`[MapBuilder] skip {placement.module} @ {placement.position} — слишком близко к геймплею`
			)
			continue
		end
		local group = groups[placement.module]
		if not group then
			group = Instance.new("Folder")
			group.Name = placement.module
			group.Parent = folder
			groups[placement.module] = group
		end
		local originY = placement.position.Y
		if module.mount == "ceiling" then
			originY = MapConfig.wallHeight
		end
		local origin = CFrame.new(placement.position.X, originY, placement.position.Z)
			* CFrame.Angles(0, math.rad(placement.rotationY), 0)
		local clone = template:Clone()
		clone:PivotTo(origin)
		clone.Parent = group
	end

	for _, t in templates do
		t:Destroy() -- template отыграл — клоны построены («один меш → клоны»)
	end

	folder.Parent = Workspace
	return folder
end

build()
print("[MapBuilder] store built from modular kit")
