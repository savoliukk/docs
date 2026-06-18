# Roadmap реалізації Service Center

Дата аналізу: 2026-05-05  
Робочі джерела: `C:\Users\<USER>\Downloads\Сервіс центр від SP MISTO.md`, `C:\work\SCNet`, `C:\work\SCNode`, `C:\work\SCNode_Tests`, `C:\work\SCInfrastructure`, `C:\work\SCDocs`, `C:\work\dependency-map.md`.

## 1. Ціль продукту

Побудувати єдиний Service Center для заявок про несправності, який:

- приймає заявки з SP MISTO, тривожних карток MISTO, oLoader II та майбутніх сторонніх систем моніторингу;
- веде повний життєвий цикл заявки: `Нові` -> `В роботі` -> `Відкладені` -> `Опрацьовані` -> `Завершені` або `Видалені`;
- підтримує ролі `Адміністратор`, `Оператор`, `Старший інженер`, `Інженер`;
- має оперативний канбан у SP MISTO, мобільний сценарій в oLoader II та табличний архів зі статистикою;
- зберігає файли/фото, коментарі, історію ремонту, дедлайни, відкладення, виконавців і snapshot-дані об'єкта на момент завершення заявки.

## 2. Поточна технічна основа

### Реалізований стек

| Зона | Поточна реалізація |
| --- | --- |
| Backend Service Center | `.NET 8`, ASP.NET Core, minimal/API controllers, hosted services |
| Мікросервіси | `ActiveTasksService`, `ArchiveTasksService`, `MistoCommunicationService`, `MistoGuardObjectsService`, `StaffService` |
| Мобільний/LAS gateway | `SCNode`: Node.js/TypeScript, Socket.IO `/io`, RabbitMQ RPC |
| Міжсервісна комунікація | RabbitMQ, `QueueEnvelope`, `QueueДіяType`, доменні черги |
| Active tasks | In-memory cache + PostgreSQL persistence + sync queues |
| Archive | Elasticsearch реалізація активна у сервісі, ClickHouse реалізація присутня як альтернативний модуль |
| Files | MinIO через `modFileStorageCore` |
| Realtime для MISTO | SignalR `/notifications` у `MistoCommunicationService` |
| Staff / join requests | `modStaffCore`, `StaffService`, PostgreSQL persistence |
| Guard objects | `MistoGuardObjectsService`, cache + PostgreSQL storage для MISTO-об'єктів |
| Observability | Logstash/Elasticsearch/Kibana, custom SCNet Logstash logger |
| CI/CD | Jenkins + Docker Hub + Argo CD + Helm/ApplicationSet |
| Active deploy contour | `SCNet/feature/k8s` -> `SCInfrastructure/argocd-feature` -> namespace `scnet-feature` |
| Tests | xUnit для SCNet модулів, Jest E2E для Socket.IO LAS flow |

### Вже наявні функціональні опори

- ActiveTasks має моделі задач, коментарів, несправностей, дедлайнів, відкладень, вкладень, історії та індекси за організацією/статусом/інженером.
- LAS протокол частково формалізований: `GET_ORGANIZATION_LIST`, `LINK_ENGINEER_TO_ORGANIZATION`, `GET_NEW_ORGANIZATION_TASKS`, `TAKE_TASK`, `ADD_COMMENT_TO_TASK` та інші команди.
- MistoCommunication має HTTP endpoints для задач, архіву, staff, guard objects, attachments і SignalR hub для push-back у MISTO.
- ArchiveTasks має snapshot-модель, фільтри, reader/writer інтерфейси, Elasticsearch індекс `scnet-feature-archive-tasks`.
- StaffService має основу для ролей, реєстру персоналу та join requests з TirasCloud/MISTO ідентичностями.
- GitOps feature-контур уже збирає та деплоїть 5 SCNet сервісів.

## 3. Головні gaps перед продуктовою реалізацією

