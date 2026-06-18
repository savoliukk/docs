# Codex Process Documentation Automation

Цей набір файлів описує Codex-автоматизацію для перетворення матеріалів з `C:\work\docs\process` у структуровану документацію.

Режим v1: **Draft first**. Codex аналізує, класифікує, готує чернетки та patch-plan, але не змінює `C:\work\SCDocs` і кодові репозиторії без окремого підтвердженого запуску.

## Мова output

- Усі людські відповіді automation, фінальні звіти, `Workspace follow-up`, `Memory update candidate`, draft snippets, patch-plan, MANIFEST prose і Markdown output files мають бути українською мовою.
- Не перекладати technical identifiers: paths, filenames, commands, env vars, Kubernetes objects, Jenkins credential IDs, product names, protocols, standards і exact required scope keys.
- `Exact next apply prompt` зберігає canonical keys англійською, зокрема `Allowed source files`, `Allowed target files`, `Allowed archive target`, `Rules`, `Allowed SCDocs promotion files`, `Expected changes`, щоб Run 2 міг прочитати approved scope.
- Пояснювальний prose усередині `Rules` і `Expected changes` пиши українською, якщо це не порушує machine-readable contract.

## Операційна модель

`C:\work\workspace` є daily cockpit для задач, Jira-ready карток, proposals і worklog. `C:\work\docs` є canonical knowledge base для стислих runbooks, security/governance notes і project docs.

Послідовність docs flow:

1. `Docs Analyze Process Inbox` - read-only triage `process/`.
2. Human review - вибір batch на 1-5 source files, для security/governance 1-3 files.
3. `Docs Apply Approved Batch` - тільки з явним approved scope.
4. Automatic archive cleanup - після successful Run 2 для consumed source files.
5. `Docs Index And Open Questions Review` - direct maintenance apply для processed knowledge base: canonical docs, індекси, open questions, links і root entrypoints.

Workspace input не проходить через docs automations. Для `C:\work\workspace\inbox` нормальний шлях: `Process Inbox` -> proposal -> `Process Proposal` -> `Plan this day` / `End this day`.

## Робочі контури

| Path | Роль |
| --- | --- |
| `C:\work\docs\process` | Inbox: research, runbooks, робочі нотатки |
| `C:\work\docs\projects` | Основна особиста база документації |
| `C:\work\SCDocs` | Зріла командна документація Service Center |
| `C:\work\ideal-octo-giggle` | GitOps repo TirasCloud |
| `C:\work\TirasCloud-2` | Application repo TirasCloud-2 |
| `C:\work\SCNet` | Service Center .NET services |
| `C:\work\SCNode` | Service Center LAS / Socket.IO gateway |
| `C:\work\SCInfrastructure` | GitOps/CI/CD repo Service Center |

## Як запускати вручну

1. Запустити read-only preflight або переконатися, що automation зробила це першим кроком:

```powershell
powershell -ExecutionPolicy Bypass -File C:\work\docs\projects\shared\codex-doc-automation\scripts\preflight-doc-automation.ps1
```

2. Відкрити новий Codex run з cwd `C:\work\docs`.

3. Вставити prompt з:

```text
C:\work\docs\projects\shared\codex-doc-automation\prompts\run-1-analyze-and-draft.prompt.md
```

4. Переглянути classification table, proposed target files, duplicates/conflicts і prepared draft snippets.

5. Якщо пропозиції ок, запустити другий ручний run з:

```text
C:\work\docs\projects\shared\codex-doc-automation\prompts\run-2-apply-approved-docs.prompt.md
```

Run 2 має отримати явний список дозволених файлів для зміни, source process files, files that must not be touched і expected changes.

### Швидкий повтор Run 2 apply/archive

Повторюваний шлях без ручної побудови команди:

1. Запусти `Docs Analyze Process Inbox` або вручну виконай `run-1-analyze-and-draft.prompt.md`.
2. У фінальному звіті скопіюй блок `Exact next apply prompt`.
3. Запусти manual/paused automation `Docs Apply Approved Batch` і встав цей prompt як approved scope.
4. Після successful apply `Docs Apply Approved Batch` автоматично архівує consumed source files у `archive/{YYYY-MM-DD}/`, створює/оновлює `MANIFEST.md` і міняє active refs із `process/...` на `archive/{YYYY-MM-DD}/...`.

Якщо треба навмисно зробити apply без архівації, у `Rules` exact scope явно додай:

```text
- Do not archive source files in this run.
```

Не додавай це правило за замовчуванням.

6. Для регулярного maintenance apply використати:

```text
C:\work\docs\projects\shared\codex-doc-automation\prompts\index-and-open-questions-review.prompt.md
```

