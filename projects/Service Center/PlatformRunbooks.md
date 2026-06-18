# Platform runbooks Service Center

Статус: особистий робочий документ  
Джерела: `C:\work\SCDocs`, `C:\work\SCInfrastructure\docs`, `archive/2026-05-11/SC_Infrastructure*.md`, `archive/2026-05-11/minio-kubernetes-infrastructure-plan.md`

## Призначення

Цей документ є index і working layer для Service Center operator runbooks. Team-ready copies треба promote до `C:\work\SCDocs` лише після review і sanitization.

## Поточні командні документи

| Team doc | Призначення |
| --- | --- |
| `SCDocs\SC_Infrastructure.md` | infrastructure overview і regulations |
| `SCDocs\SCNet_Feature_Kubernetes_Runbook.md` | SCNet feature Kubernetes CI/CD |
| `SCDocs\SC_VPN_Setup_Runbook.md` | VPN administrator setup |
| `SCDocs\SC_VPN_User_Guide.md` | VPN user guide |
| `SCDocs\scnet-feature-viewer-kubeconfig-windows.md` | read-only kubeconfig setup |
| `SCDocs\minio-kubernetes-infrastructure-plan.md` | MinIO architecture і operations |
| `SCDocs\protocol.md` | LAS protocol |

## SCNet feature deployment

Потік:

```text
SCNet/feature/k8s
  -> Jenkins
  -> Docker Hub
  -> SCInfrastructure/argocd-feature
  -> Argo CD
  -> scnet-feature namespace
```

Operator checks:

```powershell
kubectl -n scnet-feature get pods -o wide
kubectl -n scnet-feature get svc
kubectl -n scnet-feature logs deploy/<deployment-name> --tail=200
```

Використовувати `SCDocs\SCNet_Feature_Kubernetes_Runbook.md` для team-facing flow.

## VPN access

Admin setup doc:

```text
C:\work\SCDocs\SC_VPN_Setup_Runbook.md
```

User guide:

```text
C:\work\SCDocs\SC_VPN_User_Guide.md
```

Access model, який треба зберегти:

- developers використовують VPN/private access для Argo CD, Jenkins, Kibana, RabbitMQ/MinIO management там, де дозволено;
- operational docs мають давати service names і URLs, а не credentials;
- adding або revoking access має логуватися як operator action.

## Read-only Kubernetes access

Viewer docs:

```text
C:\work\SCDocs\scnet-feature-viewer-kubeconfig-windows.md
```

Safe checks для read-only users:

```powershell
kubectl -n scnet-feature get pods
kubectl -n scnet-feature get svc
kubectl -n scnet-feature logs deploy/<deployment-name> --tail=100
```

Не надавати edit permissions для normal inspection workflows.

## MinIO

Поточний team doc:

```text
C:\work\SCDocs\minio-kubernetes-infrastructure-plan.md
```

Service Center-specific notes:

- MinIO використовується для files/attachments;
- applications мають використовувати service-specific credentials, а не root credentials;
- bucket і policy model треба документувати без values;
- root credentials, access keys і secret keys не можна копіювати в docs.

## Runtime secret handling

Поточний feature-контур має temporary plaintext Secret debt у `SCInfrastructure`.

Operator runbooks мають:

- називати Kubernetes Secret object;
- називати required keys;
- пояснювати, як verify, що Secret exists;
- уникати printing або copying values;
- вказувати на approved migration path: Sealed Secrets.

Safe check:

```powershell
kubectl -n scnet-feature get secret scnet-feature-secrets
```

Avoid:

```powershell
kubectl -n scnet-feature get secret scnet-feature-secrets -o yaml
```

якщо тільки task явно не потребує secret administration і output не вставляється в docs.

## Rollback

Для application regressions:

1. Визначити image tag або GitOps change.
2. Revert GitOps change або restore previous image tag.
3. Дати Argo CD виконати sync.
4. Перевірити pods, services, logs і smoke checks.

Для platform regressions:

- перевірити, чи зміна affected CRDs, operators, PVCs або secrets;
- уникати blind rollback, якщо data schema або storage changed;
- написати short incident note з root cause і verification steps.

## Promotion checklist

Перед promotion будь-якого runbook до `SCDocs`:

- no concrete secrets/tokens/passwords;
- commands are copy-paste safe;
- paths match current repo layout;
- role/audience is clear: admin, developer, viewer, operator;
- rollback and verification steps exist;
- open questions are marked explicitly.

Promotion до `SCDocs` навмисно out of scope для цього apply run і має виконуватися як окремий approved run.

## Пов’язані shared-документи

- `projects/shared/MinIOKubernetesInfrastructure.md`;
- `projects/shared/KubernetesObservabilityLoggingGitOps.md`;
- `projects/shared/KubernetesSecurityHardening.md`;
- `projects/shared/SoftwareSupplyChainSecurity.md`.

## Відкриті питання

- Чи MinIO docs мають бути shared між TirasCloud і Service Center або split by product?
- Які SCNet smoke tests mandatory після кожного deploy?
- Які Service Center runbooks мають бути user-facing, а які admin-only?
