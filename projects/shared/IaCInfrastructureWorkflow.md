# Workflow IaC-інфраструктури

Статус: особистий робочий документ  
Джерела: `archive/2026-05-11/Workflow побудови IaC-інфраструктури.md`, нотатки infra review

## Призначення

Цей документ визначає повторюваний workflow для інфраструктурних змін, які проходять шлях від discovery до GitOps-managed runtime.

Для конкретних repo paths і команд використовувати project-specific runbooks.

## Операційний принцип

Інфраструктурна робота має проходити через:

```text
discovery -> architecture note -> IaC change -> rendered diff -> review -> apply/reconcile -> verification -> runbook update
```

Не дозволяти live cluster state ставати незадокументованим source of truth.

## Відповідальності репозиторіїв

| Шар | Відповідає за |
| --- | --- |
| Foundation / host automation | OS baseline, storage prep, MicroK8s install, базовий firewall/VPN, bootstrap. |
| Cluster GitOps | Argo CD apps, platform services, app manifests, overlays. |
| CI/CD | Build/test/push і GitOps tag updates. |
| Docs | Операційний намір, правила безпеки, verification і open questions. |

## Workflow зміни

1. Записати намір: що змінюється, чому, власник, ризик і rollback.
2. Визначити affected systems: cluster, namespace, app, data, secrets, network, CI/CD.
3. Перевірити, чи зміна platform-level або app-level.
4. Render/diff manifests перед apply.
5. Review secrets і sensitive outputs перед поширенням.
6. Apply через GitOps там, де можливо.
7. Перевірити Argo CD sync/health, pods, services, logs і data dependencies.
8. Оновити runbooks тим, що фактично змінилось.

## Safety gates

- Жодних plaintext secrets у Git.
- Жодних production/stage змін без rollback notes.
- Жодних змін storage class, PVC або database без data impact review.
- Жодних змін network exposure без ingress/L4 і firewall review.
- Жодного розширення CI/CD credentials без least-privilege review.

## Checklist перевірки

```powershell
kubectl kustomize <overlay-path>
kubectl -n argocd get applications
kubectl -n <namespace> get pods,svc,pvc
kubectl -n <namespace> get events --sort-by=.lastTimestamp
kubectl -n <namespace> logs deploy/<deployment> --tail=100
```

Використовувати `microk8s kubectl` там, де це local cluster entrypoint.

## Документаційні outputs

Кожна суттєва інфраструктурна зміна має оновлювати один із:

- project migration runbook;
- platform operations doc;
- shared Kubernetes ops/security doc;
- open questions index;
- resource register, якщо введені нові external resources.

## Відкриті питання

- Який IaC repository є authoritative для кожного environment?
- Які зміни потребують maintenance window?
- Які live-state discoveries треба backfill у GitOps?
- Яка archive policy для оброблених source notes із `process/`?
