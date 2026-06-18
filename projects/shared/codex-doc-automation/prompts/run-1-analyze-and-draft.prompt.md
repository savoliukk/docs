# Run 1: Analyze And Draft

Проаналізуй `C:\work\docs\process` як inbox документації.

Працюй у режимі **Draft first**.
Це analyze-run: не змінюй canonical docs, archive, `process/`, `SCDocs` або code/GitOps repos.

## Контекст

Primary cwd:

```text
C:\work\docs
```

Read context:

```text
C:\work\docs\process
C:\work\docs\projects
C:\work\SCDocs
C:\work\ideal-octo-giggle
C:\work\TirasCloud-2
C:\work\SCNet
C:\work\SCNode
C:\work\SCInfrastructure
```

Routing rules:

```text
C:\work\docs\projects\shared\codex-doc-automation\routing-rules.md
```

Read-only preflight:

```powershell
powershell -ExecutionPolicy Bypass -File C:\work\docs\projects\shared\codex-doc-automation\scripts\preflight-doc-automation.ps1
```

Automation memory:

```text
C:\work\docs\automations\docs-analyze-process-inbox\memory.md
```

## Жорсткі правила

- Генеруй усі людські відповіді, фінальний звіт, `Workspace follow-up`, `Memory update candidate`, draft snippets, patch-plan і Markdown output українською мовою.
- Не перекладай technical identifiers: paths, filenames, commands, env vars, Kubernetes objects, Jenkins credential IDs, product names, protocols, standards і exact required scope keys.
- У `Exact next apply prompt` залишай canonical keys англійською для сумісності з Run 2; пояснювальний prose у `Rules` і `Expected changes` пиши українською, якщо це не ламає approved scope contract.
- Не редагуй `C:\work\SCDocs`.
- Не редагуй `C:\work\ideal-octo-giggle`, `C:\work\TirasCloud-2`, `C:\work\SCNet`, `C:\work\SCNode`, `C:\work\SCInfrastructure`.
- Не записуй секрети. Дозволені тільки назви Kubernetes Secret, key names, Jenkins credential IDs і назви env vars.
- Якщо git status показує user changes, не перезаписуй їх і явно познач ризик.
- Якщо документ вже існує у `SCDocs`, готуй merge proposal, а не новий дубль.
- Не обробляй `C:\work\workspace\inbox` через docs flow. Для workspace input нормальний шлях: `Process Inbox` -> proposal -> `Process Proposal` -> `Plan this day` / `End this day`.
- Якщо source має secret-risk wording або security questionnaire content, познач `confidentiality = sensitive-review-needed` і не копіюй підозрілі значення.
- Для normal ops/runbook batch рекомендуй максимум 3-5 source files; для security/governance batch рекомендуй 1-3 source files.
- Якщо є `KUBERNETES_SECURITY_MIND_MAP v1.md` і `v2.md`, трактуй `v2` як primary source, `v1` як duplicate/outdated reference, якщо content не доводить інше.
- Якщо automation state write дозволений у конкретному run, онови тільки короткий safe state у memory file. Якщо run строго read-only, поверни `Memory update candidate` у фінальному звіті замість запису.

## Завдання

1. Зчитай список файлів у `C:\work\docs\process`.
2. Запусти read-only preflight і врахуй git status, routing, duplicate scan і secret-risk wording scan.
3. Для кожного файлу визнач:
   - project/domain;
   - document type: runbook, research, architecture, checklist, protocol, governance, process;
   - maturity: raw, draft, reviewed, outdated, duplicate;
   - confidentiality: normal, internal-only, sensitive-review-needed;
   - target personal docs path;
   - possible `SCDocs` promotion target;
   - action: update existing, create new, merge, skip, triage.
4. Звір факти з релевантними repo sources:
   - `AGENTS.md`, `README`, `docs`, `Jenkinsfile`, `k8s`, GitOps manifests, Helm values, ApplicationSets.
