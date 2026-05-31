-- P0-09: security-валидация GeneratorService (вставка отвергается без батарейки / при полном / мёртвом игроке).
-- Юниты на _tryInsert с моком игрока и stub BatteryService; KnitStart не запускается.

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GeneratorService = require(ServerScriptService.Server.Services.GeneratorService)
	local GeneratorConfig = require(ReplicatedStorage.Shared.Config.GeneratorConfig)

	local function alivePlayer()
		return {
			Name = "Mock",
			Character = {
				FindFirstChildOfClass = function(_, className)
					return className == "Humanoid" and { Health = 100 } or nil
				end,
				-- HRP у генератора → проходит серверную distance-проверку (P1-10 Interaction.playerWithin).
				FindFirstChild = function(_, childName)
					return childName == "HumanoidRootPart"
							and { Position = GeneratorConfig.position }
						or nil
				end,
			},
		}
	end

	local function stubBattery(count)
		return {
			GetCount = function()
				return count
			end,
			TryConsume = function()
				return count > 0
			end,
		}
	end

	beforeEach(function()
		GeneratorService._lastInsert = {}
		GeneratorService._power = 0
		-- Стабы зависимостей _tryInsert, добавленных после спеки (KnitInit/KnitStart не запускаются):
		-- _generator (Position) — distance-чек P1-10; _analytics (LogFunnelStep) — funnel-хук P1-09.
		GeneratorService._generator = {
			Position = GeneratorConfig.position,
			SetAttribute = function() end,
		}
		GeneratorService._analytics = { LogFunnelStep = function() end }
	end)

	describe("_tryInsert (anti-cheat)", function()
		it("rejects when the player has no battery (power unchanged)", function()
			GeneratorService._batteryService = stubBattery(0)
			GeneratorService._power = 0
			GeneratorService:_tryInsert(alivePlayer())
			expect(GeneratorService._power).to.equal(0)
		end)

		it("rejects when the generator is full (power unchanged)", function()
			GeneratorService._batteryService = stubBattery(5)
			GeneratorService._power = GeneratorConfig.maxPower
			GeneratorService:_tryInsert(alivePlayer())
			expect(GeneratorService._power).to.equal(GeneratorConfig.maxPower)
		end)

		it("rejects a player without a living character (power unchanged)", function()
			GeneratorService._batteryService = stubBattery(5)
			GeneratorService._power = 0
			GeneratorService:_tryInsert({ Name = "Dead", Character = nil })
			expect(GeneratorService._power).to.equal(0)
		end)
	end)

	describe("_applyPower threshold (P0-10)", function()
		it("sets GeneratorPowered when power >= threshold", function()
			GeneratorService._power = GeneratorConfig.poweredThreshold
			GeneratorService:_applyPower()
			expect(game:GetService("Workspace"):GetAttribute("GeneratorPowered")).to.equal(true)
		end)

		it("clears GeneratorPowered below threshold", function()
			GeneratorService._power = GeneratorConfig.poweredThreshold - 1
			GeneratorService:_applyPower()
			expect(game:GetService("Workspace"):GetAttribute("GeneratorPowered")).to.equal(false)
		end)
	end)

	describe("_tryInsert success (P0-10)", function()
		it("raises power by powerPerBattery on a valid insert", function()
			GeneratorService._batteryService = stubBattery(5)
			GeneratorService._power = 0
			GeneratorService:_tryInsert(alivePlayer())
			expect(GeneratorService._power).to.equal(GeneratorConfig.powerPerBattery)
		end)

		it("caps power at maxPower", function()
			GeneratorService._batteryService = stubBattery(5)
			GeneratorService._power = GeneratorConfig.maxPower - 1
			GeneratorService:_tryInsert(alivePlayer())
			expect(GeneratorService._power).to.equal(GeneratorConfig.maxPower)
		end)
	end)
end
