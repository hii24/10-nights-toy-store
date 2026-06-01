--!strict
-- LightingConfig — данные света Фазы 2 (P2-08). Пресеты день/ночь по арт-библии docs/08 §2/§3.
-- Только значения, без логики. Свет — КЛИЕНТСКИЙ (LightingController), не реплицируется (docs/01).
-- Цвета строго из библии: Night Neutral / Alarm Red / Warm White / Power Cyan.

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local LightingConfig = {
	-- Плавные переходы: день↔ночь медленно; powered↔dark внутри ночи — быстрее.
	transitionTime = 2.0, -- сек
	powerSwapTime = 0.8, -- сек

	-- Флор читаемости: ночь НИКОГДА не темнее этого (luma ambient) — не уходим в слепой чёрный (§3.1, §6).
	readabilityFloor = 0.05,

	-- День (Preparation/Morning/Upgrade/Intermission): тёплый конфетный «пластиковый» уют (§2).
	day = {
		clockTime = 14.5,
		brightness = 2.2,
		ambient = rgb(120, 112, 100), -- тёплый серый (R>B)
		outdoorAmbient = rgb(150, 138, 120),
		colorShiftTop = rgb(60, 50, 32), -- лёгкий тёплый shift
		fogColor = rgb(228, 220, 205),
		fogEnd = 320, -- лёгкая дымка вдали
		atmosphereDensity = 0.30,
		atmosphereColor = rgb(208, 198, 182),
		atmosphereHaze = 1.2,
		atmosphereGlare = 0,
		ccTint = rgb(255, 250, 244), -- почти нейтраль, чуть тёплая
		ccBrightness = 0,
		ccContrast = 0.04,
	},

	-- Ночь + питание (генератор запитан): синева, но лампы горят — менее страшно, холодный Power-Cyan-tilt.
	nightPowered = {
		clockTime = 0,
		brightness = 1.4,
		ambient = rgb(46, 52, 78), -- синий, но читаемый
		outdoorAmbient = rgb(32, 38, 62),
		colorShiftTop = rgb(20, 30, 55),
		fogColor = rgb(34, 44, 74),
		fogEnd = 150,
		atmosphereDensity = 0.45,
		atmosphereColor = rgb(40, 52, 84),
		atmosphereHaze = 2.0,
		atmosphereGlare = 0.2,
		ccTint = rgb(220, 238, 255), -- чуть Power-Cyan-холодная
		ccBrightness = -0.02,
		ccContrast = 0.06,
	},

	-- Ночь без питания: темно/страшно — deep-blue (Night Neutral §3), плотный туман, Alarm-пульс.
	-- НО не слепо: ambient выше floor + фонарик + аварийки дают навигацию (§3.1). brightness — база под пульс.
	nightDark = {
		clockTime = 0,
		brightness = 0.7,
		ambient = rgb(30, 36, 60), -- deep blue (B>R) — ближе к библии §3, контраст с Night Neutral полом (читаемость §6)
		outdoorAmbient = rgb(20, 26, 44),
		colorShiftTop = rgb(12, 18, 40),
		fogColor = rgb(18, 26, 52),
		fogEnd = 80, -- плотнее (клаустрофобия), но фонарик пробивает
		atmosphereDensity = 0.62,
		atmosphereColor = rgb(22, 30, 58),
		atmosphereHaze = 3.0,
		atmosphereGlare = 0.35,
		ccTint = rgb(255, 245, 245), -- база; пульсирует к Alarm Red
		ccBrightness = -0.06,
		ccContrast = 0.08,
	},

	-- Аварийный пульс (только ночь-тьма): мягкий синус яркости + тинт к Alarm Red. Комфорт глаз — НЕ строб.
	alarm = {
		color = rgb(196, 43, 38), -- Alarm Red (§3)
		tintIntensity = 0.22, -- макс. подмешивание Alarm Red в ColorCorrection.Tint на спаде
		brightnessMin = 0.82, -- множитель к nightDark.brightness (низ дыхания — не в чёрный)
		brightnessMax = 1.0,
		cycleSeconds = 3.0, -- полный «вдох-выдох» аварийки (медленно)
	},

	-- Фонарик игрока (конус): Warm White §3, low-intensity, включён ночью (гарантия навигации §3.1).
	flashlight = {
		color = rgb(255, 233, 194), -- Warm White #FFE9C2
		angle = 55, -- градусы (полный конус SpotLight)
		range = 45,
		brightness = 1.6,
		shadows = false, -- мобильный перф (cone виден как засветка; shadows — тюнинг-хвост)
	},

	-- Маркер режима (Lighting-атрибут) для HUD/тестов.
	modeAttribute = "LightMode",
	modeDay = "Day",
	modeNightPowered = "NightPowered",
	modeNightDark = "NightDark",
}

return LightingConfig
