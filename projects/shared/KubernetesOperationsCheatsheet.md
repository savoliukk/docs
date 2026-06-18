# Kubernetes operations cheatsheet

Статус: особистий робочий документ  
Джерело: `archive/2026-05-11/Kubectl cheatsheet.md`

## Призначення

Це компактний command reference Kubernetes/MicroK8s для щоденного troubleshooting.

Не вставляй у документацію вивід команд, який містить секрети.

## Здоров'я cluster

```powershell
microk8s status --wait-ready
microk8s kubectl cluster-info
microk8s kubectl get nodes -o wide
microk8s kubectl get componentstatuses
```

## Namespaces

```powershell
microk8s kubectl get ns
microk8s kubectl describe ns <namespace>
```

## Pods

```powershell
microk8s kubectl -n <namespace> get pods -o wide
microk8s kubectl -n <namespace> describe pod <pod>
microk8s kubectl -n <namespace> logs <pod> --all-containers --tail=200
microk8s kubectl -n <namespace> logs <pod> --previous --all-containers --tail=200
```

Спостерігати за pods:

```powershell
microk8s kubectl -n <namespace> get pods -w
```

## Deployments і workloads

```powershell
microk8s kubectl -n <namespace> get deploy,rs,sts,ds
microk8s kubectl -n <namespace> describe deploy <deployment>
microk8s kubectl -n <namespace> rollout status deploy/<deployment>
microk8s kubectl -n <namespace> rollout history deploy/<deployment>
```

Перезапустити deployment:

```powershell
microk8s kubectl -n <namespace> rollout restart deploy/<deployment>
```

## Services, endpoints, ingress

```powershell
microk8s kubectl -n <namespace> get svc,endpoints,ingress
microk8s kubectl -n <namespace> describe svc <service>
microk8s kubectl -n <namespace> describe ingress <ingress>
```

Port-forward для локальної перевірки:

```powershell
microk8s kubectl -n <namespace> port-forward svc/<service> <local-port>:<service-port>
```

## ConfigMaps і Secrets

Безпечні metadata checks:

```powershell
microk8s kubectl -n <namespace> get configmap
microk8s kubectl -n <namespace> get secret
microk8s kubectl -n <namespace> describe secret <secret-name>
```

Уникати документування команд, які друкують secret values.

Дозволено в docs:

- Secret name;
- key name;
- env var name;
- mounting pattern.

Заборонено в docs:

- decoded values;
- full connection strings with credentials;
- private keys;
- tokens.

## Storage

```powershell
microk8s kubectl get storageclass
microk8s kubectl get pv
microk8s kubectl -n <namespace> get pvc
microk8s kubectl -n <namespace> describe pvc <pvc>
```

Для stuck PVCs:

```powershell
microk8s kubectl -n <namespace> get events --sort-by=.lastTimestamp
```

## Events

```powershell
microk8s kubectl -n <namespace> get events --sort-by=.lastTimestamp
microk8s kubectl get events -A --sort-by=.lastTimestamp
```

## Apply і diff

Надавати перевагу GitOps для persistent state.

Для local render checks:

```powershell
kubectl kustomize <overlay-path>
```

Для server-side diff, коли доречно:

```powershell
microk8s kubectl diff -f <manifest-or-dir>
```

Виконувати apply лише тоді, коли task явно дозволяє live changes:

```powershell
microk8s kubectl apply -f <manifest-or-dir>
```

## Labels і selectors

```powershell
microk8s kubectl -n <namespace> get pods --show-labels
microk8s kubectl -n <namespace> get pods -l app=<name>
microk8s kubectl -n <namespace> logs -l app=<name> --tail=200
```

## Jobs і CronJobs

```powershell
microk8s kubectl -n <namespace> get jobs,cronjobs
microk8s kubectl -n <namespace> describe job <job>
microk8s kubectl -n <namespace> logs job/<job> --tail=200
```

## CRDs і operators

```powershell
microk8s kubectl get crd
microk8s kubectl api-resources | findstr <keyword>
microk8s kubectl -n <operator-namespace> get pods
```

Під час зміни operators:

- check CRDs;
- check operator logs;
- avoid blind upgrades;
- check immutable fields and PVC behavior.

## Helm safety checks

Перед operator або platform Helm upgrade:

```powershell
helm -n <namespace> list
helm -n <namespace> get values <release> -o yaml
helm -n <namespace> history <release>
microk8s kubectl -n <namespace> get pods
```

Після upgrade:

```powershell
helm -n <namespace> status <release>
microk8s kubectl -n <namespace> get pods -o wide
microk8s kubectl -n <namespace> get events --sort-by=.lastTimestamp
```

Не оновлюй оператори з великою кількістю CRD без перевірки release notes, immutable fields, поведінки PVC і rollback path.

## Пов’язані документи

- `KubernetesSecurityHardening.md` для RBAC, audit, NetworkPolicy і production-readiness controls.
- `KubernetesObservabilityLoggingGitOps.md` для logging pipeline і Kibana verification.
- `IaCInfrastructureWorkflow.md` для GitOps-first infrastructure changes.

## Формати output

```powershell
microk8s kubectl get pods -o wide
microk8s kubectl get deploy <deployment> -o yaml
microk8s kubectl get pods -o jsonpath="{.items[*].metadata.name}"
```

Не використовуй YAML/JSON-вивід Secrets у документації.

## MicroK8s helpers

```powershell
microk8s status
microk8s inspect
microk8s enable dns
microk8s enable hostpath-storage
microk8s kubectl get all -A
```

## Порядок troubleshooting

1. Перевірити, що namespace exists.
2. Перевірити pods і events.
3. Перевірити deployment rollout.
4. Перевірити presence config/secret object без друку values.
5. Перевірити services/endpoints.
6. Перевірити ingress.
7. Перевірити logs.
8. Перевірити platform dependencies.
9. Перевірити Argo CD sync/health, якщо GitOps-managed.
