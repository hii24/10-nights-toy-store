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

---

## [P0-08] RoundService: одна ночь, таймер, победа/поражение (ЯДРО) — 2026-05-31
- **Сделано:**
  - 4-й Knit-сервис `src/server/Services/RoundService.luau` (ядро) + `src/shared/Config/RoundConfig.luau` (`prepDuration=5`, `nightDuration=30` graybox, `tick=0.2`).
  - **Стейт-машина:** `Preparation`(враг спит) → `Night`(враг активен, таймер выживания) → `Morning`(выжил) | `Lost`(пойман). Бродкаст `Workspace.RoundState`/`RoundTimeLeft`.
  - **Гейтинг врага:** `EnemyService` теперь дефолт inactive; `RoundService` включает на `Night`, выключает на исходе. (P0-07-патруль теперь идёт во время `Night` — поведение сохранено, просто под управлением раунда.)
  - **Ловля (межсервисно):** `EnemyService` детектит игрока в `catchRadius=5` → колбэк `SetCaughtCallback` → `RoundService` → `Lost`.
  - **Мин. экран:** `src/client/RoundUiController.client.luau` (ScreenGui) — "SURVIVE - Ns" / "YOU SURVIVED" / "CAUGHT!".
  - Локально: StyLua + **Selene 0/0/0** + `rojo build` ✓. Синк Rojo (`127.0.0.1`).
  - **End-to-end (2 плейтеста, MCP):** **A победа** — Preparation→Night→таймер 30→0→`Morning`, UI "YOU SURVIVED", враг выключен. **B поражение** — в Night телепорт на медведя → `Lost`, UI "CAUGHT!".
  - `P0-08` → `passes:true`.
- **🎯 ВСЯ ГЕЙМПЛЕЙНАЯ ПЕТЛЯ ФАЗЫ 0 СОБРАНА:** спавн → батарейки → генератор → свет → медведь (быстрее в темноте) → пережить ночь = победа / пойман = поражение. Остаются P0-09 (security-тесты) и P0-10 (TestEZ) — харднинг/тесты.
- **Следующее:** `P0-09` — все RemoteEvents/прокси Фазы 0 проходят middleware-валидацию (TestEZ: мусор → отказ). `P0-10` — TestEZ покрытие RoundService/GeneratorService.
- **Известные проблемы:** прежние; `nightDuration=30` graybox (цель 3 мин — одна строка). Терминальный конец раунда (рестарт-петля — `P1-01`).
- **Коммит:** см. `git log` (P0-08).

---

## [P0-02] CI на GitHub Actions — ЗЕЛЁНЫЙ — 2026-05-31
- **Код готов:** `.github/workflows/ci.yml` исправлен — Selene+StyLua+rojo build реальные; тест-шаг (TestEZ via Open Cloud) скипается с notice, пока нет раннера/секрета (реальный прогон → `P0-10`). Локально всё зелёное. Создан репо `hii24/10-nights-toy-store`, ветка `dev` запушена.
- **Блокер (НЕ наш код):** GitHub Actions не стартует — аннотация **`account is locked due to a billing issue`**. Проверено: долга нет ($0), бюджеты заданы ($1, Stop usage Yes), карта добавлена, репо переведён в **public** — lock держится. Это ручной аккаунтный флаг GitHub → снимается только через **GitHub Support**.
- **РЕШЕНО:** карта прошла $1-верификацию → GitHub снял account-lock → CI run **`success`** за 11с (Selene+StyLua+rojo build зелёные; тест-шаг skip-green «deferred to P0-10»). `P0-02` → **`passes:true`**. `dev` пере-синкнут force-push'ем (чистая история).
- **Хвост:** несрочный warning в CI про Node 20 (`actions/checkout@v4`) — обновить на новую версию позже (не падение).
- **Важно:** игра от этого НЕ зависит — сборка/запуск/публикация локальны (Rojo/Studio/Publish to Roblox); CI — автоматизация-удобство. То же касается «зелёных в CI» в `P0-09`/`P0-10` — их суть (TestEZ) можно гонять локально в Studio, отложив только CI-галочку.
- **Коммит:** `399bc77`.

---

