# Index Maintenance Apply

Підтримай консистентність processed knowledge base у `C:\work\docs`: canonical docs, індекси, open questions, navigation links і root entrypoints.

Працюй у режимі **INDEX_MAINTENANCE_APPLY**.

`INDEX_MAINTENANCE_APPLY` = direct maintenance apply для вже processed бази знань. Цей run може редагувати дозволені docs files самостійно, без окремого Run 2 prompt, але не споживає і не архівує нові source files із `process/`.

## Контекст

Primary cwd:

```text
C:\work\docs
```

Read-only preflight:

```powershell
powershell -ExecutionPolicy Bypass -File C:\work\docs\projects\shared\codex-doc-automation\scripts\preflight-doc-automation.ps1
```

Required indexes:

```text
C:\work\docs\projects\shared\_indexes\resource-register.md
C:\work\docs\projects\shared\_indexes\project-map.md
C:\work\docs\projects\shared\_indexes\technology-map.md
C:\work\docs\projects\shared\_indexes\open-questions.md
C:\work\docs\projects\shared\_indexes\glossary.md
```

Automation memory:

```text
C:\work\docs\automations\docs-index-and-open-questions-review\memory.md
```

Allowed write targets:

```text
C:\work\docs\projects\**
C:\work\docs\README.md
C:\work\docs\AGENTS.md
C:\work\docs\automations\docs-index-and-open-questions-review\memory.md
```

Protected paths:

```text
C:\work\docs\projects\shared\codex-doc-automation\**
C:\work\docs\process\**
C:\work\docs\archive\**
C:\work\SCDocs\**
C:\work\workspace\**
C:\work\ideal-octo-giggle\**
C:\work\TirasCloud-2\**
C:\work\SCNet\**
C:\work\SCNode\**
C:\work\SCInfrastructure\**
```

## Жорсткі правила

- Генеруй усі людські відповіді, фінальний звіт, `Workspace follow-up`, memory update, draft snippets, patch-plan і Markdown output українською мовою.
- Не перекладай technical identifiers: paths, filenames, commands, env vars, Kubernetes objects, Jenkins credential IDs, product names, protocols, standards і exact required scope keys.
- Якщо формуєш `Exact next apply prompt`, залишай canonical keys англійською для сумісності з Run 2; пояснювальний prose у `Rules` і `Expected changes` пиши українською, якщо це не ламає approved scope contract.
- Не копіюй secrets або приватні значення в output.
- Якщо бачиш potential secret-risk, назви файл і risk type без значень.
- Не редагуй `process/`, `archive/`, `SCDocs`, `workspace`, code/GitOps repos або `projects/shared/codex-doc-automation/**`.
- Не редагуй `routing-rules.md`, `prompts/*.md`, `scripts/*.ps1` або automation README у regular Index Maintenance run; пропозиції щодо них винось у `Routing rules candidates` або `Automation maintenance candidates`.
- `process/` можна читати тільки для recommended future batch; не merge, не archive і не переносити content у canonical docs у цьому run.
- `archive/` можна читати тільки як source/reference history; не редагуй archived files.
- `projects/**` є canonical docs і source signals для індексів. Не дублюй canonical docs як raw sources; реєструй їх як canonical resources, technology owners або navigation targets.
- Broad cleanup дозволений: structure, headings, stale refs, broken links, duplicate sections, missing index rows, missing open questions і inconsistent wording.
- Якщо є sensitive risk, conflicting facts, SCDocs promotion need або більше ніж один plausible target, не вигадуй і не роби best-effort rewrite; винеси конкретну частину в `Skipped / blocked by ambiguity`.
- Якщо змінюєш canonical doc, перевір, чи треба оновити `resource-register.md`, `project-map.md`, `technology-map.md`, `open-questions.md` або `glossary.md`.
- Якщо automation state write дозволений, онови тільки короткий safe state у memory file.
- Не редагуй `C:\work\workspace`; якщо потрібна action у workspace, додай її в `Workspace follow-up`.

