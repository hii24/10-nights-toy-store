-- P2-08: юниты LightingConfig — пресеты день/ночь валидны и согласованы с арт-библией (docs/08 §3).
-- Ключевые инварианты: день≠ночь, ночь читаема (не чёрный), туман ночью плотнее, alarm не строб, фонарик тёплый.

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LC = require(ReplicatedStorage.Shared.Config.LightingConfig)

	local function luma(c: Color3): number
		return 0.3 * c.R + 0.6 * c.G + 0.1 * c.B
	end

	describe("LightingConfig пресеты (docs/08 §3)", function()
		it("есть три пресета: day / nightPowered / nightDark", function()
			expect(LC.day).to.be.ok()
			expect(LC.nightPowered).to.be.ok()
			expect(LC.nightDark).to.be.ok()
		end)

		it(
			"день ярче запитанной ночи, она ярче ночи-тьмы",
			function()
				expect(LC.day.brightness > LC.nightPowered.brightness).to.equal(true)
				expect(LC.nightPowered.brightness > LC.nightDark.brightness).to.equal(true)
			end
		)

		it("день тёплый (R>B ambient), ночь синяя (B>R ambient)", function()
			expect(LC.day.ambient.R > LC.day.ambient.B).to.equal(true)
			expect(LC.nightPowered.ambient.B > LC.nightPowered.ambient.R).to.equal(true)
			expect(LC.nightDark.ambient.B > LC.nightDark.ambient.R).to.equal(true)
		end)

		it(
			"ночь-тьма читаема: ambient luma >= readabilityFloor > 0 (НЕ слепой чёрный §3.1)",
			function()
				expect(LC.readabilityFloor > 0).to.equal(true)
				expect(luma(LC.nightDark.ambient) >= LC.readabilityFloor).to.equal(true)
			end
		)

		it("туман ночью плотнее и ближе, чем днём", function()
			expect(LC.nightDark.fogEnd < LC.day.fogEnd).to.equal(true)
			expect(LC.nightDark.atmosphereDensity > LC.day.atmosphereDensity).to.equal(true)
		end)

		it(
			"alarm-пульс мягкий (НЕ строб): цикл >= 1.5с, низ яркости >= 0.6 (не в чёрный)",
			function()
				expect(LC.alarm.cycleSeconds >= 1.5).to.equal(true)
				expect(LC.alarm.brightnessMin >= 0.6).to.equal(true)
				expect(LC.alarm.brightnessMax <= 1.0).to.equal(true)
			end
		)

		it(
			"фонарик: Warm White (R>B), разумные угол (0..120) и дальность > 0",
			function()
				expect(LC.flashlight.color.R > LC.flashlight.color.B).to.equal(true)
				expect(LC.flashlight.angle > 0 and LC.flashlight.angle <= 120).to.equal(true)
				expect(LC.flashlight.range > 0).to.equal(true)
			end
		)

		it("переходы заданы и положительны", function()
			expect(LC.transitionTime > 0).to.equal(true)
			expect(LC.powerSwapTime > 0).to.equal(true)
		end)
	end)
end
