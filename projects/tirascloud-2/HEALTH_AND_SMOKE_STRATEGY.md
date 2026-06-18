# Health і smoke strategy для TirasCloud-2 Dev

Статус: draft для узгодження з розробниками  
Дата: 2026-05-13  
Scope: активні Dev Applications із `C:\work\ideal-octo-giggle\cluster\clusters\dev\apps\kustomization.yaml`

## Навіщо

Цей документ фіксує, де для TirasCloud-2 Dev можна ставити Kubernetes `readinessProbe` і `livenessProbe`, а де потрібна smoke alternative, бо сервіс не має inbound порту або не має чесного health endpoint.

Ключове правило: не додавати probe, який виглядає як health check, але фактично перевіряє тільки mock route або випадковий відкритий порт.

## Терміни

`livenessProbe` відповідає на питання: процес живий і Kubernetes має залишити container running. Liveness зазвичай не має падати через тимчасову недоступність MongoDB, Redis, TMQ або зовнішнього API, бо restart pod не лікує зовнішню залежність.

`readinessProbe` відповідає на питання: pod можна використовувати для трафіку або як backend для інших сервісів. Readiness має перевіряти service-specific ready state: наприклад завантажені ключі, відновлений runtime state, підняті worker-и, готовність приймати запити.

`startupProbe` дає сервісу час стартувати до того, як Kubernetes почне застосовувати liveness/readiness. Вона корисна для сервісів, які на старті вантажать дані з MongoDB, файлів або внутрішнього state.

`smoke alternative` або `smoke docs` - це documented operator check, який виконується після Jenkins delivery і Argo CD sync, коли Kubernetes probe не може чесно підтвердити стан сервісу. Smoke check має бути конкретною командою або сценарієм: `kubectl wait`, `kubectl logs`, `port-forward + HTTP request`, TMQ/UDP/device сценарій, або Jenkins smoke stage.

`надійний health signal` - це сигнал, який напряму реалізований кодом сервісу або контрольованою командою всередині container і перевіряє саме той стан, який ми документуємо. `GET /health`, який завжди повертає `200` без перевірки залежностей, може бути liveness signal, але не є dependency readiness.

## Чому частина сервісів без inbound порту

Kubernetes `Service` потрібен тоді, коли інші workloads або зовнішній трафік мають зайти в pod по мережі.

Багато TirasCloud модулів є private TMQ consumers: вони самі відкривають outbound TCP connection до `tirasmq`, реєструють TMQ client/channel і обробляють повідомлення. Для такого workload немає inbound HTTP/TCP listener, до якого Kubernetes `Service` міг би маршрутизувати трафік.

Для private TMQ consumers коректна базова перевірка зараз така:

```powershell
kubectl -n tirascloud-dev wait --for=condition=Available deploy/<service> --timeout=180s
kubectl -n tirascloud-dev logs deploy/<service> --tail=100
kubectl -n tirascloud-dev logs deploy/<service> --tail=200 | Select-String "Connected to server successfully|TCP error|Connection of .* closed|Error"
```

Це не замінює повноцінний readiness endpoint. Це smoke alternative до моменту, коли команда додасть service-owned health contract.

## Поточні GitOps рішення

Ці probes додані або вже існували в GitOps manifests.

| Service | Kubernetes probe | Сигнал | Рішення |
| --- | --- | --- | --- |
| `tirasmq` | `readinessProbe` + `livenessProbe` | TCP socket `tmq:4050` | Залишити. Це root TCP service для TMQ. |
| `gateway` | `startupProbe` + `readinessProbe` на `GET /health`, `livenessProbe` як TCP socket | `gateway/index.js` повертає `200` тільки коли `ready=true`; `ready` виставляється після load device keys у `deviceManager.js` | Використовувати як readiness для стартового стану. |
| `onliner` | `startupProbe` + `readinessProbe` на `GET /health`, `livenessProbe` як TCP socket | `onlinerModule.js` повертає `200` тільки коли `ready=true`; `ready` виставляється після restore state у `onlinerClass.js` | Використовувати як readiness для стартового стану. |
| `udpnew` | `startupProbe` + `livenessProbe` через `node -e` exec | Перевіряє `GET /health` на worker ports `7015`, `7016`, `7017` | Використовувати як worker-level liveness/startup signal. Kubernetes readiness не додавати, бо source endpoint не доводить TMQ/device-key readiness. |
| `device` | `livenessProbe` на `GET /health` | Endpoint існує, але завжди повертає `200` для `/health` | Liveness only. Readiness не додавати без dependency-aware ready state. |
| `auth` | `livenessProbe` на `GET /health` | Endpoint існує, але повертає static `{status:"ok"}` | Liveness only. Readiness не додавати без Mongo/Redis/Firebase/TMQ-aware ready state. |
| `app-modded` | `livenessProbe` на `GET /health` порту `socketio-v4:5022` | Endpoint існує на `5020` і `5022`, повертає `OK` | Liveness only. Readiness не додавати без upstream/dependency-aware ready state. |

