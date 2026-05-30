# CLAUDE.md — 10 Nights in a Toy Store

> Это конституция проекта. Держать тугой. Детали — в `docs/`. Методология работы — в `CLAUDE_CODE_METHODOLOGY.md`.

## Что это за проект
Кооп-survival на Roblox, 4–6 игроков. Игроки заперты ночью в магазине игрушек: собирают батарейки, питают генератор, чинят двери, спасают друзей из toy box, выживают до утра. Главный враг — Mr. Huggy Bear, опаснее при выключенном свете. MVP: 3 ночи, 1 маскот + 2 мелких врага, 1 компактная карта. Стиль: stylized plastic toy horror, low-poly, third-person.

## Скоуп-гардрейлы (НАРУШАТЬ НЕЛЬЗЯ)
- Делаем **только текущую фазу** (см. `docs/05` и `harness/feature_list.json`). Не добавлять контент вперёд.
- MVP-границы: 3 ночи, 1 маскот, 2 мелких врага, 1 карта, 4–6 игроков. Расширение — только через явное обновление плана.
- **Сначала доказать петлю на серых кубах (Фаза 0). Графика/ассеты — позже.**
- НЕ делаем в MVP: 10 ночей, длинный лор, огромную карту, реализм, «умный» AI, классы, длинный туториал, first-person, instant game over.

## Стек и структура
- **Knit** (сервисы/контроллеры) + **Fusion** (HUD) + **pure Luau**. Данные — **ProfileStore**. Тесты — **TestEZ**.
- Структура: `src/server`, `src/client`, `src/shared` (Config/, Net/, Types/, Util/), `src/assets`, `tests/`. Подробно — `docs/01`.
- Тулчейн пиннится через Rokit; зависимости — через Wally.

## Несущие правила (полные версии в docs/)
1. **Безопасность (`docs/02`):** клиент НИКОГДА не владеет геймплейным состоянием. Каждый RemoteEvent проходит middleware-валидацию (type-assert → whitelist → диапазоны → rate-limit) ДО мутации. Никогда `RemoteFunction:InvokeClient()` с сервера. Вся логика врагов — серверная.
2. **Данные (`docs/03`):** ProfileStore с сессионными локами. При сбое загрузки профиля — НЕ пускать с дефолтными данными (ретрай/кик). Все DataStore-вызовы в pcall + backoff; сейв на PlayerRemoving И BindToClose; не чаще 1/6с на ключ. ProcessReceipt идемпотентен.
3. **Производительность (`docs/01`):** модульный кит (один меш → клоны), low-poly, StreamingEnabled, пулинг пикапов, мобильная читаемость.
4. **Код (`docs/07`):** официальный Roblox Lua Style Guide; Selene + StyLua обязательны; data-driven конфиги в `src/shared/Config`.
5. **Аналитика (`docs/04`):** воронка событий с первого дня (player_joined → first_battery_picked → battery_inserted_generator → first_night_survived → upgrade_selected → second_night_started). Серверная.

## Архитектурное ядро
`RoundService` — серверная стейт-машина: `Intermission → Preparation(30–45s) → Night(N)(3–4m) → Morning(30–60s) → Upgrade → [N<3? Night(N+1) : EndMatch]`. Клиент только реагирует на смену состояния. Сервисы: GeneratorService, EnemyService, DoorService, ReviveService, DataService, ShopService, ReceiptService, AnalyticsService. Клиент: HUD/Input/Flashlight/Camera. Детали — `docs/01`.

## Ритуал сессии (ОБЯЗАТЕЛЬНО — см. методологию §4)
**Начало:** `pwd` → прочитать `harness/claude-progress.md` + `git log --oneline -20` → прочитать `harness/feature_list.json`, выбрать ОДНУ фичу `passes:false` с высшим приоритетом → запустить `harness/init.sh` + смоук-тест → если сломано, сначала чинить.
**Работа:** одна фича за сессию. План (Opus, plan mode) → реализация (Sonnet) → end-to-end проверка в Studio.
**Конец:** пометить `passes:true` ТОЛЬКО после end-to-end → git-коммит с описательным сообщением → запись в `harness/claude-progress.md`. Оставить код в состоянии «годно к мёрджу».

## `feature_list.json` — правила
ТОЛЬКО менять поле `passes`. НЕ удалять и НЕ редактировать фичи/тесты — это ведёт к пропущенной/багованной функциональности.

## Команды проекта
- Сборка: `rojo build --output game.rbxlx`
- Линт/формат: `selene src` и `stylua --check src`
- Тесты: через `harness/init.sh` (TestEZ в движке через Open Cloud Luau Execution)
- Старт новой сессии: `/session-start` · взять фичу: `/next-feature` · сдать: `/ship` · ревью: `/review`

## Перед мёрджем в main
Прогнать `/review` (security + data + performance сабагенты), зелёные тесты, чистый прогресс-файл.