## Scan scope

Canonical maintenance scan включає всі Markdown docs у:

```text
C:\work\docs\projects\tirascloud-2
C:\work\docs\projects\Service Center
C:\work\docs\projects\shared
```

Виключи з maintenance scan:

```text
projects/shared/codex-doc-automation/**
archive/**
process/**
```

`projects/shared/_indexes/**` не виключай: це canonical indexes, які треба підтримувати. `projects/shared/codex-doc-automation/**` лишається protected automation layer.

## Завдання

1. Запусти read-only preflight і врахуй dirty worktrees.
2. Побудуй inventory canonical docs у `projects/**`, excluding `projects/shared/codex-doc-automation/**`.
3. Перевір, чи всі required indexes існують і чи не stale відносно canonical docs.
4. Перевір, чи canonical docs, згадані в `project-map.md`, `resource-register.md`, `technology-map.md` і root `README.md`, існують.
5. Знайди `Needs verification`, `TODO`, `FIXME`, `Open question` у canonical docs і синхронізуй їх з `open-questions.md`.
6. Перевір stale signals:
   - missing indexed paths;
   - stale active refs на `process/...` після archive cleanup;
   - missing open questions;
   - open-questions rows, які виглядають closed або duplicated;
   - contradiction між `README.md`, `project-map.md`, `resource-register.md` і фактичною структурою repo.
7. Онови allowed docs/indexes/root entrypoints, якщо зміна очевидна і не блокується ambiguity:
   - `resource-register.md`: canonical docs, archived/generated source artifacts, source-to-target usage;
   - `technology-map.md`: technologies/tools/protocols, які реально представлені в canonical docs;
   - `project-map.md`: project ownership/navigation boundary;
   - `open-questions.md`: unresolved decisions, verification needs, closed/duplicate cleanup;
   - `glossary.md`: stable terms, які повторюються в canonical docs;
   - canonical docs: headings, stale links, duplicated fragments, related-doc links, inconsistent status wording;
   - root `README.md` і `AGENTS.md`: тільки якщо змінився repo flow, mode contract або entrypoint/navigation wording.
8. Перевір obvious duplicates між `process/`, `projects/`, `archive/` і `SCDocs`.
9. Знайди source files у `process/`, які треба запропонувати для future `Docs Analyze Process Inbox` / `Docs Apply Approved Batch`; не merge і не archive їх у цьому run.
10. Сформуй next high-ROI apply batch у форматі, сумісному з `Docs Analyze Process Inbox`: максимум 3-5 source files, а для security/governance 1-3 files.
11. Якщо потрібні зміни в `routing-rules.md`, `prompts/*.md`, `scripts/*.ps1` або automation README, не редагуй їх; винеси окремо в `Automation maintenance candidates`.

## Фінальний звіт

Поверни:

1. `Preflight summary`
2. `Consistency changes applied`
3. `Index updates`
4. `Open questions delta`
5. `Resource / technology register delta`
6. `Canonical docs normalized`
7. `Process sources recommended for future batch`
8. `Routing rules candidates`
9. `SCDocs promotion candidates`
10. `Skipped / blocked by ambiguity`
11. `Workspace follow-up`
12. `Memory update`
13. `Exact next apply prompt`

`Exact next apply prompt` має бути повним copy/paste prompt у стилі `Docs Analyze Process Inbox` для майбутнього manual `Docs Apply Approved Batch`, якщо є source files із `process/`, які варто обробити. Якщо готового safe batch немає, напиши `none`.

У `Exact next apply prompt`:

- використовуй абсолютні Windows paths;
- додавай тільки `process/` files, які треба реально consume у future apply;
- додавай тільки allowed target files, які майбутній Run 2 має змінювати;
- лишай `Allowed SCDocs promotion files: - none`, якщо promotion не має explicit target files;
- не включай routing-rules/automation maintenance у docs apply prompt.