Local validation:

```powershell
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\gateway\overlays\dev
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\onliner\overlays\dev
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\udpnew\overlays\dev
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\device\overlays\dev
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\auth\overlays\dev
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\app_modded\overlays\dev
kubectl kustomize C:\work\ideal-octo-giggle\cluster\clusters\dev\apps
```

Probe visibility after Argo CD sync:

```powershell
kubectl -n tirascloud-dev get deploy gateway onliner udpnew device auth app-modded -o yaml | Select-String "startupProbe|readinessProbe|livenessProbe|/health|7015|7016|7017"
kubectl -n tirascloud-dev describe pod -l app.kubernetes.io/name=gateway
kubectl -n tirascloud-dev describe pod -l app.kubernetes.io/name=udpnew
```

## Code vs Dockerfile vs GitOps

Dockerfile не є primary source для Kubernetes probes. Він корисний як packaging cross-check: `EXPOSE` показує очікувані порти image, а `HEALTHCHECK` показує local-container intent. Kubernetes не виконує Dockerfile `HEALTHCHECK`; потрібен explicit probe у GitOps manifest.

| Service | Source code signal | Dockerfile signal | GitOps probe decision |
| --- | --- | --- | --- |
| `tirasmq` | TCP server `4050`; окремого HTTP health немає. | `EXPOSE 4050`; `HEALTHCHECK` робить TCP connect на `127.0.0.1:4050`. | TCP readiness/liveness на `tmq`. |
| `gateway` | `GET /health` на `7005`; `200` тільки коли `ready=true` після `SM.load()` і `DM.load()`. UDP `4005`. | `EXPOSE 7005 4005/udp`; `HEALTHCHECK` на `/health`. | `startupProbe` + `readinessProbe` на `/health`; liveness як TCP socket. |
| `onliner` | `GET /health` на `7001`; `200` тільки коли `ready=true` після restore state. | `EXPOSE 7001`; `HEALTHCHECK` на `/health`. | `startupProbe` + `readinessProbe` на `/health`; liveness як TCP socket. |
| `udpnew` | Master запускає 3 workers. Кожен worker має `GET /health` на `7015`, `7016`, `7017`, але endpoint не перевіряє TMQ auth/device keys. UDP `4015`-`4017`. | `EXPOSE 7015 7016 7017 4015/udp 4016/udp 4017/udp`; `HEALTHCHECK` перевіряє тільки `7016`. | `startupProbe` + `livenessProbe` перевіряють всі 3 worker health endpoints. Readiness не додавати до появи source ready contract. |
| `device` | `GET /health` на `7010` завжди `200` для route; не перевіряє MongoDB/Redis/TMQ. | `EXPOSE 7010`; `HEALTHCHECK` на `/health`. | Liveness only на `/health`. Readiness не додавати. |
| `auth` | `GET /health` на `4081` повертає static `{status:"ok"}`; не перевіряє MongoDB/Redis/Firebase/TMQ. | `EXPOSE 4081`; `HEALTHCHECK` на `/health`. | Liveness only на `/health`. Readiness не додавати. |
| `app-modded` | `GET /health` повертає `OK` на `5020` і `5022`; не перевіряє upstream dependencies. | `EXPOSE 5022 5020`; `HEALTHCHECK` на `5022/health`. | Liveness only на `socketio-v4:5022`. Readiness не додавати. |
| `firmware` | HTTP routes на `4075`, але `/health` немає. | `EXPOSE 4075`; `HEALTHCHECK` немає. | Probe не додавати; потрібен smoke fixture або source health endpoint. |
| `adddev` | HTTP `4085`, `/health` немає. | `EXPOSE 4085`; `HEALTHCHECK` немає. | Probe не додавати; потрібен source health endpoint або agreed smoke route. |
| `v2web` | HTTP `4090`, SPA/static fallback, `/health` немає. | `EXPOSE 4090`; `HEALTHCHECK` немає. | Probe не додавати; smoke через `port-forward` і UI/static request. |
| `support` | HTTP `4070`, UI/static і authenticated API, `/health` немає. | `EXPOSE 4070`; `HEALTHCHECK` немає. | Probe не додавати; потрібен source health endpoint або authenticated smoke. |
| `tgsupportbot` | HTTPS file proxy `4044`, WSS `4047`, `/health` немає. | `EXPOSE 4047 4044`; `HEALTHCHECK` немає. | Probe не додавати; потрібен Telegram-safe smoke або source health endpoint. |
| `debugger` | WSS `4021`, `/health` немає. | `EXPOSE 4021`; `HEALTHCHECK` немає. | Probe не додавати; потрібен WSS/auth smoke або source health endpoint. |
| `firegw` | UDP `4030`, health endpoint немає. | `EXPOSE 4030/udp`; `HEALTHCHECK` немає. | Probe не додавати; UDP/device smoke. |
| `fireudp` | UDP `4033`, `4035`, `4037`, `4039`, `4041`, health endpoint немає. | `EXPOSE` для UDP ports; `HEALTHCHECK` немає. | Probe не додавати; UDP/device smoke. |
| `logger` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`; CI smoke забороняє fake `/health`. | Probe не додавати; logs/Filebeat/Kibana smoke. |
| `journal` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; logs і service-specific smoke. |
| `firejournal` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; logs і service-specific smoke. |
| `firestates` | Private TMQ consumer; inbound listener немає; RocksDB/runtime state важливий. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; RocksDB/state-event smoke. |
| `notifyjournal` | Private TMQ consumer; inbound listener немає; RocksDB/runtime state важливий. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; RocksDB/notification smoke. |
| `geo` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; geolocation smoke fixture потрібен. |
| `ip2location` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; IP lookup smoke fixture потрібен. |
| `storemod` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; store operation smoke fixture потрібен. |
| `mailer` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; dry-run/test-recipient smoke потрібен. |
| `spamer` | Private TMQ consumer; inbound listener немає. | Немає `EXPOSE`/`HEALTHCHECK`. | Probe не додавати; dry-run/test-campaign smoke потрібен. |

## Services без Kubernetes readiness на цей момент

| Service | Чому немає readinessProbe | Поточна smoke alternative |
| --- | --- | --- |
| `firmware` | HTTP service має real routes `/check`, `/check/ver/:ver`, `/check/:did`, `/download/firmware/:fw`, але немає `/health` або cheap dependency-neutral ready route. | `kubectl wait`, logs, і test request з known safe firmware/version data після узгодження з dev team. |
| `adddev` | HTTP service на `4085`, але немає `/health`; маршрутна логіка доменна і потребує payload/context. | `kubectl wait`, logs, optional service curl на agreed safe route після узгодження. |
| `v2web` | HTTP service віддає SPA/static і fallback, але немає health endpoint. | `kubectl wait`, logs, `port-forward svc/v2web 4090:4090`, потім `Invoke-WebRequest http://127.0.0.1:4090/`. |
| `support` | HTTP service має UI/static і authenticated API, але немає `/health`; API smoke потребує valid JWT/user context. | `kubectl wait`, logs, `port-forward svc/support 4070:4070`, UI smoke або authenticated API smoke з тестовим обліковим записом. |
| `tgsupportbot` | HTTPS file proxy і WSS server є, але health endpoint відсутній; частина readiness залежить від Telegram, MongoDB, TLS secret і TMQ. | Logs: Mongo connect, file proxy start, WS start, Telegram polling errors. Потрібен погоджений Telegram-safe smoke. |
| `debugger` | WSS service на `4021`, health endpoint відсутній; tcp socket не доводить auth/stream functionality. | `kubectl wait`, logs, WSS handshake smoke після узгодження token/auth flow. |
| `udpnew` | Worker `/health` endpoints підтверджують liveness/startup усіх worker процесів, але не підтверджують TMQ auth, отримання device keys або device-level readiness. | `kubectl wait`, worker health checks, logs, і UDP/device smoke через selected NodePort route. |
| `firegw` | UDP service без TCP/HTTP health endpoint. | Logs + UDP/device smoke через selected NodePort route. |
| `fireudp` | UDP worker service без TCP/HTTP health endpoint. | Logs + UDP/device smoke через selected NodePort route. |
| `logger` | Private TMQ consumer; немає inbound listener. | `kubectl wait`, logs container `logger`, logs container `filebeat`, перевірка Kibana data stream. |
| `journal` | Private TMQ consumer; немає inbound listener. | `kubectl wait`, logs, TMQ connection log, Mongo/Redis error scan. |
| `firejournal` | Private TMQ consumer; немає inbound listener. | `kubectl wait`, logs, TMQ connection log, Mongo/Redis error scan. |
| `firestates` | Private TMQ consumer; немає inbound listener; RocksDB/runtime state важливий. | `kubectl wait`, logs, RocksDB path checks, service-specific state event smoke після узгодження. |
| `notifyjournal` | Private TMQ consumer; немає inbound listener; RocksDB/runtime state важливий. | `kubectl wait`, logs, RocksDB path checks, notification event smoke після узгодження. |
| `geo` | Private TMQ consumer; немає inbound listener; має Mongo/dev TMQ/GSM DB залежності. | `kubectl wait`, logs, agreed geolocation lookup smoke. |
| `ip2location` | Private TMQ consumer; немає inbound listener; lookup needs known IP fixture. | `kubectl wait`, logs, agreed IP lookup smoke. |
| `storemod` | Private TMQ consumer; немає inbound listener; store operation needs payload fixture. | `kubectl wait`, logs, agreed store operation smoke. |
| `mailer` | Private TMQ consumer; немає inbound listener; real send smoke може зачепити зовнішній provider/user. | `kubectl wait`, logs, dry-run/test recipient decision needed. |
| `spamer` | Private TMQ consumer; немає inbound listener; real smoke може створити небажані outbound messages. | `kubectl wait`, logs, dry-run/test campaign decision needed. |

