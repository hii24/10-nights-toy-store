# Toy Store — Claude Code Starter Kit

Стартовый «kit» для разработки игры **10 Nights in a Toy Store** на Roblox с Claude Code (Max 20x), собранный на основе официальных best-practices и курсов Anthropic. Цель: AAA-уровень при минимуме ручного труда и **система, которая не ломается на середине проекта**.

## Что внутри (карта файлов)

| Файл | Назначение | Когда читать |
|---|---|---|
| `CLAUDE_CODE_METHODOLOGY.md` | ⭐ Главное. Как эффективно работать в Claude Code: цикл Explore→Plan→Code→Commit, harness для долгих сессий, ритуалы, модель-стратегия, анти-паттерны | Прочитать ПЕРВЫМ, целиком |
| `.claude/CLAUDE.md` | Конституция проекта — авто-загружается Claude каждую сессию. Правила, архитектура, ритуал сессии | Положить в репозиторий; Claude читает сам |
| `.claude/settings.json` | Шаблон permissions/hooks | Настроить под себя |
| `.claude/agents/*.md` | Сабагенты (initializer, security, data, round-systems, performance, asset-pipeline) | Claude вызывает по контексту |
| `.claude/commands/*.md` | Слэш-команды (`/session-start`, `/next-feature`, `/ship`, `/review`) | Вызываешь вручную |
| `docs/01..07` | Детальные правила: архитектура, безопасность, данные, ассеты/аудио, тесты/CI, грабли, стандарты кода | Референс для агентов |
| `harness/feature_list.json` | Список фич (passes:false). Агенты только меняют статус, НЕ удаляют | Источник «что делать дальше» |
| `harness/claude-progress.md` | Журнал прогресса между сессиями | Агент читает в начале и пишет в конце сессии |
| `harness/init.sh` | Скрипт сетапа/сборки/смоук-теста | Запускается в начале каждой сессии |
| `prompts/00-initializer.md` | Промпт для самого первого запуска (initializer-агент) | Первое сообщение Claude Code |
| `prompts/01-session-template.md` | Шаблон промпта каждой рабочей сессии | Каждая последующая сессия |
| `config-templates/*` | Готовые конфиги: rokit, wally, rojo, selene, stylua, CI | Скопировать в корень репо |

## Быстрый старт (10 шагов)

1. Распакуй архив. Содержимое — это и есть скелет твоего репозитория (Git init в корне).
2. Установи Claude Code: `npm i -g @anthropic-ai/claude-code`. Открой в VS Code.
3. Установи Rokit и через него тулчейн (см. `config-templates/rokit.toml`): `rokit install`.
4. Скопируй `config-templates/*` в корень репозитория (rokit.toml, wally.toml, default.project.json, selene.toml, stylua.toml, .github/workflows/ci.yml).
5. `wally install` (поставит Knit, Fusion, ProfileStore).
6. Подключи MCP: Roblox Studio MCP (живой билд/тест) + Context7 (актуальные API-доки).
7. Заведи ID-верификацию аккаунта Roblox (нужно для аудио-аплоада — см. `docs/04`).
8. Прочитай `CLAUDE_CODE_METHODOLOGY.md` целиком. Это меняет то, КАК ты работаешь.
9. Открой Claude Code и дай ему промпт из `prompts/00-initializer.md` — он развернёт harness (feature_list.json, progress, init.sh) и Фазу 0.
10. Дальше — каждую новую сессию начинай командой `/session-start` (или промптом `prompts/01-session-template.md`).

## Главные принципы (TL;DR)

- **Claude — это младший инженер с инструментами, памятью и итерацией, а не «волшебный генератор кода».**
- **Сначала план, потом код.** Explore → Plan → Code → Commit. Plan mode на Opus.
- **Одна фича за сессию.** Никаких «one-shot всю игру».
- **Чистое состояние в конце каждой сессии:** git-коммит + запись в progress. Это точка восстановления.
- **Тесты — не для галочки.** Фича «passing» только после end-to-end проверки в Studio.
- **Клиент никогда не владеет геймплейным состоянием.** Всё валидируется на сервере.

> Источники методологии: Anthropic «Claude Code: Best Practices for Agentic Coding», «Effective harnesses for long-running agents», и курсы Anthropic Academy (Claude Code in Action, Subagents, Agent Skills).
