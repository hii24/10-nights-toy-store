-- P1-02: юнит чистого предиката толчка Wind-Up Soldier (радиус + rate-limit кулдаун).
-- _shouldPush(distance, lastPush, now, radius, cooldown): boolean — без self, чистая логика.
-- require EnemyService безопасен: модуль только регистрирует сервис (KnitStart не запускается).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local EnemyService = require(ServerScriptService.Server.Services.EnemyService)

	local RADIUS = 6
	local COOLDOWN = 1.5

	describe("_shouldPush (radius + cooldown)", function()
		it("pushes a player in range with no prior push", function()
			expect(EnemyService._shouldPush(3, nil, 100, RADIUS, COOLDOWN)).to.equal(true)
		end)

		it("does not push a player out of range", function()
			expect(EnemyService._shouldPush(RADIUS + 0.1, nil, 100, RADIUS, COOLDOWN)).to.equal(
				false
			)
		end)

		it("pushes exactly at the radius boundary", function()
			expect(EnemyService._shouldPush(RADIUS, nil, 100, RADIUS, COOLDOWN)).to.equal(true)
		end)

		it("does not push again within the cooldown window", function()
			-- последний толчок в now=100; сейчас 100.5 → прошло 0.5 < 1.5 → нет.
			expect(EnemyService._shouldPush(1, 100, 100.5, RADIUS, COOLDOWN)).to.equal(false)
		end)

		it("pushes again after the cooldown elapses", function()
			-- последний толчок в now=100; сейчас 102 → прошло 2 >= 1.5 → да.
			expect(EnemyService._shouldPush(1, 100, 102, RADIUS, COOLDOWN)).to.equal(true)
		end)
	end)

	describe("_isLookedAt (Doll Blinker view cone)", function()
		local THRESHOLD = 0.5 -- конус ~120° (как dollViewDotThreshold)
		local forward = Vector3.new(0, 0, -1)

		it("sees the doll straight ahead", function()
			expect(EnemyService._isLookedAt(forward, Vector3.new(0, 0, -10), THRESHOLD)).to.equal(
				true
			)
		end)

		it("does not see the doll to the side (perpendicular)", function()
			expect(EnemyService._isLookedAt(forward, Vector3.new(10, 0, 0), THRESHOLD)).to.equal(
				false
			)
		end)

		it("does not see the doll behind", function()
			expect(EnemyService._isLookedAt(forward, Vector3.new(0, 0, 10), THRESHOLD)).to.equal(
				false
			)
		end)

		it("sees the doll just inside the cone (~50deg)", function()
			expect(EnemyService._isLookedAt(forward, Vector3.new(0.766, 0, -0.643), THRESHOLD)).to.equal(
				true
			)
		end)

		it("does not see the doll just outside the cone (~70deg)", function()
			expect(EnemyService._isLookedAt(forward, Vector3.new(0.940, 0, -0.342), THRESHOLD)).to.equal(
				false
			)
		end)
	end)
end
