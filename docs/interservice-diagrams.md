# Межсервисное взаимодействие (диаграммы)

## Расширенная архитектурная диаграмма (включая инфраструктуру)
```mermaid
flowchart LR
  %% Клиенты и периметр
  subgraph CLIENTS[Clients]
    WEB[Web App]
    MOBILE[Mobile App]
  end

  subgraph EDGE[Edge]
    CDN[CDN]
    GW[API Gateway / OIDC Proxy]
  end

  CLIENTS --> CDN --> GW
  MOBILE --> GW

  %% Доменные сервисы (Java)
  subgraph JAVA[Domain Services (Java)]
    AUTH[Auth/Identity (Java)]
    PROJ[Projects (Java)]
    TASKS[Tasks (Java)]
    COMM[Comments (Java)]
  end

  %% Доменные сервисы (.NET)
  subgraph DOTNET[Domain Services (.NET)]
    FILES[Files (.NET)]
    NOTIF[Notifications (.NET)]
    SEARCH[Search (.NET)]
    REPORT[Reporting (.NET)]
  end

  %% Сообщения
  subgraph MSG[Messaging]
    KAFKA[(Kafka Cluster)]
  end

  %% Хранилища данных
  subgraph DATA[Data Stores]
    PG[(PostgreSQL)]
    MONGO[(MongoDB)]
    REDIS[(Redis)]
    ES[(Elasticsearch/OpenSearch)]
    MINIO[(MinIO/S3 Object Storage)]
  end

  %% Внешние интеграции
  subgraph EXT[External Integrations]
    SMTP[(SMTP Email)]
    WEBPUSH[(Web Push Service)]
    CLAMAV[(ClamAV Antivirus)]
  end

  %% Наблюдаемость
  subgraph OBS[Observability]
    OTEL[OpenTelemetry Collector]
    PROM[(Prometheus)]
    GRAF[Grafana]
    LOGS[(ELK/EFK)]
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

  %% Observability wiring
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
- MinIO используется для бинарных файлов и экспортов отчётов, PostgreSQL — для OLTP, MongoDB — для истории/аудита, Redis — для кэшей/сессий/идемпотентности, Elasticsearch — для поиска.

---

## Карта хранилищ (что и где хранится)
```mermaid
flowchart TB
  subgraph OLTP[PostgreSQL]
    U[(USERS)]
    P[(PROJECTS, PROJECT_MEMBERS)]
    T[(TASKS, TASK_ASSIGNEES, TAGS, TASK_TAGS)]
    C[(COMMENTS)]
    F[(FILES, FILE_VERSIONS)]
    N[(NOTIFICATION_TEMPLATES, NOTIFICATIONS)]
  end

  subgraph HISTORY[MongoDB]
    TA[(task_activity)]
  end

  subgraph CACHE[Redis]
    RC[(Sessions, Idempotency Keys, Query Cache)]
  end

  subgraph SEARCH[Elasticsearch]
    ET[(tasks index)]
    EC[(comments index)]
    EF[(files index)]
  end

  subgraph OBJECTS[MinIO/S3]
    OA[(task-attachments/...)]
    OR[(reports-exports/...)]
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
  participant T as Tasks Service (Java)
  participant B as Kafka
  participant N as Notifications (.NET)
  participant S as Search (.NET)
  participant PG as PostgreSQL
  participant MG as MongoDB

  C->>GW: POST /tasks
  GW->>T: POST /tasks (JWT, X-Correlation-Id)
  T->>PG: INSERT task
  T->>MG: INSERT task_activity(created)
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
  participant CM as Comments (Java)
  participant B as Kafka
  participant N as Notifications (.NET)
  participant S as Search (.NET)
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
  participant F as Files (.NET)
  participant B as Kafka
  participant S3 as MinIO/S3
  participant CL as ClamAV
  participant PG as PostgreSQL

  C->>GW: POST /files (taskId?)
  GW->>F: POST /files
  F->>S3: PUT object (pre-signed)
  F->>CL: scan object
  F->>PG: INSERT file + version
  F-->>C: 201 + presigned URL
  F-->>B: publish file.uploaded { taskId }
```
