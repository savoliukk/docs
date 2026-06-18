# CI/CD Pipeline Review: services TirasCloud

Дата: 2026-05-08

Обсяг: `journal`, `firejournal`, `mailer`, `firmware`, `ip2location`, `geo`, `storemod`, `auth`, `spamer`, `tgsupportbot`, `onliner`, `debugger`, `gateway`, `device`, `firegw`, `udpnew`, `fireudp`, `adddev`, `v2web`, `app_modded`, `support`.

Переглянуті джерела:

- App repository: `C:\work\TirasCloud-2`
- GitOps repository: `C:\work\ideal-octo-giggle`
- Карта залежностей: `C:\work\docs\projects\tirascloud-2\DEPENDENCY_MAP.md`
- RocksDB blocker doc: `C:\work\docs\projects\tirascloud-2\ROCKSDB_NATIVE_RUNTIME_BLOCKER.md`
- Service traffic routing doc: `C:\work\docs\projects\tirascloud-2\SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md`
- Kubernetes exposure doc: `C:\work\docs\projects\tirascloud-2\Як правильно відкривати Kubernetes-сервіси - назовні HTTP через Ingress, UDP через L4, внутрішнє — через ClusterIP.md`

Validation, виконана локально:

- `kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\<service>\overlays\dev` passed для всіх 21 services.
- `npm run test:<service>` passed для всіх 21 services.
- `npm run test:rdb-contract` passed і підтвердив, що metadata `modules/common/rdb.node` points to `librocksdb.so.5.17` і `docker.io/tiras12/tirascloud-node-rocksdb:node22-rocksdb5.17`.
- Jenkins/Kaniko live build, ArgoCD sync або runtime pod smoke не виконувались як частина цього review.

Важливо: Telegram token, наданий у chat, не був записаний у repository або цей report. Він має лишатися тільки в Kubernetes Secret / Jenkins Credential.

## Ключові висновки

### P1: External exposure не завершений для device-facing UDP і user-facing HTTP/WS services

Переглянуті service manifests здебільшого deploy Deployments і ClusterIP Services. Це правильно для internal services, але ще не робить public/device-facing workloads usable ззовні cluster.

Докази:

- Platform public Ingress зараз routes `microk8s.dev.tirascloud.com` лише до `acme-placeholder`: `C:\work\ideal-octo-giggle\cluster\platform\public-ingress\ingress-microk8s-dev.yaml`.
- Device-facing UDP Services досі `ClusterIP`: `gateway` UDP 4005, `udpnew` UDP 4015/4016/4017, `firegw` UDP 4030, `fireudp` UDP 4033/4035/4037/4039/4041.
- UDP routing document каже, що їх не можна routed by HTTP Ingress і потрібні L4 exposure, source IP preservation та environment-specific external IP/port values.
- HTTP/WS services, яким імовірно потрібен external access, також лишаються ClusterIP-only: `firmware`, `auth`, `tgsupportbot`, `debugger`, `adddev`, `v2web`, `app_modded`, `support`.

Вплив:

- ArgoCD може показувати `Synced` і `Healthy`, але real devices/users можуть досі не reach service.
- UDP bootstrap може return address, який не reachable from devices.
- Migration може виглядати successful на pod level, але failing на workload level.

Prompt для Codex:

```text
PLEASE IMPLEMENT A PROPOSAL, NOT A BLIND ROLLOUT:
Переглянь GitOps repo C:\work\ideal-octo-giggle і підготуй dev exposure manifests для TirasCloud services відповідно до docs:
- HTTP/HTTPS/WebSocket через Ingress або Gateway API.
- Device UDP через L4 Service/NodePort/LoadBalancer з externalTrafficPolicy: Local.
- Тримай base manifests environment-neutral і клади exposure лише в dev overlays або platform layer.
- Не expose нічого публічно, доки hostnames, source ranges, external IPs і NodePort/MetalLB strategy не підтверджені.
- Підготуй decision table для firmware, auth, tgsupportbot, debugger, adddev, v2web, app_modded, support, gateway, udpnew, firegw, fireudp.
```

### P1: UDP bootstrap/server-list configuration досі baked into app files

Докази:

- `C:\work\TirasCloud-2\modules\gateway\settings.json` advertises worker IPs як `127.0.0.1` для ports 4015/4016/4017.
- `C:\work\TirasCloud-2\modules\udpnew\settings.json` starts local workers з `127.0.0.1` ports 4015/4016/4017.
- `C:\work\TirasCloud-2\modules\firegw\serverList.json` і `C:\work\TirasCloud-2\modules\fireudp\settings.json` містять hard-coded public IPv4 values для ports 4033/4035/4037/4039/4041.
- `gateway/events.js` builds ACK payloads з `server.ip` і `server.port`; `firegw/events/protoV3.js` робить те саме для fire devices.

Вплив:

- Image embeds environment-specific routing values.
- Kubernetes rollout може update pod, але не actual device handoff target, якщо baked JSON не correct for dev.
- DNS не можна використати напряму в existing ACK payload, бо code converts IPv4 string octets into bytes.

Prompt для Codex:

```text
PLEASE IMPLEMENT ENVIRONMENT-SPECIFIC UDP ROUTING CONFIG SAFELY:
Проаналізуй runtime config loading у gateway, udpnew, firegw і fireudp. Перенеси gateway/settings.json, udpnew/settings.json, firegw/serverList.json і fireudp/settings.json у Kubernetes ConfigMaps, змонтовані в dev overlays, зі збереженням current file paths усередині container. Не змінюй wire protocol. Лишай defaults в image лише для local dev. Додай validation script, який fails, якщо device-facing advertised IPs є 127.0.0.1, Pod IP, ClusterIP або non-IPv4 strings під час запуску в Kubernetes.
```

### P1: `support` starts active WebSocket listeners, які не exposed by Kubernetes

Докази:

- `C:\work\TirasCloud-2\modules\support\index.js:14` requires `./lib/ologService` during startup.
- `C:\work\TirasCloud-2\modules\support\lib\ologService.js:22` starts WS on 4071.
- `C:\work\TirasCloud-2\modules\support\lib\ologService.js:26` starts WSS on 4072.
- GitOps exposes only 4070: `C:\work\ideal-octo-giggle\cluster\apps\tirascloud\support\base\deployment.yaml` і `service.yaml`.

Вплив:

- Support HTTP може бути reachable через Service, але online-log WS clients не можуть reach 4071/4072 через Kubernetes Service.
- Runtime smoke, який перевіряє лише 4070, пропустить це.

Prompt для Codex:

```text
PLEASE FIX SUPPORT PORT CONTRACT:
Переглянь modules/support/index.js і modules/support/lib/ologService.js. Виріши з code, чи 4071/4072 є active public/internal WebSocket APIs. Якщо active, онови Dockerfile EXPOSE, GitOps Deployment containerPorts, Service ports і dev runbook checks. Якщо їх треба disabled in Kubernetes, gate ologService startup через env і задокументуй disabled mode. Не expose externally без explicit private/public ingress decision.
```

### P1: `app_modded` starts active log Socket.IO server на 5102, який не exposed

Докази:

- `C:\work\TirasCloud-2\modules\app_modded\boot\index.js:2` loads `./log`.
- `C:\work\TirasCloud-2\modules\app_modded\classes\log.js:99` sets port 5102.
- `C:\work\TirasCloud-2\modules\app_modded\classes\log.js:233` listens on 5102.
- Dockerfile/GitOps expose only 5020 і 5022.

Вплив:

- Main Socket.IO ports можуть work, поки online log endpoint unreachable.
- Container healthcheck на 5022 не detect broken/missing 5102 contract.

Prompt для Codex:

```text
PLEASE FIX APP_MODDED LOG SOCKET CONTRACT:
Проаналізуй app_modded boot/log usage і consumers 5102 Socket.IO log server. Якщо 5102 required, додай env-configurable port, Dockerfile EXPOSE, Deployment containerPort, Service port і runtime smoke для 5102. Якщо він not required in Kubernetes, додай env flag для disable і задокументуй це decision. Збережи existing 5020/5022 behavior.
```

### P1: `mailer` depends on `/usr/sbin/sendmail`, але image не explicitly provide known MTA

Докази:

- `C:\work\TirasCloud-2\modules\mailer\index.js:20-23` creates a Nodemailer sendmail transport with `path: '/usr/sbin/sendmail'`.
- `C:\work\TirasCloud-2\modules\mailer\Dockerfile` based on `node:18-alpine` і не explicitly install/configure `sendmail`, `msmtp`, `postfix` або SMTP credentials.
- `npm run test:mailer` запускає лише static file/Dockerfile checks.

