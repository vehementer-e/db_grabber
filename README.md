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

## CLI примеры
```bash
# как на скриншоте: батч-генерация документации
python -m docsgen.cli build-all --db Reports --schema dbo --max-conns 8 procedure

# выгрузка текстов всех процедур в .sql
python -m docsgen.cli export-procedure-sources --db Reports --schema dbo --max-conns 8
# итоговая иерархия: build/sql/procedures/<db>/<schema>/<procedure>.sql

# выгрузка SQL Agent jobs и шагов (из msdb)
python -m docsgen.cli export-job-sources --msdb msdb --name-filter report --max-conns 8
# итоговая иерархия: build/sql/jobs/<msdb>/<job_name>/{job.json,01_step.sql,...}
```

## Подключение к БД
По умолчанию используется trusted connection (актуально для запуска на Windows под текущим пользователем):
- `Trusted_Connection=yes`

Если **заданы все** переменные окружения ниже, включается SQL-аутентификация и они имеют приоритет:
- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`

Дополнительные env-переменные:
- `DOCSGEN_SERVER`
- `DOCSGEN_DEFAULT_DB`
- `DOCSGEN_OUT_DIR`
- `DOCSGEN_PROC_SRC_DIR`
- `DOCSGEN_JOB_SRC_DIR`

## Архитектура
```
repo/
  src/
    docsgen/
      cli.py
      batch.py
      procedure_source.py   # экспорт SQL текстов процедур
      async_db.py
      db.py
      config.py
```

## Статус
WIP: базовая генерация для процедур/таблиц/функций + экспорт исходников процедур.
