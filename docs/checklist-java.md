# Чек-лист разработчика (Java)

Ниже — подробный план реализации для сервисов Java: Auth/Identity, Projects, Tasks, Comments.

## Общие задачи (для всех сервисов)
- Инициализировать Spring Boot 3.x проект, настроить Gradle, версии Java 21.
- Подключить Spring Cloud, Spring Data JPA, Spring Validation, MapStruct, springdoc-openapi.
- Настроить Flyway миграции и Testcontainers для интеграционных тестов.
- Настроить OpenTelemetry трассировку и метрики Prometheus.
- Добавить обработку `X-Correlation-Id` и структурированное логирование.
- Реализовать глобальную обработку ошибок (ProblemDetails).
- Описать OpenAPI, включить Swagger UI.
- Настроить CI (GitHub Actions): сборка, тесты, публикация Docker-образа.

---

## Auth/Identity Service
- Модель данных (PostgreSQL):
  - `users(id, email, password_hash, display_name, status, created_at, updated_at)`
  - `roles(id, code, name)`
  - `user_roles(user_id, role_id)`
  - `refresh_tokens(id, user_id, token, expires_at, revoked)`
- API:
  - POST `/auth/register`, POST `/auth/login`, POST `/auth/refresh`, POST `/auth/logout`
  - GET `/users/me`, GET `/users/{id}`, GET `/users` (поиск/пагинация)
  - POST `/users/{id}/roles`, DELETE `/users/{id}/roles/{role}`
- Безопасность:
  - Пароли — Argon2/BCrypt, JWT (RS256), ротация refresh-токенов, ограничение попыток входа.
  - OIDC совместимость для Gateway.
- События:
  - Публикация `user.created`, `user.updated` при регистрации/изменении.
- Тестирование:
  - Интеграционные тесты аутентификации/авторизации, миграций и репозиториев.

## Projects Service
- Модель данных (PostgreSQL):
  - `projects(id, key, name, description, owner_id, created_at, updated_at)`
  - `project_members(project_id, user_id, role, added_at)`
- API:
  - CRUD проектов; управление участниками; поиск по `key/name`.
- Правила:
  - Только владельцы/админы проекта могут управлять участниками.
- События:
  - `project.created`, `project.updated`, `project.member_added`, `project.member_removed`.
- Тестирование:
  - Контракты API, ограничения прав, миграции, репозитории.

## Tasks Service
- Модель данных (PostgreSQL):
  - `tasks(id, project_id, title, description, status, priority, due_date, created_by, created_at, updated_at)`
  - `task_assignees(task_id, user_id)`
  - `tags(id, name, color)`
  - `task_tags(task_id, tag_id)`
  - `task_activity(id, task_id, actor_id, type, payload_json, created_at)`
- API:
  - CRUD задач; фильтры по проекту/статусу/исполнителю/тегам/дедлайну; пагинация.
  - Массовые обновления статуса; назначение исполнителей; управление тегами.
- Интеграции:
  - Публиковать `task.created`, `task.updated`, `task.assigned` (Kafka).
  - Консумить `file.uploaded` (линковать вложения, если нужен cross-ref).
- Индексы/перфоманс:
  - Индексы по `(project_id, status, due_date)`, GIN по тегам, полнотекст по `title/description` (внутренний или через Search Service).

## Comments Service
- Модель данных (PostgreSQL):
  - `comments(id, task_id, author_id, body, created_at, updated_at, is_edited)`
- API:
  - CRUD комментариев; пагинация; редактирование/удаление с аудитом.
- Интеграции:
  - Публиковать `comment.added` для уведомлений и поиска.
- Валидации:
  - Упоминания `@user` и проверки доступа к задаче.

## Нефункциональные требования
- Идемпотентность для повторных POST через Idempotency-Key.
- Ограничения скорости (rate limiting) на уровне Gateway.
- Миграции обратимы; данные — с мягким удалением (soft-delete при необходимости).
- Обновления схем — с оценкой влияния на индексы и планы запросов.

## Definition of Done
- Все эндпойнты покрыты интеграционными тестами (>=80%).
- События публикуются и корректно сериализуются (Avro/JSON Schema). Проверены контрактные тесты.
- Обновлён OpenAPI и диаграммы.
- CI зелёный; образы в реестре; Helm chart обновлён.