5. Знайди дублікати:
   - same filename;
   - same topic;
   - process file that already exists in `SCDocs`;
   - process file that overlaps existing `projects` docs.
6. Підготуй тільки draft output:
   - proposed section outlines;
   - snippets or patch-plan for `C:\work\docs\projects`;
   - promotion proposal for `C:\work\SCDocs`;
   - no direct writes to canonical docs.

## Формат фінального звіту

Поверни:

1. `Preflight summary`
2. `Classification table`
3. `Existing docs to update`
4. `New docs to create`
5. `Duplicates and conflicts`
6. `Security / sanitization notes`
7. `Recommended batch`
8. `Draft snippets / patch-plan`
9. `SCDocs promotion candidates`
10. `Skipped files`
11. `Workspace follow-up`
12. `Memory update candidate`
13. `Exact next apply prompt`

`Exact next apply prompt` має бути повним copy/paste prompt для manual run `Docs Apply Approved Batch`. Не посилайся на helper scripts і не вимагай від користувача формувати команду.

Формат `Exact next apply prompt`:

````text
Read and execute:
C:\work\docs\projects\shared\codex-doc-automation\prompts\run-2-apply-approved-docs.prompt.md

Mode: APPLY_APPROVED.

Use this exact apply scope:
```
Run 2 APPLY_APPROVED for C:\work\docs.

Allowed source files:
- C:\work\docs\process\<SOURCE_FILE_1>
- C:\work\docs\process\<SOURCE_FILE_2>

Allowed target files:
- C:\work\docs\projects\<PROJECT_OR_SHARED>\<TARGET_DOC>.md
- C:\work\docs\projects\shared\_indexes\resource-register.md
- C:\work\docs\projects\shared\_indexes\technology-map.md
- C:\work\docs\projects\shared\_indexes\open-questions.md
- C:\work\docs\projects\shared\_indexes\project-map.md

Allowed archive target:
- C:\work\docs\archive\{YYYY-MM-DD}
- C:\work\docs\archive\{YYYY-MM-DD}\MANIFEST.md

Rules:
- Do not edit SCDocs unless exact promotion files are listed below.
- Do not edit workspace, code repositories, GitOps repositories, or unrelated docs.
- Read existing target docs before editing.
- Merge/update existing canonical docs instead of creating duplicates.
- Sanitize secrets, credentials, kubeconfig, connection strings, customer/user data and private values.
- Document only Secret object names, key names, Jenkins credential IDs, env var names and placeholders.
- Keep Sealed Secrets as the approved Kubernetes runtime secret workflow.
- Add Needs verification for vendor pricing, licensing, public case claims and non-durable citation markers.
- After successful apply, archive consumed source files into C:\work\docs\archive\{YYYY-MM-DD}.
- Create or update MANIFEST.md with source paths, moved files, canonical target/usage, sensitivity and follow-up notes.
- Update active refs from process/... to archive/{YYYY-MM-DD}/... after archiving.
- After edits and archive cleanup, run secret-risk scan on touched docs, check stale process refs and run git status.

Allowed SCDocs promotion files:
- none

Expected changes:
- <SHORT_OPERATIONAL_DESCRIPTION>
```
````

Правила для `Exact next apply prompt`:

- Використовуй абсолютні Windows paths.
- Підстав поточну дату для `{YYYY-MM-DD}`.
- Додавай у `Allowed target files` тільки файли, які Run 2 має право змінювати.
- Для security/governance batch тримай `Allowed source files` у межах 1-3 файлів.
- Якщо source потрібен лише для context, duplicate scan або fact-check, не додавай його в `Allowed source files`.
- Не додавай `Do not archive source files in this run`, якщо користувач явно не попросив apply без архівації.
- Якщо потрібна SCDocs promotion, додай exact SCDocs files; інакше лишай `- none`.

`Workspace follow-up` має містити тільки те, що варто передати в `C:\work\workspace` як Jira/proposal/open decision; не редагуй workspace напряму.
