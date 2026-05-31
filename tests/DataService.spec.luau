-- P1-08: юниты чистых хелперов DataService.
-- _shouldKick(profile): сбой загрузки (nil) → кик (НЕ дефолт; docs/03).
-- _levelForXp(xp): уровень от Xp.
-- require DataService безопасен: ProfileStore.New в KnitStart (не дёргается при require).

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local DataService = require(ServerScriptService.Server.Services.DataService)

	describe("_shouldKick (load failure -> kick, NOT defaults)", function()
		it("kicks when the profile failed to load (nil)", function()
			expect(DataService._shouldKick(nil)).to.equal(true)
		end)

		it("does not kick when the profile loaded", function()
			expect(DataService._shouldKick({ Data = {} })).to.equal(false)
		end)
	end)

	describe("_levelForXp (xpPerLevel=100)", function()
		it("is level 1 at 0 XP", function()
			expect(DataService._levelForXp(0)).to.equal(1)
		end)

		it("stays level 1 just below the threshold", function()
			expect(DataService._levelForXp(99)).to.equal(1)
		end)

		it("levels up exactly at the XP threshold", function()
			expect(DataService._levelForXp(100)).to.equal(2)
		end)

		it("scales with accumulated XP", function()
			expect(DataService._levelForXp(250)).to.equal(3)
		end)
	end)

	-- Доказывает «релог → данные на месте» через mock ProfileStore (без публикации плейса):
	-- сессия загрузила шаблон → записали Coins → EndSession (сейв) → новая сессия → Coins на месте.
	describe("persist round-trip (mock store)", function()
		it("reloads saved Coins across sessions", function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local ProfileStore = require(ServerScriptService.Server.Vendor.ProfileStore)
			local DataConfig = require(ReplicatedStorage.Shared.Config.DataConfig)
			local store = ProfileStore.New("SpecPersist", DataConfig.profileTemplate).Mock
			local key = "rt_" .. tostring(os.clock())

			local p1 = store:StartSessionAsync(key)
			expect(p1).to.be.ok()
			p1:Reconcile()
			p1.Data.Coins = 42
			p1:EndSession()

			local p2 = store:StartSessionAsync(key, { Steal = true })
			expect(p2).to.be.ok()
			expect(p2.Data.Coins).to.equal(42) -- данные пережили EndSession → relog
			p2:EndSession()
		end)
	end)
end