| Gap | Чому важливо | Де закривати |
| --- | --- | --- |
| Єдина модель статусів | Вимоги мають `Нові/В роботі/Відкладені/Опрацьовані/Видалені/Завершені`, протокол має `NEW/ASSIGNED/PROCESSED/DEFERRED/COMPLETED`, код зберігає `int Status`. | `modActiveTaskContracts`, LAS protocol, SCNode, UI |
| Єдина permission matrix | Ролі описані в продукті, але немає централізованої політики переходів і дій. | `StaffService`, `ActiveTasksService`, `MistoCommunicationService`, SCNode |
| LAS command contract drift | SCNode код використовує повні назви команд, а `SCNode_Tests` надсилає скорочені `GET_ORG_LIST`, `LINK_ENG_TO_ORG` тощо. | `SCNode`, `SCNode_Tests`, `SCDocs/protocol.md` |
| Неповні payload-и SCNode RPC | `CommandCreator` зараз формує payload лише з `organizationId` і `engineerId`, що недостатньо для `taskId`, faults, comments. | `SCNode/src/core/utils/CommandCreator.ts` |
| Віртуальна база сторонніх об'єктів | Поточний `MistoGuardObjectsService` описує MISTO guard objects, але не окремі сторонні monitoring systems/import/API/source marker. | `MistoGuardObjectsService`, `MistoCommunicationService`, SP MISTO |
| Duplicate folding | Вимога про схлопування дублів заявок ще не виділена як окрема доменна політика. | `ActiveTasksService`, MISTO alarm integration |
| Архівне сортування і export | Elasticsearch readme прямо фіксує, що `SortParam` передається, але не застосовується у `SearchRequest`; export/analytics ще відсутні. | `ArchiveTasksService`, future export/analytics module |
| Push notifications | Є Socket.IO/SignalR основа, але продуктова матриця push events для oLoader II ще не реалізована повністю. | SCNode, mobile push provider, ActiveTasks events |
| Секрети в GitOps | Для feature-контуру є тимчасовий plaintext Kubernetes Secret. | `SCInfrastructure`, SealedSecret/ExternalSecret/Pulumi |
| PR-preview модель | Документація описує цільову PR-preview модель, але активний контур поки постійний `scnet-feature`. | `SCInfrastructure`, Jenkins, Argo CD |

## 4. Roadmap

### Фаза 0. Контрактна стабілізація і discovery

Ціль: зафіксувати межі MVP, прибрати розходження між описом, протоколом, тестами та кодом.

Роботи:

- Затвердити єдиний enum статусів заявки і мапінг UI label -> protocol value -> DB value.
- Затвердити state machine переходів для кожної ролі.
- Переписати permission matrix у машинно-перевірний формат: `role + status + action -> allow/deny`.
- Уніфікувати LAS command names у `SCNet`, `SCNode`, `SCNode_Tests`, `SCDocs/protocol.md`.
- Виправити payload envelope у SCNode, щоб усі команди передавали повні дані.
- Вирішити, чи SCNode лишається окремим LAS gateway, чи його частина поступово переноситься у SCNet/MistoCommunication.
- Затвердити джерело істини для протоколу: Markdown + contract tests або OpenAPI/AsyncAPI/JSON Schema.
- Узгодити MVP-обсяг: чи входять у першу поставку сторонні системи, import API, export PDF, графіки, auto-complete processed tasks.

Research/gap-дослідження:

- Інтерв'ю з адміністратором, оператором, старшим інженером та інженером щодо реального flow.
- Перевірка, які статуси вже існують у SP MISTO і як їх мігрувати без ламання старих екранів.
- Уточнення, хто є source of truth для ролей: MISTO, TirasCloud чи Service Center.
- Рішення по архівному сховищу для MVP: Elasticsearch достатній чи потрібен ClickHouse.

Критерії виходу:

- Є затверджений `ServiceCenterContract.md` або аналог.
- LAS E2E тести проходять з тими ж command names, що й код.
- Статуси й права не зберігаються як неописані `int`.

