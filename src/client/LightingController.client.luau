--!strict
-- LightingController — клиентский визуал света от СЕРВЕРНОГО состояния.
-- Читает Workspace.GeneratorPowered: не запитан → мигаем Lighting; запитан → ровно.
-- Изменения Lighting на клиенте НЕ реплицируются — это пер-клиентский визуал (docs/01).

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ATTR_POWERED = "GeneratorPowered"
local ATTR_FLICKERING = "PowerFlickering" -- клиентский маркер режима (для проверки/HUD)

-- Базовые («запитанные») значения освещения — захватываем до любого мигания.
local baseBrightness = Lighting.Brightness
local baseOutdoor = Lighting.OutdoorAmbient
local baseAmbient = Lighting.Ambient

local DARK_AMBIENT = Color3.fromRGB(12, 12, 16)

local flickering = false

local function isPowered(): boolean
	return Workspace:GetAttribute(ATTR_POWERED) == true
end

local function setSteady()
	Lighting.Brightness = baseBrightness
	Lighting.OutdoorAmbient = baseOutdoor
	Lighting.Ambient = baseAmbient
end

local function applyState()
	flickering = not isPowered()
	Lighting:SetAttribute(ATTR_FLICKERING, flickering)
	if not flickering then
		setSteady()
	end
end

-- Флик-петля: пока не запитан — рандомно мигаем яркостью/ambient.
task.spawn(function()
	while true do
		if flickering then
			local lit = math.random() < 0.45
			Lighting.Brightness = if lit then baseBrightness * 0.5 else 0
			Lighting.OutdoorAmbient = if lit then DARK_AMBIENT else Color3.fromRGB(4, 4, 6)
			Lighting.Ambient = DARK_AMBIENT
			task.wait(math.random(4, 16) / 100) -- 0.04–0.16с
		else
			task.wait(0.2)
		end
	end
end)

Workspace:GetAttributeChangedSignal(ATTR_POWERED):Connect(applyState)
applyState()
