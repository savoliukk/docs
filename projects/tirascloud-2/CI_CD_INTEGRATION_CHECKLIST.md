- Rollout order бере service-to-service dependency table з migration runbook.
- Нижня config.json dependency table у migration runbook є infra/runtime reference, не rollout source of truth.
- MongoDB і Redis вважаються готовими prerequisites перед app rollout.
- Dependencies із `~` і dependency cycles вважаються soft runtime/integration dependencies.
- Soft/cyclic dependencies перевіряються у фінальному traceability & monitoring step.
- `common`, `auth_mock` і `emulator` не є deployable services для цього CI/CD checklist.
- `firegateway` у старих нотатках означає `firegw`.

## Wave 0: prerequisites

- [x] Namespace `tirascloud-dev` існує і керується через GitOps.
- [x] Argo CD має доступ до `C:\work\ideal-octo-giggle` через configured repo secret.
- [x] Jenkins має доступ до `C:\work\TirasCloud-2` і може push-ити image tag updates у GitOps.
- [x] Docker registry credentials існують у Jenkins як `dockerhub-credentials`.
- [x] GitOps SSH credential існує у Jenkins як `github-savoliukk-ssh`.
- [x] MongoDB готовий для app runtime.
- [x] Redis готовий для app runtime.
- [ ] Runtime secret placeholders або sealed/cluster-backed secrets існують для потрібних object names.
- [ ] GitOps diff не містить реальних plaintext secret values.
- [ ] `tirascloud-runtime-secrets` synced перед service deployments, які посилаються на shared secrets.

## Deployment waves

Для кожного сервісу використовується один promotion loop: local test gate, Jenkins build/push, GitOps tag update, Argo CD sync, pod/runtime smoke check. У межах однієї хвилі сервіси можна розгортати незалежно, якщо нижче не вказано інше.

### Wave 1: root service

- [x] `tirasmq` - root TMQ service без app service dependency.

### Wave 2: незалежні non-RocksDB services

Ці сервіси не залежать від RocksDB-affected services і можуть іти до RocksDB gate.

Примітка: `firestates` перенесений до Wave 4 because RDB storage exists / RocksDB-related service.
- [x] `logger` - depends on `tirasmq`.
- [x] `journal` - depends on `tirasmq`, MongoDB, Redis.
- [x] `firejournal` - depends on `tirasmq`, MongoDB, Redis.
- [x] `mailer` - depends on `tirasmq`, MongoDB.
- [x] `firmware` - depends on `tirasmq`, MongoDB.

### Wave 3: RocksDB unblock gate

Не promote-ити RocksDB-affected services, доки не закриті всі blocker conditions:

- [x] Є compatible glibc-based Node/RocksDB runtime або `modules/common/rdb.node` rebuilt під обраний runtime.
- [x] Native CI smoke gate падає до image build/push, якщо `rdb.node` не вантажиться або basic read/write не працює.
- [x] GitOps manifests мають explicit writable mounts для RocksDB data paths.
- [x] PVC/persistence policy визначена для data, яка має переживати pod restart.

Blocked services: `auth`, `firestates`, `geo`, `ip2location`, `notifyjournal`, `storemod`.

### Wave 4: RocksDB-affected services

Розгортати тільки після проходження Wave 3.

- [x] `firestates` - depends on `tirasmq`; RDB storage exists / RocksDB-related service.
- [x] `notifyjournal` - depends on `tirasmq`; active RocksDB user.
- [ ] `ip2location` - depends on `tirasmq`; active RocksDB user.
- [ ] `geo` - depends on `tirasmq`, MongoDB; active RocksDB user.
- [ ] `storemod` - depends on `tirasmq`, MongoDB; active RocksDB user.
- [ ] `auth` - depends on `tirasmq`, MongoDB, Redis, `mailer`; active RocksDB user. `app_modded~` treated as soft/cyclic.

### Wave 5: simple downstream services

- [x] `spamer` - depends on `tirasmq`, MongoDB, `mailer`.
- [ ] `tgsupportbot` - depends on `tirasmq`, MongoDB, `auth`.

### Wave 6: cyclic core group

