## 1. Статуси
### Backlog
Епік або задача вже визнані потрібними, але робота ще не запланована в активний цикл.
### Selected for Development
Епік або задача вже пріоритезовані, зрозумілі по scope, і їх можна брати найближчим часом.  
Це не “колись”, а **наступна черга**.
### In Progress
Є реальна активна робота, артефакти або зміни в коді / інфраструктурі / документації.
### Done
Є зафіксований outcome, який можна прийняти як завершений на поточному етапі.

---
## 2. Як класифікувати задачі за допомогою лейблів
Важливо, щоб labels не перетворилися на хаос, тому рекомендую не робити “вільні теги”, а ввести 3 обов’язкові осі labels:
#### A. Domain / Area
Що це за продуктова або інфраструктурна зона.
Рекомендований naming:
- `dom-tirascloud`
- `dom-service-center`
- `dom-shared`
#### B. Workstream
Який це тип роботи.
Рекомендований naming:
- `ws-platform`
- `ws-workloads`
- `ws-enabler`
- `ws-discovery`
- `ws-migration`
- `ws-delivery`
#### C. Environment / Scope
Для якого середовища або масштабу актуальна робота.
Рекомендований naming:
- `env-dev`
- `env-prod`
- `env-stage`
- `env-shared`

---
## 3. Naming convention для labels
Фіксуємо таке правило:
- тільки **lowercase**
- тільки **kebab-case**
- префікс обов’язковий
- один label = одна вісь класифікації
- не дублювати зміст статусом або Summary
### Рекомендований формат

`<prefix>-<value>`
### Префікси
- `dom-` → domain
- `ws-` → workstream
- `env-` → environment
- `prog-` → program / strategic track
- `tech-` → технологічний акцент, лише якщо дуже потрібно
### Приклади
- `dom-tirascloud`
- `dom-service-center`
- `dom-shared`
- `ws-platform`
- `ws-migration`
- `ws-enabler`
- `env-dev`
- `env-prod`
- `env-shared`
- `prog-k8s-platform`
- `prog-ha-platform`

---
## 4. Як правильно розділити домени
Dev і Prod не зливаємо в один operational Epic, але й не розводимо їх у комплексну розділену таксономію, якщо вони належать до однієї платформи.
## Рівень домену
Один домен:
- `dom-tirascloud`
## Рівень середовища
Окремі labels:
- `env-dev`
- `env-prod`
- `env-shared`
## Рівень Epic-ів
Епіки робити **по operational outcome**, а не “по всій платформі одразу”.
Тобто зараз:
- якщо ми реально працюємо над міграцією Dev середовища, то Epic-и мають бути з лейблом `env-dev`
- Prod не треба змішувати всередині тих самих Epic-ів, якщо workstream іще не активний
- Загальні речі можна помічати як `env-shared`
### Практично це означає:
#### Dev-focused Epic
`dom-tirascloud + env-dev + ws-platform`
#### Майбутній Prod-focused Epic
`dom-tirascloud + env-prod + ws-platform`
#### Shared Epic
Наприклад pipeline model або access model:  
`dom-tirascloud + env-shared + ws-enabler`

---
## 6. Стратегічні задачі
Оскільки у нас **немає Initiative-рівня** в Jira ми обходимо це program label, щоб класифікувати задачі за стратегічними довгостроковими треками (такими як перехід на k8s всієї ІТ-інфраструктури).
### Верхньорівневі program labels:
- `prog-k8s-platform`
- `prog-ha-platform`
### Як їх застосовувати
#### `prog-k8s-platform`
Ставити на всі епіки й задачі, які ведуть до переходу на Kubernetes/GitOps platform model.
#### `prog-ha-platform`
Ставити тільки там, де є прямий внесок у майбутню HA-модель:
- storage semantics
- reproducible foundation
- GitOps ownership
- stateful services
- cutover readiness
- prod-oriented platform design

---
## 7. Робота в спейсі
Дошка — це робочий простір.  
Але щоб бачити “весь трек переходу на Kubernetes/HA”, краще мати:
1. **один або два program labels**
2. збережений Jira filter / quick filter
3. короткий roadmap-doc / Confluence note з поясненням програми
Тобто:
- **board** = execution space
- **labels + filters** = навігація по програмі
- **roadmap note** = пояснення, куди все це рухається

---
## 8. Початкова label-схема
Ось готовий мінімальний набір на поточний моменти, з якого можна стартувати.
### Domain
- `dom-tirascloud`
- `dom-service-center`
- `dom-shared`
### Environment
- `env-dev`
- `env-prod`
- `env-stage`
- `env-shared`

### Workstream
- `ws-platform`
- `ws-workloads`
- `ws-migration`
- `ws-enabler`
- `ws-discovery`
- `ws-delivery`
### Program
- `prog-k8s-platform`
- `prog-ha-platform`

### Опційно, якщо справді потрібно
- `tech-gitops`
- `tech-argocd`
- `tech-jenkins`
- `tech-mongodb`
- `tech-redis`
- `tech-minio`