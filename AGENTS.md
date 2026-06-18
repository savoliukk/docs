# Інструкції для агентів у репозиторії документації

Цей репозиторій є особистою DevOps-adjacent базою знань. Працюй з ним як з knowledge repository, а не як з codebase.

## Мова і стиль

- Відповіді агента, фінальні звіти, `Workspace follow-up`, `Memory update candidate`, draft snippets, patch-plan, MANIFEST prose і всі нові або оновлені Markdown output files генеруй українською мовою.
- Документи веди українською мовою.
- Англійську використовуй тільки для:
  - назв технологій, інструментів, протоколів і стандартів;
  - назв класів, методів, змінних, env vars, Kubernetes objects, Jenkins credential IDs;
  - canonical automation keys і required scope keys, наприклад `Allowed source files`, `Allowed target files`, `Allowed archive target`, `Rules`, `Allowed SCDocs promotion files`, `Expected changes`;
  - команд, шляхів, кодових фрагментів і дослівних технічних термінів без природного українського аналога.
- `Exact next apply prompt` має зберігати machine-readable canonical keys англійською для сумісності з Run 2; пояснювальний prose усередині rules/expected changes пиши українською, якщо це не ламає contract prompt-а.
- Не перекладай назви файлів автоматично.
- Для нових технічних документів використовуй стиль назв файлів `UPPER_SNAKE_CASE.md`, наприклад `PLATFORM_OPERATIONS.md`.
- Виняток допускається для вже наявного довгого українського документа про відкриття Kubernetes-сервісів.

## Основні директорії

| Директорія | Призначення |
| --- | --- |
| `process/` | Inbox для нових сирих нотаток, research, runbooks, тимчасових файлів. |
| `projects/` | Канонічна особиста документація. |
| `projects/tirascloud-2/` | Документація TirasCloud-2. |
| `projects/Service Center/` | Документація Service Center. |
| `projects/shared/` | Cross-project знання: security, Kubernetes, CI/CD, GitOps, runbooks, governance. |
| `projects/shared/_indexes/` | Навігаційні індекси: resource register, project map, technology map, open questions, glossary. |
| `archive/{date}/` | Оброблені source-файли з `process/`. |
| `career/` | Майбутня зона для portfolio/career extraction. Створювати тільки за явним запитом. |

## Режими роботи

### ANALYZE_ONLY

У цьому режимі:

- не редагуй, не створюй і не переміщуй файли;
- класифікуй файли з `process/`;
- знайди дублікати, конфлікти, security risks і target paths;
- підготуй patch-plan та apply prompt;
- не копіюй секрети або чутливі значення.

### APPLY_APPROVED

У цьому режимі:

- редагуй тільки явно дозволені файли;
- перечитай існуючий target doc перед зміною;
- не створюй дублікати, якщо треба оновити наявний документ;
- переносити файли в `archive/` можна тільки за явним підтвердженням;
- після роботи перевір посилання, secret-risk patterns і git status.

### INDEX_MAINTENANCE_APPLY

У цьому режимі:

- підтримуй консистентність уже processed knowledge base;
- можна редагувати canonical docs у `projects/`, індекси в `projects/shared/_indexes/`, root `README.md`, root `AGENTS.md` і short memory відповідної automation;
- не редагуй `process/`, `archive/`, `SCDocs`, `workspace`, code/GitOps repos або `projects/shared/codex-doc-automation/`;
- використовуй усі canonical docs у `projects/` як source signals для `resource-register.md`, `project-map.md`, `technology-map.md`, `open-questions.md` і `glossary.md`;
- `process/` читай тільки для recommended future batch; не merge, не archive і не перенос content у canonical docs у цьому режимі;
- broad cleanup дозволений для headings, links, stale refs, duplicate sections, missing index rows, missing open questions і inconsistent wording;
- якщо є sensitive risk, conflicting facts, SCDocs promotion need або більше ніж один plausible target, не вигадуй: винеси це в unresolved/follow-up.

## Обробка вхідних файлів

1. Зчитай список файлів у `process/`.
2. Для кожного файлу визнач:
   - project: `tirascloud-2`, `service-center`, `shared`, `career`, `business`, `unknown / triage-needed`;
   - domain: `kubernetes`, `gitops`, `ci-cd`, `observability`, `security`, `database`, `networking`, `incident-management`, `documentation`, `career`, `income-strategy`, `other`;
   - type: `runbook`, `playbook`, `research`, `architecture`, `adr`, `checklist`, `resource`, `glossary`, `roadmap`, `interview-prep`, `triage-needed`;
   - maturity: `raw`, `draft`, `reviewed`, `team-ready`, `outdated`, `duplicate`;
   - recommended_action: `update existing`, `create new`, `merge`, `split`, `archive`, `skip`, `triage`;
   - target_path;
   - portfolio_value;
   - career_focus;
   - confidentiality.
