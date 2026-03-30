# MD Generator (docsgen)

Инструмент для автоматической генерации Markdown‑документации по объектам DWH. На первом этапе — **процедуры**.

## Цели
- Единый формат документации в `.md`.
- Минимум ручной работы: вход — JSON (при желании дополняется анализом SQL).
- Простая расширяемость на таблицы/функции/другие объекты.

## Принцип работы (первичный)
1. Получаем JSON с метаданными процедуры (`schema`, `name`, `description`, `parameters`, `result_dataset`, `dependencies`, `modifications`, `error_handling`, `source_sql`).
2. Валидируем и нормализуем данные.
3. (Опционально) анализируем `source_sql` для источников SELECT и DML‑модификаций.
4. Рендерим Markdown по шаблону (Jinja2).
5. Сохраняем файл `<schema>.<name>.md` и обновляем общий `summary.md`.

## Архитектура
```
repo/
  misc/                # черновики, заметки, временные материалы
  source/
    template/          # исходные шаблоны/примеры (если используются)
  src/
    docsgen/
      examples/        # примеры входных JSON
      io/              # загрузка JSON, запись .md
      models/          # pydantic-модели входных данных
      pipeline/        # orchestrator, validators, transformers, analyzers
      render/          # jinja2 и шаблоны рендера
      test/            # простые юнит‑тесты
      utils/           # утилиты (текст, хэши, и пр.)
      cli.py
      config.py
      logging_conf.py
  README.md
```

## Статус
WIP: базовая генерация для процедур. 
NEXT: таблицы/функции, добавлени анализатора SQL?
