--!strict
-- UpgradeConfig — сессионные апгрейд-карты Фазы 1 (P1-06, graybox). Только значения, без логики.
-- Эффект = множители от базовых Humanoid-значений; накапливаются за матч (НЕ персистится).

local UpgradeConfig = {
	baseWalkSpeed = 16, -- дефолт Humanoid
	baseJumpPower = 50, -- дефолт Humanoid
	cards = {
		{
			id = "swift",
			name = "Swift",
			desc = "+35% move",
			walkSpeedMult = 1.35,
			jumpPowerMult = 1.0,
		},
		{
			id = "leaper",
			name = "Leaper",
			desc = "+60% jump",
			walkSpeedMult = 1.0,
			jumpPowerMult = 1.6,
		},
		{
			id = "steady",
			name = "Steady",
			desc = "+15% move & jump",
			walkSpeedMult = 1.15,
			jumpPowerMult = 1.15,
		},
	},
}

return UpgradeConfig