## Platform і non-workload active apps

Ці Applications активні в `cluster/clusters/dev/apps`, але не є TirasCloud service containers з власними app probes.

| Application | Перевірка |
| --- | --- |
| `minio-tenant` | `argocd app get minio-tenant`; `kubectl -n minio-tenant get pods,svc,pvc`; MinIO console/API smoke за platform runbook. |
| `mongodb` | `argocd app get mongodb`; `kubectl -n mongodb get pods,svc`; operator/replica status за MongoDB runbook. |
| `redis` | `argocd app get redis`; `kubectl -n redis get pods,svc`; Redis ping через approved admin path. |
| `tirascloud-namespace` | `argocd app get tirascloud-namespace-dev`; `kubectl get ns tirascloud-dev`. |
| `tirascloud-runtime-secrets` | `argocd app get tirascloud-runtime-secrets-dev`; `kubectl -n tirascloud-dev get secret`; не друкувати secret values. |
| `tirascloud-udp-nodeport` | `argocd app get tirascloud-udp-nodeport-dev`; `kubectl -n tirascloud-dev get svc gateway-device-nodeport udpnew-device-nodeport firegw-device-nodeport fireudp-device-nodeport`. |

## Jenkins delivery checks

Після Jenkins build/push для конкретного сервісу:

