# Распределение сервисов и стек технологий

Ниже приведено распределение микросервисов между двумя разработчиками и рекомендуемый стек технологий. Каждый сервис имеет чёткие границы ответственности и взаимодействует с другими через REST/gRPC и асинхронные события.

## Архитектура (высокоуровневый обзор)
- Домены: Users, Projects, Tasks, Comments, Files, Notifications, Search, Reporting, Auth/Identity, Gateway.
- Синхронные вызовы: HTTP REST/gRPC через API Gateway.
- Асинхронные события: брокер сообщений (Kafka или RabbitMQ) для событий `task.created`, `task.updated`, `task.assigned`, `comment.added`, `file.uploaded`, `notification.sent`.

## Разработчик A (Java)
- Язык/платформа: Java 21, Spring Boot 3.x, Gradle, Spring Cloud.
- Инфраструктура: Spring Data JPA (PostgreSQL), Spring Data Mongo (история/аудит), Redis (кэш/сессии), Flyway (миграции), Testcontainers, OpenAPI (springdoc), MapStruct, OpenTelemetry.
- Сервисы:
  1. Auth/Identity Service — OIDC/JWT, пользователи, роли, SSO.
  2. Projects Service — CRUD проектов, участники, роли в проекте.
  3. Tasks Service — CRUD задач, статусы, исполнители, теги, дедлайны, приоритеты.
  4. Comments Service — комментарии к задачам, упоминания, реакции.

## Разработчик B (.NET)
- Язык/платформа: .NET 8, ASP.NET Core, EF Core, MediatR.
- Инфраструктура: EF Core (PostgreSQL), Dapper (репорты), Redis (кэш/очереди), Elasticsearch .NET client, Hangfire/Quartz (фоновые задачи), OpenAPI (Swashbuckle), OpenTelemetry.
- Сервисы:
  1. Files Service — загрузка/хранение файлов (S3/MinIO), версии, превью, антивирус.
  2. Notifications Service — e-mail, web-pуш, in-app, шаблоны и доставки.
  3. Search Service — полнотекстовый поиск (Elasticsearch/OpenSearch) по задачам/комментариям/файлам.
  4. Reporting/Analytics Service — агрегации, метрики, экспорт CSV/Excel/PDF.

## Общие компоненты
- API Gateway: NGINX/Envoy + OIDC Proxy.
- Message Broker: Kafka (рекомендуется) или RabbitMQ.
- Observability: Prometheus, Grafana, OpenTelemetry, ELK/EFK.
- CI/CD: GitHub Actions, Docker, Helm, Kubernetes.

## Контракты взаимодействия
- Аутентификация: заголовок `Authorization: Bearer <jwt>` (issuer — Auth/Identity).
- Корреляция: заголовок `X-Correlation-Id` (генерируется на входе API Gateway).
- События (Kafka topics, ключ — `aggregateId`):
  - `task.created`, `task.updated`, `task.assigned`
  - `comment.added`
  - `file.uploaded`
  - `notification.sent`

См. также: [Чек-листы](./checklist-java.md, ./checklist-dotnet.md), [БД (реляционные)](./db-relational.md), [БД (NoSQL)](./db-nosql.md), [Диаграммы взаимодействия](./interservice-diagrams.md).
