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
