# Runbook GitOps migration TirasCloud-2

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/Runbook міграції TirasCloud (Dev).md`, `archive/2026-05-11/Перенесення кластера Tiras Dev в GitOps.md`, `archive/2026-05-11/Workflow побудови IaC-інфраструктури.md`, `archive/2026-05-11/InfraCluster Review.md`, `archive/2026-05-11/InfraFoundation Review.md`, `C:\work\ideal-octo-giggle`, `C:\work\TirasCloud-2`

## Призначення

Цей документ є working runbook для перенесення TirasCloud-2 Dev workloads у модель MicroK8s + GitOps.

Поточний source-of-truth split:

| Зона | Source |
| --- | --- |
| App source, Dockerfiles, tests, Jenkins allow-list | `C:\work\TirasCloud-2` |
| Dev Kubernetes manifests, Argo CD apps, platform manifests | `C:\work\ideal-octo-giggle` |
| Working documentation | `C:\work\docs\projects\tirascloud-2` |

## Межі репозиторіїв

`ideal-octo-giggle` є GitOps source для MicroK8s migration TirasCloud-2.

Manifest rules, які треба зберегти:

- service manifests live under `cluster/apps/tirascloud/<service>/base` and `cluster/apps/tirascloud/<service>/overlays/dev`;
- base manifests stay environment-neutral where possible;
- dev-only config belongs in `overlays/dev`;
- Jenkins updates only `images[].newTag` in dev overlay `kustomization.yaml`;
- runtime secret values must not be committed in plaintext;
- private TMQ consumers не мають отримувати Kubernetes `Service` objects, якщо code не exposes inbound port;
- HTTP probes are added only when code exposes real health endpoints;
- PVC-backed single-writer services should use `strategy.type: Recreate`.

## Migration flow

### Phase 0. Discovery і current-state audit

Записати для кожного service:

- module path in `C:\work\TirasCloud-2\modules`;
- Dockerfile status;
- root npm test script status;
- runtime ports and protocols;
- config source: env, config file, Kubernetes Secret, ConfigMap;
- persistence needs: ephemeral, PVC, external DB, object storage;
- external dependencies: TMQ, MongoDB, Redis, MinIO, Firebase, SMS, mail, HTTP APIs;
- current GitOps overlay path.

Done, коли кожен service має factual row у `DEPENDENCY_MAP.md` або service-specific note.

### Phase 1. Foundation bootstrap

Foundation owns host-level і cluster bootstrap work:

- base OS setup;
- storage mount validation/preparation;
- MicroK8s install and minimal addons;
- firewall/VPN baseline;
- Argo CD bootstrap handoff.

Поточні підтвердження з repo:

- `foundation/ansible/playbooks/bootstrap-hosts.yml`;
- `foundation/ansible/playbooks/prepare-cluster.yml`;
- `foundation/ansible/playbooks/post-bootstrap.yml`;
- `foundation/ansible/playbooks/validate-cluster.yml`;
- `foundation/ansible/playbooks/roles/storage`;
- `foundation/ansible/playbooks/roles/microk8s`;
- `foundation/ansible/playbooks/roles/argocd-bootstrap`.

Перевірка:

```powershell
git -C C:\work\ideal-octo-giggle status --short
```

На cluster host перевірити MicroK8s і Argo CD за project runbooks перед app rollout.

### Phase 2. GitOps platform rollout

Platform owns cluster-level services, які reconciled by Argo CD:

- storage classes;
- sealed-secrets;
- ingress-nginx and private ingresses;
- cert-manager and issuers;
- ECK operator, Elasticsearch, Logstash, Kibana, Filebeat;
- Jenkins;
- MinIO operator and tenant;
- Redis/MongoDB operators and runtime dependencies.

Поточні підтвердження з repo:

- `cluster/clusters/dev/platform/kustomization.yaml`;
- `cluster/platform/storage`;
- `cluster/platform/sealed-secrets`;
- `cluster/platform/private-ingresses`;
- `cluster/platform/eck-*`;
- `cluster/platform/jenkins`;
- `cluster/apps/minio-tenant`;
- `cluster/apps/redis`;
- `cluster/apps/mongodb`.

Done criteria:

- Argo CD platform apps є `Synced`;
- Argo CD platform apps є `Healthy`;
- required namespaces exist;
- storage classes exist;
- platform endpoints reachable через documented VPN/private ingress path.

### Phase 3. App rollout

Для кожного service:

1. Confirm Dockerfile, package files, root test script, Jenkins allow-list entry, and GitOps overlay exist.
2. Build and test from Jenkins.
3. Push image to Docker Hub.
4. Let Jenkins update only the GitOps image tag.
5. Let Argo CD reconcile.
6. Verify pod readiness, logs, service endpoints, and dependency connectivity.

Поточні Jenkins facts з `C:\work\TirasCloud-2\Jenkinsfile`:

- `serviceConfig` is the Jenkins allow-list;
- every service maps to a `gitopsImageTagFile`;
- Docker Hub namespace defaults to `<DOCKER_NAMESPACE>`;
- credentials are referenced by Jenkins credential IDs, not documented as values.

## Storage model

Використовувати stable storage class names у docs і manifests:

| Class | Intended use |
| --- | --- |
| `local-fast` | low-latency data such as RocksDB-like local service state |
| `local-bulk` | logs, object storage, heavier platform data |
| `local-general` | general persistent workloads where speed/capacity is not special |

Поточні підтвердження з repo:

- `cluster/platform/storage/storageclass-local-fast.yaml`;
- `cluster/platform/storage/storageclass-local-bulk.yaml`;
- service PVC overlays under `cluster/apps/tirascloud/*/overlays/dev`.

## Secret handling

Не документувати real values.

Дозволено в docs:

- Kubernetes Secret names;
- key names;
- Jenkins credential IDs;
- env var names.

Цільовий direction:

- plaintext Kubernetes Secret values мають бути замінені на Sealed Secrets;
- application docs мають описувати expected secret shape, а не values.

Поточний затверджений workflow:

- Sealed Secrets є approved path для GitOps-managed Kubernetes runtime secrets.
- Manual cluster-created Secrets можуть існувати лише як temporary Dev debt і мають tracked.
- Не promote plaintext Secret manifests до Етап/Prod.

## Пов’язані shared-документи

- `projects/shared/IaCInfrastructureWorkflow.md` для generic infrastructure workflow.
- `projects/shared/KubernetesSecurityHardening.md` для RBAC, audit, NetworkPolicy і production readiness.
- `projects/shared/SoftwareSupplyChainSecurity.md` для CI/CD trust chain і artifact controls.
- `projects/shared/RedisOperatingModel.md` і `projects/shared/MinIOKubernetesInfrastructure.md` для shared platform service decisions.

## Rollback model

Preferred rollback для GitOps-managed apps:

1. Revert or correct the GitOps commit that changed the rendered state.
2. Let Argo CD sync the previous desired state.
3. Verify deployment, pods, logs, and dependency checks.

Image tag rollback прийнятний для app-only regressions, коли schema або data migration не змінювалися.

Не використовувати rollback як shortcut для:

- incompatible DB/data migrations;
- broken secret rotation;
- storage layout mistakes;
- cross-service protocol changes.

## Done criteria для кожного migration step

Migration step не done, доки operator не підтвердить:

- local validation passed;
- Jenkins build/test/push succeeded;
- GitOps image tag was updated in the expected overlay only;
- Argo CD app is `Synced`;
- Argo CD app is `Healthy`;
- runtime workload check passed;
- logs are discoverable in the expected observability path.

## Відкриті питання

- Які existing manual/plaintext Dev secrets треба першими migrate into Sealed Secrets?
- Які workloads потребують PVCs лише для Dev, а які мають keep persistence в Етап/Prod?
- Який exact promotion boundary від Dev overlays до future Етап/Prod overlays?
- Які service migrations потребують data migration runbooks, а не app-only rollout?