3. Якщо тема вже є в `projects/`, оновлюй/merge, а не створюй дубль.
4. Якщо source-файл є generated artifact або binary (`pdf`, `pptx`, `png`), реєструй його як resource artifact, не копіюй вміст у docs.
5. Якщо source містить неперевірені факти, додай `Needs verification` і конкретне питання.

## Архівація

- Після approved apply-run source-файли можна перенести з `process/` у `archive/{YYYY-MM-DD}/`.
- Не використовуй структуру `archive/process/{date}`.
- У кожному архівному каталозі створюй `MANIFEST.md`.
- `MANIFEST.md` має містити:
  - дату;
  - початковий source path;
  - список moved files;
  - canonical target або usage;
  - sensitivity/confidentiality;
  - follow-up notes.
- Після переміщення онови активні посилання в `projects/` на `archive/{date}/...`.
- Не видаляй архівні source-файли без окремого explicit approval.

## Security і sanitization

Ніколи не записуй і не повторюй:

- паролі;
- токени;
- private keys;
- kubeconfig contents;
- реальні connection strings;
- customer/user data;
- production logs із PII;
- приватні IP/hostnames без потреби.

Дозволено документувати:

- Kubernetes Secret names;
- Secret key names;
- Jenkins credential IDs;
- env var names;
- placeholders: `<SECRET_NAME>`, `<PRIVATE_IP>`, `<CLIENT>`, `<DOCKER_NAMESPACE>`.

Якщо source містить потенційно чутливі дані:

- познач `confidentiality = sensitive-review-needed`;
- не копіюй підозрілі значення;
- пропонуй sanitized version;
- додавай перевірку secret-risk patterns після apply.

## Sealed Secrets

Поточний approved workflow для Kubernetes runtime secrets: **Sealed Secrets**.

Правила:

- plaintext Kubernetes Secret manifests не мають бути production-ready джерелом правди;
- у docs описуй Secret object names і key names, не values;
- backup/restore Sealed Secrets controller key є частиною DR;
- міграцію plaintext secrets у SealedSecret тримай як open question або task, якщо вона ще не виконана.

## Індекси

Підтримуй актуальними:

- `projects/shared/_indexes/resource-register.md`;
- `projects/shared/_indexes/project-map.md`;
- `projects/shared/_indexes/technology-map.md`;
- `projects/shared/_indexes/open-questions.md`;
- `projects/shared/_indexes/glossary.md`.

Коли створюєш або змінюєш canonical doc, перевір, чи треба оновити індекси.

## Service Center і SCDocs

- `projects/Service Center/` є особистим working layer.
- `C:\work\SCDocs` є окремою team-docs зоною.
- Не редагуй `SCDocs` без окремого approved promotion run з exact target files.
- Якщо source overlap-ить `SCDocs`, готуй promotion proposal, а не автоматичний rewrite.

## Automation artifacts

Каталог `projects/shared/codex-doc-automation/` є службовим.

Не перекладай і не переписуй automation artifacts без окремого запиту:

- `README.md`;
- `routing-rules.md`;
- `run-*-report*.md`;
- `prompts/*.md`;
- `scripts/*.ps1`.

Скрипт `preflight-doc-automation.ps1` виконує read-only preflight:

- показує git status для docs/SCDocs/пов'язаних repo;
- маршрутизує inbox-файли евристично;
- шукає potential duplicates у `SCDocs`;
- сканує secret-risk wording без друку значень;
- показує шляхи до Run 1/Run 2 prompt-ів.

## Git і робоче дерево

- У репозиторії можуть бути user changes.
- Не revert-ь чужі зміни.
- Перед масовими змінами дивись `git status`.
- Якщо git блокує status через `safe.directory`, використовуй:

```powershell
git -c safe.directory=C:/work/docs status --short
```

## Перевірка після змін

Після apply-run виконай:

- перевірку на secret-risk patterns у touched docs;
- перевірку посилань на старий `process/`, якщо файли архівувалися;
- перевірку структури `archive/{date}/`;
- `git status`;
- короткий підсумок: changed files, moved files, skipped files, unresolved questions.
