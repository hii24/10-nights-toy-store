-- P0-09/P1-05: RoundService — поимка в Night → Capture (revive, state-gated); исход ночи по wipe.
-- Стабим _revive (Capture-spy + AreAllBoxed), чтобы тестировать логику RoundService в изоляции.

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RoundService = require(ServerScriptService.Server.Services.RoundService)

	local function stubRevive(allBoxed)
		local captured = {}
		return {
			captured = captured,
			Capture = function(_, player)
				table.insert(captured, player)
			end,
			AreAllBoxed = function()
				return allBoxed
			end,
		}
	end

	describe("_onCaught (state-gated capture)", function()
		it("does not capture outside Night", function()
			RoundService._revive = stubRevive(false)
			RoundService._state = "Preparation"
			RoundService:_onCaught({ Name = "X" })
			RoundService._state = "Morning"
			RoundService:_onCaught({ Name = "X" })
			expect(#RoundService._revive.captured).to.equal(0)
		end)

		it("captures during Night", function()
			RoundService._revive = stubRevive(false)
			RoundService._state = "Night"
			RoundService:_onCaught({ Name = "X" })
			expect(#RoundService._revive.captured).to.equal(1)
		end)
	end)

	describe("_resolveOutcome (wipe -> Lost)", function()
		it("returns Lost on a wipe (all boxed)", function()
			RoundService._revive = stubRevive(true)
			expect(RoundService:_resolveOutcome()).to.equal("Lost")
		end)

		it("returns Morning when not all boxed", function()
			RoundService._revive = stubRevive(false)
			expect(RoundService:_resolveOutcome()).to.equal("Morning")
		end)
	end)

	describe("_setState", function()
		it("updates the server state", function()
			RoundService:_setState("Night")
			expect(RoundService._state).to.equal("Night")
			RoundService:_setState("Morning")
			expect(RoundService._state).to.equal("Morning")
		end)
	end)
end
