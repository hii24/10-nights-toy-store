-- P1-04: юнит чистого предиката валидности починки (анти-мгновенно: реальное время удержания).
-- _isHoldValid(elapsed, required, tolerance): boolean — без self, чистая логика.
-- require DoorService безопасен: модуль только регистрирует сервис (KnitStart не запускается).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local DoorService = require(ServerScriptService.Server.Services.DoorService)

	local REQUIRED = 4
	local TOL = 0.85 -- засчитываем при elapsed >= 3.4

	describe("_isHoldValid (anti-instant repair)", function()
		it("accepts a full hold", function()
			expect(DoorService._isHoldValid(REQUIRED, REQUIRED, TOL)).to.equal(true)
		end)

		it("accepts a hold at the tolerance boundary", function()
			expect(DoorService._isHoldValid(REQUIRED * TOL, REQUIRED, TOL)).to.equal(true)
		end)

		it("rejects a hold just under tolerance", function()
			expect(DoorService._isHoldValid(REQUIRED * TOL - 0.1, REQUIRED, TOL)).to.equal(false)
		end)

		it("rejects an instant trigger (zero elapsed)", function()
			expect(DoorService._isHoldValid(0, REQUIRED, TOL)).to.equal(false)
		end)
	end)
end
