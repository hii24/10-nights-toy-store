# Claude Progress Log

> Каждый coding-агент: читает этот файл в начале сессии, дописывает запись в конце.
> Формат записи: дата · что сделано · что следующее · известные проблемы · git-коммит.

---

## [INIT] Проект развёрнут — 2026-05-31
- **Сделано:**
  - Окружение Фазы 0: Node nvm default → v22.22.1; Rokit 1.2.0 + тулчейн (rojo 7.5.1, wally 0.3.2, selene 0.29.0, stylua 2.3.0, lune 0.10.4, mantle 0.11.16).
  - Структура выровнена: содержимое kit перенесено в корень репо (.git был уровнем выше).
  - Конфиги в корне: rokit.toml, wally.toml, default.project.json, selene.toml, stylua.toml, .github/workflows/ci.yml.
  - Скаффолд исходников: `src/{server,client,shared/{Config,Net,Types,Util},assets}`, `tests/` (+ `.gitkeep`). Добавлен `.gitignore` (Packages/, build-артефакты, .DS_Store).
  - `init.sh` упрочнён: `rokit install --no-trust-check` + сообщения «не найден» vs «упал» больше не путаются.
  - Смоук-сборка зелёная: `wally install` (7 пакетов) + `rojo build` → game.rbxlx (388 KB); selene/stylua чисто.
- **Следующее:** P0-01 — открыть game.rbxlx в Studio без ошибок (подтвердить сборку end-to-end), затем P0-03 (graybox-спавн). `passes:true` выставлять ТОЛЬКО после проверки в Studio.
- **Известные проблемы:**
  - ProfileStore нет в реестре Wally (официально — manual ModuleScript). Отложен до P1-08: закомментирован в `wally.toml`; подключить вендором/проверенным источником.
  - `selene std="roblox"`: на пустом `src` чисто; при появлении реального Luau убедиться, что roblox-std резолвится.
  - Node default→v22 подхватится в НОВОМ терминале (текущий процесс унаследовал старый PATH).
  - MCP не подключены: Roblox Studio MCP (плейтест) и Context7 (доки) — настроить перед P0-03.
- **Коммит:** `chore: project scaffold + harness` (хеш — в `git log`)

---

<!-- Новые записи добавлять ниже этой строки, сверху вниз по времени -->

## [P0-01] game.rbxlx открывается в Studio без ошибок — 2026-05-31
- **Сделано:**
  - End-to-end проверка в Studio (через computer-use): `game.rbxlx` открыт, **Output чист** — единственная строка «'game.rbxlx' auto-recovery file was created» (служебная Studio, не ошибка). Красных/жёлтых строк нет.
  - Смоук пакетов в Command Bar: `SMOKE Packages= true Knit= true Fusion= true` — папка Packages на месте, Knit/Fusion `require` без ошибок.
  - Сборочный пайплайн повторно зелёный (`init.sh`): rokit + wally (7 пакетов) + Selene 0/0/0 + StyLua чисто + `rojo build` → game.rbxlx (388 KB).
  - Дерево DataModel совпадает с `default.project.json` (ReplicatedStorage.{Shared,Packages}, ServerScriptService.Server, StarterPlayer…Client, Workspace.StreamingEnabled).
  - `P0-01` → `passes:true`.
  - **Мост Studio MCP настроен:** Assistant → «…» → Manage MCP Servers → включён тумблер **«Enable Studio as MCP server»** (статус «2 clients connected»). На стороне Claude Code сервер `roblox-studio` = бундл-бинарь `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` (stdio), конфиг корректный.
- **Следующее:** `P0-03` — graybox-спавн (игрок появляется в серой сцене, камера third-person). `P0-02` (CI) можно параллельно.
- **Известные проблемы:**
  - Инструменты `roblox-studio` MCP **не видны в текущей сессии Claude Code**: прокси стартовал, когда тумблер в Studio был выключен. Лечится **рестартом сессии** (Studio держать открытой с включённым тумблером). Проверить в начале следующей сессии.
  - ProfileStore по-прежнему отложен до `P1-08` (нет в реестре Wally).
- **Коммит:** см. `git log` (P0-01).

---

