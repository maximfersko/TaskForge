# Чек-лист разработчика (Java)

Ниже — подробный план реализации для сервисов Java: Auth/Identity, Projects, Tasks, Comments.

## Рекомендации по порядку выполнения

### Этап 1: Инфраструктура и общие компоненты
- [ ] Настроить инфраструктуру: PostgreSQL, MongoDB, Redis, Kafka, Elasticsearch
- [ ] Создать базовый Spring Boot проект с общими зависимостями
- [ ] Настроить Docker Compose для локальной разработки
- [ ] Подключить OpenTelemetry, Prometheus, Grafana для мониторинга
- [ ] Настроить CI/CD pipeline (GitHub Actions, Docker registry)

### Этап 2: Интеграция с Keycloak
- [ ] Настроить Keycloak сервер (Docker Compose или отдельный инстанс)
- [ ] Создать realm для TaskForge приложения
- [ ] Настроить клиенты для frontend и backend сервисов
- [ ] Создать роли и группы пользователей в Keycloak
- [ ] Настроить пользовательские атрибуты (display_name, department, etc.)
- [ ] Реализовать интеграцию с Keycloak через Spring Security OAuth2
- [ ] Настроить JWT token validation с публичными ключами Keycloak
- [ ] Добавить тестирование интеграции с Keycloak

### Этап 3: Projects Service
- [ ] Создать Projects Service с интеграцией Keycloak
- [ ] Реализовать модели данных и связи с пользователями (user_id из Keycloak)
- [ ] Добавить CRUD операции для проектов
- [ ] Реализовать управление участниками проекта (синхронизация с Keycloak группами)
- [ ] Настроить события (project.created, project.updated)
- [ ] Добавить тестирование и документацию

### Этап 4: Tasks Service
- [ ] Создать Tasks Service с базовой функциональностью
- [ ] Реализовать модели данных и связи с проектами
- [ ] Добавить CRUD операции для задач
- [ ] Реализовать назначение исполнителей и теги
- [ ] Настроить события (task.created, task.updated, task.assigned)
- [ ] Добавить Saga pattern для сложных операций
- [ ] Реализовать Event Sourcing для аудита
- [ ] Настроить CQRS для оптимизации запросов
- [ ] Добавить тестирование и документацию

### Этап 5: Comments Service
- [ ] Создать Comments Service
- [ ] Реализовать модели данных и связи с задачами
- [ ] Добавить CRUD операции для комментариев
- [ ] Реализовать упоминания пользователей
- [ ] Настроить события (comment.added)
- [ ] Добавить тестирование и документацию

### Этап 6: API Gateway
- [ ] Создать Gateway Service на Spring Cloud Gateway
- [ ] Настроить маршрутизацию к всем сервисам
- [ ] Реализовать фильтры аутентификации и авторизации
- [ ] Добавить rate limiting и circuit breaker
- [ ] Настроить мониторинг и логирование
- [ ] Протестировать интеграцию всех сервисов

### Этап 7: Дополнительные паттерны
- [ ] Реализовать Outbox Pattern для гарантированной доставки событий
- [ ] Настроить Circuit Breaker и Bulkhead
- [ ] Добавить Distributed Caching
- [ ] Реализовать Message Queue Patterns
- [ ] Настроить Security Patterns
- [ ] Добавить Performance Patterns

### Этап 8: Тестирование и оптимизация
- [ ] Настроить Contract Testing между сервисами
- [ ] Добавить Performance Testing
- [ ] Реализовать Security Testing
- [ ] Настроить Chaos Engineering тесты
- [ ] Оптимизировать производительность
- [ ] Подготовить документацию для продакшена

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

## Keycloak Integration
- Конфигурация Keycloak:
  - Realm: `taskforge`
  - Clients: `taskforge-frontend`, `taskforge-backend`
  - Роли: `admin`, `project_manager`, `developer`, `viewer`
  - Группы: `project-{projectId}-members`, `project-{projectId}-admins`
  - Пользовательские атрибуты: `display_name`, `department`, `phone`
- Spring Security OAuth2:
  - JWT token validation с публичными ключами Keycloak
  - Автоматическое извлечение ролей из JWT claims
  - Интеграция с Spring Security для method-level security
