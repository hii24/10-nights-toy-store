# 04 — Пайплайн ассетов и аудио

## Сначала — арт-библия (заблокировать)
Палитра день (warm yellow / candy red / toy blue / soft green / plastic pink) и ночь (deep blue / purple / red alarm / green emergency / flashlight cones); материалы (plastic glossy, cardboard matte, plush fabric, metal, emissive neon); поли-бюджет; мобильная читаемость. **Через библию прогоняем ВСЁ** — иначе главный AAA-риск: развал стиля.

## Матрица: генерить / брать / заказывать
- **ГЕНЕРИТЬ (ИИ Roblox):** фоновые игрушки (car, ball, blocks, duck, dino, train) — Cube 3D; материалы — Material Generator; декали/постеры — Texture Generator. ~80% недифференцирующего контента. Ассеты из встроенных ИИ-инструментов Roblox можно использовать в опубликованных играх.
- **БРАТЬ (Creator Store) — только blockout/коммодити:** заглушки на graybox. Строго: без скриптов, чистить Explorer, не тянуть тяжёлое, без узнаваемых IP. Для финала опасно (стиль расходится).
- **ЗАКАЗ/КАСТОМ — дифференцирующие 20%:** Mr. Huggy Bear, Doll Blinker, Wind-Up Soldier, логотип, thumbnail, иконка, hero-анимации медведя (Moon Animator 2 / заказ).
- **МОДУЛЬНЫЙ КИТ (сделать раз -> клонировать):** wall/floor/ceiling, shelf, counter, register, rack, box, crate, door, vent, camera, lamp, neon sign.

## Cube 3D — нюансы
Выход почти всегда требует чистки; включить тоглы EditableImage/EditableMesh (Game Settings -> Security), иначе текстуры молча слетают; rate-limit ~5 генераций/мин на experience.

## Аудио — Suno (музыка) + Roblox library / ElevenLabs (SFX)
**Важно: Suno = музыка/амбиент/темы, НЕ дискретные SFX.** Делим:
- **Музыка — Suno API:** menu theme, store hum bed (день), night tension score, music-box motif маскота, morning bell jingle. Промпт: жанр + настроение + инструменты + длина + "instrumental / loopable". Использовать стемы для слоёв.
- **SFX — Roblox Creator Store audio (free, лицензировано) как основа** + опц. ElevenLabs Sound Effects (text-to-SFX): footsteps, squeak, door slam, generator loop, cartoonish growl, alarm, battery-pickup ping, flicker.

### Suno — правовые/практические нюансы
Официального публичного API нет — доступ через одобренных партнёров или сторонних провайдеров (sunoapi.org / API.box / ApiPass). Коммерческие права на вывод — только на **платном тарифе** (Pro/Premier); у провайдеров вывод обычно без водяных знаков. Правовой статус AI-музыки в 2026 не до конца устаканен (осознанный риск). Модели поэтапно меняются на обученные на лицензированной музыке -> **бэкапить все треки**.

### Требования Roblox к аудио (официально)
Форматы .mp3/.ogg/.wav/.flac; **< 20 MB и < 7 минут**; sample rate <= 48 kHz; mono или stereo 2.0/3.0/5.1. Лимит импорта: **2000 файлов / 30 дней при верификации ID** (иначе 100) -> **верифицировать ID заранее**. Загрузка через Asset Manager, Creator Dashboard И **Open Cloud Create Asset API** (автоматизируемо). Аудио проходит **очередь модерации** (до одобрения может не играть). Asset privacy: дать своему опыту разрешение на использование.

## Автоматизация
Сгенерированные меши/текстуры/аудио — файлами в Git. **Tarmac** (`tarmac sync --target roblox`) заливает и генерирует Lua с ID -> Rojo делает ModuleScript. Аудио — через Open Cloud Create Asset API. Ручное «загрузил -> скопировал ID» исчезает.
