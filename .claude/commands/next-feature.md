---
description: Взять и реализовать одну следующую фичу по циклу Explore->Plan->Code->Commit
---

Возьми следующую фичу (если ещё не выбрана через /session-start — выбери одну `passes:false` высшего приоритета).

Следуй циклу:
1. **Explore** — прочитай релевантные файлы и доки (Context7), пойми контекст. Код пока не пиши.
2. **Plan** (plan mode, Opus) — предложи план реализации ОДНОЙ фичи. Дождись «ок».
3. **Code** (Sonnet) — реализуй. Соблюдай `docs/01-03,07`. RemoteEvent — только через `/add-validated-remote`.
4. **Test** — TestEZ + end-to-end плейтест в Studio. Пометь `passes:true` ТОЛЬКО после end-to-end.
5. Передай на ревью соответствующим сабагентам (security-reviewer обязательно, если трогал remote/экономику; data-engineer — если данные; performance-auditor — если визуал).
6. Заверши через `/ship`.

Одна фича за раз. Не выходи за рамки текущей фазы.
