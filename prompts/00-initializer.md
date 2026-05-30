# Первый промпт для Claude Code (initializer — самый первый запуск)

Скопируй это как ПЕРВОЕ сообщение в Claude Code на пустом/скелетном репозитории.

---

Действуй как initializer-агент (см. `.claude/agents/initializer.md`). Прочитай `CLAUDE_CODE_METHODOLOGY.md`, `.claude/CLAUDE.md` и `docs/01`-`docs/07` — это полная методология и правила проекта.

Твоя задача — заложить harness и скаффолд, НЕ реализуя игровые фичи:

1. Скопируй конфиги из `config-templates/` в корень (rokit.toml, wally.toml, default.project.json, selene.toml, stylua.toml, .github/workflows/ci.yml). Создай структуру `src/{server,client,shared/{Config,Net,Types,Util},assets}`, `tests/`.
2. Проверь `harness/feature_list.json` — список фич Фаз 0-1 полон и все `passes:false`. Дополни недостающее (не удаляя существующее).
3. Доведи `harness/init.sh` до рабочего состояния (rojo build + указание на TestEZ/Open Cloud + Studio MCP плейтест).
4. Сделай начальный git-коммит `chore: project scaffold + harness`.
5. Запиши стартовую запись в `harness/claude-progress.md`.

Работай в plan mode (Opus): сперва покажи план скаффолда, дождись моего «ок», потом выполни. Соблюдай скоуп-гардрейлы — НЕ реализуй игровые системы сверх минимального скаффолда. По завершении предложи запустить первую рабочую сессию через `/session-start`.