```powershell
kubectl -n jenkins get pods,svc
kubectl -n jenkins logs deploy/jenkins -c jenkins --tail=200
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\<service>\overlays\dev | Select-String "image:"
```

Перевірити, що Jenkins змінив тільки `images[].newTag` у відповідному dev overlay:

```powershell
git -C C:\work\ideal-octo-giggle -c safe.directory=C:/work/ideal-octo-giggle diff -- cluster/apps/tirascloud/<service>/overlays/dev/kustomization.yaml
```

## Argo CD sync checks

```powershell
argocd app get tirascloud-<service>-dev
argocd app wait tirascloud-<service>-dev --sync --health --timeout 300
argocd app list | Select-String "tirascloud"
```

Якщо Argo CD health не `Healthy`, не закривати migration step. Перейти до `kubectl describe`, pod events і logs.

## Runtime workload checks

Базові checks для кожного app workload:

```powershell
kubectl -n tirascloud-dev get deploy,pod,svc,endpoints
kubectl -n tirascloud-dev wait --for=condition=Available deploy/<service> --timeout=180s
kubectl -n tirascloud-dev describe deploy/<service>
kubectl -n tirascloud-dev describe pod -l app.kubernetes.io/name=<service>
kubectl -n tirascloud-dev logs deploy/<service> --tail=100
```

