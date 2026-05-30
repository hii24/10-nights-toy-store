# 05 — Тестирование, CI/CD и фазы

## Тестирование
- **Unit:** TestEZ (используется самим Roblox для их приложений/плагинов). Гоняется в реальном движке через **Open Cloud Luau Execution** в CI.
- **End-to-end:** плейтест через **Studio MCP** — агент реально запускает игру и проверяет петлю как игрок.
- **Правило:** `passes:true` в feature_list.json — ТОЛЬКО после end-to-end проверки. Никогда авансом.

## CI/CD (GitHub Actions)
Пайплайн: `StyLua --check` + `Selene` (lint) -> `rojo build --output game.rbxlx` -> **TestEZ через Open Cloud Luau Execution** -> **Mantle deploy** на мёрдж в `main` (только если тесты зелёные). Ветки: `dev` (фичи) / `main` (прод). Тесты — гейт деплоя.
**Секреты:** `OPEN_CLOUD_API_KEY`, `MANTLE_OPEN_CLOUD_API_KEY`, `ROBLOSECURITY`, `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` (S3 remote-state Mantle).
**Вводить поэтапно:** сначала lint+build+test; Mantle deploy подключить на Фазе 1-2, не в день 1.

## Фазы (источник истины — harness/feature_list.json)
- **Фаза 0 — v0.1 Graybox:** скаффолд + ОДНА сцена (спавн -> батарейка -> генератор -> мигание -> пробуждение Bear -> выжить 3 мин). Серые кубы. *Acceptance:* на graybox реально напряжённо и хочется ещё.
- **Фаза 1 — v0.2 MVP:** 3 ночи + стейт-машина; 2-й/3-й враг; repair; revive/toy box; сессионные апгрейды; HUD; ProfileStore (coins/XP); анти-эксплойт middleware; воронка аналитики; Mantle deploy.
- **Фаза 2 — v0.3 Visual Hook:** кастомный Bear + кит + материалы/декали; Suno-музыка + SFX; освещение; thumbnail/иконка; первые косметики.
- **Фаза 3 — v0.4 Retention:** daily reward; collectibles; badges; дерево апгрейдов; night modifiers.
- **Фаза 4 — v1.0 Push:** полиш; трейлер; thumbnails; TikTok/Shorts; live-update план.
