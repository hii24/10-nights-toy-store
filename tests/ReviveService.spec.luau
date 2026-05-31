-- P1-05: юнит чистого предиката wipe (команда уничтожена = все живые игроки в коробках).
-- _isWipe(total, boxed): boolean — без self, чистая логика.
-- require ReviveService безопасен: модуль только регистрирует сервис (KnitStart не запускается).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ReviveService = require(ServerScriptService.Server.Services.ReviveService)

	describe("_isWipe (team wipe condition)", function()
		it("is not a wipe with no players", function()
			expect(ReviveService._isWipe(0, 0)).to.equal(false)
		end)

		it("is not a wipe when someone is still free", function()
			expect(ReviveService._isWipe(2, 1)).to.equal(false)
		end)

		it("is a wipe when all players are boxed", function()
			expect(ReviveService._isWipe(2, 2)).to.equal(true)
		end)

		it("is a wipe for a solo player who is boxed", function()
			expect(ReviveService._isWipe(1, 1)).to.equal(true)
		end)
	end)
end
