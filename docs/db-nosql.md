# Схемы NoSQL (MongoDB, Redis, Elasticsearch)

## MongoDB (аудит/история)
```mermaid
classDiagram
  class TaskActivityDoc {
    _id: ObjectId
    taskId: UUID
    actorId: UUID
    type: string // created|updated|assigned|commented
    payload: object
    createdAt: Date
  }
```
- Коллекции: `task_activity` (шардинг по `taskId`).
- Индексы: `{ taskId: 1, createdAt: -1 }`.

## Redis (кэш/сессии/ключи идемпотентности)
- Ключи:
  - `idemp:{service}:{key}` -> TTL 24h
  - `session:{userId}` -> JWT meta, TTL 1h
  - `task:list:{projectId}:{filtersHash}` -> страницы результатов, TTL 5m

## Elasticsearch/OpenSearch (поиск)
```mermaid
classDiagram
  class TaskIndexDoc {
    id: UUID
    projectId: UUID
    title: string
    description: string
    status: string
    priority: string
    tags: string[]
    assignees: UUID[]
    dueDate: date
    createdAt: date
    updatedAt: date
  }
  class CommentIndexDoc {
    id: UUID
    taskId: UUID
    authorId: UUID
    body: string
    createdAt: date
  }
  class FileIndexDoc {
    id: UUID
    taskId: UUID
    projectId: UUID
    name: string
    contentType: string
    size: long
    createdAt: date
  }
```
- Анализаторы: ru/en, edge_ngram для подсказок, стоп-слова, синонимы.
- Политика обновления: upsert по событиям `task.*`, `comment.added`, `file.uploaded`.
