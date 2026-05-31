-- P0-09: RoundService._onCaught засчитывает поимку ТОЛЬКО во время Night (state-gate).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RoundService = require(ServerScriptService.Server.Services.RoundService)

	beforeEach(function()
		RoundService._caught = false
	end)

	describe("_onCaught (state-gated)", function()
		it("ignores a catch outside Night", function()
			RoundService._state = "Preparation"
			RoundService:_onCaught({ Name = "X" })
			expect(RoundService._caught).to.equal(false)

			RoundService._state = "Morning"
			RoundService:_onCaught({ Name = "X" })
			expect(RoundService._caught).to.equal(false)
		end)

		it("registers a catch during Night", function()
			RoundService._state = "Night"
			RoundService:_onCaught({ Name = "X" })
			expect(RoundService._caught).to.equal(true)
		end)
	end)

	describe("_resolveOutcome (P0-10 transitions)", function()
		it("returns Lost when caught", function()
			RoundService._caught = true
			expect(RoundService:_resolveOutcome()).to.equal("Lost")
		end)

		it("returns Morning when survived", function()
			RoundService._caught = false
			expect(RoundService:_resolveOutcome()).to.equal("Morning")
		end)
	end)

	describe("_setState (P0-10)", function()
		it("updates the server state", function()
			RoundService:_setState("Night")
			expect(RoundService._state).to.equal("Night")
			RoundService:_setState("Morning")
			expect(RoundService._state).to.equal("Morning")
		end)
	end)
end