## [P0-09] Security-валидация: TestEZ-спеки (мусор → сервер отвергает) — 2026-05-31
- **Сделано:**
  - **Локальный TestEZ-харнесс:** `default.project.json` расширен (`DevPackages`→`ReplicatedStorage.DevPackages`, `tests`→`ServerScriptService.Tests`). 3 спека в `tests/`.
  - **Спеки (docs/02 анти-чит):** `BatteryService` (TryConsume отвергает `amount≤0`/`>count`, GetCount=0, `_tryPickup` whitelist); `GeneratorService` (вставка отвергается без батарейки / при полном / у мёртвого); `RoundService` (`_onCaught` только в `Night`).
  - Локально: StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` (с tests/DevPackages) ✓.
  - **Прогон TestEZ через мост (edit-режим):** `passed=10, failed=0, skipped=0`. Все 3 шага P0-09 (мусор → сервер отвергает → спеки проходят) выполнены.
  - `P0-09` → `passes:true`.
- **Пометка:** прогон **ЛОКАЛЬНЫЙ** (через Studio-мост, edit-режим, плагин-контекст видит серверные модули), не в CI. Реальный TestEZ-в-CI через Open Cloud — это `P0-10` (вариант B, нужен Open Cloud key для CI-части). CI на `src` (Selene/StyLua/rojo build) — зелёный.
- **Следующее:** `P0-10` — TestEZ покрытие (RoundService переходы + GeneratorService) + «зелёные в CI через Open Cloud» (нужен Open Cloud key для CI-части; локальная часть — как тут).
- **Известные проблемы:** `tests/` не линтятся Selene (TestEZ-DSL globals; CI делает только `selene src`); prod-build project без тестов — при шиппинге.
- **Коммит:** см. `git log` (P0-09).

---

## [ПАМЯТКА / ОТЛОЖЕНО] Open Cloud CI (шаг «зелёные в CI через Open Cloud» для P0-10 и P0-09) — 2026-05-31
Решено **отложить** реальный headless-прогон TestEZ в CI (Open Cloud Luau Execution). Подключить **при релизе/публикации**. Локальные TestEZ через Studio-мост (edit-режим) — рабочая альтернатива (так сделан P0-09; так же делаем локальную часть P0-10).
**Что нужно, когда вернёмся (по шагам):**
1. **Опубликовать игру** (Studio → File → Publish to Roblox, personal-use/private достаточно). Прежде — снять блок **Account status: good standing** на `create.roblox.com` → Publishing permissions → Account status → **Start** (был красный «!» для personal use; Identity/Age/2-step — только для 16+/all-ages, для personal не нужны).
2. **Open Cloud API key:** `create.roblox.com/dashboard/credentials` → API Keys → право **Luau Execution**, привязать к experience. Ключ — СЕКРЕТ.
3. **GitHub secret** `OPEN_CLOUD_API_KEY` (репо → Settings → Secrets and variables → Actions). + при необходимости universe/place ID как vars.
4. **Раннер** `scripts/run-tests.luau` (lune + Open Cloud Luau Execution): прогнать TestEZ на опубликованном месте, exit≠0 при фейле.
5. **CI:** тест-шаг в `.github/workflows/ci.yml` уже готов — при наличии секрета **и** `scripts/run-tests.luau` он перестанет скипаться и побежит реально (см. условие `if [ -z "$OPEN_CLOUD_API_KEY" ] || [ ! -f scripts/run-tests.luau ]`).
**Контекст блока:** Open Cloud-путь упирается в аккаунт-настройку (Roblox account-standing + публикация), поэтому для graybox отложен как опциональная автоматизация.

---

## [P0-10 — ЧАСТИЧНО / passes:false] TestEZ-покрытие ядра (локально зелёно) — 2026-05-31
- **Сделано (тест-контент):**
  - Крошечный рефактор: `RoundService` — вынесен `_resolveOutcome()` (исход ночи: `Lost`/`Morning`), поведение не изменено.
  - Спеки: RoundService переходы (`_resolveOutcome` Morning/Lost, `_setState`); GeneratorService power-модель (`_applyPower` порог `GeneratorPowered`; `_tryInsert`-**успех**: рост на `powerPerBattery` + кап на `maxPower`). Расширены `tests/RoundService.spec` + `tests/GeneratorService.spec`.
  - Локально: StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓.
  - **Прогон TestEZ через мост (в свежем place):** `passed=17, failed=0, skipped=0` (10 P0-09 + 7 P0-10). Шаги 1-2 P0-10 (спеки RoundService/GeneratorService) выполнены.
- **`passes:false` (честно):** 3-й шаг «Зелёные в CI через Open Cloud» — **отложен** (см. памятку Open Cloud CI выше). Флипнем `P0-10` (+ ретроспективно `P0-09` в CI), когда поднимем Open Cloud.
- **Грабли (важно для локальных прогонов):** Studio кэширует `require` — после правки модулей нужен **переоткрыть place** (или fresh playtest), иначе TestEZ гоняет старые версии. (Сегодня поймали: правки синкались, но прогон давал старые 10 → переоткрытие game.rbxlx дало 17.)
- **Фаза 0:** **9/10** (геймплей + анти-чит + ядро-покрытие; остаётся только «зелёные в CI через Open Cloud» для `P0-10`/`P0-09`).
- **Коммит:** см. `git log` (P0-10).

---

## [P1-01 — passes:true] Полный цикл из 3 ночей (Preparation/Night/Morning/Upgrade → EndMatch) — 2026-05-31
Первая фича **Фазы 1**. `RoundService` расширен с одной ночи (P0-08) до полного матча из 3 ночей.
- **Сделано:**
  - `RoundConfig`: `nightCount=3`, `morningDuration=4`, `upgradeDuration=5` (graybox; `nightDuration=30` — 3 мин = поздний баланс).
  - `RoundService._runRound` переработан: `Prep → for night=1..3 { _setNight → Night(enemy on, _nightCountdown) → enemy off → _resolveOutcome()==Lost ? Lost+return : Morning → night<3 ? Upgrade } → EndMatch`. Новые состояния `Upgrade`/`EndMatch`, атрибут `RoundNight`. Хелперы `_setNight`/`_countdown`/`_nightCountdown` (досрочный выход по `_caught`). Реюз `_resolveOutcome()` (P0-10).
  - `RoundUiController`: читает `RoundNight`; тексты `NIGHT {n} - SURVIVE {t}s` / `NIGHT {n} SURVIVED` / `UPGRADE... {t}s` / `YOU WON - ALL NIGHTS SURVIVED` / `CAUGHT! (Night {n})`.
  - Враг гейтится по ночам (active только в `Night` через `EnemyService:SetActive`). Всё серверно; клиент только реагирует на атрибуты.
- **End-to-end в Studio (MCP-опрос `RoundState`/`RoundNight`):**
  - **Плейтест A (победа):** `NIGHT 1 - SURVIVE 20s` → захвачено `Morning/N2 → Upgrade/N2 → Night/N3` → `EndMatch/N3`, UI `"YOU WON - ALL NIGHTS SURVIVED"`. Счётчик ночей 1→2→3, Morning+Upgrade между ночами ✓.
  - **Плейтест B (поражение):** во время Night медведь поймал игрока → `state=Lost`, UI `"CAUGHT! (Night 2)"` (терминально) ✓.
  - Консоль — без ошибок наших скриптов (только Studio-тема `StyleRule`).
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓.
- **Грабли (повтор P0-10):** Studio кэширует `require`/Rojo-sync в edit-режиме — для актуального кода переоткрывали `game.rbxlx`. Серверный `execute_luau`-телепорт персонажа ненадёжен (клиентское сетевое владение откатывает позицию) — для ловли двигали анкорного медведя на игрока.
- **Скоуп:** Upgrade-фаза = структурный плейсхолдер (карточки → P1-06). Рестарт/Intermission-петля — позже.
- **Ветка:** `feat/p1-01-three-night-cycle` → мёрдж в `dev`. Коммит — см. `git log`.
- **Следующее:** `P1-02` (Wind-Up Soldier, появляется на Night 2).

---

## [P1-02 — passes:true] Wind-Up Soldier (2-й враг: линейный патруль, толкает, шумит) — 2026-05-31
Вторая фича Фазы 1. Второй враг с дизайн-ролью «помеха» (НЕ летальный, в отличие от медведя). Вся логика в `EnemyService` (docs/01).
- **Сделано:**
  - `EnemyConfig`: блок солдата (`soldierFirstNight=2`, путь A↔B `(0,0,-16)`↔`(0,0,16)`, `soldierSpeed=12`, `soldierPushRadius=6`, `soldierPushForce/Up`, `soldierPushCooldown=1.5`, `soldierNoiseInterval=0.8`).
  - `EnemyService`: `_buildSoldier` (anchored, CanCollide=false), `SetSoldierActive`, `_stepSoldier` (ping-pong патруль A↔B + детект пуша + шум-пульс), `_pushPlayer` (атрибуты на Player), чистый `_shouldPush(distance,lastPush,now,radius,cooldown)`. Heartbeat зовёт `_step`(медведь)+`_stepSoldier`. Чистка `_lastPush` на PlayerRemoving.
  - `RoundService`: гейт `SetSoldierActive(night >= soldierFirstNight)` в ночном цикле.
  - `SoldierController.client.luau` (НОВЫЙ): слушает `SoldierPushTick` на LocalPlayer → `HRP:ApplyImpulse` (knockback своему персонажу — ownership-safe).
  - `tests/EnemyService.spec.luau` (НОВЫЙ): 5 юнитов `_shouldPush` (радиус + кулдаун).
- **Толчок (ownership-safe, важно):** сервер — авторитет (детект в радиусе + rate-limit) → ставит атрибуты `SoldierPushTick/X/Z` на Player → клиент применяет импульс СВОЕМУ персонажу. Серверный пуш чужого персонажа откатывается сетевым владением (грабли из P1-01) — поэтому через клиент. Без RemoteEvent (атрибут-broadcast, как Фаза 0).
- **End-to-end в Studio (MCP, медведь отодвигался для изоляции):**
  - **Night 1:** `SoldierActive=false`, припаркован на `(0,2,-16)`, `moved_in_3s=0.000` ✓.
  - **Night 2:** `SoldierActive=true`; Z-трек `13→-14`(разворот у pathA)`→7` — линейный ping-pong ✓; `SoldierNoisePulse` растёт ✓.
  - **Толчок:** `pushCountΔ=1`, на Player `tick/X/Z` выставлены, **HRP-скорость пик 50.8** (тонкая выборка 0.05с) → клиент-импульс работает; игрок смещается ✓; кулдаун держит. Раньше казалось «0.1» — артефакт грубой выборки 0.25с.
  - **Не летален:** под толчками (медведь отодвинут) дошли до `EndMatch`, `everLost=false` ✓. (Эмерджентно: без изоляции солдат может толкнуть игрока в медведя → Lost — это фича, не баг.)
  - Консоль — без ошибок наших скриптов.
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ через мост: passed=22 failed=0** (17 + 5 новых).
- **Заметка по dev-loop:** в этот раз **Rojo Connect сработал** (адрес `127.0.0.1`, не `localhost`) и дал свежий require-кэш — переоткрывать `game.rbxlx` НЕ пришлось.
- **Скоуп:** «шумит» = плейсхолдер-пульс (реальное аудио — asset-фаза). «Мешает ремонту» — литерально с P1-04 (ремонт ещё нет); пуш — примитив помехи.
- **Ветка:** `feat/p1-02-windup-soldier` → мёрдж в `dev`. Коммит — см. `git log`.
- **Следующее:** `P1-03` (Doll Blinker — движется только когда не смотрят; сервер: look-вектор + LOS).

---

## [P1-03 — passes:true] Doll Blinker (3-й враг: «weeping-angel», движется в слепые тики) — 2026-05-31
Завершает набор врагов MVP (медведь + 2 мелких). Новая **механика наблюдения**, не урон. Решения: **безвредна** (creep/freeze, летальность позже), **с Night 3** (эскалация N1→N2→N3 = +1 враг/ночь).
- **Сделано:**
  - `EnemyConfig`: блок куклы (`dollFirstNight=3`, `dollStart=(18,0,-18)`, `dollSpeed=16`, `dollViewDotThreshold=0.5` ≈ конус 120°, `dollReachEpsilon=1.5`).
  - `EnemyService`: `_buildDoll` (anchored, CanCollide=false), `SetDollActive`, `_stepDoll` (наблюдение → freeze / в слепой тик → к ближайшему игроку), `_isDollObserved` (угол+LOS по игрокам), `_dollHasLOS` (рейкаст), `_nearestPlayerHrp`, чистый `_isLookedAt(lookVector,dirToDoll,dot)`. Heartbeat шагает 3 врагов. Бродкаст `DollActive`/`DollObserved`.
  - `RoundService`: гейт `SetDollActive(night >= dollFirstNight)`.
  - `tests/EnemyService.spec`: +5 юнитов `_isLookedAt` (конус: перед/перпендикуляр/сзади/±граница).
- **Сервер-авторитет, без клиент-данных:** «взгляд» = `HRP.CFrame.LookVector` (серверно, анти-чит — клиент не спуфит «смотрю»). Фонарика/камеро-передачи нет (отложено). LOS-рейкаст реализован (в открытом зале почти всегда чист → правит угол).
- **End-to-end в Studio (поворотом игрока — см. грабли):** на Night 1 (врем. `dollFirstNight=1`, изоляция): лицом к кукле → `DollObserved=true`, `dollMoved=0.00` (freeze ✓); спиной → `DollObserved=false`, дистанция `19.5→2.7` (крадётся ✓); безвредна — дошла, `state=Night` (НЕ Lost ✓). Гейт: на Night 1 при `dollFirstNight=3` → `DollActive=false` ✓; активная-ветка (`DollActive=true`) проверена при `=1`; порог `>=3` — код-паритет с гейтом солдата (дважды проверен). `dollFirstNight` возвращён на 3.
- **🔑 Грабли (ВАЖНО, ново):** **`execute_luau` в play-режиме исполняется на КЛИЕНТЕ** (`IsServer=false IsClient=true`; ServerScriptService пуст для клиента → серверные сервисы не доступны). Поэтому: (1) двигать анкорных серверных врагов/куклу из execute_luau **нельзя** (клиент-локально, сервер не видит) — прошлые «парковки» врагов в P1-01/02 работали как побочный эффект/совпадение; (2) надёжный рычаг — **поворот/телепорт клиент-владеемого персонажа** (реплицируется на сервер). Куклу тестировал поворотом ИГРОКА к ней/от неё, а не перемещением куклы.
- **Грабли (повтор):** edit-режимный TestEZ после правок модулей кэширует `require` — переоткрыл `game.rbxlx` для свежего кэша (прогон дал 22 → после переоткрытия 27).
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ: passed=27 failed=0** (22 + 5).
- **Скоуп:** летальность/эффект куклы — позже; стан фонариком, реальный конус камеры — позже.
- **Ветка:** `feat/p1-03-doll-blinker` → мёрдж в `dev`. Коммит — см. `git log`.
- **Враги MVP готовы (3/3).** **Следующее:** `P1-04` (repair дверей: hold-to-repair, серверный счёт, rate-limit).

---

## [P1-04 — passes:true] Repair дверей (hold-to-repair, серверный счёт прогресса, анти-мгновенно) — 2026-05-31
Первая «защитная» механика для игроков. Новый `DoorService` по образцу `GeneratorService`.
- **Сделано:**
  - `DoorConfig` (НОВЫЙ): 2 двери `(±18,0,8)`, размеры/цвета (intact зелёный / broken красный), `repairDuration=4`, `holdTolerance=1.0`, `prompt.holdDuration=60`.
  - `DoorService` (НОВЫЙ): `_buildDoors` (Part+ProximityPrompt, prompt off), `_setBroken` (атрибут `Broken`+цвет+prompt.Enabled), `_breakAll`/`_resetAll`, hold-репэйр (`PromptButtonHoldBegan`→старт, `_updateProgress` Heartbeat считает+завершает, `PromptButtonHoldEnded`→сброс при раннем релизе), чистый `_isHoldValid`. Слушает `Workspace.RoundState` → на Night ломает двери, иначе восстанавливает (decoupled, без правок RoundService). Авто-регистрация через `Bootstrap.AddServices(folder)`.
  - `tests/DoorService.spec` (НОВЫЙ): 4 юнита `_isHoldValid` (анти-мгновенно).
- **Серверная авторитетность (docs/02):** сервер сам копит прогресс по РЕАЛЬНОМУ времени удержания (`os.clock()` от HoldBegan) и завершает при `elapsed >= repairDuration`. НЕ зависит от `prompt.Triggered`. Клиент не может доделать быстрее `repairDuration`. Бродкаст `RepairProgress` (для HUD/проверки).
- **End-to-end в Studio (execute_luau КЛИЕНТСКИЙ → телепорт игрока + `prompt:InputHoldBegin/End`):**
  - На Night: дверь `Broken=true`, `prompt.Enabled=true` ✓.
  - **Успех:** игрок к стене-стороне двери (7 студов от пути медведя — безопасно), `InputHoldBegin` → `RepairProgress 0→1.00` (сервер считал) → `Broken=false` (починена сервером на 4с) ✓.
  - **Анти-мгновенно:** `InputHoldBegin`→`InputHoldEnd` через 1.3с (< 4с) → `progMid=0.32`→`0.00` (сброс), `Broken=true` (НЕ доделать быстро) ✓.
  - Консоль без ошибок.
- **🔑 Грабли (новое):** программный `prompt:InputHoldBegin()` **НЕ вызывает `Triggered`** как реальный ввод (на HoldDuration срабатывает `HoldEnded` вместо/раньше `Triggered`, сбрасывая прогресс). Поэтому завершение через `Triggered` не годилось — переделал на server-accumulate (сервер сам завершает по накопленному прогрессу, `prompt.HoldDuration=60` чтоб промпт не авто-триггерил). Это и надёжнее против чита. Тест дверей: игрок безопасен от медведя на стене-стороне (x=±23, ≥7 студов от пути ±16; 6 студов не хватало — ловило между вызовами).
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ: passed=31 failed=0** (27 + 4; без переоткрытия — DoorService новый, кэш старого валиден).
- **Скоуп:** последствия сломанных дверей (враги сквозь/drain), прогрессивная поломка, HUD-бар (P1-07), персист частичного прогресса, непрерывность удержания против suppressed-HoldEnded — позже.
- **Ветка:** `feat/p1-04-door-repair` → мёрдж в `dev`. Коммит — см. `git log`.
- **Следующее:** `P1-05` (Revive: пойманный → toy box, тиммейт освобождает).

---

## [P1-05 — passes:true] Revive / Toy Box (пойманный → коробка; тиммейт освобождает) — 2026-05-31
Кооп-механика второго шанса: поимка медведем больше НЕ мгновенный Lost. Новый `ReviveService`.
- **Сделано:**
  - `ReviveConfig` (НОВЫЙ): toy box `(-20,0,20)`, клетка (cageOffset), `freeDuration=2`, prompt holdDuration=60.
  - `ReviveService` (НОВЫЙ): `Capture` (флаг InToyBox + `_cageNow`: анкор HRP + телепорт в клетку), `_release`/`FreeAll` (разанкор + телепорт к спавну), `AreAllBoxed`/`_isWipe`, `_canRescue` (жив + НЕ в коробке), server-accumulate hold открытия коробки (как DoorService) → FreeAll, бродкаст `BoxedCount`/`InToyBox`. Авто-регистрация.
  - `RoundService` (ИЗМЕНЁН): caught-колбэк → `_onCaught` → `_revive:Capture` (только в Night); `_nightCountdown`/`_resolveOutcome` по `AreAllBoxed` (wipe); Morning → `FreeAll`; убрано поле `_caught`.
  - `tests/RoundService.spec` ОБНОВЛЁН (стаб `_revive`: Capture-spy + AreAllBoxed; 5 тестов). `tests/ReviveService.spec` НОВЫЙ (`_isWipe`, 4).
- **Серверная авторитетность (docs/02):** capture/free/«пойман ли»/позиция — серверно; нет RemoteEvent-поверхности (ProximityPrompt + атрибуты); free валидирует холдера ДО мутации; анкор держит против клиентского владения.
- **End-to-end в Studio (solo, через мост):** Capture → `InToyBox=true`, `HRP.Anchored=true`, точно в клетке (distToBox=5.0), `BoxedCount=1` ✓; Wipe→Lost (1 игрок = все в коробках) ✓; отказ самоспасения (пойманный держал промпт 3с → не вышел) ✓.
- **Security-review: PASS** (нет CRIT/HIGH; всё серверно, валидация до мутации, мгновенно не доделать). **Закрыл MED-1** (escape через респаун → false-Lost) и **MED-2** (потеря поимки на гонке HRP) → re-cage на `CharacterAdded` + флаг ставится всегда. LOW-1 (нет recheck дистанции в hold — идентично DoorService), LOW-2/3 — отложены.
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ: passed=35 failed=0** (31 + 4 `_isWipe`; RoundService.spec переписан под стаб).
- **🔸 НЕЗАКРЫТЫЙ ХВОСТ (для будущей проверки):** живой **2-player positive-free** («не-пойманный держит коробку → пойманный возвращается») НЕ прогнан end-to-end — заблокирован инструментами (computer-use отключился, Studio-мост клиентский → серверный FreeAll не вызвать, multi-client Studio UI не настроился у юзера). Логика подтверждена: release = зеркало проверенного capture; hold-открытие = доказанный паттерн дверей (P1-04); accept-ветка `_canRescue` = инверсия проверенной reject-ветки; security-review прошёл. **Рекомендуемая ручная проверка:** Studio Test → F7 «Server and Clients» → «Add Clients» (2 игрока): один попадается → в коробку, второй держит «Free teammates» → первый возвращается, матч жив. `passes:true` поставлен по решению юзера на этом покрытии.
- **Скоуп-хвосты на потом:** LOW-1 distance-recheck (вместе с DoorService), исключение бокснутых из таргетинга врагов, наказание за повторную поимку, HUD-коробки (P1-07).
- **Ветка:** `feat/p1-05-revive` → мёрдж в `dev`. Коммит — см. `git log`.
- **Следующее:** `P1-06` (сессионные апгрейды после ночи — выбор карточки; Upgrade-фаза из P1-01 = плейсхолдер).

---

## [P1-06 — passes:true] Сессионные апгрейды (выбор карты в Upgrade-фазе) — 2026-05-31
Сделал Upgrade-фазу функциональной. **Первый валидированный client→server RemoteEvent** в проекте — заложена Net-инфра.
- **Сделано:**
  - `src/shared/Net/RemoteSchema` (НОВЫЙ — реестр `{SelectUpgrade}`) + `Net.luau` (НОВЫЙ — сервер создаёт RemoteEvent под `ReplicatedStorage.Remotes`, клиент ждёт).
  - `UpgradeConfig` (НОВЫЙ — 3 карты: swift WalkSpeed×1.35, leaper JumpPower×1.6, steady ×1.15/×1.15; база 16/50; чистые данные).
  - `UpgradeService` (НОВЫЙ — `_onSelect` middleware ДО мутации: type-assert → whitelist (`_isValidUpgradeId`) → rate-limit → state-gate (только Upgrade) → one-per-phase; apply множителей на Humanoid; re-apply на CharacterAdded; per-player, сессионно). Авто-регистрация.
  - `UpgradeUiController.client` (НОВЫЙ — мини-UI: ScreenGui c 3 TextButton в Upgrade-фазе, клик → `SelectUpgrade:FireServer(id)`; НЕ Fusion — это P1-07).
  - `RoundConfig.upgradeDuration` 5→8 (время на выбор). `tests/UpgradeService.spec` (НОВЫЙ — `_isValidUpgradeId`: type+whitelist, отвержение мусора).
- **Безопасность (docs/02, /add-validated-remote):** клиент шлёт только намерение (id); множители — серверные (из конфига); провал валидации → warn + тихий игнор. RemoteEvent создаёт только сервер.
- **End-to-end в Studio (мост КЛИЕНТСКИЙ → `FireServer` = действие кнопки; врем. upgradeDuration=30 для поимки окна, потом 8):** UI показан в Upgrade ✓; `FireServer("swift")` → `WalkSpeed 16→21.60` (16×1.35) ✓; отвергнуты: тип `123`, whitelist `"hack"`, one-per-phase `"leaper"` после swift → WalkSpeed=21.60 без изменений ✓; swift не трогает JumpPower (пер-стат) ✓.
- **Security-review: PASS** (нет CRIT/HIGH/MED) — middleware полная, до мутации; накопление ограничено (макс 2 карты/матч → WalkSpeed≤29.2, JumpPower≤128); Net серверо-создаётся; нет `InvokeClient`. 3 LOW (мёртвая ветка `getCard`-lookup после `_isValidUpgradeId`; порядок rate-limit vs state-gate; JumpPower-модель — обработано форсом `UseJumpPower=true`) — косметика, отложены.
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ: passed=39 failed=0** (35 + 4). `upgradeDuration` возвращён на 8.
- **🔸 Тонкость:** Upgrade-фаза короткая (8с) → ловить окно через мост сложно (зазор между вызовами > окна); тестил на врем. 30с, вернул 8. Phase-gate (выбор вне Upgrade) явно не прогнан, но в валидированной цепочке + покрыт security-review.
- **Net-инфра заложена** — следующие client→server remote'ы добавлять через `RemoteSchema` + handler с middleware (`/add-validated-remote`).
- **Ветка:** `feat/p1-06-session-upgrades` → мёрдж в `dev`. Коммит — см. `git log`.
- **Следующее:** `P1-07` (HUD на Fusion: батарея-бар, счётчик ночи, прогресс ремонта, revive-промпт; мини-UI апгрейда из P1-06 можно поднять до Fusion).

---

## [P1-07 — passes:true] HUD на Fusion (батарея/ночь/ремонт/revive) + upgrade-UI на Fusion — 2026-05-31
Первый Fusion-HUD (0.3.0), реактивный к серверным бродкаст-атрибутам. По просьбе («подними») — upgrade-карточки P1-06 подняты до Fusion.
- **Сделано:**
  - `HudController.client` (НОВЫЙ, Fusion 0.3 scoped API): `attrValue` провязывает атрибут→Fusion `Value` (GetAttributeChangedSignal→:set), Computed-биндинги. Элементы: ночь `NIGHT n/3` (верх-право), батарея `Batteries: N` + power-бар (низ-лево), repair-бар (низ-центр, виден при 0<p<1), revive-текст (верх-центр). Мобильно: TextScaled, обводка, по углам, центр свободен, `IgnoreGuiInset=false` (safe zones).
  - `UpgradeUiController.client` ПЕРЕПИСАН на Fusion (карточки swift/leaper/steady, Enabled-биндинг от RoundState, Activated→`SelectUpgrade:FireServer`; min-size+обводка для телефона). Сервер P1-06 не тронут.
  - `DoorService` (правка): бродкаст `RepairProgress` на Player-холдера (для HUD-бара; сброс на complete/release). Read-only display.
  - `RoundUiController` (правка): `IgnoreGuiInset=false` (выровнено с HUD, safe zones).
- **End-to-end в Studio (execute_luau КЛИЕНТСКИЙ → видит HUD GUI):** HUD рендерится; ночь `NIGHT 1/3`; батарея `Batteries: N`; **repair-бар fill точно трекает серверный RepairProgress** (0.12→0.62, виден 0<p<1, сброс на релиз) — Fusion-реактивность end-to-end; revive-текст `CAUGHT!...` при InToyBox; upgrade-карточки Fusion (Enabled-биндинг, клик применяет — `WalkSpeed→18.4` от твоего клика «steady»). Условная видимость работает. Консоль без ошибок Fusion.
- **performance-auditor:** 1-й прогон NEEDS WORK (2 HIGH: ReviveLabel перекрывал центр-лейбл; Supplies/NightLabel клип за нотч/home bar). Починил (ReviveLabel Y→0.27; IgnoreGuiInset=false + отступы; +min-size/обводка карточек). 2-й прогон: HIGH закрыты, но ложная сработка (якобы нет обводки у RoundUiController — она ЕСТЬ, строка 27). 3-й прогон: **PASS** (нет реальных crit/high).
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ: passed=39** (без изменений — HUD=UI, DoorService-правка аддитивна).
- **🔸 На потом:** реальный тест на телефоне (нотч/Dynamic Island, узкий/широкий экран) до `main`; ReviveLabel-позиция при одновременных RoundUi+HUD; консолидация RoundUiController в HUD.
- **Ветка:** `feat/p1-07-fusion-hud` → мёрдж в `dev`. Коммит — см. `git log`.
- **Фаза 1: 7/11.** **Следующее:** `P1-08` (ProfileStore: coins/XP персист между сессиями + fail-handling — ретрай/кик, НЕ дефолт).

---

## [P1-08 — passes:true] ProfileStore: персист coins/XP + fail-handling — 2026-05-31
Первая **персистентность данных**. coins/XP сохраняются между сессиями (ProfileStore: сессионные локи + авто-сейв + backoff). Проверено на **РЕАЛЬНОМ** DataStore (плейс опубликован).
- **Сделано:**
  - `vendor/ProfileStore.luau` (НОВЫЙ — официальный `github.com/MadStudioRoblox/ProfileStore`, by loleris; единый ModuleScript, **вне `src` → вне линта**). `default.project.json`: маппинг `ServerScriptService.Server.Vendor → vendor`. `wally.toml`: коммент о вендоринге.
  - `src/shared/Config/DataConfig` (НОВЫЙ — `storeName="PlayerData_v1"`, `profileTemplate={Coins=0,Xp=0,Level=1}`, `coinsPerNight=10`, `xpPerNight=5`, `coinsPerWin=30`, `xpPerLevel=100`; чистые данные).
  - `src/server/Services/DataService` (НОВЫЙ, Knit): `KnitStart`→`ProfileStore.New`; `_onPlayerAdded` (StartSessionAsync с `Cancel` → `_shouldKick(nil)`→**Kick** → `Reconcile`+`AddUserId`+`OnSessionEnd`(лок украден→кик)+`_profiles[p]`+атрибуты); `_onPlayerRemoving`→`EndSession`; `BindToClose`→`EndSession` всем (синхронно); API `AddCoins/AddXp/GetCoins`; чистые `_shouldKick`/`_levelForXp`; бродкаст `Coins/Xp/Level` в Player-атрибуты. **Анти-гонка `_loading`-гард** (двойная загрузка PlayerAdded + early-joiners).
  - `src/server/Services/RoundService` (ИЗМЕНЁН): `KnitInit`+`_data=GetService("DataService")`; `_awardSurvivors(coins,xp)` — на Morning (`+10/+5` выжившим) и EndMatch (`+30` coins бонус). Серверно.
  - `tests/DataService.spec` (НОВЫЙ — `_shouldKick` (nil→kick; таблица→нет), `_levelForXp` (0/99/100/250→1/1/2/3), **persist round-trip на `ProfileStore.Mock`**: сессия→`Coins=42`→`EndSession`→новая сессия(`Steal`)→`Coins==42`).
- **Данные (docs/03):** сбой загрузки (`StartSessionAsync→nil`) → **кик, НЕ дефолт** (дефолт перезатёр бы сейв); сейв на `PlayerRemoving` + `BindToClose` (синхронно); pcall+backoff+сессионные локи + ≤1 сейв/6с — внутри ProfileStore. Монетизация/`ProcessReceipt` — отдельно (позже), не тут.
- **End-to-end на РЕАЛЬНОМ DataStore** (плейс **опубликован** «10 Nights Toy Store dev», `PlaceId=84110572941861`; Studio API access ON; Rojo sync MED-фикса подтверждён `_loading×5` в движке): профиль загрузился (`Coins=0/Xp=0/Level=1` = template, **игрок не кикнут**) → пережил Night 1 (safe-spot Y=500 anchored) → Morning начислил **`Coins=10, Xp=5`** → **стоп** (`EndSession`→save) → **старт** → **`Coins=10, Xp=5` пережили релог** (реальная запись/чтение DataStore, не mock). Консоль без ошибок DataStore/ProfileStore.
- **data-engineer: PASS.** Закрыт **MED** (двойная загрузка профиля: `PlayerAdded` + early-joiners-loop на одного игрока) → `_loading`-гард (`if _profiles[p] or _loading[p] then return`). Fail-handling и идемпотентность сейва — ок.
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` (vendor включён) ✓. **TestEZ: passed=45 failed=0** (8 spec-файлов; +`DataService.spec`: `_shouldKick`, `_levelForXp`, persist round-trip mock).
- **🔸 На потом:** персистим только `Coins/Xp/Level` (graybox); toy tickets/косметика/badges/монетизация — позже; HUD-показ coins (биндинг к атрибутам) — позже; реальный **кросс-сервер** relog-стресс — нужен лайв-сервер (Studio-стоп/старт = один сервер, но реальный DataStore-раунд-трип доказан).
- **Публикация плейса разблокировала отложенное:** `P0-10` (Open Cloud CI — TestEZ на пуше) и `P1-11` (Mantle deploy).
- **Ветка:** `feat/p1-08-profilestore` → мёрдж в `dev`. Коммит — см. `git log`.
- **Фаза 1: 8/11.** **Следующее:** `P1-09` (воронка аналитики, серверно: `player_joined … second_night_started`).