### Фаза 1. Platform hardening і delivery contour

Ціль: зробити dev/feature контур достатньо стабільним, щоб на ньому будувати функціональність.

Роботи:

- Закріпити `SCNet/feature/k8s -> Jenkins -> Docker Hub -> SCInfrastructure/argocd-feature -> Argo CD -> scnet-feature`.
- Додати contract/smoke tests після деплою: health endpoints, RabbitMQ connectivity, PostgreSQL migrations, MinIO, Elasticsearch.
- Включити SCNode/LAS у той самий перевірюваний контур або створити окремий узгоджений contour для `las`.
- Замінити plaintext Kubernetes Secret на SealedSecret, ExternalSecret або Pulumi-managed secret.
- Описати rollback не тільки для image tag, а й для DB migrations.
- Перевірити централізовані логи для всіх 5 SCNet сервісів і LAS.
- Додати read-only handoff для QA/розробників: Argo CD, Kubernetes logs, Kibana.

Research/gap-дослідження:

- Вибір секрет-менеджменту для GitOps.
- Чи достатньо Jenkins Docker-in-Docker для майбутнього масштабу, чи планувати BuildKit/buildx.
- Які smoke tests мають бути обов'язковими для кожного merge/deploy.

Критерії виходу:

- Після push у feature-гілку команда бачить Jenkins result, Argo CD health, pods, logs і smoke result.
- Секрети не зберігаються plaintext у Git.
- SCNode/LAS перевіряється разом з ActiveTasks command flow.

### Фаза 2. Core Task Workflow MVP

Ціль: реалізувати надійний backend життєвого циклу заявки для MISTO та oLoader II.

Роботи:

- Ввести формальну state machine заявок: `NEW`, `IN_PROGRESS`, `DEFERRED`, `PROCESSED`, `DELETED`, `COMPLETED`.
- Реалізувати role-based transitions:
  - оператор створює, редагує, призначає, видаляє лише власну нову заявку;
  - адміністратор і старший інженер керують призначенням, дедлайном, поверненням у роботу, видаленням;
  - інженер бере в роботу, відкладає, додає коментарі/вкладення, відмічає виконані несправності, завершує в `PROCESSED`.
- Додати обов'язковий коментар для завершення/видалення там, де це вимагає продукт.
- Реалізувати duplicate folding для активних заявок по об'єкту і несправностях.
- Додати deadline/postpone automation: повернення простроченої відкладеної заявки в `NEW`, події для сповіщень.
- Перейти від тимчасових ID у `ActiveTasksServiceHandler` до PostgreSQL sequence/identity.
- Закріпити persistence/sync: cache -> DB -> archive queue без втрати подій.
- Покрити xUnit tests для state machine, permissions, duplicate folding, postpone rotation.

Research/gap-дослідження:

- Точні правила duplicate folding: одна заявка на об'єкт, на об'єкт+fault, чи на об'єкт+активні статуси.
- Що робити з одночасним редагуванням MISTO/oLoader.
- Які поля є immutable після `COMPLETED` і `DELETED`.

Критерії виходу:

- Backend не дозволяє заборонені переходи незалежно від UI.
- MISTO та LAS команди повертають однакову доменну модель.
- Є regression tests на ключові role/status сценарії.

### Фаза 3. SP MISTO integration і віртуальна база сторонніх об'єктів

Ціль: дати SP MISTO повний операторський/адміністративний інтерфейс та джерела заявок.

Роботи:

- Оновити MISTO task creation:
  - множинний вибір несправностей на створенні;
  - deadline і urgent flag;
  - однаковий layout для MISTO та сторонніх об'єктів;
  - створення з alarm card з відповідальним інженером.
- Додати Kanban API:
  - колонки активних статусів;
  - counters по статусах;
  - фільтри за виконавцем, типом несправності, регіоном;
  - drag/drop або action-based status move.
