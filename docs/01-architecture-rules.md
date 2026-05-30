# 01 — Архитектурные правила

## Структура репозитория (Rojo)
```
src/
  server/    RoundService, GeneratorService, EnemyService, DoorService,
             ReviveService, DataService, ShopService, ReceiptService, AnalyticsService
  client/    HUDController, InputController, FlashlightController, CameraController
  shared/    Enums, Config/ (NightConfig, EnemyConfig, UpgradeConfig, ItemConfig),
             Types/, Net/ (RemoteSchema + middleware), Util/
  assets/    генерируемые ассеты (Tarmac -> ModuleScript с asset IDs)
tests/       *.spec.luau (TestEZ)
```

## Принципы
- **Server-authoritative во всём геймплее.** Клиент — только UI и ввод.
- **Data-driven.** Всё балансируемое — в `src/shared/Config` как таблицы. Менять баланс без правки логики.
- **Сервис = одна зона ответственности.** Не мешать данные, бой, экономику в один модуль.
- **Один источник правды для состояния раунда** — `RoundService`.

## RoundService — стейт-машина (сердце игры)
```
Intermission -> Preparation(30-45s) -> Night(N)(3-4min)
-> Morning/Reward(30-60s) -> Upgrade(choice)
-> [N < 3 ? Night(N+1) : EndMatch] -> Intermission
```
Сервер владеет состоянием, таймерами, номером ночи. Клиент реагирует на смену состояния (через атрибуты/state-объект). Клиент НЕ решает, началась ли ночь.

## Сервисы и зоны
- `GeneratorService` — уровень питания (батарейки); бродкаст light state. Фликер света = клиентский визуал от серверного состояния.
- `EnemyService` — вся логика врагов (серверно). Параметры из `EnemyConfig`.
- `DoorService` — hold-to-repair; сервер считает прогресс, rate-limit (нельзя доделать мгновенно).
- `ReviveService` — пойманный -> состояние `InToyBox`; тиммейт освобождает. Серверно.
- `DataService` — ProfileStore (см. `docs/03`).
- `ShopService` + `ReceiptService` — монетизация (см. `docs/03`).
- `AnalyticsService` — события (см. `docs/04`).
- Клиент: HUD (Fusion), ввод, фонарик, камера — только UI/ввод.

## Враги (серверно)
- **Mr. Huggy Bear:** waypoint-патруль (узлы, НЕ PathfindingService на всех — см. `docs/06`); слух (детект спринта в радиусе); скорость = f(атрибут GeneratorPowered); стан ~2с от направленного фонарика.
- **Doll Blinkers:** двигаются только в «слепые» тики (сервер проверяет look-векторы + LOS).
- **Wind-Up Soldiers:** линейный патруль, толкают, шумят.

## Состояние: сессионное vs персистентное (не путать)
- *Сессионное* (один матч, НЕ персистится): in-round апгрейды, текущие батарейки, статус InToyBox.
- *Персистентное* (ProfileStore): coins, toy tickets, XP/level, cosmetics, collectibles, badges, passes.

## Производительность
Модульный кит (одна полка -> 20 клонов; один меш -> дубли, не повторные загрузки); low-poly; StreamingEnabled (осторожно с серверными врагами — `docs/06`); пулинг инстансов пикапов; не перегружать props; картинка не слишком тёмная; крупные силуэты; UI не закрывает экран.