---

## [P1-09 — passes:true] Воронка аналитики (AnalyticsService, серверно) — 2026-05-31
Первая **аналитика**: серверная воронка первой сессии из 6 шагов (где отваливаются в первой минуте).
Бэкенд — встроенный Roblox `AnalyticsService:LogFunnelStepEvent` (плейс опубликован → данные летят в Dashboard).
- **Сделано:**
  - `src/shared/Config/AnalyticsConfig` (НОВЫЙ): `funnelName="first_session"`, `steps` (6 по порядку:
    player_joined → first_battery_picked → battery_inserted_generator → first_night_survived →
    upgrade_selected → second_night_started), предвычисленный `stepIndex` (name→1..6).
  - `src/server/Services/AnalyticsService` (НОВЫЙ, Knit): `LogFunnelStep(player, step)` → дедуп
    (`_fired[player]`) → `LogFunnelStepEvent(player, funnelName, sessionId, idx, step)` в `pcall` →
    Studio-only зеркало в атрибут `FunnelFired` (csv) → print. `player_joined` на PlayerAdded +
    early-joiners; cleanup на PlayerRemoving. Чистые `_stepIndex`/`_shouldFire`. `sessionId` =
    `HttpService:GenerateGUID`. **Без RemoteEvent, без мутации экономики** — логирование ПОСЛЕ валидации.
  - Хуки (по одной строке в проверенной success-точке, ref через `Knit.GetService` в KnitInit):
    `BatteryService` (after `_setCount`) → first_battery_picked; `GeneratorService` (after `_applyPower`)
    → battery_inserted_generator; `RoundService` (`_logFunnelAll`: night==1 Morning → first_night_survived;
    night==2 Night → second_night_started); `UpgradeService` (after `_applyToCharacter`) → upgrade_selected.
  - `tests/AnalyticsService.spec` (НОВЫЙ): `_stepIndex` (known/unknown), `_shouldFire` (fresh/already/unknown),
    порядок+кол-во шагов.