- Розширити guard object domain:
  - `MonitoringSystem` / стороння система;
  - `VirtualGuardObject`;
  - source marker у заявці й архівному snapshot;
  - ручне створення;
  - import CSV/JSON/XML з upsert по пультовому номеру;
  - validation report для помилок імпорту.
- Додати API для сторонніх систем після discovery.
- Додати виклик ГШР для стороннього об'єкта, якщо підтверджено інтеграційний контракт.
- Додати сторінку управління інженерами охоронної організації на базі `StaffService`/join requests.

Research/gap-дослідження:

- Формати імпорту, обсяг файлів, частота синхронізації, owner/source model.
- Геодовідники MISTO: чи використовуються як runtime dependency, чи копіюються в Service Center.
- Полігони регіонів для фільтрації: джерело, версіонування, fallback без координат.
- Інтеграція ГШР: наявний API, SLA, error handling.
- Реальний UX Kanban: потрібні масові операції, сортування, audit trail.

Критерії виходу:

- Заявка може бути створена з MISTO-об'єкта і стороннього об'єкта з однаковим контрактом.
- Джерело об'єкта видно в активній заявці та архіві.
- Імпорт сторонніх об'єктів має повторювані validation errors і audit trail.

### Фаза 4. Functional slice oLoader II

Ціль: дати інженерам і старшим інженерам мобільний сценарій без прямого доступу до MISTO backend.

Роботи:

- Реалізувати точку входу Service Center в oLoader II через LAS/SCNode.
- Реалізувати join-to-organization flow:
  - список доступних охоронних компаній;
  - один active/pending relationship у першій ітерації;
  - статуси `підтверджено`, `очікуємо`, `відхилено`, `скасовано`;
  - сторінка охоронної компанії.
- Реалізувати senior engineer create task через LAS або MCS-backed command.
- Реалізувати task lists для `NEW`, `IN_PROGRESS`, `DEFERRED`, `PROCESSED`.
- Приховати `DELETED` і `COMPLETED` як архівні для мобільного перегляду, але дозволити дозволені дії старшому інженеру.
- Додати actions: take task, postpone, add comment, add standard/custom fault, add/read attachments, complete/processed.
- Реалізувати push notification matrix:
  - auto-return from deferred to new;
  - engineer self-assigned task;
  - nearing deferred deadline;
  - assigned-to-engineer;
  - changes in assigned task.
- Розширити `SCNode_Tests` на happy path і permission-denied path.

Research/gap-дослідження:

- Який push provider використовує oLoader II і як SCNode має з ним інтегруватися.
- Чи потрібен offline/cache режим для інженера.
- Чи всі файли мають проходити через LAS, як вказано в protocol.md, чи мобільний клієнт може використовувати signed MinIO URLs.
- Як TirasCloud identity token мапиться на `engineerId`.

Критерії виходу:

- Інженер може приєднатися до організації, побачити задачі, взяти задачу, додати коментар/фото, відкласти або опрацювати.
- Усі мобільні команди мають contract tests на SCNode -> RabbitMQ -> ActiveTasks.

### Фаза 5. Archive, statistics, export

Ціль: зробити завершені й видалені заявки придатними для пошуку, контролю та аналітики.

Роботи:

- Завершити snapshot enrichment: ActiveTask + GuardObject + Staff + attachments + history.
- Ввести правила архівації:
  - manual/mass move з `PROCESSED` у `COMPLETED`;
  - auto move через налаштований проміжок часу, якщо підтверджено для ітерації;
  - `DELETED` завжди іде в архів з обов'язковим коментарем.
- Реалізувати табличний archive API:
  - фільтри за статусом, типом, причиною, джерелом, об'єктом, ризиком, регіоном, датами, тривалістю, інженером, автором, attachments;
  - sorting за датою, тривалістю, інженером, типом, об'єктом, причиною, системою моніторингу;
  - pagination.