- API для синхронизации:
  - GET `/users/sync` — синхронизация пользователей из Keycloak
  - GET `/users/{id}` — получение информации о пользователе
  - GET `/users` — поиск пользователей (поиск/пагинация)
- События:
  - Публикация `user.synced`, `user.updated` при синхронизации из Keycloak
- Тестирование:
  - Интеграционные тесты с Keycloak Testcontainers
  - Тестирование JWT token validation
  - Тестирование синхронизации пользователей

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

## Saga Pattern (Оркестрация распределённых транзакций)

### Проблемы и сценарии применения
- **Проблема**: В микросервисах нет ACID транзакций между сервисами. Нужна консистентность данных при сложных операциях.
- **Сервисы**: Tasks, Projects, Comments, Auth/Identity
- **Сценарии**:
  1. **Создание проекта с первыми задачами** — атомарность создания проекта + задач + назначений
  2. **Удаление пользователя** — каскадное удаление/архивирование связанных данных
  3. **Перенос задач между проектами** — валидация прав + обновление связей

### Зависимости и инфраструктура
- [ ] Подключить `spring-cloud-starter-stream-kafka` для работы с Kafka
- [ ] Подключить `spring-statemachine-starter` для управления состояниями саг
- [ ] Настроить Kafka topics для событий саг: `saga.project-creation.*`, `saga.user-deletion.*`
- [ ] Создать таблицу `saga_instances` в PostgreSQL для хранения состояния саг

### Реализация Saga Orchestrator
- [ ] Создать `ProjectCreationSaga` в Tasks Service как координатор
- [ ] Реализовать методы: `startProjectCreation()`, `onProjectCreated()`, `onTasksCreated()`, `onTasksAssigned()`
- [ ] Добавить компенсационные методы: `compensateProjectCreation()`, `compensateTaskCreation()`
- [ ] Настроить обработчики событий с аннотациями `@SagaOrchestrationStart`, `@SagaOrchestrationStep`, `@SagaOrchestrationEnd`
- [ ] Реализовать `UserDeletionSaga` для каскадного удаления пользователя
- [ ] Реализовать `TaskTransferSaga` для переноса задач между проектами

### State Machine Configuration
- [ ] Создать `ProjectCreationStateMachine` с состояниями: `PROJECT_CREATING`, `TASKS_CREATING`, `TASKS_ASSIGNING`, `COMPLETED`, `FAILED`
- [ ] Настроить переходы между состояниями по событиям: `PROJECT_CREATED`, `TASKS_CREATED`, `TASKS_ASSIGNED`
- [ ] Добавить переходы в состояние `FAILED` при ошибках с компенсационными действиями
- [ ] Создать аналогичные state machine для других типов саг

### Персистентность состояния саг
- [ ] Создать таблицу `saga_instances` с полями: `id`, `saga_type`, `correlation_id`, `state`, `payload`, `created_at`, `updated_at`
- [ ] Добавить индексы: `idx_saga_correlation`, `idx_saga_state`
- [ ] Реализовать `SagaRepository` для сохранения/загрузки состояния саг
- [ ] Добавить уникальный индекс по `(saga_type, correlation_id)` для предотвращения дублирования

### Обработка ошибок и таймаутов
- [ ] Создать `SagaTimeoutHandler` с `@Scheduled` методом для проверки зависших саг
- [ ] Настроить таймаут 5 минут для состояний саг
- [ ] Реализовать автоматическую компенсацию при таймауте
- [ ] Добавить уведомления в систему мониторинга при таймаутах
- [ ] Настроить retry логику для временных ошибок (сетевые проблемы, недоступность сервисов)

### Тестирование саг
- [ ] Создать интеграционные тесты `ProjectCreationSagaTest` с Testcontainers
- [ ] Тест успешного завершения саги: создание проекта → задач → назначений
- [ ] Тест компенсации при ошибке: симуляция ошибки создания задач → откат проекта
- [ ] Тест таймаутов: симуляция зависшей саги → автоматическая компенсация
- [ ] Тест идемпотентности: повторная отправка команды → корректная обработка
- [ ] Добавить тесты для других типов саг: `UserDeletionSagaTest`, `TaskTransferSagaTest`

