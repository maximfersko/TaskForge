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

## Дополнительные паттерны и интеграции (.NET)

### Circuit Breaker Pattern
- [ ] Подключить `Polly` для реализации Circuit Breaker
- [ ] Настроить Circuit Breaker для вызовов к внешним сервисам (Java сервисы, SMTP, Elasticsearch)
- [ ] Конфигурация: failure rate threshold 50%, timeout 3s, retry 3 раза
- [ ] Fallback методы для критических операций (кэшированные данные, деградированный режим)
- [ ] Метрики Circuit Breaker в Prometheus для мониторинга

### Bulkhead Pattern
- [ ] Разделить thread pools для разных типов операций (файловые операции, уведомления, поиск)
- [ ] Настроить отдельные connection pools для разных БД (PostgreSQL, Redis, Elasticsearch)
- [ ] Изолировать ресурсы для тяжёлых операций (генерация отчётов, индексация)
- [ ] Конфигурация `ThreadPool.SetMinThreads` и `ThreadPool.SetMaxThreads`

### Outbox Pattern
- [ ] Создать таблицу `outbox_events` для гарантированной доставки событий
- [ ] Реализовать `OutboxEventPublisher` с транзакционной публикацией событий
- [ ] Настроить Hangfire job для периодической отправки событий из outbox (каждые 5 секунд)
- [ ] Добавить идемпотентность для предотвращения дублирования событий
- [ ] Очистка обработанных событий старше 7 дней

### Distributed Caching
- [ ] Настроить Redis как distributed cache для кэширования результатов поиска
- [ ] Реализовать кэширование шаблонов уведомлений с TTL 1 час
- [ ] Кэширование результатов отчётов с TTL 30 минут
- [ ] Кэширование метаданных файлов с TTL 15 минут
- [ ] Настроить cache eviction policies (LRU, TTL-based)

### Message Queue Patterns
- [ ] Реализовать Dead Letter Queue для обработки неудачных сообщений
- [ ] Настроить retry с exponential backoff для временных ошибок
- [ ] Добавить message deduplication по message ID
- [ ] Реализовать message ordering для критических событий (по task_id)
- [ ] Настроить batch processing для массовых операций (уведомления, индексация)

### Observability Patterns
- [ ] Настроить distributed tracing с OpenTelemetry и Jaeger
- [ ] Добавить structured logging с Serilog и correlation ID для трассировки запросов
- [ ] Реализовать health checks для всех сервисов (`/health`)
- [ ] Настроить custom metrics для бизнес-метрик (количество файлов, уведомлений, поисковых запросов)
- [ ] Добавить alerting rules в Prometheus для критических метрик

### Security Patterns
- [ ] Реализовать JWT token validation с публичными ключами
- [ ] Добавить RBAC (Role-Based Access Control) на уровне методов
- [ ] Настроить method-level security с `[Authorize]` атрибутами
- [ ] Реализовать audit logging для всех изменений данных
- [ ] Добавить input validation и sanitization для предотвращения инъекций

### Performance Patterns
- [ ] Реализовать connection pooling для всех БД (Npgsql, Redis, Elasticsearch)
- [ ] Настроить lazy loading для EF Core entities
- [ ] Добавить pagination для всех списковых операций
- [ ] Реализовать async processing для тяжёлых операций (генерация отчётов, индексация)
- [ ] Настроить compression для HTTP responses (gzip)

### Background Processing Patterns
- [ ] Настроить Hangfire для фоновых задач (отправка уведомлений, генерация отчётов)
- [ ] Реализовать job scheduling с cron expressions
- [ ] Добавить job monitoring и retry логику
- [ ] Настроить job queues с приоритетами
- [ ] Реализовать job progress tracking для длительных операций

### File Processing Patterns
- [ ] Реализовать streaming для больших файлов (chunked upload/download)
- [ ] Добавить virus scanning с ClamAV через gRPC
- [ ] Настроить async file processing pipeline
- [ ] Реализовать file preview generation (thumbnails, text extraction)
- [ ] Добавить file deduplication по checksum

### Search Optimization Patterns
- [ ] Реализовать search result caching с TTL
- [ ] Настроить search suggestions с edge_ngram
- [ ] Добавить search analytics (популярные запросы, клики)
- [ ] Реализовать search result ranking
- [ ] Настроить search index optimization (refresh, merge policies)

### Reporting Patterns
- [ ] Реализовать materialized views для быстрых отчётов
- [ ] Настроить async report generation с progress tracking
- [ ] Добавить report scheduling и delivery
- [ ] Реализовать report caching и sharing
- [ ] Настроить report export в различные форматы (CSV, Excel, PDF)

### Testing Patterns
- [ ] Реализовать contract testing с Pact для межсервисного взаимодействия
- [ ] Добавить integration testing с Testcontainers
- [ ] Настроить performance testing с NBomber для нагрузочного тестирования
- [ ] Реализовать chaos engineering тесты для проверки resilience
- [ ] Добавить security testing с OWASP ZAP для проверки уязвимостей

## Нефункциональные требования
- Идемпотентность обработчиков событий по ключу сообщения.
- Полные трассировки запросов/фоновых задач.
- Стабильные миграции и откат.
- Circuit Breaker, Bulkhead, Outbox Pattern для повышения надёжности и производительности.

## Definition of Done
- Индексы созданы; запросы быстрые (<200ms P95).
- События корректно обрабатываются; поисковые индексы консистентны.
- Документация и OpenAPI обновлены.
- CI зелёный; образы в реестре; Helm chart обновлён.