Вплив:

- CI може pass, поки runtime mail delivery fails.
- Навіть якщо Alpine provides BusyBox sendmail applet, delivery behavior implicit і не є auditable production contract.

Prompt для Codex:

```text
PLEASE FIX MAILER DELIVERY CONTRACT:
Переглянь modules/mailer/index.js і Dockerfile. Заміни implicit /usr/sbin/sendmail dependency на explicit delivery strategy: або install/configure known lightweight MTA, наприклад msmtp, з SMTP settings із Kubernetes Secret, або switch Nodemailer to SMTP transport using env/Secret values. Додай CI image smoke, який verifies, що configured binary/transport exists, без sending real email. Не commit SMTP credentials і не send real mail in CI.
```

### P2: Jenkins updates GitOps broad text replacement і не render manifests before pushing

Докази:

- `C:\work\TirasCloud-2\Jenkinsfile:384-388` runs `sed -i 's#newTag: .*#newTag: ...#'` against each dev kustomization.
- Pipeline не запускає `kubectl kustomize` або equivalent після tag update.
- Поточні kustomizations мають по одному image, тому це працює сьогодні, але буде fragile, коли overlay матиме multiple images або comments.

Вплив:

- Future kustomization з multiple `newTag` fields може бути changed incorrectly.
- Broken GitOps може бути pushed before ArgoCD discovers it.

Prompt для Codex:

```text
PLEASE HARDEN JENKINS GITOPS UPDATE:
У C:\work\TirasCloud-2\Jenkinsfile заміни broad sed newTag replacement на small script, який updates лише image entry, що matches serviceConfig[service].imageName у cluster/apps/tirascloud/<service>/overlays/dev/kustomization.yaml. Після updates запусти kubectl kustomize для кожного selected service перед commit. Тримай Jenkins updating only images[].newTag і не modify other manifest fields.
```

### P2: RocksDB runtime зараз значно кращий, але runtime image versioning досі mutable/manual

Докази:

- RDB services: `auth`, `geo`, `ip2location`, `storemod` плюс уже handled `notifyjournal`.
- Їхні Dockerfiles use `ARG ROCKSDB_RUNTIME_IMAGE=docker.io/tiras12/tirascloud-node-rocksdb:node22-rocksdb5.17` і run `scripts/ci-rocksdb-smoke.js` during build.
- `C:\work\TirasCloud-2\Jenkinsfile:252` uses mutable shared runtime tag `node22-rocksdb5.17`.
- `BUILD_RDB_RUNTIME` manually controlled.

Вплив:

- Service image build має catch native load failures, і це добре.
- Але runtime provenance важче audit, бо base runtime tag не include `rdb.node` SHA, а rebuild manually toggled.

Prompt для Codex:

```text
PLEASE MAKE ROCKSDB RUNTIME IMMUTABLE:
Онови Jenkins і docker/rocksdb-runtime так, щоб runtime image tag include Node version, RocksDB SONAME/version і rdb.node short SHA. Auto-detect changes у modules/common/rdb.node, modules/common/rdbDriver.js, modules/common/rdb.node.meta.json або docker/rocksdb-runtime/Dockerfile і require/build matching runtime image перед affected services. Тримай service image tags з app SHA і rdb SHA. Додай image inspect/report step, який shows OCI labels.
```

### P2: Local file-backed state exists без PVC decisions

Докази:

- `spamer` uses `modules/common/localRedis.js` via `senderModule.js`, initialized as `mailingList.tdb`.
- `onliner` writes/restores `online_<type>.bkp` in `modules/onliner/onlinerClass.js`.
- Ні `spamer`, ні `onliner` не мають PVC у GitOps.

Вплив:

- Pod restart може lose mailing queue або online-routing warm state.
- Це може бути acceptable in dev, але має бути explicit decision перед production/stage.

Prompt для Codex:

```text
PLEASE ASSESS LOCAL FILE STATE FOR SPAMER AND ONLINER:
Проаналізуй spamer localRedis mailingList.tdb і onliner online_*.bkp behavior. Виріши, чи ці files є cache, queue або required durable state. Якщо durable, додай PVCs і Recreate strategy у dev overlays із safe mount paths. Якщо cache-only, задокументуй data-loss behavior у runbooks і додай runtime smoke, який proving services recover acceptably після pod restart.
```

