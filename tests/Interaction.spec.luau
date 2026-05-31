-- P1-10: юнит чистого ядра Interaction.within (серверная перепроверка дистанции, docs/02).
-- playerWithin (обёртка с HRP-lookup) проверяется e2e/структурно — Player в TestEZ не создать.

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Interaction = require(ReplicatedStorage.Shared.Util.Interaction)

	describe("Interaction.within (|a-b| <= max)", function()
		it("true когда в пределах", function()
			expect(Interaction.within(Vector3.new(0, 0, 0), Vector3.new(3, 0, 0), 5)).to.equal(true)
		end)

		it("true ровно на границе", function()
			expect(Interaction.within(Vector3.new(0, 0, 0), Vector3.new(5, 0, 0), 5)).to.equal(true)
		end)

		it(
			"false когда дальше максимума (анти «через всю карту»)",
			function()
				expect(Interaction.within(Vector3.new(0, 0, 0), Vector3.new(100, 0, 0), 8)).to.equal(
					false
				)
			end
		)

		it("учитывает все оси (3-4-5)", function()
			expect(Interaction.within(Vector3.new(0, 0, 0), Vector3.new(3, 4, 0), 5)).to.equal(true)
			expect(Interaction.within(Vector3.new(0, 0, 0), Vector3.new(3, 4, 0), 4.9)).to.equal(
				false
			)
		end)
	end)
end