У цих сервісів є runtime dependency cycles у migration runbook. Розгортаємо у фіксованому порядку, а cross-service behavior перевіряємо в кінці.

- [x] `onliner` - depends on `tirasmq`, MongoDB, `debugger`; `debugger` soft during initial deploy.
- [ ] `debugger` - depends on `tirasmq`, `onliner`, `udpnew`; `udpnew` soft during initial deploy.
- [x] `gateway` - depends on `tirasmq`, MongoDB, Redis, `logger`, `journal`, `onliner`, `device`; `device` soft during initial deploy.
- [x] `device` - depends on `tirasmq`, MongoDB, Redis, `gateway`, `firegw`, `onliner`, `mailer`; `gateway` і `firegw` soft during initial deploy.
- [x] `firegw` - depends on `tirasmq`, MongoDB, `onliner`, `device`, `firestates`.
- [x] `udpnew` - depends on `tirasmq`, `storemod`, `gateway`, `onliner`, `device`, `debugger`, `geo`; `app_modded~` soft/cyclic.
- [x] `fireudp` - depends on `tirasmq`, MongoDB, `device`, `onliner`, `firegw`.
- [x] `adddev` - depends on `tirasmq`, `device`.
- [x] `v2web` - depends on `tirasmq`, `device`.

### Wave 7: aggregation і user-facing services

- [ ] `app_modded` - depends on `tirasmq`, MongoDB, Redis, `device`, `onliner`, `auth`, `gateway`, `mailer`, `notifyjournal`, `ip2location`, `journal`, `udpnew`.
- [ ] `support` - depends on `tirasmq`, MongoDB, `gateway`, `firegw`, `onliner`, `storemod`, `geo`, `app_modded`, `spamer`.

## Service matrix

| Service | Wave | CI gate | GitOps status | Runtime risk / next action |
| --- | ---: | --- | --- | --- |
| `tirasmq` | 1 | `test:tirasmq` | base/dev/Application present | Baseline root service; `TMQ_PASSWORD` має бути secret-backed. |
| `firestates` | 4 | `test:firestates` | base/dev/Application present | RDB storage exists / RocksDB-related; status already validated before Wave 4 regrouping. |
| `logger` | 2 | `test:logger` | base/dev/Application present | Confirm health strategy і writable log behavior. |
| `journal` | 2 | `test:journal` | base/dev/Application present | Needs MongoDB/Redis runtime validation. |
| `firejournal` | 2 | `test:firejournal` | base/dev/Application present | Needs MongoDB/Redis runtime validation. |
| `mailer` | 2 | `test:mailer` | base/dev/Application present | Decide local sendmail vs SMTP/API provider before promotion. |
| `firmware` | 2 | `test:firmware` | base/dev/Application present | Confirm HTTP port і public exposure model. |
| `notifyjournal` | 4 | `test:notifyjournal` | base/dev/Application present | RocksDB blocked; confirm health strategy. |
| `ip2location` | 4 | `test:ip2location` | base/dev/Application present | RocksDB blocked; confirm health strategy. |
| `geo` | 4 | `test:geo` | base/dev/Application present | RocksDB blocked; confirm GSM DB/dev TMQ runtime config. |
| `storemod` | 4 | `test:storemod` | base/dev/Application present | RocksDB blocked; needs writable data path. |
| `auth` | 4 | `test:auth` | base/dev/Application present | RocksDB blocked; needs JWT/Firebase secrets і public exposure. |
| `spamer` | 5 | `test:spamer` | base/dev/Application present | Validate `mailer` dependency і Redis usage. |
| `tgsupportbot` | 5 | `test:tgsupportbot` | base/dev/Application present | Needs Telegram/JWT/TLS secret flow без plaintext values. |
| `onliner` | 6 | `test:onliner` | base/dev/Application present | Cyclic group; validate health port. |
| `debugger` | 6 | `test:debugger` | base/dev/Application present | Cyclic group; remove hardcoded runtime config before promotion if still present. |
| `gateway` | 6 | `test:gateway` | base/dev/Application present | Cyclic group; decide UDP exposure model. |
| `device` | 6 | `test:device` | base/dev/Application present | Cyclic group; validate health and downstream calls. |
| `firegw` | 6 | `test:firegw` | base/dev/Application present | Cyclic group; decide UDP exposure and health strategy. |
| `udpnew` | 6 | `test:udpnew` | base/dev/Application present | Cyclic group; decide workload model for UDP workers. |
| `fireudp` | 6 | `test:fireudp` | base/dev/Application present | Cyclic group; decide workload model for UDP workers. |
| `adddev` | 6 | `test:adddev` | base/dev/Application present | Deploy after `device`; confirm `/health` route. |
| `v2web` | 6 | `test:v2web` | base/dev/Application present | Deploy after `device`; add real frontend build/runtime smoke gate. |
| `app_modded` | 7 | `test:app_modded` | base/dev/Application present | Aggregator; validate upstream calls and Firebase/TLS secret mounts. |
| `support` | 7 | `test:support` | base/dev/Application present | Aggregator; add real build/runtime smoke gate and TLS handling decision. |

