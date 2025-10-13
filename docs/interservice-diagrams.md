# Межсервисное взаимодействие (диаграммы)

## Расширенная архитектурная диаграмма (включая инфраструктуру)
```mermaid
flowchart LR
  %% Клиенты и периметр
  subgraph CLIENTS
    WEB[Web App]
    MOBILE[Mobile App]
  end

  subgraph EDGE
    CDN[CDN]
    GW[API Gateway + OIDC Proxy]
  end

  CLIENTS --> CDN
  CDN --> GW
  MOBILE --> GW

  %% Доменные сервисы (Java)
  subgraph JAVA
    AUTH[Auth Identity - Java]
    PROJ[Projects - Java]
    TASKS[Tasks - Java]
    COMM[Comments - Java]
  end

  %% Доменные сервисы (.NET)
  subgraph DOTNET
    FILES[Files - .NET]
    NOTIF[Notifications - .NET]
    SEARCH[Search - .NET]
    REPORT[Reporting - .NET]
  end

  %% Сообщения
  subgraph MSG
    KAFKA[(Kafka Cluster)]
  end

  %% Хранилища данных
  subgraph DATA
    PG[(PostgreSQL)]
    MONGO[(MongoDB)]
    REDIS[(Redis)]
    ES[(Elasticsearch OpenSearch)]
    MINIO[(MinIO S3 Object Storage)]
  end

  %% Внешние интеграции
  subgraph EXT
    SMTP[(SMTP Email)]
    WEBPUSH[(Web Push Service)]
    CLAMAV[(ClamAV Antivirus)]
  end

  %% Наблюдаемость
  subgraph OBS
    OTEL[OpenTelemetry Collector]
    PROM[(Prometheus)]
    GRAF[Grafana]
    LOGS[(ELK or EFK)]
  end

  %% Связи с периметра
  GW --> AUTH
  GW --> PROJ
  GW --> TASKS
  GW --> COMM
  GW --> FILES
  GW --> NOTIF
  GW --> SEARCH
  GW --> REPORT

  %% Java сервисы -> данные/сообщения
  AUTH --> PG
  AUTH --> REDIS
  PROJ --> PG
  TASKS --> PG
  TASKS --> MONGO
  TASKS --> REDIS
  COMM --> PG

  %% .NET сервисы -> данные/интеграции
  FILES --> MINIO
  FILES --> PG
  FILES --> REDIS
  FILES --> CLAMAV
  NOTIF --> PG
  NOTIF --> REDIS
  NOTIF --> SMTP
  NOTIF --> WEBPUSH
  SEARCH --> ES
  REPORT --> PG
  REPORT --> ES
  REPORT --> MINIO

  %% События (publish)
  TASKS -- "task.created | task.updated | task.assigned" --> KAFKA
  COMM -- "comment.added" --> KAFKA
  FILES -- "file.uploaded | file.version_added" --> KAFKA
  NOTIF -- "notification.sent" --> KAFKA

  %% События (consume)
  SEARCH -- consumes --> KAFKA
  NOTIF -- consumes --> KAFKA
  REPORT -- consumes --> KAFKA

  %% Наблюдаемость
  AUTH --> OTEL
  PROJ --> OTEL
  TASKS --> OTEL
  COMM --> OTEL
  FILES --> OTEL
  NOTIF --> OTEL
  SEARCH --> OTEL
  REPORT --> OTEL
  GW --> OTEL

  OTEL --> PROM
  OTEL --> LOGS
  GRAF --- PROM
```

### Легенда
- Кластеры DATA, MSG, OBS группируют инфраструктуру.
- Направленные стрелки показывают синхронные вызовы; стрелки к Kafka — публикацию событий; пометка consumes — подписка.
- MinIO используется для бинарных файлов и экспортов отчётов, PostgreSQL — для OLTP, MongoDB — для истории и аудита, Redis — для кэшей, сессий и идемпотентности, Elasticsearch — для поиска.

---

## Карта хранилищ (что и где хранится)
```mermaid
flowchart TB
  subgraph OLTP
    U[(USERS)]
    P[(PROJECTS, PROJECT_MEMBERS)]
    T[(TASKS, TASK_ASSIGNEES, TAGS, TASK_TAGS)]
    C[(COMMENTS)]
    F[(FILES, FILE_VERSIONS)]
    N[(NOTIFICATION_TEMPLATES, NOTIFICATIONS)]
  end

  subgraph HISTORY
    TA[(task_activity)]
  end

  subgraph CACHE
    RC[(Sessions, Idempotency Keys, Query Cache)]
  end

  subgraph SEARCH
    ET[(tasks index)]
    EC[(comments index)]
    EF[(files index)]
  end

  subgraph OBJECTS
    OA[(task-attachments ...)]
    OR[(reports-exports ...)]
  end

  T --> TA
  C --> EC
  T --> ET
  F --> EF
  F --> OA
  N --> OR
  U --- RC
  T --- RC
```

---

