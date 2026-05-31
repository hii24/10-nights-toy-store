-- scripts/deploy.luau — P1-11: авто-деплой плейса в прод через Open Cloud (на мёрдж в main).
-- Публикует свежесобранный game.rbxl как Published-версию плейса. Гейтится зелёными тестами в CI
-- (джоба deploy: needs lint-build-test). Тот же OPEN_CLOUD_API_KEY (universe-places:write) — без куки/AWS.
-- Запуск: rojo build --output game.rbxl && OPEN_CLOUD_API_KEY=<key> lune run scripts/deploy
-- Lune-скрипт (НЕ Roblox): @lune/*; вне `selene src`.

local process = require("@lune/process")
local net = require("@lune/net")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local UNIVERSE_ID = "10253418020"
local PLACE_ID = "84110572941861"
local PLACE_FILE = "game.rbxl"

local API_KEY = process.env.OPEN_CLOUD_API_KEY
if not API_KEY or API_KEY == "" then
	print("[deploy] ERROR: env OPEN_CLOUD_API_KEY пуст. (CI: проверь secrets.OPEN_CLOUD_API_KEY)")
	process.exit(1)
end

local bytes = fs.readFile(PLACE_FILE)
print(`[deploy] publishing {PLACE_FILE} ({#bytes} bytes) → place {PLACE_ID}...`)

local res = net.request({
	url = `https://apis.roblox.com/universes/v1/{UNIVERSE_ID}/places/{PLACE_ID}/versions?versionType=Published`,
	method = "POST",
	headers = {
		["x-api-key"] = API_KEY,
		["Content-Type"] = "application/octet-stream",
	},
	body = bytes,
})

if not res.ok then
	print(`[deploy] PUBLISH FAILED: HTTP {res.statusCode} {res.statusMessage}`)
	print(`[deploy] body: {res.body}`)
	process.exit(1)
end

local data = serde.decode("json", res.body)
print(`[deploy] ✅ deployed version {data.versionNumber} → place {PLACE_ID} (Published)`)
process.exit(0)