- Додати full-text search по коментарях.
- Реалізувати export CSV/XLSX як MVP, PDF як окрему ітерацію після погодження шаблонів.
- Додати analytics panel: counters, average duration, top fault types, SLA buckets.

Research/gap-дослідження:

- Elasticsearch vs ClickHouse як основний backend архівної статистики.
- Які саме колонки з Google Spreadsheet є MVP, а які йдуть у backlog.
- Політика retention, PII, право на зміну/видалення архівних коментарів і вкладень.
- Експортні формати, мова, timezone, права доступу.

Критерії виходу:

- Архів не змінюється при зміні об'єкта в MISTO.
- Фільтри/сортування покриті інтеграційними тестами.
- Export працює для фільтрованої вибірки.

### Фаза 6. Production readiness і rollout

Ціль: підготувати Service Center до production-grade запуску.

Роботи:

- Перевести feature contour у target PR-preview / Dev / Staging / Prod flow.
- Додати migration strategy для PostgreSQL і archive indices.
- Ввести rate limits, authorization policies, audit logs для критичних дій.
- Провести load/performance tests:
  - активні заявки;
  - RabbitMQ RPC latency;
  - archive search;
  - file uploads;
  - SignalR/Socket.IO connections.
- Підготувати backup/restore runbooks для PostgreSQL, Elasticsearch/ClickHouse, MinIO.
- Підготувати UAT сценарії по ролях.
- Запустити pilot на обмеженій кількості охоронних організацій.

Research/gap-дослідження:

- Реальні обсяги заявок, фото, історії та архівних запитів.
- SLA для push notifications і RabbitMQ retries.
- Юридичні/операційні вимоги до retention і audit.
- План міграції існуючих заявок/об'єктів, якщо він потрібен.

Критерії виходу:

- Є production checklist, rollback checklist, monitoring dashboards, support runbook.
- Pilot користувачі пройшли UAT.
- Відомі P1/P2 дефекти закриті або прийняті як release risk.

## 5. Пріоритетний MVP-slice

Рекомендований перший наскрізний slice:

1. Уніфікований LAS contract і SCNode payload fix.
2. ActiveTasks state machine + permissions для `NEW`, `IN_PROGRESS`, `DEFERRED`, `PROCESSED`.
3. Join request / engineer organization flow.
4. oLoader: список організацій, приєднання, список нових задач, взяття в роботу, коментар, відкладення, опрацювання.
5. MISTO: створення/редагування заявки, призначення, дедлайн, коментарі, basic Kanban.
6. Archive: snapshot запис для `COMPLETED` і `DELETED`, базовий table API без advanced analytics.
7. Feature deploy + smoke + logs + rollback.

Цей slice мінімізує невідомість: він проходить через усі критичні компоненти, але не блокується імпортом сторонніх баз, PDF export, графіками або повним PR-preview.

## 6. Рекомендовані документи-наступники

- `ServiceCenterContract.md`: статуси, ролі, actions, state machine, command schemas.
- `LASContractTests.md`: список контрактних тестів між SCNode і ActiveTasks.
- `VirtualObjectsDiscovery.md`: сторонні системи, import/API, source marker, ГШР.
- `ArchiveAnalyticsSpec.md`: колонки, фільтри, сортування, export, dashboard.
- `ReleaseChecklist.md`: CI/CD, smoke, rollback, logs, migrations, secrets.

## 7. Посилання на platform documentation

- `InfrastructureAndGitOps.md` - active feature contour, Jenkins/Argo CD model і secret debt.
- `PlatformRunbooks.md` - operator checks і promotion checklist.
- `projects/shared/KubernetesSecurityHardening.md` - RBAC, NetworkPolicy, audit і Sealed Secrets baseline.
- `projects/shared/MinIOKubernetesInfrastructure.md` - shared object-storage operating model.
- `projects/shared/KubernetesObservabilityLoggingGitOps.md` - logging і post-deploy visibility.

Service Center promotion до `SCDocs` лишається окремим approved run.
