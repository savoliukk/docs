# Platform operations TirasCloud-2

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/Kubectl cheatsheet.md`, `archive/2026-05-11/helm-upgrade-playbook.md`, `archive/2026-05-11/deployment-rollback-runbook.md`, `archive/2026-05-11/kubernetes-observability-logging-gitops-guide.md`, Redis/MinIO/Percona archive notes, `C:\work\ideal-octo-giggle`

## Operating model

Використовувати цей документ для day-to-day Dev platform operations навколо MicroK8s, GitOps, Argo CD, Jenkins, storage, logging, Redis, MinIO і database operators.

Правила:

- надавати перевагу GitOps changes над live cluster edits;
- тримати commands як verification steps, а не hidden mutation;
- не копіювати secret values у docs;
- записувати unresolved decisions як `Відкрите питання`.

## Швидкі cluster checks

Використовувати ці checks перед debugging app-level failures:

```powershell
microk8s status --wait-ready
microk8s kubectl get nodes -o wide
microk8s kubectl get ns
microk8s kubectl get pods -A
microk8s kubectl get events -A --sort-by=.lastTimestamp
```

Для GitOps-managed resources:

```powershell
microk8s kubectl -n argocd get applications
microk8s kubectl -n argocd get appprojects
```

## Kubernetes operator checks

Pods:

```powershell
microk8s kubectl -n <namespace> get pods -o wide
microk8s kubectl -n <namespace> describe pod <pod>
microk8s kubectl -n <namespace> logs <pod> --all-containers --tail=200
microk8s kubectl -n <namespace> logs <pod> --previous --all-containers --tail=200
```

Services і ingress:

```powershell
microk8s kubectl -n <namespace> get svc,endpoints,ingress
microk8s kubectl -n <namespace> describe ingress <name>
```

Exposure boundary:

```powershell
microk8s kubectl -n <namespace> get svc -o wide
microk8s kubectl -n <namespace> get networkpolicy
microk8s kubectl -n <namespace> describe svc <service>
```

Правила перевірки:

- internal service-to-service traffic має йти через `ClusterIP`, не через VPN, NodePort або LoadBalancer;
- HTTP/HTTPS/WebSocket exposure має йти через Ingress або Gateway API;
- device-facing UDP exposure має йти через L4 Service: Dev `NodePort`, Етап/Prod `LoadBalancer`/MetalLB або cloud L4 balancer;
- admin/private UI/API не мають бути public by default; використовувати VPN/private access/allowlist або private Ingress/Gateway;
- для device-facing UDP перевіряти `externalTrafficPolicy: Local`, edge node scheduling і відсутність зайвого SNAT/Masquerade на inbound path;
- `gateway/settings.json` і `firegw/serverList.json` мають рекламувати device-reachable external edge IP/VIP і real firmware port, не Pod IP, ClusterIP, `127.0.0.1` або Kubernetes `nodePort`.

Storage:

```powershell
microk8s kubectl get storageclass
microk8s kubectl -n <namespace> get pvc,pv
microk8s kubectl -n <namespace> describe pvc <pvc>
```

Rendered GitOps output:

```powershell
kubectl kustomize C:\work\ideal-octo-giggle\cluster\apps\tirascloud\<service>\overlays\dev
```

## Helm upgrade playbook

Використовувати Helm upgrades обережно для platform modules і operators.

Перед upgrade:

```powershell
helm -n <namespace> list
helm -n <namespace> get values <release> -o yaml
helm -n <namespace> history <release>
microk8s kubectl -n <namespace> get pods
```

Upgrade pattern:

```powershell
helm repo update
helm -n <namespace> upgrade <release> <chart> -f <values-file>
```

Після upgrade:

```powershell
helm -n <namespace> status <release>
microk8s kubectl -n <namespace> get pods -o wide
microk8s kubectl -n <namespace> get events --sort-by=.lastTimestamp
```

Не upgrade operators blindly, коли залучені CRDs, storage або immutable fields.

## GitOps rollback

Використовувати Git revert як default rollback path.

Коли потрібен rollback:

1. Identify whether the regression is image-only, manifest-only, secret/config, or data/schema.
2. Prefer reverting the GitOps commit.
3. Sync through Argo CD.
4. Verify pods, logs, services, and app-specific smoke checks.

Image tag rollback прийнятний лише коли deployment contract не changed.

## Observability and logging

Baseline mental model:

- applications мають писати logs у `stdout`/`stderr`, де це можливо;
- platform Filebeat може collect container logs;
- file-based logs потребують або app changes, або sidecar/tail pattern;
- Logstash transforms і forwards events до Elasticsearch;
- Kibana є operator search UI.

Поточні підтвердження з repo:

- `cluster/platform/eck-filebeat`;
- `cluster/platform/eck-logstash`;
- `cluster/platform/eck-es`;
- `cluster/platform/eck-kb`;
- `cluster/apps/tirascloud/logger`.

Для service `logger` dev overlay тримає file logs на PVC `logger-logs` і запускає Filebeat sidecar, який forwards to Logstash.

Operator checks:

```powershell
microk8s kubectl -n elastic-stack get pods
microk8s kubectl -n elastic-stack logs <filebeat-or-logstash-pod> --tail=200
```

У Kibana filter by namespace, pod, container, service name або message text.

## Redis operations

Поточний Redis direction для Dev:

- використовувати operator-managed Redis там, де GitOps repo вже його defines;
- тримати storage class і persistence explicit;
- не commit Redis passwords in plaintext;
- документувати ACL/user names і secret keys, а не values.

Поточні підтвердження з repo:

- `cluster/platform/redis-operator`;
- `cluster/apps/redis/redis.yaml`;
- `cluster/apps/redis/README.md`.

Відкрите питання:

- Який Redis mode потрібен після Dev: Sentinel або Redis Cluster?

Див. також:

- `projects/shared/RedisOperatingModel.md` для shared Redis placement, topology і verification guidance.

## MinIO operations

Поточний MinIO direction:

- MinIO operator і tenant є platform-managed;
- app docs мають описувати bucket/user/policy model, а не root credentials;
- root credentials не мають використовуватися applications;
- Service Center-specific MinIO documentation треба promote через `SCDocs\minio-kubernetes-infrastructure-plan.md`, а не дублювати.

Поточні підтвердження з repo:

- `cluster/platform/minio-operator`;
- `cluster/apps/minio-tenant`;
- `cluster/platform/private-ingresses`.

Див. також:

- `projects/shared/MinIOKubernetesInfrastructure.md` для shared tenant/bucket/user/policy model.

## Percona and MongoDB operations

Для MongoDB/Percona operator changes:

- спочатку verify CRDs і operator health;
- перевірити storage classes і PVCs перед app rollout;
- уникати in-place changes до immutable storage fields;
- тримати backup/restore procedures окремо від app deploy procedures.

Поточні підтвердження з repo:

- `cluster/platform/psmdb-operator`;
- `cluster/apps/mongodb`;
- `archive/2026-05-11/percona-rs-test-runbook.md`.

## Security notes

Ніколи не документувати:

- real passwords;
- PATs;
- private keys;
- kubeconfig contents;
- Secret values;
- `.env` values.

Дозволено:

- Kubernetes Secret object names;
- Secret key names;
- Jenkins credential IDs;
- environment variable names.

Approved runtime secret workflow:

- Sealed Secrets.

Traffic exposure baseline:

- base manifests лишати internal/`ClusterIP` by default;
- environment overlays мають явно описувати Ingress/Gateway, NodePort/LoadBalancer, NetworkPolicy і private/admin access;
- не робити public exposure у `base`;
- не використовувати stretched single Kubernetes cluster через local site + AWS VPN як перший production baseline; кращий напрямок - окремі site/cluster deployments, GitOps source of truth і edge-level failover.

Needs verification:

- actual Dev/Етап/Prod external edge endpoints для UDP;
- MetalLB pool, annotation syntax і VIP ownership перед team-ready manifests;
- current Gateway API/UDPRoute maturity перед production use;
- Calico default-deny policy coverage у app namespaces.

Пов’язані shared-документи:

- `projects/shared/KubernetesObservabilityLoggingGitOps.md`;
- `projects/shared/KubernetesSecurityHardening.md`;
- `projects/shared/IaCInfrastructureWorkflow.md`;
- `projects/tirascloud-2/ENTRA_ARC_MICROK8S_RBAC_POC.md` для Entra ID, Azure Arc, MicroK8s RBAC, Guard webhook, audit і rollback PoC.
- `projects/tirascloud-2/ROCKSDB_RUNTIME_SMOKE_RUNBOOK.md`.
- `projects/tirascloud-2/SERVICE_TRAFFIC_ROUTING_TIRASCLOUD_2.md`.

## Відкриті питання

- Які platform runbooks мають стати team docs, а які лишитися personal working notes?
- Які Redis/MinIO/MongoDB decisions є Dev-only, а які мають стати Етап/Prod baseline?
- Які observability indexes/data views canonical для TirasCloud Dev?
- Які exact external endpoints і VIPs затверджені для TirasCloud UDP у Dev/Етап/Prod?

