# Чек-лист разработчика (.NET)

Ниже — подробный план реализации для сервисов .NET: Files, Notifications, Search, Reporting.

## Общие задачи (для всех сервисов)
- Инициализировать .NET 8 проект (ASP.NET Core), включить Swagger, HealthChecks, Serilog.
- Настроить EF Core (PostgreSQL), миграции, FluentValidation, MediatR.
- Настроить OpenTelemetry (traces/metrics/logs), Prometheus scraping.
- Поддержать `X-Correlation-Id` и глобальные ошибки (ProblemDetails).
- CI: GitHub Actions (restore, build, test, publish Docker), контейнеризация.

---

## Files Service
- Хранилище: S3/MinIO (buckets: `task-attachments/{projectId}/{taskId}/{fileId}/{version}`), presigned URLs.
- БД (PostgreSQL):
  - `files(id, owner_id, task_id, name, content_type, size, storage_key, checksum, created_at)`
  - `file_versions(id, file_id, version, storage_key, size, checksum, created_at)`
- Функционал:
  - Загрузка/скачивание, версии, удаление (soft-delete), генерация превью (фоново), антивирус (ClamAV).
- API:
  - POST `/files`, GET `/files/{id}`, GET `/tasks/{taskId}/files`, POST `/files/{id}/versions`
- События:
  - Публиковать `file.uploaded`, `file.version_added`; прикладывать `task_id` если есть связь.

## Notifications Service
- Каналы: Email (SMTP), WebPush, In-App; шаблоны (liquid/handlebars).
- БД:
  - `notification_templates(id, code, subject, body, channel, locale, updated_at)`
  - `notifications(id, recipient_id, channel, template_code, payload_json, status, try_count, created_at, sent_at)`
- Очереди/ретраи: Hangfire/Quartz, экспоненциальные повторы.
- Консумит события: `task.created`, `task.assigned`, `comment.added`, `file.uploaded`.
- Публикует: `notification.sent`.
- API: управление шаблонами, ручная отладочная отправка.

## Search Service
- Elasticsearch/OpenSearch индексы:
  - `tasks`: поля `title, description, project, tags, assignees, status, due_date`.
  - `comments`: `task_id, author_id, body, created_at`.
  - `files`: `name, content_type, task_id, project_id` (опционально OCR/текст).
- Настроить анализаторы (ru/en), edge_ngram для подсказок, синонимы.
- Консумит события: `task.*`, `comment.added`, `file.uploaded` — обновляет индексы.
- API поиска: `GET /search?q=...&type=task|comment|file` с фильтрами.

## Reporting/Analytics Service
- Хранилище: PostgreSQL (материализованные представления) + Dapper для сложных репортов.
- Метрики: количество задач по статусам, среднее время цикла, SLA уведомлений.
- Планировщик: Hangfire/Quartz — ночные отчёты, экспорт в CSV/Excel/PDF.
- API: генерация отчётов on-demand и выдача ссылок на скачивание.

## Нефункциональные требования
- Идемпотентность обработчиков событий по ключу сообщения.
- Полные трассировки запросов/фоновых задач.
- Стабильные миграции и откат.

## Definition of Done
- Индексы созданы; запросы быстрые (<200ms P95).
- События корректно обрабатываются; поисковые индексы консистентны.
- Документация и OpenAPI обновлены.
- CI зелёный; образы в реестре; Helm chart обновлён.
