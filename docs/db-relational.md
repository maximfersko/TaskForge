# Схемы реляционных БД (PostgreSQL)

Ниже приведены ключевые таблицы для доменов Users, Projects, Tasks, Comments, Files, Notifications, Reporting.

## ER-диаграмма (Mermaid)
```mermaid
erDiagram
  USERS ||--o{ USER_ROLES : has
  ROLES ||--o{ USER_ROLES : contains
  USERS ||--o{ REFRESH_TOKENS : has

  PROJECTS ||--o{ PROJECT_MEMBERS : has
  PROJECTS ||--o{ TASKS : has
  TASKS ||--o{ TASK_ASSIGNEES : has
  TASKS ||--o{ TASK_TAGS : has
  TAGS ||--o{ TASK_TAGS : contains
  TASKS ||--o{ COMMENTS : has

  FILES }o--|| TASKS : "optional for task"
  FILE_VERSIONS ||--|{ FILES : belongs_to

  NOTIFICATION_TEMPLATES ||--o{ NOTIFICATIONS : used_by
  USERS ||--o{ NOTIFICATIONS : recipient

  USERS {
    uuid id PK
    varchar email UK
    varchar password_hash
    varchar display_name
    varchar status
    timestamptz created_at
    timestamptz updated_at
  }
  ROLES {
    uuid id PK
    varchar code UK
    varchar name
  }
  USER_ROLES {
    uuid user_id FK
    uuid role_id FK
  }
  REFRESH_TOKENS {
    uuid id PK
    uuid user_id FK
    varchar token UK
    timestamptz expires_at
    boolean revoked
  }

  PROJECTS {
    uuid id PK
    varchar key UK
    varchar name
    text description
    uuid owner_id FK
    timestamptz created_at
    timestamptz updated_at
  }
  PROJECT_MEMBERS {
    uuid project_id FK
    uuid user_id FK
    varchar role
    timestamptz added_at
  }

  TASKS {
    uuid id PK
    uuid project_id FK
    varchar title
    text description
    varchar status
    varchar priority
    date due_date
    uuid created_by FK
    timestamptz created_at
    timestamptz updated_at
  }
  TASK_ASSIGNEES {
    uuid task_id FK
    uuid user_id FK
  }
  TAGS {
    uuid id PK
    varchar name UK
    varchar color
  }
  TASK_TAGS {
    uuid task_id FK
    uuid tag_id FK
  }
  COMMENTS {
    uuid id PK
    uuid task_id FK
    uuid author_id FK
    text body
    boolean is_edited
    timestamptz created_at
    timestamptz updated_at
  }

  FILES {
    uuid id PK
    uuid owner_id FK
    uuid task_id FK
    varchar name
    varchar content_type
    bigint size
    varchar storage_key
    varchar checksum
    timestamptz created_at
  }
  FILE_VERSIONS {
    uuid id PK
    uuid file_id FK
    int version
    varchar storage_key
    bigint size
    varchar checksum
    timestamptz created_at
  }

  NOTIFICATION_TEMPLATES {
    uuid id PK
    varchar code UK
    varchar subject
    text body
    varchar channel
    varchar locale
    timestamptz updated_at
  }
  NOTIFICATIONS {
    uuid id PK
    uuid recipient_id FK
    varchar channel
    varchar template_code
    jsonb payload_json
    varchar status
    int try_count
    timestamptz created_at
    timestamptz sent_at
  }
```

## Ключевые ограничения и индексы
- Уникальные: `users.email`, `roles.code`, `projects.key`, `tags.name`.
- Внешние ключи: каскадное удаление для связей many-to-many по потребности, soft-delete обсуждается отдельно.
- Индексы:
  - `tasks(project_id, status, due_date)`, `comments(task_id, created_at)`
  - `files(task_id, created_at)`, `notifications(recipient_id, created_at)`

## Таблицы и поля (описания)
- USERS.status: active/locked/deleted.
- TASKS.status: backlog/todo/in_progress/in_review/done/cancelled.
- TASKS.priority: low/medium/high/urgent.
- NOTIFICATIONS.status: pending/sent/failed.

## Миграции
- Использовать Flyway/EF Migrations; версии — атомарные изменения с обратимостью.
- Все изменения сопровождать измерением влияния на планы запросов.