Для services з HTTP health:

```powershell
kubectl -n tirascloud-dev port-forward svc/gateway 7005:7005
Invoke-WebRequest http://127.0.0.1:7005/health
```

Для `udpnew` worker health:

```powershell
kubectl -n tirascloud-dev port-forward svc/udpnew 7015:7015 7016:7016 7017:7017
Invoke-WebRequest http://127.0.0.1:7015/health
Invoke-WebRequest http://127.0.0.1:7016/health
Invoke-WebRequest http://127.0.0.1:7017/health
```

Для private TMQ consumers:

```powershell
kubectl -n tirascloud-dev logs deploy/<service> --tail=200 | Select-String "Connected to server successfully|TCP error|Connection of .* closed|Error"
```

Цей log scan показує корисні symptoms, але не є повноцінним readiness contract. Для promotion потрібен service-specific smoke.

## Питання до розробників / техліда

1. Для кожного HTTP/WSS сервісу потрібен стандартний endpoint pair: `GET /livez` і `GET /readyz`? Якщо так, які mandatory dependencies має перевіряти `readyz` для `firmware`, `adddev`, `v2web`, `support`, `tgsupportbot`, `debugger`, `auth`, `app-modded`?
2. Чи погоджуємо правило: liveness не перевіряє MongoDB/Redis/TMQ/Telegram/Firebase, а readiness перевіряє тільки ті залежності, без яких сервіс не може виконувати свою основну функцію?
3. Для TMQ consumers який health contract правильний: internal HTTP listener, CLI command всередині container, TMQ admin/status request, або Jenkins/PostSync smoke job?
4. Поточний TMQ client log `Connected to server successfully` означає тільки TCP connect чи вже auth + channel registration? Якщо тільки TCP, який log/event вважати canonical ready?
5. Для `udpnew` чи має worker `/health` повертати `200` тільки після `udp.server.bind`, TMQ auth і отримання device keys від `gateway`?
6. Для `gateway` чи достатньо `ready=true` після `SM.load()` і `DM.load()`, чи readiness також має перевіряти TMQ auth/channel, UDP bind і Redis/Mongo runtime availability?
7. Для `device` current `/health` завжди `200`. Які checks треба додати для `readyz`: MongoDB, Redis, TMQ, server list, firmware link base, інше?
8. Для `auth` current `/health` static. Чи треба `readyz` перевіряти Firebase key load, MongoDB, Redis, TMQ і `mailer` dependency?
9. Для `app-modded` current `/health` static на `5020` і `5022`. Чи треба readiness окремо для legacy Socket.IO і v4 Socket.IO, і які upstream dependencies blocking?
10. Для `firmware` який safe read-only smoke fixture можна використовувати: known firmware version, known DID, або synthetic test record?
11. Для `support` і `tgsupportbot` який безпечний smoke сценарій не створює реальних повідомлень користувачам і не потребує production-like credentials?
12. Для `mailer` і `spamer` чи є dry-run/test recipient mode, щоб smoke не відправляв реальні повідомлення?
13. Для UDP services (`gateway`, `udpnew`, `firegw`, `fireudp`) який team-approved device simulator або fixture payload можна використовувати після Argo CD sync?

## Done criteria

Migration step для service лишається open, доки operator не підтвердить:

- Jenkins build/test/push succeeded;
- Jenkins змінив тільки expected GitOps image tag;
- Argo CD Application `Synced`;
- Argo CD Application `Healthy`;
- Kubernetes rollout/available check passed;
- probes або documented smoke alternative passed;
- logs не містять repeated `TCP error`, reconnect loop, missing secret/config, Mongo/Redis auth errors або unhandled exceptions;
- unresolved questions для service зафіксовані як follow-up tasks.