## [P0-03] Graybox-спавн: игрок в сером зале, third-person — 2026-05-31
- **Сделано:**
  - `src/shared/Config/MapConfig.luau` (ModuleScript, data-driven размеры зала) + `src/server/GrayboxBuilder.server.luau` (серверный Script: идемпотентно строит пол + 4 стены + `SpawnLocation`, серый `SmoothPlastic`, всё `Anchored`).
  - Локально: StyLua формат+check ✓, **Selene 0/0/0** ✓, `rojo build` ✓.
  - Залито в Studio через Rojo live-sync (`rojo serve` :34872 + плагин Connect/Accept). Мост подтвердил: `GrayboxBuilder`=Script в `ServerScriptService.Server`, `MapConfig`=ModuleScript в `ReplicatedStorage.Shared.Config`.
  - **End-to-end плейтест (через MCP `start_stop_play`):** `Graybox=[Floor, Wall1–4, SpawnLocation]` построен; `players=1, char=true, hrpY=4.0` (стоит на полу). Output: `[GrayboxBuilder] graybox built` (Server), ошибок нет. Скриншот: серый зал, аватар со спины = third-person (дефолт Classic).
  - `P0-03` → `passes:true`.
- **Следующее:** `P0-04` — подбор батарейки на полу (Interact → серверный инвентарь сессии). Появится первый RemoteEvent → middleware-валидация (`docs/02`) + вероятно Knit-бутстрап.
- **Известные проблемы:**
  - Graybox строится процедурно при старте плейтеста (в edit-режиме его нет) — ок для Фазы 0; настоящая авторская карта/кит — позже.
  - `get_console_output` по MCP иногда отдаёт неполный/устаревший срез лога — визуальную проверку дублирую скриншотом / `execute_luau`.
- **Коммит:** см. `git log` (P0-03).

---

## [P0-04] Подбор батарейки (Knit BatteryService) — 2026-05-31
- **Сделано:**
  - **Введён Knit:** `src/server/Bootstrap.server.luau` (`Knit.AddServices(Server.Services)` + `Knit.Start`) + `src/server/Services/BatteryService.luau` (первый Knit-сервис) + `src/shared/Config/BatteryConfig.luau` (data-driven). API сверен с Knit 1.7.0.
  - Подбор через **ProximityPrompt** (санкц. `docs/02` стр.18): сервер на `Triggered` валидирует ДО мутации — whitelist (промпт зарегистрирован/не взят), state (игрок жив), **rate-limit** (0.2с/игрок). Дистанция — движком (`MaxActivationDistance`). Провал → `warn` + тихий игнор (без кика).
  - **Сессионный инвентарь серверно:** `self._inventory[player]` + зеркало в `player:SetAttribute("Batteries", n)` (реплицируется в клиент для HUD/проверки).
  - Локально: StyLua + **Selene 0/0/0** + `rojo build` ✓. Синк через Rojo (фикс: адрес `127.0.0.1` вместо `localhost` — macOS резолвил в IPv6 `::1`, Rojo слушал IPv4 → ConnectionClosed).
  - **End-to-end плейтест (MCP):** 5 батареек с промптами заспавнены; подбор (`InputHoldBegin`) → `Batteries` 0→1, батарейка уничтожена, **server-authoritative**; повтор одного промпта → `delta=1` (отвергнут); финал `Batteries=2`, осталось 3.
  - `P0-04` → `passes:true`.
- **Следующее:** `P0-05` — вставка батарейки в генератор повышает питание (`GeneratorService`; первый межсервисный вызов Knit — генератор тратит батарейки игрока).
- **Известные проблемы:**
  - `StreamingEnabled` + клиентский контекст `execute_luau`: части мерцают в стриме — для проверки серверного состояния опираюсь на реплицируемый атрибут (не зависит от стрима) + retry на поиск части.
  - `fireproximityprompt` недоступен в sandbox `execute_luau` (контекст клиента) — триггерю через `InputHoldBegin/End` + телепорт в радиус.
  - Адверсариальные спеки (мусор → отказ) — в `P0-09` (TestEZ).
- **Коммит:** см. `git log` (P0-04).

---

## [P0-05] Вставка батарейки в генератор (GeneratorService, межсервисно) — 2026-05-31
- **Сделано:**
  - 2-й Knit-сервис `src/server/Services/GeneratorService.luau` + `src/shared/Config/GeneratorConfig.luau` (data-driven: позиция/размер/цвет, power-модель start=0 / perBattery=20 / max=100).
  - **Первый межсервисный вызов Knit:** GeneratorService (`KnitInit` → `Knit.GetService`) тратит батарейку через новый публичный API `BatteryService:GetCount/TryConsume` (+ хелпер `_setCount`; поведение подбора не изменилось).
  - Вставка через ProximityPrompt: валидация `docs/02` ДО мутации — жив / генератор не полон / есть батарейка / rate-limit. Питание серверно: `self._power`, зеркало в `Generator.Power/MaxPower` + глобально `Workspace.GeneratorPower` (не стримится — задел для P0-06 свет / P0-07 враг / HUD).
  - Локально: StyLua + **Selene 0/0/0** + `rojo build` ✓. Синк Rojo (`127.0.0.1`).
  - **End-to-end плейтест (MCP):** генератор `Power 0/100`; подбор `B 0→1` → вставка `Power 0→20` + `B 1→0` (межсервисное списание); вставка без батарейки → `Power 20→20` (отвергнута). Server-authoritative.
  - `P0-05` → `passes:true`.