- **Семантика «first_*»** — из дедупа (хук зовётся на каждом успехе, фиксируется первый).
- **End-to-end (мост, читаю `player.FunnelFired`; врем. prep/upgrade бамп для окон, возвращены 5/8):**
  Полный матч (выжил 3 ночи → EndMatch). Воронка = `[player_joined, first_night_survived,
  upgrade_selected, second_night_started]` — **4/6 шагов вживую**, порядок верный, **0 дублей**
  (дедуп держится через весь матч), **0 спурьёзных** шагов. `upgrade_selected` сработал в лок-степе с
  реально применённым множителем (WalkSpeed 16→18.4) — хук точен. `player_joined` ✓ на join.
- **🔸 НЕЗАКРЫТЫЙ ХВОСТ (инструментальный, как P1-05/06):** `first_battery_picked` /
  `battery_inserted_generator` НЕ прогнаны вживую — оба «реальных» триггера ProximityPrompt из моста
  недоступны (`fireproximityprompt`=nil в клиентском контексте; `user_keyboard_input` E не доходит до
  промпта). Покрытие: пути подбора/вставки доказаны e2e (P0-04/P0-06), хук = одна строка в проверенной
  success-точке, `LogFunnelStep`/дедуп — юнит-тест, механизм воронки доказан вживую на 4 шагах.
  Рекомендуемая ручная проверка: войти, поднять батарейку (E), вставить в генератор (E) → в Dashboard
  funnel `first_session` шаги 2–3.
- **Review:** mandatory-триггеры не задеты (нет remote → security; нет persist-данных → data-engineer;
  нет визуала → performance). Самопроверка: хуки после валидации/мутации, pcall вокруг бэкенда, дедуп
  корректен, спеки прежние не сломаны.
- **Локально:** StyLua src+tests ✓, **Selene src 0/0/0** ✓, `rojo build` ✓. **TestEZ: passed=51 failed=0**
  (45 + 6 AnalyticsService.spec; 9 spec-файлов).
- **Ветка:** `feat/p1-09-analytics` → мёрдж в `dev`. Коммит — см. `git log`.
- **Фаза 1: 9/11.** **Следующее:** `P1-10` (security-ревью всей Фазы 1) или разблокированные `P0-10`
  (TestEZ в CI через Open Cloud) / `P1-11` (Mantle deploy).
