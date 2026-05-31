-- P1-09: юниты чистых хелперов AnalyticsService (воронка первой сессии).
-- _stepIndex(name): индекс шага воронки (1..N) или nil.
-- _shouldFire(firedSet, name): известный шаг И не зафиксирован → true (дедуп раз-на-игрока).
-- require AnalyticsService безопасен: Log-вызовы в методах, не на top-level (как DataService).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local AnalyticsService = require(ServerScriptService.Server.Services.AnalyticsService)
	local AnalyticsConfig = require(ReplicatedStorage.Shared.Config.AnalyticsConfig)

	describe("воронка first_session (AnalyticsConfig)", function()
		it(
			"содержит ровно 6 шагов в правильном порядке",
			function()
				expect(#AnalyticsConfig.steps).to.equal(6)
				expect(AnalyticsConfig.steps[1]).to.equal("player_joined")
				expect(AnalyticsConfig.steps[6]).to.equal("second_night_started")
			end
		)
	end)

	describe("_stepIndex (name -> 1..N | nil)", function()
		it("даёт 1-based индекс известного шага", function()
			expect(AnalyticsService._stepIndex("player_joined")).to.equal(1)
			expect(AnalyticsService._stepIndex("upgrade_selected")).to.equal(5)
			expect(AnalyticsService._stepIndex("second_night_started")).to.equal(6)
		end)

		it("nil для шага не из воронки", function()
			expect(AnalyticsService._stepIndex("garbage")).to.never.be.ok()
			expect(AnalyticsService._stepIndex("")).to.never.be.ok()
		end)
	end)

	describe("_shouldFire (дедуп раз-на-игрока)", function()
		it(
			"true для известного и ещё не зафиксированного шага",
			function()
				expect(AnalyticsService._shouldFire({}, "player_joined")).to.equal(true)
			end
		)

		it("false для уже зафиксированного шага (дедуп)", function()
			expect(AnalyticsService._shouldFire({ player_joined = true }, "player_joined")).to.equal(
				false
			)
		end)

		it("false для неизвестного шага", function()
			expect(AnalyticsService._shouldFire({}, "garbage")).to.equal(false)
		end)
	end)
end
