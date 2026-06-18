# Gaps протоколу LAS

Статус: особистий робочий документ  
Джерела: `C:\work\SCDocs\protocol.md`, `C:\work\SCNet\docs\las-protocol.md`, `C:\work\SCNet\docs\las-commands`, `C:\work\SCNode\src`

## Призначення

Цей документ tracks gaps між LAS protocol documentation, SCNet contract docs і SCNode implementation.

Ціль — зробити LAS command contract достатньо стабільним для:

- oLoader II mobile flow;
- SCNode Socket.IO gateway;
- RabbitMQ RPC with ActiveTasksService;
- `SCDocs\protocol.md` as team-facing documentation.

## Поточні джерела правди

| Source | Роль |
| --- | --- |
| `SCDocs\protocol.md` | team-facing protocol document |
| `SCNet\docs\las-protocol.md` | protocol copy біля SCNet source |
| `SCNet\docs\las-commands\*.md` | atomic command docs |
| `SCNode\src\interfaces\enums\commands.enum.ts` | implemented command enum |
| `SCNode\src\adapters\rabbitmq\RabbitMQAdapter.ts` | outbound RabbitMQ adapter |
| `SCNode\src\tests\integration.rabbit.socket.test.ts` | integration coverage для Socket.IO + RabbitMQ flow |

## Вирівнювання commands

Observed command names загалом align між protocol docs і SCNode enum:

| Command | Direction | Status |
| --- | --- | --- |
| `GET_ORGANIZATION_LIST` | LAS -> ATM/MCS | documented і implemented |
| `LINK_ENGINEER_TO_ORGANIZATION` | LAS -> ATM/MCS | documented і implemented |
| `UNLINK_ENGINEER_FROM_ORGANIZATION` | LAS -> ATM/MCS | documented і implemented |
| `GET_ENGINEER_ORGANIZATION_LIST` | LAS -> ATM/MCS | documented і implemented |
| `GET_NEW_ORGANIZATION_TASKS` | LAS -> ATM | documented і implemented |
| `GET_ENGINEER_TASKS_IN_PROGRESS` | LAS -> ATM | documented і implemented |
| `GET_PROCESSED_ENGINEER_TASKS` | LAS -> ATM | documented і implemented |
| `GET_DEFERRED_ENGINEER_TASKS` | LAS -> ATM | documented і implemented |
| `GET_TASK` | LAS -> ATM, response ATM -> LAS | documented і implemented |
| `TAKE_TASK` | LAS -> ATM | documented і implemented |
| `ADD_STANDARD_FAULT_TO_TASK` | LAS -> ATM | documented і implemented |
| `ADD_CUSTOM_FAULT_TO_TASK` | LAS -> ATM | documented і implemented |
| `ADD_COMMENT_TO_TASK` | LAS -> ATM | documented і implemented |
| `ASSIGN_TASK` | ATM -> LAS | documented і implemented як server command |

## Відомі gaps

### Direction ambiguity

Деякі protocol sections досі кажуть `ATM (MCS) ?` або залишають uncertainty щодо того, чи command іде до ActiveTasksService напряму, чи через MistoCommunicationService.

Потрібне рішення:

- документувати logical direction як LAS -> Service Center backend;
- документувати runtime transport окремо як RabbitMQ queues;
- назвати actual owner service для кожної command.

### Payload completeness

SCNode command creation має передавати достатній payload для commands, яким потрібно більше ніж `organizationId` і `engineerId`.

Commands, які потребують careful payload checks:

- `TAKE_TASK`;
- `ADD_STANDARD_FAULT_TO_TASK`;
- `ADD_CUSTOM_FAULT_TO_TASK`;
- `ADD_COMMENT_TO_TASK`;
- `GET_TASK`;
- `ASSIGN_TASK` notification acknowledgement.

### Status vocabulary

Protocol docs включають task states на кшталт `NEW`, `ASSIGNED`, `PROCESSED`, `DEFERRED`, `COMPLETED`.

Service Center roadmap також обговорює status/state-machine gaps. Protocol не має drift from backend state machine.

### File transfer path

Protocol notes питають, чи всі data, навіть files, проходять через LAS.

Потребує перевірки:

- чи mobile file upload/download має проходити через LAS;
- чи треба використовувати MistoCommunicationService/MinIO signed URLs;
- як authentication і audit працюють для mobile attachments.

## Запропонований порядок cleanup

1. Freeze command-name table.
2. Для кожної command визначити owner service і runtime queue.
3. Для кожної command визначити request payload і response payload.
4. Додати error model на command.
5. Align `SCDocs\protocol.md`, `SCNet\docs\las-commands` і SCNode integration tests.
6. Додати contract tests для payload shape.

## Proposal для promotion

Later promotion target:

```text
C:\work\SCDocs\protocol.md
```

Не promote, доки:

- command direction ambiguity resolved;
- payload completeness checked against SCNode і SCNet;
- status vocabulary aligned із Service Center backend state machine.

## Відкриті питання

- Чи `MCS` є transport participant для LAS commands або лише documentation alias?
- Чи `SCNet\docs\las-commands` має стати source для generating sections у `SCDocs\protocol.md`?
- Які tests authoritative для protocol compatibility: SCNode Jest tests, SCNet tests або окремий schema/contract suite?
