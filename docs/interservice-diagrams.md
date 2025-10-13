# Межсервисное взаимодействие (диаграммы)

## Контекстная диаграмма (C4-like)
```mermaid
flowchart LR
  GW[API Gateway] --> AUTH[Auth/Identity]
  GW --> PROJ[Projects]
  GW --> TASKS[Tasks]
  GW --> COMM[Comments]
  GW --> FILES[Files]
  GW --> NOTIF[Notifications]
  GW --> SEARCH[Search]
  GW --> REPORT[Reporting]
  BROKER[(Kafka/RabbitMQ)]

  TASKS -- task.* --> BROKER
  COMM -- comment.added --> BROKER
  FILES -- file.uploaded --> BROKER
  NOTIF -- notification.sent --> BROKER

  SEARCH -- consumes --> BROKER
  NOTIF -- consumes --> BROKER
  REPORT -- consumes --> BROKER
```

## Последовательность: создание задачи
```mermaid
sequenceDiagram
  participant C as Client
  participant GW as API Gateway
  participant T as Tasks Service (Java)
  participant N as Notifications (.NET)
  participant S as Search (.NET)
  participant B as Broker

  C->>GW: POST /tasks
  GW->>T: POST /tasks (JWT, X-Correlation-Id)
  T-->>C: 201 Created
  T-->>B: event task.created
  B-->>N: task.created
  B-->>S: task.created
  N-->>N: enqueue delivery
  S-->>S: upsert index
```

## Последовательность: комментарий к задаче
```mermaid
sequenceDiagram
  participant C as Client
  participant GW as API Gateway
  participant CM as Comments (Java)
  participant N as Notifications (.NET)
  participant S as Search (.NET)
  participant B as Broker

  C->>GW: POST /tasks/{id}/comments
  GW->>CM: POST /tasks/{id}/comments
  CM-->>C: 201 Created
  CM-->>B: event comment.added
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
  participant T as Tasks (Java)
  participant S as Search (.NET)
  participant B as Broker

  C->>GW: POST /files (taskId?)
  GW->>F: POST /files
  F-->>C: 201 + presigned URL
  F-->>B: event file.uploaded { taskId }
  B-->>T: file.uploaded (link to task)
  B-->>S: file.uploaded (index)
```
