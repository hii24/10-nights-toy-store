-- P2-03: юниты BearConfig — извлечённая/курированная геометрия Mr. Huggy Bear валидна.

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BearConfig = require(ReplicatedStorage.Shared.Config.BearConfig)

	describe("BearConfig (геометрия Mr. Huggy Bear)", function()
		it("части непусты (силуэт-набор)", function()
			expect(#BearConfig.parts >= 10).to.equal(true)
		end)

		it(
			"каждая часть валидна (shape ∈ PartType, material ∈ Material, размеры > 0)",
			function()
				for _, p in BearConfig.parts do
					expect((Enum.PartType :: any)[p.shape]).to.be.ok()
					expect((Enum.Material :: any)[p.material]).to.be.ok()
					expect(p.size.X > 0 and p.size.Y > 0 and p.size.Z > 0).to.equal(true)
				end
			end
		)

		it("scale разумен (0 < scale <= 1)", function()
			expect(BearConfig.scale > 0 and BearConfig.scale <= 1).to.equal(true)
		end)

		it("есть плюш (Fabric) — §8 материал медведя", function()
			local hasFabric = false
			for _, p in BearConfig.parts do
				if p.material == "Fabric" then
					hasFabric = true
				end
			end
			expect(hasFabric).to.equal(true)
		end)
	end)

	describe("BearConfig.mesh (реальный меш по asset ID)", function()
		it("mesh-блок есть: meshId + PBR-карты — строки rbxassetid", function()
			local m = BearConfig.mesh
			expect(m).to.be.ok()
			for _, key in { "meshId", "colorMap", "normalMap", "metalnessMap", "roughnessMap" } do
				expect(typeof(m[key])).to.equal("string")
				expect(string.find(m[key], "rbxassetid://") ~= nil).to.equal(true)
			end
		end)
	end)
end
