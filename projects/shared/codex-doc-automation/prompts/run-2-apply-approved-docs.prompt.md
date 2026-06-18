# Run 2: Apply Approved Docs

Застосуй тільки ті документаційні зміни, які явно дозволені нижче користувачем у цьому запуску.

Працюй обережно: це apply-run після Run 1.
Якщо approved scope відсутній, неповний або двозначний, не редагуй файли.

## Контекст

Primary cwd:

```text
C:\work\docs
```

Default write target:

```text
C:\work\docs\projects
```

Optional promotion target, only if explicitly listed by user:

```text
C:\work\SCDocs
```

Read-only preflight:

```powershell
powershell -ExecutionPolicy Bypass -File C:\work\docs\projects\shared\codex-doc-automation\scripts\preflight-doc-automation.ps1
```

Automation memory:

```text
C:\work\docs\automations\docs-apply-approved-batch\memory.md
```

Archive target:

```text
C:\work\docs\archive\{apply-run-date}
```

## Жорсткі правила

- Генеруй усі людські відповіді, фінальний звіт, `Workspace follow-up`, memory update, MANIFEST prose і Markdown output українською мовою.
- Не перекладай technical identifiers: paths, filenames, commands, env vars, Kubernetes objects, Jenkins credential IDs, product names, protocols, standards і exact required scope keys.
- Required approved-scope keys залишай англійською: `Allowed source files`, `Allowed target files`, `Allowed archive target`, `Rules`, `Allowed SCDocs promotion files`, `Expected changes`.
- Пояснювальний prose у `Rules` і `Expected changes` пиши українською, якщо це не ламає approved scope contract.
- Не редагуй кодові репозиторії:
  - `C:\work\ideal-octo-giggle`
  - `C:\work\TirasCloud-2`
  - `C:\work\SCNet`
  - `C:\work\SCNode`
  - `C:\work\SCInfrastructure`
- Не редагуй `C:\work\SCDocs`, якщо користувач явно не дозволив конкретні файли.
- Не створюй дублікати, якщо існуючий документ треба оновити.
- Не записуй секрети. Дозволені тільки secret names, key names, Jenkins credential IDs, env var names.
- Перед редагуванням покажи git status для `C:\work\docs` і, якщо є promotion, для `C:\work\SCDocs`.
- Після редагування покажи touched files і git status after.
- Запусти preflight перед редагуванням і врахуй secret-risk wording scan.
- Не обробляй `C:\work\workspace\inbox` через docs flow.
- Якщо source overlap-ить `SCDocs`, редагуй `SCDocs` тільки якщо exact files явно listed у approved scope; інакше створи promotion proposal у фінальному звіті.
- Для security/governance batch тримай scope малим: 1-3 source files, sanitized content only.
- Після successful apply автоматично архівуй consumed source files з `C:\work\docs\process` у `C:\work\docs\archive\{apply-run-date}`.
- `Consumed source file` означає source, зміст якого merged у canonical doc, або source artifact, який зареєстровано в canonical register/resource index.
- Не архівуй source files, які були лише прочитані для context, duplicate scan або fact-check.
- Для архівації створи або онови `MANIFEST.md` у відповідному archive directory; він має містити дату apply-run, початкові source paths, moved files, canonical target або usage, sensitivity/confidentiality і follow-up notes.
- Після архівації онови active refs у touched docs/indexes з `process/...` на `archive/{apply-run-date}/...`.
- Якщо archive move або reference update не може бути виконаний безпечним способом, не роби частковий cleanup; залиш source files у `process/` і явно познач `archive status = blocked`.
- Якщо automation state write дозволений, онови memory file коротким safe summary: last approved scope, touched files, source files consumed, archive status, skipped sensitive sources, unresolved questions.

## User-approved scope

Run 2 може редагувати файли тільки якщо current run context містить повний canonical approved scope у цьому форматі:

```text
Run 2 APPLY_APPROVED for C:\work\docs.

Allowed source files:
- C:\work\docs\process\<SOURCE_FILE>

Allowed target files:
- C:\work\docs\projects\<PROJECT_OR_SHARED>\<TARGET_DOC>.md
- C:\work\docs\projects\shared\_indexes\<INDEX>.md

Allowed archive target:
- C:\work\docs\archive\{YYYY-MM-DD}
- C:\work\docs\archive\{YYYY-MM-DD}\MANIFEST.md

Rules:
- <RUN-SPECIFIC RULES>

Allowed SCDocs promotion files, if any:
- none

Expected changes:
- <EXPECTED CHANGES>
```

Required scope keys:

- `Allowed source files`;
- `Allowed target files`;
- `Allowed archive target`;
- `Rules`;
- `Allowed SCDocs promotion files`;
- `Expected changes`.

Backward compatibility: якщо користувач надав старий формат із `Allowed files to edit` і `Source process files`, але scope повний і недвозначний, можна трактувати `Allowed files to edit` як `Allowed target files`. У фінальному звіті познач, що використано legacy scope format.

Якщо будь-який required scope key відсутній, порожній або суперечливий, не редагуй файли і поверни `Missing approved scope` разом із canonical template.

Archive policy:

- За замовчуванням після successful apply архівуй усі consumed source files із `Allowed source files`.
- Якщо `Rules` явно містять `Do not archive source files in this run`, не архівуй і поверни `archive status = intentionally skipped`.
- Якщо scope одночасно дозволяє archive target і забороняє архівацію, вважай scope суперечливим і поверни `Missing approved scope`.
- Якщо `Allowed archive target` дорівнює `none`, архівуй тільки якщо `Rules` явно дозволяють і задають archive target; інакше поверни `archive status = intentionally skipped`.
- Не архівуй source files, які були лише прочитані для context, duplicate scan або fact-check.

## Завдання

1. Перечитай Run 1 report і canonical approved scope з цього prompt.
2. Якщо required scope keys не задані явно або scope суперечливий, зупинись і поверни `Missing approved scope`.
3. Запусти read-only preflight.
4. Перевір існуючі target docs, щоб не втратити поточну структуру.
5. Застосуй тільки дозволені зміни.
6. Якщо виникла невідповідність між source note і repo facts, не вигадуй: додай `Open question` або `Needs verification`.
7. Онови docs коротко і операційно: що робити, навіщо, як перевірити.
8. Не змінюй unrelated files.
9. Визнач consumed source files і архівуй їх після successful apply.
10. Після archive cleanup перевір touched docs на secret-risk patterns і старі посилання на `process/`, якщо source files були archived або referenced.

## Фінальний звіт

Поверни українською мовою, зберігаючи наведені нижче technical labels без перекладу:

- files changed;
- files intentionally skipped;
- source files consumed;
- duplicates resolved;
- open questions;
- verification performed;
- workspace follow-up;
- memory update;
- archive status;
- git status after.
