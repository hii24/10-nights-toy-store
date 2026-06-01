--!strict
-- LightingController — КЛИЕНТСКИЙ свет день/ночь (P2-08) от серверного состояния (docs/01: не реплицируется).
-- Драйв: Workspace.RoundState (день vs ночь) + Workspace.GeneratorPowered (ночью: питание vs тьма).
-- Пресеты — LightingConfig (docs/08 §3). Ночь-тьма: мягкий Alarm-пульс (синус, НЕ строб — комфорт глаз).

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LightingConfig = require(Shared:WaitForChild("Config"):WaitForChild("LightingConfig"))

local ATTR_STATE = "RoundState"
local ATTR_POWERED = "GeneratorPowered"
local STATE_NIGHT = "Night"

-- Персистентные пер-клиент эффекты (создаём один раз; reuse при ре-ране).
local function ensure(className: string, name: string): Instance
	local inst = Lighting:FindFirstChild(name)
	if not (inst and inst:IsA(className)) then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
	end
	return inst
end
local atmosphere = ensure("Atmosphere", "P2Atmosphere") :: Atmosphere
local colorCorrection =
	ensure("ColorCorrectionEffect", "P2ColorCorrection") :: ColorCorrectionEffect

-- Гарантия §3.1: ночь-тьма не темнее readabilityFloor (CI-spec гейтит сборку; здесь — рантайм-предупреждение).
do
	local a = LightingConfig.nightDark.ambient
	local luma = 0.3 * a.R + 0.6 * a.G + 0.1 * a.B
	if luma < LightingConfig.readabilityFloor then
		warn(
			"[LightingController] nightDark ambient ниже readabilityFloor — ночь может быть слепой (§3.1)"
		)
	end
end

local MODE_DAY = LightingConfig.modeDay
local MODE_NIGHT_POWERED = LightingConfig.modeNightPowered
local MODE_NIGHT_DARK = LightingConfig.modeNightDark

local currentMode: string? = nil

local function presetFor(mode: string)
	if mode == MODE_DAY then
		return LightingConfig.day
	elseif mode == MODE_NIGHT_POWERED then
		return LightingConfig.nightPowered
	end
	return LightingConfig.nightDark
end

local function computeMode(): string
	if Workspace:GetAttribute(ATTR_STATE) == STATE_NIGHT then
		if Workspace:GetAttribute(ATTR_POWERED) == true then
			return MODE_NIGHT_POWERED
		end
		return MODE_NIGHT_DARK
	end
	return MODE_DAY
end

-- В nightDark яркостью (Lighting.Brightness) и тинтом (CC.TintColor) владеет пульс-петля — их НЕ твиним тут.
local function applyMode(mode: string, tweenTime: number)
	local p = presetFor(mode)
	local info = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local isDark = mode == MODE_NIGHT_DARK

	local lightingGoal: { [string]: any } = {
		ClockTime = p.clockTime,
		Ambient = p.ambient,
		OutdoorAmbient = p.outdoorAmbient,
		ColorShift_Top = p.colorShiftTop,
		FogColor = p.fogColor,
		FogEnd = p.fogEnd,
	}
	if not isDark then
		lightingGoal.Brightness = p.brightness
	end
	TweenService:Create(Lighting, info, lightingGoal):Play()

	TweenService:Create(atmosphere, info, {
		Density = p.atmosphereDensity,
		Color = p.atmosphereColor,
		Haze = p.atmosphereHaze,
		Glare = p.atmosphereGlare,
	}):Play()

	local ccGoal: { [string]: any } = {
		Brightness = p.ccBrightness,
		Contrast = p.ccContrast,
		Saturation = 0,
	}
	if not isDark then
		ccGoal.TintColor = p.ccTint
	end
	TweenService:Create(colorCorrection, info, ccGoal):Play()

	currentMode = mode
	Lighting:SetAttribute(LightingConfig.modeAttribute, mode)
end

local function refresh()
	local mode = computeMode()
	if mode == currentMode then
		return
	end
	-- день↔ночь медленно; powered↔dark внутри ночи — быстрее.
	local prev = currentMode
	local bothNight = prev ~= nil and prev ~= MODE_DAY and mode ~= MODE_DAY
	local t = if bothNight then LightingConfig.powerSwapTime else LightingConfig.transitionTime
	applyMode(mode, t)
end

-- Аварийный пульс: мягкий синус (медленный «вдох-выдох»), только в nightDark. Не строб — глаза.
-- Петля — ЕДИНСТВЕННЫЙ владелец Brightness/TintColor в nightDark; плавно ЗАХОДИТ (lerp к таргету) → нет снапа
-- при nightPowered→nightDark (яркость прошлого режима гладко стекает к пульсу, согласно с остальными твинами).
local alarm = LightingConfig.alarm
local nd = LightingConfig.nightDark
task.spawn(function()
	local t = 0
	local step = 0.06
	local omega = (2 * math.pi) / alarm.cycleSeconds
	while true do
		if currentMode == MODE_NIGHT_DARK then
			local s = (math.sin(t * omega) + 1) * 0.5 -- 0..1 плавно
			local targetB = nd.brightness
				* (alarm.brightnessMin + s * (alarm.brightnessMax - alarm.brightnessMin))
			local targetTint = nd.ccTint:Lerp(alarm.color, (1 - s) * alarm.tintIntensity)
			Lighting.Brightness += (targetB - Lighting.Brightness) * 0.15 -- плавный заход (без снапа)
			colorCorrection.TintColor = colorCorrection.TintColor:Lerp(targetTint, 0.15)
			t += task.wait(step) -- фактический elapsed → независимо от FPS
		else
			t = 0
			task.wait(0.2)
		end
	end
end)

Workspace:GetAttributeChangedSignal(ATTR_STATE):Connect(refresh)
Workspace:GetAttributeChangedSignal(ATTR_POWERED):Connect(refresh)

-- Инициализация мгновенно (без твина).
applyMode(computeMode(), 0)