### Мониторинг и метрики
- [ ] Создать `SagaMetrics` компонент для сбора метрик Prometheus
- [ ] Метрики: `saga.started`, `saga.completed`, `saga.failed`, `saga.duration`
- [ ] Добавить теги по типу саги: `project_creation`, `user_deletion`, `task_transfer`
- [ ] Настроить алерты в Grafana при высокой частоте неудачных саг
- [ ] Добавить логирование ключевых событий саг с correlation_id для трассировки

### Оптимизация и производительность
- [ ] Настроить batch обработку событий для саг с большим количеством шагов
- [ ] Реализовать параллельное выполнение независимых шагов саги
- [ ] Добавить кэширование состояния саг в Redis для быстрого доступа
- [ ] Настроить очистку завершённых саг старше 30 дней
- [ ] Оптимизировать запросы к `saga_instances` с правильными индексами

## Дополнительные паттерны и интеграции

### Circuit Breaker Pattern
- [ ] Подключить `spring-cloud-starter-circuitbreaker-resilience4j`
- [ ] Настроить Circuit Breaker для вызовов к внешним сервисам (.NET сервисы)
- [ ] Конфигурация: failure rate threshold 50%, timeout 3s, retry 3 раза
- [ ] Fallback методы для критических операций (кэшированные данные)
- [ ] Метрики Circuit Breaker в Prometheus для мониторинга

### Bulkhead Pattern
- [ ] Разделить thread pools для разных типов операций (CRUD, поиск, уведомления)
- [ ] Настроить отдельные connection pools для разных БД (PostgreSQL, MongoDB, Redis)
- [ ] Изолировать ресурсы для тяжёлых операций (массовые обновления, экспорт)
- [ ] Конфигурация thread pool executor'ов с разными размерами очередей

### Event Sourcing (для критических доменов)
- [ ] Реализовать Event Store для Tasks Service (история всех изменений задач)
- [ ] Создать таблицу `task_events` с полями: `id`, `task_id`, `event_type`, `payload`, `version`, `created_at`
- [ ] Реализовать Event Handlers для восстановления состояния задач
- [ ] Добавить snapshot'ы для оптимизации чтения (каждые 100 событий)
- [ ] Тестирование: проверка корректности восстановления состояния

### CQRS (Command Query Responsibility Segregation)
- [ ] Разделить модели для команд (write) и запросов (read) в Tasks Service
- [ ] Создать отдельные DTO для команд: `CreateTaskCommand`, `UpdateTaskCommand`, `AssignTaskCommand`
- [ ] Создать отдельные DTO для запросов: `TaskView`, `TaskListView`, `TaskDetailsView`
- [ ] Настроить MapStruct маппинг между моделями команд/запросов и доменными моделями
- [ ] Оптимизировать read модели под конкретные use case'ы

### Outbox Pattern
- [ ] Создать таблицу `outbox_events` для гарантированной доставки событий
- [ ] Реализовать `OutboxEventPublisher` с транзакционной публикацией событий
- [ ] Настроить периодическую отправку событий из outbox (каждые 5 секунд)
- [ ] Добавить идемпотентность для предотвращения дублирования событий
- [ ] Очистка обработанных событий старше 7 дней

### API Gateway Implementation (Spring Cloud Gateway)
- [ ] Создать отдельный микросервис Gateway на базе Spring Cloud Gateway
- [ ] Настроить маршрутизацию к внутренним сервисам: `/api/auth/**`, `/api/projects/**`, `/api/tasks/**`, `/api/comments/**`
- [ ] Конфигурация маршрутов через `application.yml` с предикатами и фильтрами
- [ ] Настроить load balancing между инстансами сервисов (Round Robin, Weighted Response Time)
- [ ] Реализовать фильтр аутентификации: извлечение JWT из заголовка Authorization
- [ ] Добавить фильтр авторизации: проверка ролей и прав доступа к ресурсам
- [ ] Настроить rate limiting: ограничение запросов по IP/пользователю (Redis-based)
- [ ] Реализовать CORS фильтр для cross-origin запросов
- [ ] Добавить фильтр логирования: запись всех входящих запросов с correlation ID
- [ ] Настроить фильтр добавления заголовков: X-Correlation-Id, X-Forwarded-For
- [ ] Реализовать фильтр трансформации ответов: добавление метаданных, форматирование ошибок
- [ ] Добавить circuit breaker на уровне Gateway для защиты downstream сервисов
- [ ] Настроить retry логику для временных ошибок (5xx, timeout)
- [ ] Реализовать фильтр кэширования для GET запросов (Redis-based)
- [ ] Настроить мониторинг Gateway: метрики Prometheus, health checks
- [ ] Добавить фильтр валидации: проверка обязательных заголовков и параметров
- [ ] Реализовать фильтр безопасности: защита от SQL injection, XSS, CSRF
- [ ] Настроить фильтр сжатия ответов: gzip compression для больших payload'ов
- [ ] Добавить фильтр трансформации запросов: изменение URL, добавление параметров
- [ ] Реализовать фильтр агрегации: объединение ответов от нескольких сервисов
- [ ] Настроить конфигурацию через Spring Cloud Config Server
- [ ] Добавить поддержку WebSocket соединений для real-time уведомлений
- [ ] Реализовать фильтр версионирования API: поддержка разных версий API
- [ ] Настроить фильтр лимитирования размера запроса: защита от DoS атак
- [ ] Добавить фильтр геолокации: маршрутизация по региону пользователя
- [ ] Реализовать фильтр A/B тестирования: маршрутизация части трафика
- [ ] Настроить фильтр резервного копирования: fallback на статичные ответы при недоступности сервисов

