# Методологія Jira

Статус: особистий робочий документ  
Джерело: `archive/2026-05-11/Методологія ведення Jira.md`

## Призначення

Цей документ визначає просту методологію Jira для project work у product, platform, infrastructure і security tasks.

Ціль — consistent planning і filtering, а не ceremony.

## Statuses

| Status | Значення |
| --- | --- |
| Backlog | idea або task існує, але не selected |
| Selected for Development | готово скоро стартувати |
| In Progress | активно виконується |
| Done | завершено і verified |

Правила:

- уникати переміщення unclear tasks у `Selected for Development`;
- кожна active task має мати owner, domain і expected result;
- `Done` потребує verification, а не лише implementation.

## Виміри labels

Використовувати labels, щоб відповісти на чотири питання:

| Dimension | Питання |
| --- | --- |
| Домен | Яка product/system area володіє цим? |
| Workstream | Який це вид work? |
| Environment | Який runtime/scope це зачіпає? |
| Program | Яку larger initiative це підтримує? |

## Рекомендований формат labels

Використовувати predictable prefixes:

```text
domain:<name>
workstream:<name>
env:<name>
program:<name>
```

Приклади:

```text
domain:tirascloud
domain:service-center
domain:platform
domain:security
workstream:gitops
workstream:cicd
workstream:backend
workstream:docs
env:dev
env:stage
env:prod
program:migration
program:access-governance
```

## Домен split

Запропоновані domains:

| Домен | Використовувати для |
| --- | --- |
| `domain:tirascloud` | TirasCloud app і GitOps migration |
| `domain:service-center` | SCNet, SCNode, SCDocs, Service Center product work |
| `domain:platform` | shared Kubernetes, GitOps, logging, storage, CI/CD |
| `domain:security` | access, secrets, governance, incident response |
| `domain:docs` | documentation-only tasks |

## Workstream split

Запропоновані workstreams:

- `workstream:discovery`;
- `workstream:architecture`;
- `workstream:implementation`;
- `workstream:gitops`;
- `workstream:cicd`;
- `workstream:testing`;
- `workstream:runbook`;
- `workstream:security`;
- `workstream:cleanup`.

## Практична форма task

Хороша Jira task має включати:

- context;
- intended result;
- files/repos affected;
- validation steps;
- known blockers;
- out-of-scope notes.

Template:

```text
Ціль:

Context:

Обсяг:

Поза обсягом:

Acceptance criteria:

Перевірка:
```

## Strategic tasks

Використовувати program labels для larger streams:

- `program:tirascloud-gitops-migration`;
- `program:service-center-mvp`;
- `program:platform-hardening`;
- `program:security-governance`;
- `program:docs-consolidation`.

## Documentation consolidation labels

Використовувати ці labels для docs work, яка обробляє sources із `process/`:

```text
workstream:docs
workstream:security
workstream:runbook
program:docs-consolidation
program:platform-hardening
```

Рекомендована форма task:

```text
Ціль: merge sanitized source notes into canonical docs.
Обсяг: exact source files і allowed target docs.
Поза обсягом: process file moves, SCDocs promotion, code/GitOps repo edits.
Перевірка: git status, allowed-file diff, no secret values copied.
```

## Початкова label scheme

Minimum set:

```text
domain:tirascloud
domain:service-center
domain:platform
domain:security
domain:docs

env:dev
env:stage
env:prod
env:shared

workstream:discovery
workstream:architecture
workstream:implementation
workstream:gitops
workstream:cicd
workstream:testing
workstream:runbook
workstream:security

program:tirascloud-gitops-migration
program:service-center-mvp
program:platform-hardening
program:security-governance
program:docs-consolidation
```

## Відкриті питання

- Чи labels треба створювати globally або per Jira project?
- Які labels мають бути mandatory перед тим, як task входить у `Selected for Development`?
- Хто володіє periodic cleanup of stale labels?