## Service-by-service review

### 1. journal

Runtime-факти:

- Entrypoint: `modules/journal/index.js`.
- TMQ alias: `journal`.
- Dependencies: TMQ, MongoDB, Redis config/secrets.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=journal`.
- `npm run test:journal` passed, але це лише static smoke.
- Dockerfile is `node:18-alpine`, non-root, no fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 67.
- Немає Kubernetes Service, що відповідає private TMQ consumer behavior.
- ConfigMap/Secrets wired for TMQ/Mongo/Redis.

Висновки:

- Прийнятно для current worker-style rollout.
- Бракує runtime TMQ/Mongo smoke, але це не blocker для першого dev rollout.

Невизначеності:

- Чи journal backlog replay or Mongo collection compatibility should be tested before prod.

### 2. firejournal

Runtime-факти:

- Entrypoint: `modules/firejournal/index.js`.
- TMQ alias: `fire-journal`.
- Dependencies: TMQ, MongoDB, Redis config/secrets.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=firejournal`.
- `npm run test:firejournal` passed, лише static.
- Dockerfile non-root і без fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 67.
- Немає Service, що доречно для TMQ consumer.

Висновки:

- Такий самий pattern як у `journal`; immediate manifest issue не знайдено.

Невизначеності:

- Runtime verification має включати safe TMQ write/read path, якщо developers підтвердять non-destructive payload.

### 3. mailer

Runtime-факти:

- Entrypoint: `modules/mailer/index.js`.
- TMQ alias: `mailer`.
- Dependencies: TMQ, MongoDB, Nodemailer sendmail transport.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=mailer`.
- `npm run test:mailer` passed, але не доводить mail delivery.
- Dockerfile явно не install/configure MTA.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 68.
- Немає Service, правильно для TMQ worker.

Висновки:

- P1: mail delivery contract is implicit through `/usr/sbin/sendmail`; fix with explicit MTA/SMTP Secret strategy.

Невизначеності:

- Чи dev should use real SMTP, a mail sink, or disabled/no-op delivery.

Prompt для Codex: див.  P1 mailer prompt above.

### 4. firmware

Runtime-факти:

- Entrypoint: `modules/firmware/index.js`.
- HTTP port: 4075.
- Routes include `/check`, `/check/ver/:ver`, `/check/:did`, `/download/firmware/:fw`.
- Dependencies: TMQ, MongoDB.
- `LINK_BASE_URL` in dev ConfigMap is `https://firmware.tirascloud.com`.

Огляд CI:

- Jenkins supports `SERVICES=firmware`.
- `npm run test:firmware` passed, лише static.
- Dockerfile exposes 4075 і не має fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 69.
- Service є ClusterIP на 4075.
- Service-specific Ingress відсутній.

Висновки:

- P1/decision: firmware download URL is external-looking, but Kubernetes exposure is internal-only. If devices/users must fetch firmware from dev cluster, add HTTP Ingress and align `LINK_BASE_URL` with that hostname.

Невизначеності:

- Чи `firmware.tirascloud.com` points to this dev cluster, another environment, or should remain external during dev.

### 5. ip2location

Runtime-факти:

- Entrypoint: `modules/ip2location/index.js`.
- TMQ consumer.
- RocksDB path: `modules/ip2location/storage.js` uses `ip2location/ipStorage`.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=ip2location`.
- `npm run test:ip2location` passed.
- RDB contract runs, коли цей service selected.
- Dockerfile uses RocksDB runtime і runs `ci-rocksdb-smoke.js` during image build.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 66.
- PVC exists: `ip2location-rocksdb`, mounted to `/app/modules/ip2location/ipStorage`.
- Recreate strategy patched у dev overlay.
- Немає Service, правильно для TMQ worker.

Висновки:

- Добрий current RDB pattern.
- Залишкове improvement: immutable RocksDB runtime tagging and post-build image metadata reporting.

Невизначеності:

- Чи IP database import should be part of CI, an init job, or an operator action.

### 6. geo

Runtime-факти:

- Entrypoint: `modules/geo/index.js`.
- Uses `ipcProd` and optional `ipcDev` from `ipcChannel`.
- RocksDB path: `modules/geo/storage.js` uses `geo/gsmStorage`.
- Dependencies: TMQ, MongoDB, optional secondary dev TMQ/Mongo.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=geo`.
- `npm run test:geo` passed.
- Dockerfile uses RocksDB runtime і runs native smoke.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 67.
- PVC exists: `geo-rocksdb`, mounted to `/app/modules/geo/gsmStorage`.
- Recreate strategy patched.
- Dev ConfigMap leaves `GEO_DEV_TMQ_HOST` empty; secondary env secrets exist as placeholders.

