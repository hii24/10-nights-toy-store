--!strict
-- FlashlightController — конус фонарика игрока (P2-08). SpotLight (Warm White §3) по направлению камеры.
-- Включён ночью (Workspace.RoundState == "Night") — гарантия навигации в темноте (docs/08 §3.1). Клиентский.
-- Эмиттер идемпотентен (без дублей при ре-ране/телепорте); целится в голову+камеру каждый кадр (переживает respawn).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LightingConfig = require(Shared:WaitForChild("Config"):WaitForChild("LightingConfig"))
local fl = LightingConfig.flashlight

local ATTR_STATE = "RoundState"
local STATE_NIGHT = "Night"
local player = Players.LocalPlayer

-- Невидимый эмиттер со SpotLight (идемпотентно — мирроринг ensure() из LightingController; без дублей).
local function ensureEmitter(): Part
	local existing = Workspace:FindFirstChild("FlashlightEmitter")
	if existing and existing:IsA("Part") then
		return existing
	end
	local p = Instance.new("Part")
	p.Name = "FlashlightEmitter"
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Locked = true
	p.Parent = Workspace
	return p
end
local emitter = ensureEmitter()
local spot = (emitter:FindFirstChildWhichIsA("SpotLight") or Instance.new("SpotLight")) :: SpotLight
spot.Color = fl.color
spot.Angle = fl.angle
spot.Range = fl.range
spot.Brightness = fl.brightness
spot.Shadows = fl.shadows
spot.Face = Enum.NormalId.Front -- конус вдоль -Z части (= LookVector камеры); при инверсии — Back (тюнинг)
spot.Enabled = false
spot.Parent = emitter

-- Кэш «сейчас ночь» (вне горячего RenderStepped; согласовано со стилем LightingController на сигналах).
local nightActive = Workspace:GetAttribute(ATTR_STATE) == STATE_NIGHT
Workspace:GetAttributeChangedSignal(ATTR_STATE):Connect(function()
	nightActive = Workspace:GetAttribute(ATTR_STATE) == STATE_NIGHT
end)

local function getHead(): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	return (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")) :: BasePart?
end

RunService.RenderStepped:Connect(function()
	local head = getHead()
	if not head or not nightActive then
		if spot.Enabled then
			spot.Enabled = false
		end
		return
	end
	local camera = Workspace.CurrentCamera
	local origin = head.Position
	local look = if camera then camera.CFrame.LookVector else head.CFrame.LookVector
	emitter.CFrame = CFrame.lookAt(origin, origin + look)
	if not spot.Enabled then
		spot.Enabled = true
	end
end)
