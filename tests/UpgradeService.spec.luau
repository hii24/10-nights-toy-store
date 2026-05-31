-- P1-06: юнит чистого предиката валидности апгрейд-id (type-assert + whitelist).
-- _isValidUpgradeId(id): boolean — без self, чистая логика. (требование /add-validated-remote:
-- спека на отвержение невалидных/мусорных значений RemoteEvent).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local UpgradeService = require(ServerScriptService.Server.Services.UpgradeService)

	describe("_isValidUpgradeId (type-assert + whitelist)", function()
		it("accepts a known card id", function()
			expect(UpgradeService._isValidUpgradeId("swift")).to.equal(true)
		end)

		it("rejects an unknown id (whitelist)", function()
			expect(UpgradeService._isValidUpgradeId("hack")).to.equal(false)
		end)

		it("rejects a non-string id (type-assert)", function()
			expect(UpgradeService._isValidUpgradeId(123)).to.equal(false)
		end)

		it("rejects nil", function()
			expect(UpgradeService._isValidUpgradeId(nil)).to.equal(false)
		end)
	end)
end
