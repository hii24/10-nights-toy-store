--!strict
-- GrayboxBuilder — строит серый graybox-зал Фазы 0: пол + 4 стены + SpawnLocation.
-- Серверно и идемпотентно (пересоздаёт Workspace.Graybox). Геометрия — в MapConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local MapConfig = require(Config:WaitForChild("MapConfig"))

local GRAYBOX_NAME = "Graybox"

local function makePart(name: string, size: Vector3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = MapConfig.color
	part.Material = MapConfig.material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function buildGraybox(): Folder
	local previous = Workspace:FindFirstChild(GRAYBOX_NAME)
	if previous then
		previous:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = GRAYBOX_NAME

	local floorSize = MapConfig.floorSize
	local halfX = floorSize.X / 2
	local halfZ = floorSize.Z / 2
	local height = MapConfig.wallHeight
	local thickness = MapConfig.wallThickness

	-- Пол: верхняя грань на y = 0.
	local floor = makePart("Floor", floorSize, CFrame.new(0, -floorSize.Y / 2, 0))
	floor.Parent = folder

	-- 4 стены по периметру, центр на высоте height/2.
	type WallSpec = { size: Vector3, cframe: CFrame }
	local walls: { WallSpec } = {
		{
			size = Vector3.new(thickness, height, floorSize.Z),
			cframe = CFrame.new(halfX, height / 2, 0),
		},
		{
			size = Vector3.new(thickness, height, floorSize.Z),
			cframe = CFrame.new(-halfX, height / 2, 0),
		},
		{
			size = Vector3.new(floorSize.X, height, thickness),
			cframe = CFrame.new(0, height / 2, halfZ),
		},
		{
			size = Vector3.new(floorSize.X, height, thickness),
			cframe = CFrame.new(0, height / 2, -halfZ),
		},
	}
	for index, spec in ipairs(walls) do
		local wall = makePart("Wall" .. index, spec.size, spec.cframe)
		wall.Parent = folder
	end

	-- SpawnLocation в центре зала, на полу.
	local spawnSize = MapConfig.spawnSize
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "SpawnLocation"
	spawnPad.Size = spawnSize
	spawnPad.CFrame = CFrame.new(0, spawnSize.Y / 2, 0)
	spawnPad.Anchored = true
	spawnPad.Neutral = true
	spawnPad.Color = MapConfig.color
	spawnPad.Material = MapConfig.material
	spawnPad.Parent = folder

	folder.Parent = Workspace
	return folder
end

buildGraybox()
print("[GrayboxBuilder] graybox built")
