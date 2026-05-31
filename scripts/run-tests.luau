-- scripts/run-tests.luau — P0-10: прогон TestEZ в НАСТОЯЩЕМ движке Roblox через Open Cloud Luau Execution.
-- Публикует свежесобранный плейс, headless-гоняет TestEZ, парсит результат, exit≠0 при провале.
-- Запуск: rojo build --output game.rbxl && OPEN_CLOUD_API_KEY=<key> lune run scripts/run-tests
-- Это Lune-скрипт (НЕ Roblox): использует @lune/* и НЕ линтится roblox-std (вне `selene src`).

local process = require("@lune/process")
local net = require("@lune/net")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local task = require("@lune/task")

local UNIVERSE_ID = "10253418020"
local PLACE_ID = "84110572941861"
local PLACE_FILE = "game.rbxl"
local API_BASE = "https://apis.roblox.com"
local POLL_INTERVAL = 3 -- сек между опросами
local POLL_TIMEOUT = 180 -- общий кап ожидания, сек

local API_KEY = process.env.OPEN_CLOUD_API_KEY
if not API_KEY or API_KEY == "" then
	print("[run-tests] ERROR: env OPEN_CLOUD_API_KEY пуст. (CI: проверь secrets.OPEN_CLOUD_API_KEY)")
	process.exit(1)
end

-- Скрипт, исполняемый ВНУТРИ движка Roblox: запускает TestEZ и возвращает счётчики.
local RUNNER_SCRIPT = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)
local ok, results = pcall(function()
	return TestEZ.TestBootstrap:run({ ServerScriptService.Tests }, TestEZ.Reporters.TextReporter)
end)
if not ok then
	return { errored = true, message = tostring(results) }
end
return {
	errored = false,
	success = results.successCount,
	failure = results.failureCount,
	skipped = results.skippedCount,
}
]==]

local function headers(contentType)
	local h = { ["x-api-key"] = API_KEY }
	if contentType then
		h["Content-Type"] = contentType
	end
	return h
end

local function fail(stage, res)
	print(`[run-tests] {stage} FAILED: HTTP {res.statusCode} {res.statusMessage}`)
	print(`[run-tests] body: {res.body}`)
	process.exit(1)
end

-- 1) Publish: загрузить бинарный билд → номер версии.
local function publishPlace()
	local bytes = fs.readFile(PLACE_FILE)
	print(`[run-tests] publishing {PLACE_FILE} ({#bytes} bytes)...`)
	local url = `{API_BASE}/universes/v1/{UNIVERSE_ID}/places/{PLACE_ID}/versions?versionType=Published`
	local res = net.request({
		url = url,
		method = "POST",
		headers = headers("application/octet-stream"),
		body = bytes,
	})
	if not res.ok then
		fail("PUBLISH", res)
	end
	local data = serde.decode("json", res.body)
	print(`[run-tests] published version {data.versionNumber}`)
	return data.versionNumber
end

-- 2) Execute: создать luau-execution-task против опубликованной версии.
local function createTask(version)
	local url = `{API_BASE}/cloud/v2/universes/{UNIVERSE_ID}/places/{PLACE_ID}/versions/{version}/luau-execution-session-tasks`
	local res = net.request({
		url = url,
		method = "POST",
		headers = headers("application/json"),
		body = serde.encode("json", { script = RUNNER_SCRIPT }),
	})
	if not res.ok then
		fail("CREATE_TASK", res)
	end
	local data = serde.decode("json", res.body)
	print(`[run-tests] task: path={data.path} state={data.state}`)
	return data.path
end

-- 3) Poll: ждать терминального состояния.
local function pollTask(path)
	local url = `{API_BASE}/cloud/v2/{path}`
	local waited = 0
	while waited < POLL_TIMEOUT do
		local res = net.request({ url = url, method = "GET", headers = headers() })
		if not res.ok then
			fail("POLL", res)
		end
		local data = serde.decode("json", res.body)
		if data.state == "COMPLETE" or data.state == "FAILED" or data.state == "CANCELLED" then
			print(`[run-tests] task terminal: {data.state} (after {waited}s)`)
			return data
		end
		task.wait(POLL_INTERVAL)
		waited += POLL_INTERVAL
	end
	print(`[run-tests] POLL timeout after {POLL_TIMEOUT}s`)
	process.exit(1)
	return nil
end

-- 4) Logs (дебаг): печать движкового вывода (warn/print из TestEZ).
local function printLogs(path)
	local res = net.request({ url = `{API_BASE}/cloud/v2/{path}/logs`, method = "GET", headers = headers() })
	if not res.ok then
		print(`[run-tests] (logs unavailable: HTTP {res.statusCode})`)
		return
	end
	local data = serde.decode("json", res.body)
	local logs = data.luauExecutionSessionTaskLogs
	if not logs then
		return
	end
	print("[run-tests] ── engine logs ──")
	for _, entry in logs do
		if entry.messages then
			for _, msg in entry.messages do
				print(`  {msg}`)
			end
		end
	end
	print("[run-tests] ─────────────────")
end

-- main
print(`[run-tests] universe={UNIVERSE_ID} place={PLACE_ID}`)
local version = publishPlace()
local path = createTask(version)
local result = pollTask(path)
printLogs(path)

if result.state ~= "COMPLETE" then
	print(`[run-tests] FAIL: задача завершилась как {result.state} (не COMPLETE)`)
	print(`[run-tests] full: {serde.encode("json", result, true)}`)
	process.exit(1)
end

-- output.results — возвращённое значение скрипта (возможно массив возвратов → берём первый).
local out = result.output and result.output.results
local r = out
if typeof(out) == "table" and out[1] ~= nil then
	r = out[1]
end
if typeof(r) ~= "table" then
	print(`[run-tests] FAIL: нет output.results`)
	print(`[run-tests] full: {serde.encode("json", result, true)}`)
	process.exit(1)
end
if r.errored then
	print(`[run-tests] FAIL: TestEZ errored в движке: {r.message}`)
	process.exit(1)
end

print(`[run-tests] TestEZ: success={r.success} failure={r.failure} skipped={r.skipped}`)
if (r.failure or 0) > 0 then
	print("[run-tests] ❌ есть упавшие тесты")
	process.exit(1)
end
print("[run-tests] ✅ все тесты зелёные (real engine via Open Cloud)")
process.exit(0)
