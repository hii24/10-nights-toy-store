-- P0-09: security-валидация BatteryService (мусор → сервер отвергает; docs/02).
-- Юниты на публичном API + whitelist пикапа. Моки игрока без живого Knit.Start.

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local BatteryService = require(ServerScriptService.Server.Services.BatteryService)

	local function mockPlayer()
		return {
			Name = "MockPlayer",
			_attrs = {},
			SetAttribute = function(self, key, value)
				self._attrs[key] = value
			end,
		}
	end

	beforeEach(function()
		-- сброс серверного состояния между тестами
		BatteryService._inventory = {}
		BatteryService._batteries = {}
		BatteryService._lastPickup = {}
	end)

	describe("GetCount", function()
		it("returns 0 for an unknown player", function()
			expect(BatteryService:GetCount(mockPlayer())).to.equal(0)
		end)
	end)

	describe("TryConsume bounds (anti-cheat)", function()
		it("rejects non-positive amount, no mutation", function()
			local p = mockPlayer()
			BatteryService._inventory[p] = 3
			expect(BatteryService:TryConsume(p, 0)).to.equal(false)
			expect(BatteryService:TryConsume(p, -5)).to.equal(false)
			expect(BatteryService:GetCount(p)).to.equal(3)
		end)

		it("rejects amount greater than count, no mutation", function()
			local p = mockPlayer()
			BatteryService._inventory[p] = 1
			expect(BatteryService:TryConsume(p, 2)).to.equal(false)
			expect(BatteryService:GetCount(p)).to.equal(1)
		end)

		it("consumes a valid amount and mirrors to the attribute", function()
			local p = mockPlayer()
			BatteryService._inventory[p] = 3
			expect(BatteryService:TryConsume(p, 2)).to.equal(true)
			expect(BatteryService:GetCount(p)).to.equal(1)
			expect(p._attrs.Batteries).to.equal(1)
		end)
	end)

	describe("_tryPickup whitelist", function()
		it("ignores an unregistered prompt (no inventory change)", function()
			local p = mockPlayer()
			BatteryService._inventory[p] = 0
			BatteryService:_tryPickup({}, p) -- prompt отсутствует в реестре _batteries
			expect(BatteryService:GetCount(p)).to.equal(0)
		end)
	end)
end