Цей run не є Run 1/Run 2 для нових source files. Він може сам редагувати processed docs у `projects/`, root `README.md`, root `AGENTS.md` і власний short memory, але не споживає і не архівує `process/` files. Нові source files із `process/` він тільки рекомендує для майбутнього `Docs Analyze Process Inbox` / `Docs Apply Approved Batch`.

`Docs Apply Approved Batch` має бути manual/paused за замовчуванням. Scheduled apply без approved scope повинен повертати `Missing approved scope`, а не редагувати файли.

Після successful Run 2 automation автоматично архівує consumed source files у `archive/{apply-run-date}/`. Consumed source file - це source, зміст якого merged у canonical doc, або source artifact, який зареєстровано в canonical register/resource index. Sources, які читалися лише для context, duplicate scan або fact-check, лишаються в `process/`.

Для archive cleanup Run 2 має:

- створити або оновити `archive/{apply-run-date}/MANIFEST.md`;
- зафіксувати moved files, canonical target або usage, sensitivity/confidentiality і follow-up notes;
- оновити active refs у touched docs/indexes з `process/...` на `archive/{apply-run-date}/...`;
- повернути `archive status` у фінальному звіті.

## Правила безпеки

- Не записувати секрети. Дозволені тільки назви Kubernetes Secret, key names, Jenkins credential IDs та назви env vars.
- Не редагувати `C:\work\SCDocs` у Run 1.
- Не редагувати `ideal-octo-giggle`, `TirasCloud-2`, `SCNet`, `SCNode`, `SCInfrastructure` у межах цієї автоматизації.
- Перед apply-проходом перевірити dirty worktrees і не змішувати чужі незакомічені зміни з документаційним оновленням.
- Якщо документ вже є в `SCDocs`, оновлювати його через proposal, а не створювати дубль.
- Кожен docs run має мати `Workspace follow-up`: що варто передати в `C:\work\workspace` як Jira/proposal/open decision, без прямого редагування workspace.
- Automation memory зберігати тільки у `C:\work\docs\automations\<automation-id>\memory.md`, коротко і без sensitive values.

## Очікуваний результат Run 1

Run 1 має завершитися звітом з такими блоками:

- preflight summary;
- classification table для всіх файлів у `process`;
- existing docs to update vs new docs to create;
- security/sanitization notes;
- conflicts and duplicates;
- recommended batch;
- draft snippets або patch-plan для `C:\work\docs\projects`;
- suggested promotion list для `C:\work\SCDocs`;
- workspace follow-up;
- memory update candidate;
- exact next apply prompt.

## Очікуваний результат Run 2

Run 2 має:

- змінити тільки явно дозволені файли в `C:\work\docs\projects`;
- залишити `SCDocs` без змін, якщо promotion не був явно дозволений;
- архівувати consumed source files у `archive/{apply-run-date}/` після successful apply;
- показати git status before/after;
- перелічити touched files, skipped files, unresolved questions;
- показати verification performed, workspace follow-up, archive status і memory update.

## Очікуваний результат Index Review

Index Review має:

- запустити read-only preflight;
- працювати як `INDEX_MAINTENANCE_APPLY`: самостійно редагувати allowed processed docs, якщо зміна очевидна і не блокується ambiguity;
- редагувати тільки `C:\work\docs\projects/**` за винятком `projects/shared/codex-doc-automation/**`, root `README.md`, root `AGENTS.md` і short memory `automations/docs-index-and-open-questions-review/memory.md`;
- не редагувати `process/`, `archive/`, `SCDocs`, `workspace`, code/GitOps repos або automation artifacts;
- перевірити `resource-register.md`, `project-map.md`, `technology-map.md`, `open-questions.md`, `glossary.md`;
- сканувати всі canonical docs у `projects/**` як source signals для index maintenance;
- знайти stale links, unresolved `Needs verification`, missing open questions, missing indexed paths, closed/duplicate open questions і суперечності між entrypoints/indexes та фактичною структурою repo;
- нормалізувати headings, links, status wording, related-doc references і очевидні duplicate fragments у canonical docs;
- якщо є sensitive risk, conflicting facts, SCDocs promotion need або більше ніж один plausible target, винести це в `Skipped / blocked by ambiguity`;
- запропонувати next high-ROI apply batch для `process/` sources у форматі, сумісному з `Docs Analyze Process Inbox`;
- винести зміни до `routing-rules.md`, `prompts/*.md`, `scripts/*.ps1` або automation README у candidates, а не редагувати їх у regular Index Review;
- повернути `Workspace follow-up` без редагування workspace.