## Последовательность: создание задачи
```mermaid
sequenceDiagram
  participant C as Client
  participant GW as API Gateway
  participant T as Tasks Service - Java
  participant B as Kafka
  participant N as Notifications - .NET
  participant S as Search - .NET
  participant PG as PostgreSQL
  participant MG as MongoDB

  C->>GW: POST /tasks
  GW->>T: POST /tasks (JWT, X-Correlation-Id)
  T->>PG: INSERT task
  T->>MG: INSERT task_activity created
  T-->>C: 201 Created
  T-->>B: publish task.created
  B-->>N: task.created
  B-->>S: task.created
  N-->>N: enqueue delivery
  S-->>S: upsert task index
```

## Последовательность: комментарий к задаче
```mermaid
sequenceDiagram
  participant C as Client
  participant GW as API Gateway
  participant CM as Comments - Java
  participant B as Kafka
  participant N as Notifications - .NET
  participant S as Search - .NET
  participant PG as PostgreSQL

  C->>GW: POST /tasks/{id}/comments
  GW->>CM: POST /tasks/{id}/comments
  CM->>PG: INSERT comment
  CM-->>C: 201 Created
  CM-->>B: publish comment.added
  B-->>N: comment.added
  B-->>S: comment.added
  N-->>N: generate notifications
  S-->>S: index comment
```

## Последовательность: загрузка файла
```mermaid
sequenceDiagram
  participant C as Client
  participant GW as API Gateway
  participant F as Files - .NET
  participant B as Kafka
  participant S3 as MinIO S3
  participant CL as ClamAV
  participant PG as PostgreSQL

  C->>GW: POST /files (taskId?)
  GW->>F: POST /files
  F->>S3: PUT object pre-signed
  F->>CL: scan object
  F->>PG: INSERT file + version
  F-->>C: 201 + presigned URL
  F-->>B: publish file.uploaded { taskId }
```

### Детализация по хранилищам

- PostgreSQL (OLTP)
  - Основные сущности: `USERS`, `PROJECTS`, `PROJECT_MEMBERS`, `TASKS`, `TASK_ASSIGNEES`, `TAGS`, `TASK_TAGS`, `COMMENTS`, `FILES`, `FILE_VERSIONS`, `NOTIFICATION_TEMPLATES`, `NOTIFICATIONS`.
  - Индексация:
    - `TASKS(project_id, status, due_date)`, `TASKS(title) GIN trigram при необходимости`
    - `COMMENTS(task_id, created_at)`
    - `FILES(task_id, created_at)`, `USERS(email) UNIQUE`, `PROJECTS(key) UNIQUE`, `TAGS(name) UNIQUE`
  - Паттерны доступа: транзакционные CRUD, пагинация, фильтры по проекту/статусу/исполнителю, join'ы по справочникам.
  - Ретеншн: основное долгосрочное хранение; soft-delete по потребности.
  - Бэкапы: ежедневные snapshot'ы + point-in-time recovery; тест восстановления ежемесячно.
  - Владелец: команды Java (.Java) и .NET сервисов, через свои схемы/роли.

- MongoDB (История/аудит)
  - Коллекции: `task_activity` (события жизненного цикла задач).
  - Индексация: `{ taskId: 1, createdAt: -1 }`, шардирование по `taskId` при росте.
  - Паттерны доступа: аппенды при изменениях, чтение лент активности по `taskId`.
  - Ретеншн: 18 месяцев (конфигурируемо), далее архив или удаление.
  - Бэкапы: бэкап на уровне кластера + периодические дампы коллекции.
  - Владелец: Tasks (Java).

- Redis (Кэш/сессии/идемпотентность)
  - Ключи: `session:{userId}`, `idemp:{service}:{key}`, `task:list:{projectId}:{filtersHash}`.
  - Индексация: не применяется; TTL: 1h для сессий, 24h для идемпотентности, 5m для списков.
  - Паттерны доступа: get/set, инвалидация по событиям, ограничения частоты.
  - Ретеншн: краткосрочно, только кэш и служебные ключи.
  - Бэкапы: не критично; AOF/RDB по профилю эксплуатации.
  - Владелец: все сервисы как клиенты; операционный владелец — платформа.

- Elasticsearch/OpenSearch (Поиск)
  - Индексы: `tasks`, `comments`, `files`.
  - Схемы документов: см. `db-nosql.md` (TaskIndexDoc, CommentIndexDoc, FileIndexDoc).
  - Анализаторы: ru/en, edge_ngram для автодополнения, синонимы.
  - Паттерны доступа: upsert по событиям `task.*`, `comment.added`, `file.uploaded`; запросы полнотекста с фильтрами.
  - Ретеншн: 12 месяцев для `comments`, 24 месяца для `tasks`/`files` (регулируемо ILM).
  - Бэкапы: snapshot в объектное хранилище по расписанию.
  - Владелец: Search (.NET).

- MinIO/S3 (Объектное хранилище)
  - Бакеты: `task-attachments`, `reports-exports`.
  - Ключи: `task-attachments/{projectId}/{taskId}/{fileId}/{version}`, `reports-exports/{reportId}/{ts}`.
  - Паттерны доступа: pre-signed URL для загрузки/скачивания; серверная валидация.
  - Ретеншн: версии файлов — согласно политике проекта; отчёты — 30 дней.
  - Бэкапы: версионирование + репликация бакета между зонами.
  - Владелец: Files (.NET), Reporting (.NET) для экспортов.
