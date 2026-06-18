# Особиста документація

Це особисте сховище документації. Звідси файли можна вручну синхронізувати в GitOps-репозиторій або репозиторій коду, коли документ стане корисним для команди.

## Структура

- `projects/tirascloud-2/CI_CD_PIPELINE.md` - короткий опис поточного CI/CD pipeline для TirasCloud-2.
- `projects/tirascloud-2/BUILD_STRATEGY.md` - рекомендована build strategy, POC-критерії для BuildKit/buildx і майбутній supply-chain напрям.
- `projects/tirascloud-2/CI_CD_INTEGRATION_CHECKLIST.md` - перенесений робочий чекліст інтеграції сервісів.
- `projects/tirascloud-2/DEPENDENCY_MAP.md` - карта runtime- і зовнішніх залежностей модулів TirasCloud-2.
- `projects/tirascloud-2/HEALTH_AND_SMOKE_STRATEGY.md` - стратегія readiness/liveness probes і smoke alternatives для активних Dev apps.
- `projects/shared/codex-doc-automation/` - Draft-first automation для `process/` sources і direct index maintenance для processed knowledge base.
- `process/` - inbox для нових сирих нотаток, research, runbooks і тимчасових файлів; конкретний склад змінюється після apply/archive runs.
- `projects/shared/_indexes/` - resource register, project map, technology map, open questions і glossary; підтримуються разом із canonical docs.

## Правила

- Відповіді агентів, звіти automation і Markdown output files пишемо українською мовою.
- Не перекладаємо технічні ідентифікатори: paths, filenames, commands, env vars, Kubernetes objects, Jenkins credential IDs і canonical automation keys.
- Документи пишемо коротко: що робити, навіщо, якою командою перевірити.
- Секрети не записуємо. Дозволені тільки назви Kubernetes Secret, Jenkins credential IDs і назви ключів.
- Складні слова пояснюємо поруч або замінюємо простішими.