Висновки:

- Добрий RDB/PVC baseline.
- The dual-environment dev behavior remains a real product decision, not just CI/CD.

Невизначеності:

- Чи geo should connect to two TMQ/Mongo environments in the dev cluster.

### 7. storemod

Runtime-факти:

- Entrypoint: `modules/storemod/index.js`.
- RocksDB path: `modules/storemod/storage.js` uses `storemod/modulesStorage`.
- Dependencies: TMQ, MongoDB, RocksDB.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=storemod`.
- `npm run test:storemod` passed.
- Dockerfile uses RocksDB runtime and native smoke.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 67.
- PVC exists: `storemod-rocksdb`, mounted to `/app/modules/storemod/modulesStorage`.
- Recreate strategy patched.
- Немає Service, правильно для private worker.

Висновки:

- Добрий current RDB pattern.
- Add runtime TMQ smoke only after a safe non-destructive payload is confirmed.

Невизначеності:

- Storage schema migration/compatibility для existing `modulesStorage` data.

### 8. auth

Runtime-факти:

- Entrypoint: `modules/auth/index.js`.
- HTTP port: 4081.
- Health endpoint exists: `modules/auth/httpRoutes.js` has `/health`.
- TMQ alias: `auth`.
- RocksDB path: `modules/auth/services/rocksdbStorageService.js` uses `auth/rdbStorage`.
- Dependencies: TMQ, MongoDB, Redis, Firebase secret, JWT secret, RocksDB.

Огляд CI:

- Jenkins supports `SERVICES=auth`.
- `npm run test:auth` passed.
- Dockerfile uses RocksDB runtime, native smoke, exposes 4081, і має real Docker healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 71.
- Service є ClusterIP на 4081.
- PVC exists: `auth-rocksdb`, mounted to `/app/modules/auth/rdbStorage`.
- Recreate strategy patched.

Висновки:

- RDB/PVC/health baseline solid.
- Public/private exposure unresolved: auth is an HTTP API but no Ingress exists.

Невизначеності:

- Який hostname/path should expose auth, and whether it is public, private, or only internal for dev.

### 9. spamer

Runtime-факти:

- Entrypoint: `modules/spamer/index.js`.
- TMQ alias: `spamer`.
- Dependencies: TMQ, MongoDB, Redis, `mailer` service.
- Local file-backed queue/cache: `senderModule.js` initializes `mailingList.tdb` via `modules/common/localRedis.js`.
- Inbound ports: none.

Огляд CI:

- Jenkins supports `SERVICES=spamer`.
- `npm run test:spamer` passed, лише static.
- Dockerfile non-root і без fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 69.
- Немає Service, правильно для TMQ worker.
- Немає PVC.

Висновки:

- P2: decide whether `mailingList.tdb` must survive pod restart.
- Mailer dependency issue affects spamer end-to-end behavior.

Невизначеності:

- Чи mailing queue loss is acceptable in dev/stage/prod.

Prompt для Codex: див.  P2 local file state prompt above.

### 10. tgsupportbot

Runtime-факти:

- Entrypoint: `modules/tgsupportbot/index.js`.
- HTTP file proxy port: 4044.
- WS port: 4047.
- Dependencies: TMQ, MongoDB, JWT secret, Telegram API token, TLS files.
- Code uses `TGBOT_TG_TOKEN` env fallback before config token.

Огляд CI:

- Jenkins supports `SERVICES=tgsupportbot`.
- `npm run test:tgsupportbot` passed, лише static.
- Dockerfile exposes 4044/4047 і runs non-root.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 79.
- Service exposes ClusterIP ports 4044 і 4047.
- Deployment references `tgsupportbot-secret` key `TGBOT_TG_TOKEN`.
- Runtime secret placeholder існує і не містить real token.

Висновки:

- Secret handling structurally correct.
- Health endpoint не confirmed; no probes added, which is appropriate.
- External/private exposure decision досі відкрите.

Невизначеності:

- Чи Telegram webhook/file proxy/WS must be public, private, or only reachable from support UI.
- Чи dev tests should hit Telegram at all; поточна recommendation: no real outbound side effects in CI.

Нотатка operator:

```bash
kubectl -n tirascloud-dev create secret generic tgsupportbot-secret --from-literal=TGBOT_TG_TOKEN='<token-from-vault-or-jenkins-credential>' --dry-run=client -o yaml | kubectl apply -f -
```

### 11. onliner

Runtime-факти:

- Entrypoint: `modules/onliner/index.js` and `onlinerModule.js`.
- TMQ alias: `onliner`.
- Health HTTP port: 7001 with `/health`.
- Dependencies: TMQ, MongoDB.
- Writes/restores `online_<type>.bkp` files.

Огляд CI:

- Jenkins supports `SERVICES=onliner`.
- `npm run test:onliner` passed.
- Dockerfile exposes 7001 і має real Docker healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 70.
- Service є ClusterIP на 7001.
- Немає PVC.

Висновки:

- Health endpoint і ClusterIP health Service valid.
- P2: local backup files need an explicit persistence decision.

Невизначеності:

- Чи online routing state must survive pod restart or can rebuild from device traffic.

Prompt для Codex: див.  P2 local file state prompt above.

### 12. debugger

Runtime-факти:

- Entrypoint: `modules/debugger/index.js`.
- WSS port: 4021.
- Dependencies: TMQ, JWT secret, TLS files.

Огляд CI:

- Jenkins supports `SERVICES=debugger`.
- `npm run test:debugger` passed, лише static.
- Dockerfile exposes 4021 і runs non-root.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 80.
- Service є ClusterIP на 4021.
- TLS secret mounted і env paths supplied.

Висновки:

- Internal WSS Service coherent.
- Health endpoint не confirmed, so absence of probes is acceptable.

Невизначеності:

- Чи debugger should remain private/VPN-only or get an internal Ingress hostname.

### 13. gateway

Runtime-факти:

- Entrypoint: `modules/gateway/index.js`.
- TMQ alias from settings: `gw`.
- UDP bind: 4005.
- Health HTTP port: 7005 with `/health`.
- Dependencies: TMQ, MongoDB, Redis.
- Advertises worker server IP/port from `settings.json`.

Огляд CI:

- Jenkins supports `SERVICES=gateway`.
- `npm run test:gateway` passed, лише static.
- Dockerfile exposes 4005/UDP and 7005/TCP; Docker healthcheck checks 7005.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 73.
- Service є ClusterIP з TCP 7005 і UDP 4005.
- No L4 external exposure.

Висновки:

- P1: device-facing UDP не exposed externally.
- P1: worker handoff settings are baked with `127.0.0.1`, which is not valid for real external devices.
- Health endpoint valid для process readiness, але не доводить UDP reachability.

Невизначеності:

- Dev external IP/port strategy для Guard devices.
- Чи NodePort or MetalLB LoadBalancer is the intended next step.

Prompt для Codex: див.  UDP routing/config prompt above.

### 14. device

Runtime-факти:

- Entrypoint: `modules/device/index.js`.
- TMQ alias: `devstorage`.
- Health HTTP port: 7010 with `/health`.
- Dependencies: TMQ, MongoDB, Redis.
- Uses firmware link base URL via env/config.

Огляд CI:

- Jenkins supports `SERVICES=device`.
- `npm run test:device` passed, лише static.
- Dockerfile exposes 7010 і має real Docker healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 72.
- Service є ClusterIP на 7010.

Висновки:

- Health Service coherent.
- Public exposure не required from current code view.

Невизначеності:

- Чи devstorage data paths need migration tests with existing Mongo data.

### 15. firegw

Runtime-факти:

- Entrypoint: `modules/firegw/index.js`.
- TMQ alias: `fire-gw`.
- UDP bind: 4030.
- Dependencies: TMQ, MongoDB, Redis/Grafana logging config.
- Server assignment comes from `serverList.json` and is encoded into fire device ACKs.

Огляд CI:

- Jenkins supports `SERVICES=firegw`.
- `npm run test:firegw` passed, лише static.
- Dockerfile exposes 4030/UDP і не має fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 74.
- Service є ClusterIP UDP 4030.
- Grafana config defaults to `grafana.example.invalid` and mounts placeholder CA secret.

Висновки:

- P1: device-facing UDP не exposed externally.
- P1: server list is baked and contains hard-coded external IP values.
- No HTTP health endpoint exists; no K8s probes are added, which is appropriate.

Невизначеності:

- External endpoint strategy для fire devices.
- Чи Grafana logging should be enabled in dev or disabled until real endpoint/CA are provided.

Prompt для Codex: див.  UDP routing/config prompt above.

### 16. udpnew

Runtime-факти:

- Entrypoint: `modules/udpnew/index.js`.
- Spawns worker processes from `settings.json`.
- UDP ports: 4015/4016/4017.
- Per-worker health ports: 7015/7016/7017.
- TMQ aliases: `udpnew1_kx`, `udpnew2_kx`, `udpnew3_kx`.
- Dependencies: TMQ, MongoDB.

Огляд CI:

- Jenkins supports `SERVICES=udpnew`.
- `npm run test:udpnew` passed, лише static.
- Dockerfile exposes UDP and health ports, but Docker healthcheck checks only 7016.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 75.
- Service є ClusterIP з UDP 4015/4016/4017 і TCP health 7015/7016/7017.
- Немає external L4 exposure.

Висновки:

- P1: device-facing UDP не exposed externally.
- P2: healthcheck on only one worker can miss failure of ports 4015/7015 or 4017/7017.
- Settings are baked and use `127.0.0.1` because all workers live in one pod; this is okay internally, but external gateway handoff must advertise reachable external IPs.

Невизначеності:

- Чи dev should expose all three UDP ports externally.
- Чи worker health should be combined into one readiness endpoint or checked port-by-port.

Prompt для Codex:

```text
PLEASE HARDEN UDPNEW HEALTH WITHOUT CHANGING UDP PROTOCOL:
Проаналізуй modules/udpnew/index.js і udpWorker.js. Додай safe aggregate health check або CI/runtime smoke, який verifies, що всі configured workers started і всі health ports 7015/7016/7017 respond. Не змінюй UDP protocol. Не додавай Kubernetes probes, доки aggregate endpoint не стане real and reliable.
```

### 17. fireudp

Runtime-факти:

- Entrypoint: `modules/fireudp/index.js`.
- Spawns worker processes from `settings.json`.
- UDP ports: 4033/4035/4037/4039/4041.
- TMQ aliases: `fireudp1_dev` ... `fireudp5_dev`.
- Dependencies: TMQ, MongoDB, Grafana logging config.

Огляд CI:

- Jenkins supports `SERVICES=fireudp`.
- `npm run test:fireudp` passed, лише static.
- Dockerfile exposes UDP ports і не має fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 76.
- Service є ClusterIP для всіх пʼяти UDP ports.
- Немає external L4 exposure.

Висновки:

- P1: device-facing UDP не exposed externally.
- P1: settings містять hard-coded external IP values.
- Відсутність HTTP/K8s probes acceptable, доки real endpoint exists.

Невизначеності:

- Fire UDP external IP/port mapping for dev.
- Чи to introduce worker-level health endpoints like `udpnew` or keep runtime log-based checks.

Prompt для Codex: див.  UDP routing/config prompt above.

### 18. adddev

Runtime-факти:

- Entrypoint: `modules/adddev/index.js`.
- HTTP port: 4085.
- TMQ alias: `adddev`.
- Dependencies: TMQ.

Огляд CI:

- Jenkins supports `SERVICES=adddev`.
- `npm run test:adddev` passed, лише static.
- Dockerfile exposes 4085 and has no healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 77.
- Service є ClusterIP на 4085.

Висновки:

- Internal HTTP Service coherent.
- Немає confirmed health endpoint; probes не додані, це appropriate.

Невизначеності:

- Чи `adddev` is a public API, private admin API, or internal-only service. Exposure не треба додавати без цього decision.

### 19. v2web

Runtime-факти:

- Entrypoint: `modules/v2web/index.js`.
- HTTP port: 4090.
- TMQ alias: `v2`.
- Dependencies: TMQ and downstream `devstorage` messages.

Огляд CI:

- Jenkins supports `SERVICES=v2web`.
- `npm run test:v2web` passed, лише static.
- Dockerfile exposes 4090 і не має fake healthcheck.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 78.
- Service є ClusterIP на 4090.
- Немає Ingress.

Висновки:

- Pod/service deployment coherent.
- Якщо це user-facing web/API, an Ingress decision is still missing.

Невизначеності:

- Hostname/path/TLS exposure для v2 web API.

### 20. app_modded

Runtime-факти:

- Entrypoint: `modules/app_modded/index.js`.
- Socket.IO v2 port: 5020.
- Socket.IO v4 / health port: 5022.
- Additional log Socket.IO server: 5102.
- Dependencies: TMQ, MongoDB, Redis, Firebase secrets, JWT secret, TLS files.

Огляд CI:

- Jenkins supports `SERVICES=app_modded`.
- `npm run test:app_modded` passed, лише static.
- Dockerfile exposes 5020/5022 and healthchecks 5022.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 81.
- Service є ClusterIP на 5020/5022.
- Firebase/TLS secrets mounted.
- Service port для 5102 відсутній.
- Немає Ingress.

Висновки:

- P1: active 5102 log server не exposed.
- P1/decision: app-facing WebSocket exposure is not yet modeled through Ingress.

Невизначеності:

- Чи 5102 is required by support/admin UI.
- Public hostnames і WebSocket ingress annotations/timeouts.

Prompt для Codex: див.  app_modded 5102 prompt above.

### 21. support

Runtime-факти:

- Entrypoint: `modules/support/index.js`.
- HTTP port: 4070.
- Active WS/WSS ports from `ologService`: 4071 and 4072.
- TMQ alias: `support-react`.
- Dependencies: TMQ, MongoDB, Redis, JWT secret, TLS files.

Огляд CI:

- Jenkins supports `SERVICES=support`.
- `npm run test:support` passed, лише static.
- Dockerfile exposes only 4070.

Огляд CD:

- ArgoCD app exists on `main`, sync wave 82.
- Service є ClusterIP лише на 4070.
- TLS secret mounted і env paths supplied.
- Немає Ingress.

Висновки:

- P1: active WS/WSS listeners 4071/4072 не exposed by Deployment/Service.
- P1/decision: support UI/API exposure model is not defined.

Невизначеності:

- Чи support should be private/VPN-only.
- Чи 4071/4072 should be exposed, disabled, or routed through the same HTTP service.

Prompt для Codex: див.  support port contract prompt above.

## Прогалини cross-service delivery runbook

Поточний pipeline може build і push images, потім update GitOps image tags. Перед тим як довіряти service як migrated, додати або запускати такі checks для кожного service:

1. Jenkins build:
   - `SERVICES=<service>`
   - `GITOPS_BRANCH=main`
   - `BUILD_RDB_RUNTIME=false` unless `rdb.node`, `rdbDriver.js`, RDB metadata, or runtime Dockerfile changed.
2. GitOps render:
   - `kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\<service>\overlays\dev`
3. ArgoCD:
   - `argocd app sync tirascloud-<service>-dev`
   - `argocd app wait tirascloud-<service>-dev --sync --health --timeout 300`
4. Kubernetes:
   - `kubectl -n tirascloud-dev rollout status deploy/<deployment-name>`
   - `kubectl -n tirascloud-dev logs deploy/<deployment-name> --tail=200`
5. Runtime smoke:
   - TMQ workers: connect to `tirasmq` and send only a confirmed non-destructive action.
   - HTTP services: curl real endpoint only if code confirms it exists.
   - UDP services: verify L4 exposure and actual UDP receive path from outside the cluster, preserving source IP.
   - RocksDB services: run basic CRUD on a safe test path/PVC; do not use TTL cleanup as a gating test until developers confirm TTL semantics.

## Фінальна рекомендація

Manifests syntactically healthy, і Jenkins знає всі requested services. Поточний CI/CD достатній для internal pod rollout experiments, але ще недостатній, щоб назвати full migration complete для externally reachable workloads.

Рекомендований implementation order після цього review:

1. Harden Jenkins GitOps update and render gate.
2. Fix `mailer` delivery contract.
3. Fix `support` 4071/4072 and `app_modded` 5102 port contracts.
4. Decide HTTP/WS exposure hostnames and privacy model.
5. Decide UDP L4 strategy and move UDP routing config into GitOps ConfigMaps.
6. Make RocksDB runtime tag immutable and auto-detected.
7. Decide PVC/state policy for `spamer` and `onliner`.

