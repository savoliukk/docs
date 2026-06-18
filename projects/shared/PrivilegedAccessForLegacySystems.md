# Privileged access для legacy systems

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/Без назви.md`, `archive/2026-05-11/Без назви 1.md`, access/secrets governance notes

## Призначення

Цей документ фіксує практичні варіанти зменшення ризику навколо legacy systems, які все ще залежать від shared passwords або слабких access boundaries.

Ціль не в тому, щоб "ділитися паролем з меншою кількістю людей". Ціль — прибрати direct password exposure там, де можливо, і додати audit, revoke та rotation.

## Модель проблеми

Legacy shared-password systems зазвичай створюють такі ризики:

- no individual accountability;
- hard offboarding;
- password reuse;
- no session evidence;
- password copied into notes, chat or browsers;
- no clean way to grant temporary access.

## Варіант matrix

| Варіант | З чим допомагає | Обмеження |
| --- | --- | --- |
| Password manager with groups | Controlled sharing, audit, offboarding | Users усе ще можуть бачити/копіювати password. |
| PAM / privileged session manager | Credential injection, session recording, approval | Вищий cost і operational overhead. |
| Remote desktop / jump host | Ховає credentials за controlled session | Має запобігати clipboard/file leakage там, де потрібно. |
| ZTNA / access proxy | Controls, хто може досягати legacy app | Не завжди ховає password всередині app. |
| VPN + IP allowlist | Network containment | Слабка accountability, якщо password усе ще shared. |
| App modernization / SSO wrapper | Long-term fix | Потребує development або vendor support. |

## Рекомендований phased approach

### Phase 1. Stabilize

- Інвентаризувати legacy systems і owners.
- Перенести shared credentials в approved password manager.
- Обмежити access за group.
- Додати rotation при staff/contractor changes.
- Зафіксувати, хто approves access.

### Phase 2. Contain

- Розмістити app за VPN/ZTNA або access proxy.
- Прибрати public exposure там, де можливо.
- Додати IP allowlist і logging.
- Вимагати MFA перед досягненням access layer.

### Phase 3. Reduce direct password exposure

- Провести pilot credential injection або session proxy для highest-risk system.
- Додати session logging для privileged workflows.
- Rotate underlying shared password після того, як proxy path live.

### Phase 4. Replace

- Перейти на per-user accounts, SSO або application modernization.
- Retire shared password.

## Правила документації

Дозволено:

- system alias;
- owner;
- access group name;
- password manager item name;
- rotation date;
- approval path.

Заборонено:

- actual password;
- screenshots showing password fields or tokens;
- private URLs with secret tokens;
- connection strings with credentials.

## Відкриті питання

- Які legacy systems є P0 для shared-password reduction?
- Який варіант реалістичний першим: лише password manager, jump host, ZTNA або PAM?
- Які actions потребують session recording?
- Хто є власником quarterly access review?