- **Следующее:** `P0-06` — свет мигает при низком питании (клиентский визуал от серверного `Workspace.GeneratorPower`; первый клиентский контроллер).
- **Известные проблемы:** те же (`StreamingEnabled` мерцает части в клиентском `execute_luau` — опора на глобальные/реплицируемые атрибуты; адверсариальные TestEZ-спеки — `P0-09`).
- **Коммит:** см. `git log` (P0-05).

---

## [P0-06] Свет мигает при низком питании (первый клиентский визуал) — 2026-05-31
- **Сделано:**
  - **Сервер:** `GeneratorService._applyPower` выводит `Workspace.GeneratorPowered` (`power >= poweredThreshold=30`); добавлен слабый **drain** (4 power/тик, `task.spawn`-петля по `drainInterval=1с`). `GeneratorConfig`: poweredThreshold/drainInterval/drainAmount.
  - **Клиент (первый!):** `src/client/LightingController.client.luau` — плоский LocalScript: читает `Workspace.GeneratorPowered`, мигает глобальным `Lighting` когда не запитан (рандом Brightness/Ambient), ровно когда запитан; выставляет `Lighting.PowerFlickering`. Изменения Lighting локальны (не реплицируются) — пер-клиентский визуал.
  - Локально: StyLua + **Selene 0/0/0** + `rojo build` ✓. Синк Rojo (`127.0.0.1`).
  - **End-to-end плейтест (MCP, `execute_luau` в клиенте):** старт `power=0 → powered=false → flickering=true`; собрал 2 → вставил → `power=36 powered=true flickering=false` (ровно); **+3.5с drain → `power=24 powered=false flickering=true`** (мигание вернулось). Drain подтверждён (наблюдалось 56→0).
  - `P0-06` → `passes:true`.
- **Следующее:** `P0-07` — Mr. Bear: waypoint-патруль (серверно; скорость зависит от `GeneratorPowered`). `EnemyService` (3-й Knit-сервис).
- **Известные проблемы:** прежние (`StreamingEnabled`, `get_console_output` срез, adversarial TestEZ — `P0-09`). Баланс drain/порога — грубый, тюнинг с ночным таймером `P0-08`.
- **Коммит:** см. `git log` (P0-06).

---

## [P0-07] Mr. Huggy Bear: waypoint-патруль, скорость от питания — 2026-05-31
- **Сделано:**
  - 3-й Knit-сервис `src/server/Services/EnemyService.luau` + `src/shared/Config/EnemyConfig.luau` (4 waypoint-ноды-петля, размер/цвет, `speedDark=16` / `speedPowered=9`).
  - **Кинематический медведь** (Anchored Part): сервер двигает по `RunService.Heartbeat` между нодами (НЕ PathfindingService — `docs/06`); поворот лицом, y фикс; wrap по петле. Скорость каждый шаг от `Workspace.GeneratorPowered`. Публичный `SetActive` — хук для гейтинга в `P0-08`.
  - Зеркала `Workspace.BearSpeed`/`BearWaypoint` (надёжно под `StreamingEnabled`).
  - Локально: StyLua + **Selene 0/0/0** + `rojo build` ✓. Синк Rojo (`127.0.0.1`).
  - **End-to-end плейтест (MCP):** медведь есть; unpowered → `BearSpeed=16`, waypoint `2→3`, прошёл **34.7 студов за 3с** (патруль); запитал (3 батарейки) → `powered=true → BearSpeed=9` (медленнее на свету). Server-authoritative.
  - `P0-07` → `passes:true`.
- **Следующее:** `P0-08` — `RoundService`: одна ночь, таймер выживания 3 мин, экран победы/поражения (ловля медведем → поражение; гейтинг врага через `EnemyService:SetActive`).
- **Известные проблемы:** прежние; баланс скоростей/нод — грубый. Ловля игрока — в `P0-08`.
- **Коммит:** см. `git log` (P0-07).