### Distributed Caching
- [ ] Настроить Redis как distributed cache для сессий и кэширования
- [ ] Реализовать кэширование пользовательских данных (роли, права доступа)
- [ ] Кэширование результатов поиска задач с TTL 5 минут
- [ ] Кэширование проектов и участников с TTL 15 минут
- [ ] Настроить cache eviction policies (LRU, TTL-based)

### Message Queue Patterns
- [ ] Реализовать Dead Letter Queue для обработки неудачных сообщений
- [ ] Настроить retry с exponential backoff для временных ошибок
- [ ] Добавить message deduplication по message ID
- [ ] Реализовать message ordering для критических событий (по task_id)
- [ ] Настроить batch processing для массовых операций

### Observability Patterns
- [ ] Настроить distributed tracing с OpenTelemetry и Jaeger
- [ ] Добавить structured logging с correlation ID для трассировки запросов
- [ ] Реализовать health checks для всех сервисов (/actuator/health)
- [ ] Настроить custom metrics для бизнес-метрик (количество задач, проектов)
- [ ] Добавить alerting rules в Prometheus для критических метрик

### Security Patterns
- [ ] Реализовать JWT token validation с публичными ключами Keycloak
- [ ] Добавить RBAC (Role-Based Access Control) на уровне методов
- [ ] Настроить method-level security с `@PreAuthorize` аннотациями
- [ ] Реализовать синхронизацию пользователей и ролей с Keycloak
- [ ] Добавить интеграцию с Keycloak Admin API для управления пользователями
- [ ] Реализовать audit logging для всех изменений данных
- [ ] Добавить input validation и sanitization для предотвращения инъекций

### Performance Patterns
- [ ] Реализовать connection pooling для всех БД (HikariCP)
- [ ] Настроить lazy loading для JPA entities
- [ ] Добавить pagination для всех списковых операций
- [ ] Реализовать async processing для тяжёлых операций
- [ ] Настроить compression для HTTP responses (gzip)

### Testing Patterns
- [ ] Реализовать contract testing с Pact для межсервисного взаимодействия
- [ ] Добавить mutation testing с PIT для проверки качества unit тестов
- [ ] Настроить performance testing с JMeter для нагрузочного тестирования
- [ ] Реализовать chaos engineering тесты для проверки resilience
- [ ] Добавить security testing с OWASP ZAP для проверки уязвимостей

## Нефункциональные требования
- Идемпотентность для повторных POST через Idempotency-Key.
- Ограничения скорости (rate limiting) на уровне Gateway.
- Миграции обратимы; данные — с мягким удалением (soft-delete при необходимости).
- Обновления схем — с оценкой влияния на индексы и планы запросов.
- Saga pattern для распределённых транзакций между сервисами.
- Circuit Breaker, Bulkhead, Event Sourcing, CQRS для повышения надёжности и производительности.

## Definition of Done
- Все эндпойнты покрыты интеграционными тестами (>=80%).
- События публикуются и корректно сериализуются (Avro/JSON Schema). Проверены контрактные тесты.
- Обновлён OpenAPI и диаграммы.
- CI зелёный; образы в реестре; Helm chart обновлён.