Excluded from deployable service waves: `common`, `auth_mock`, `emulator`.

## Нагадування щодо secrets і runtime config

- Runtime values мають приходити через Kubernetes `Secret`, `ConfigMap`, Jenkins credentials або sealed/cluster-backed secret flow.
- Комітити можна тільки явні dummy placeholders або encrypted/sealed manifests.
- Jenkins credential IDs:
  - `dockerhub-credentials`
  - `github-savoliukk-ssh`
- App runtime secret object names, referenced by TirasCloud manifests:
  - `tirascloud-dev/tirasmq-secret`
  - `tirascloud-dev/tirascloud-mongo-secret`
  - `tirascloud-dev/tirascloud-redis-secret`
  - `tirascloud-dev/tirascloud-auth-secret`
  - `tirascloud-dev/tirascloud-firebase-auth-secret`
  - `tirascloud-dev/tirascloud-firebase-app-secret`
  - `tirascloud-dev/tirascloud-tls-secret`
  - `tirascloud-dev/tgsupportbot-secret`
  - `tirascloud-dev/tirascloud-grafana-secret`
  - `tirascloud-dev/dockerhub-pull-secret`
- Argo CD/Jenkins platform dependency secrets:
  - `jenkins/jenkins-admin-secret`
  - `jenkins/jenkins-ci-credentials`
  - `jenkins/jenkins-github-savoliukk-ssh`
  - `argocd/repo-gitops`
  - `argocd/argocd-secret`

## Фінальний non-blocking step: traceability і monitoring check

Цей step виконується після rollout waves. Знайдені gaps стають follow-up tasks і не блокують сам deployment sequence.

- [x] Для кожного service є Argo CD Application.
- [ ] Кожен Argo CD Application має `Synced` і `Healthy`, або має зафіксований follow-up.
- [ ] Кожен deployed image tag traceable до Jenkins run, який його зібрав і запушив.
- [ ] Кожен Deployment pod template використовує expected image tag.
- [ ] Running pods використовують expected image або digest.
- [ ] Logs reachable для кожного app pod.
- [ ] Required labels/annotations існують для ownership, app identity, environment і traceability.
- [ ] Monitoring gaps, dashboard gaps, alert gaps і missing log routing записані як окремі tasks.

## Швидка validation перед наступним редагуванням цього файла

- [ ] Кожен Jenkins `serviceConfig` service appears in exactly one wave.
- [ ] Жоден service, який depends on RocksDB-affected services, не appears before Wave 4.
- [ ] Жодних real secret values із migration notes або local configs немає.
- [ ] Details, які belong in dedicated docs, linked, not duplicated here.

## Linked runbooks

- `CI_CD_PIPELINE.md` - Jenkins/GitOps/Argo CD pipeline behavior.
- `BUILD_STRATEGY.md` - BuildKit direction і POC acceptance.
- `ROCKSDB_NATIVE_RUNTIME_BLOCKER.md` - чому RocksDB services лишаються gated.
- `ROCKSDB_RUNTIME_SMOKE_RUNBOOK.md` - як validate affected services після runtime fixes.
- `projects/shared/SoftwareSupplyChainSecurity.md` - shared supply-chain security controls.

Approved runtime secret workflow: Sealed Secrets.
