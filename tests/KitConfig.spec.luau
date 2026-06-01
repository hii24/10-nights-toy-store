-- P2-02: юниты KitConfig — чистый isClearOf + инварианты данных модульного кита.
-- Ключевой инвариант: floor-модули layout НЕ блокируют геймплей-точки (clearance).

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)

	describe("isClearOf (XZ дальше radius от всех точек)", function()
		it("false внутри радиуса", function()
			expect(KitConfig.isClearOf(Vector3.new(3, 0, 0), { Vector3.new(0, 0, 0) }, 5)).to.equal(
				false
			)
		end)
		it("true вне радиуса", function()
			expect(KitConfig.isClearOf(Vector3.new(6, 0, 0), { Vector3.new(0, 0, 0) }, 5)).to.equal(
				true
			)
		end)
		it("true для пустого списка точек", function()
			expect(KitConfig.isClearOf(Vector3.new(0, 0, 0), {}, 5)).to.equal(true)
		end)
		it("игнорирует Y (только XZ)", function()
			expect(KitConfig.isClearOf(Vector3.new(0, 100, 3), { Vector3.new(0, 0, 0) }, 5)).to.equal(
				false
			)
		end)
	end)

	describe("модули кита", function()
		it(
			"непусты и валидны (role ∈ palette, material ∈ materials, mount валиден)",
			function()
				local mounts = { floor = true, ceiling = true, wall = true }
				local count = 0
				for _, module in KitConfig.modules do
					count += 1
					expect(mounts[module.mount]).to.equal(true)
					expect(#module.parts > 0).to.equal(true)
					for _, spec in module.parts do
						expect(KitConfig.palette[spec.role]).to.be.ok()
						expect(KitConfig.materials[spec.material]).to.be.ok()
					end
				end
				expect(count >= 8).to.equal(true) -- когерентный набор
			end
		)
	end)

	describe(
		"buildLayout (спроектированный уровень-магазин)",
		function()
			local layout = KitConfig.buildLayout(55, 55, 28) -- продакшн-размер (MapConfig 110×110×28)

			it("генерирует непустую раскладку", function()
				expect(#layout > 0).to.equal(true)
			end)

			it(
				"каждый плейсмент ссылается на известный модуль",
				function()
					for _, p in layout do
						expect(KitConfig.modules[p.module]).to.be.ok()
					end
				end
			)

			it(
				"floor-модули НЕ блокируют геймплей-точки (clearance)",
				function()
					for _, p in layout do
						local module = KitConfig.modules[p.module]
						if module and module.mount == "floor" then
							expect(
								KitConfig.isClearOf(
									p.position,
									KitConfig.gameplayPoints,
									KitConfig.clearanceRadius
								)
							).to.equal(true)
						end
					end
				end
			)
		end
	)
end
