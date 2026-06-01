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

-- Флик-петля: пока не запитан — МЯГКОЕ редкое затемнение (комфорт глаз, НЕ строб).
-- Раньше был резкий строб (0↔50% яркости каждые 0.04–0.16с) → заменён на лёгкий dim, медленный, без чёрного.
task.spawn(function()
	while true do
		if flickering then
			-- Лёгкое колебание яркости 82–100% базовой; ambient держим (не уходим в чёрный).
			Lighting.Brightness = baseBrightness * (0.82 + math.random() * 0.18)
			Lighting.OutdoorAmbient = DARK_AMBIENT
			Lighting.Ambient = DARK_AMBIENT
			task.wait(0.5 + math.random() * 0.6) -- 0.5–1.1с (не строб)
		else
			task.wait(0.2)
		end
	end
end)

Workspace:GetAttributeChangedSignal(ATTR_POWERED):Connect(applyState)
applyState()
