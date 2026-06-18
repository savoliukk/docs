# Entra ID, Azure Arc і MicroK8s RBAC PoC

Статус: особистий робочий runbook  
Дата поточного зрізу: 2026-05-28  
Перенесено з source-файлу `C:\work\ideal-octo-giggle\foundation\runbooks\entra-arc-microk8s-rbac-poc.md`; source-файл після перенесення видалено за запитом.

## Призначення

Цей runbook фіксує PoC для Microsoft Entra ID authentication і Azure RBAC authorization на self-managed MicroK8s dev cluster `tiras-cloud-dev`.

Мета - довести або відхилити Azure Arc як шлях доступу до existing MicroK8s cluster без міграції в AKS.

Це не production approval. PoC вважається успішним тільки після проходження decision gates, перевірки allow/deny/revoke path, audit evidence і rollback path.

## Поточний стан

- Дата: 2026-05-28.
- Azure subscription: `Azure subscription 1`.
- Resource group: `rg-tirascloud-dev-arc-poc`.
- Arc cluster name: `tiras-cloud-dev`.
- Region: `westeurope`.
- Entra groups:
  - `TC-K8S-Viewers`
  - `TC-K8S-ClusterAdmins`
- MicroK8s host: `tiras-dev-cp1`.
- MicroK8s architecture: `linux/amd64`.
- Temporary Arc kubeconfig: `$ARC_KUBECONFIG`.
- Temporary kubeconfig limitation: `insecure-skip-tls-verify=true` використовується лише для цього PoC, бо MicroK8s API server CA certificate не пройшов Azure CLI certificate validation.

## Потрібні admin permissions

Використовувати цей checklist перед Portal або CLI роботами. Якщо permissions відсутні, зазвичай це проявляється як disabled Portal buttons або Azure CLI authorization errors.

Azure subscription/resource permissions:

- Register resource providers: subscription `Owner`, `Contributor` або інша роль із provider registration permissions.
- Create/delete Arc connected cluster resource: subscription/resource group `Contributor` або `Owner`.
- Assign Azure roles to users/groups/managed identities: `Owner`, `User Access Administrator` або `Role Based Access Control Administrator` на target scope.
- Read role assignments and check access: `Reader` або сильніша роль на target scope.

Microsoft Entra permissions:

- Create non-admin test user: `User Administrator` або `Global Administrator`.
- Add/remove group members: `Groups Administrator`, `User Administrator` або `Global Administrator`.
- Read users/groups: basic directory read access зазвичай достатній, але в locked-down tenants можуть знадобитися admin roles.

Kubernetes/MicroK8s permissions:

- Local break-glass admin kubeconfig для `microk8s kubectl`.
- SSH/sudo access на `tiras-dev-cp1` для редагування `/var/snap/microk8s/current/args/kube-apiserver`, копіювання Guard webhook files, налаштування audit logging і restart MicroK8s control-plane service.

Якщо дія в Portal недоступна:

1. Перевірити, що активний tenant і subscription правильні.
2. Перевірити, що active account має роль на правильному scope.
3. Використовувати найменший scope, достатній для дії.
4. Після нових role assignments зачекати кілька хвилин перед повторною спробою.

## Decision gates

PoC не доведений, доки кожен gate нижче не має свіжого evidence.

| Gate | Evidence | Вплив на рішення |
| --- | --- | --- |
| Arc bootstrap | `az connectedk8s show` повертає `ConnectivityStatus=Connected`; Arc pods працюють; Arc identity certificate secrets існують | Обов'язково перед Azure RBAC/API server роботами |
| Azure RBAC feature | `guard` deployment працює в `azure-arc`; `azure-arc-guard-manifests` існує в `kube-system` | Обов'язково перед зміною MicroK8s API server |
| MicroK8s API server | API server використовує `Node,RBAC,Webhook` і Guard authn/authz webhook config files; local admin kubeconfig досі працює | Обов'язково перед Entra user authorization через Azure RBAC |
| Viewer grant | `TC-K8S-Viewers` може list non-secret resources у `tirascloud-dev` через `az connectedk8s proxy` | Доводить least-privilege read access |
| Viewer denial | Viewer не може читати secrets і delete pods | Доводить deny path |
| Admin grant | `TC-K8S-ClusterAdmins` може виконувати cluster admin actions через `az connectedk8s proxy` | Доводить admin path |
| Revoke | Видалення Viewer role assignment робить Viewer user forbidden після propagation | Доводить revoke path |
| Audit | Azure activity log показує role assignment changes; Kubernetes API audit path налаштований і перевірений | Обов'язково перед claim audit coverage |
| Rollback | API server backup відновлює local admin access; Azure role assignments/features можна прибрати | Обов'язково перед production use |

Поточне рішення:

- Azure Arc plus Azure RBAC лишається plausible path для цього x86_64 self-managed MicroK8s cluster.
- Arc bootstrap gate пройдений після clean delete і reconnect.
- Azure RBAC feature gate пройдений; Guard deployment і Guard webhook secret існують.
- Cluster managed identity має `Connected Cluster Managed Identity CheckAccess Reader` на Arc cluster scope.
- Pilot group role assignments підтверджені для `TC-K8S-Viewers` і `TC-K8S-ClusterAdmins`.
- MicroK8s API server gate пройдений; API server використовує Arc Guard authn/authz webhooks, local admin access досі працює.
- Наступний gate - Viewer/Admin allow-deny testing через `az connectedk8s proxy`.

## Виконаний recovery step

2026-05-28 broken Arc installation було deleted і reconnected успішно.

Validated evidence:

- `az connectedk8s show` повернув `provisioningState=Succeeded`, `connectivityStatus=Connected` і `agentVersion=1.34.2`.
- Усі pods у namespace `azure-arc` були `Running`.
- Secrets `azure-identity-certificate` і `kube-aad-proxy-certificate` існували.
- `clusteridentityoperator` успішно отримав certificates from HIS з HTTP 200.

Зберегти ці recovery notes для майбутніх cleanup attempts. Якщо `az connectedk8s delete` зависає на:

```text
Confirming 'azure-arc' namespace got deleted.
```

натиснути `Ctrl+C` після 10-15 хвилин, потім спочатку виконати тільки:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc azure-arc-release

az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc
```

Інтерпретація:

- Якщо `az connectedk8s show` повертає not found і обидва namespaces зникли, перейти до `Reconnect Arc`.
- Якщо `az connectedk8s show` повертає not found, але `azure-arc` у стані `Terminating`, використовувати stuck namespace diagnostics із `Clean-delete broken Arc`.
- Якщо `az connectedk8s show` досі повертає resource, ще не робити reconnect; спочатку завершити або force Azure-side delete.

## Operator sequence

Виконувати саме в цьому порядку. Не пропускати gates.

1. Register Azure resource providers.
2. Створити non-admin Viewer test user.
3. Додати test user тільки до `TC-K8S-Viewers`.
4. Connect або clean-reconnect MicroK8s cluster до Azure Arc.
5. Дочекатися Arc `ConnectivityStatus=Connected`.
6. Призначити cluster managed identity роль `Connected Cluster Managed Identity CheckAccess Reader`.
7. Enable Azure RBAC на Arc cluster.
8. Verify Guard і `azure-arc-guard-manifests`.
9. Призначити pilot Azure roles для Viewer/Admin groups.
10. Під час maintenance window налаштувати MicroK8s API server на Guard webhooks.
11. Протестувати Viewer allow/deny behavior через `az connectedk8s proxy`.
12. Протестувати ClusterAdmin behavior через `az connectedk8s proxy`.
13. Протестувати revoke через delete Viewer role assignment.
14. Зібрати audit evidence.
15. Прийняти рішення, чи path viable для production, і записати remaining limitations.

## Gate: не рухатися далі

Не вмикати Azure RBAC і не змінювати MicroK8s API server authorization flags, доки Arc не показує `ConnectivityStatus=Connected` і Arc identity certificates не існують.

Required evidence:

```bash
az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --query "{provisioningState:provisioningState,connectivityStatus:connectivityStatus,agentVersion:agentVersion}" \
  -o table

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -n azure-arc

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret -n azure-arc -o name \
  | grep -E 'azure-identity-certificate|kube-aad-proxy-certificate'
```

Expected:

- `provisioningState` is `Succeeded`.
- `connectivityStatus` is `Connected`.
- Arc pods are running.
- Secrets include `azure-identity-certificate` and `kube-aad-proxy-certificate`.

## Спостережений broken Arc installation

Перший Arc install створив ARM resource, але cluster лишився в `Connecting`.

Observed symptoms:

- `kube-aad-proxy` stuck in `ContainerCreating`.
- `config-agent` readiness probe returned HTTP 500.
- Secret `kube-aad-proxy-certificate` був відсутній.
- Secret `azure-identity-certificate` був відсутній.
- `AzureClusterIdentityRequest` objects мали empty status або empty `tokenReference`.
- `clusteridentityoperator` постійно не міг отримати certificates from HIS:
  - status code `403`
  - code `HCRP403`
  - message `Validation of signed message failed.`
- `curl -Iv https://westeurope.dp.kubernetesconfiguration.azure.com` успішно проходив DNS/TLS/connectivity level і повертав HTTP 404 для `/`, тож це не виглядало як базова outbound connectivity failure до DP.

Decision:

- Не створювати Arc certificate secrets вручну.
- Clean-delete і reconnect вирішили цей occurrence.

## Register Azure resource providers

Виконати один раз на subscription:

```bash
az account set --subscription "Azure subscription 1"

az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation
```

Дочекатися registration:

```bash
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table
```

Expected `RegistrationState`:

```text
Registered
```

Portal path:

1. Open https://portal.azure.com.
2. Search for `Subscriptions`.
3. Open `Azure subscription 1`.
4. In the left menu, open `Resource providers`.
5. Search for each provider and select `Register`:
   - `Microsoft.Kubernetes`
   - `Microsoft.KubernetesConfiguration`
   - `Microsoft.ExtendedLocation`
6. Refresh until each provider shows `Registered`.

## Create Entra test user and group membership

Для Viewer test використовувати non-admin user. Account, який створює users, потребує Entra role на кшталт `User Administrator` або `Global Administrator`.

Отримати default Entra domain:

```bash
az rest \
  --method get \
  --url "https://graph.microsoft.com/v1.0/domains?\$filter=isDefault eq true" \
  --query "value[0].id" \
  -o tsv
```

Set variables:

```bash
ENTRA_DOMAIN="<tenant-default-domain>"
VIEWER_UPN="arc-viewer-test@$ENTRA_DOMAIN"
VIEWER_PASSWORD="<temporary-strong-password>"
```

Create non-admin test user:

```bash
az ad user create \
  --display-name "Arc Viewer Test" \
  --user-principal-name "$VIEWER_UPN" \
  --password "$VIEWER_PASSWORD" \
  --force-change-password-next-sign-in true
```

Додати user тільки до `TC-K8S-Viewers`:

```bash
VIEWER_GROUP_ID=$(az ad group show --group "TC-K8S-Viewers" --query id -o tsv)
VIEWER_USER_ID=$(az ad user show --id "$VIEWER_UPN" --query id -o tsv)

az ad group member add \
  --group "$VIEWER_GROUP_ID" \
  --member-id "$VIEWER_USER_ID"
```

Verify membership:

```bash
az ad group member list \
  --group "$VIEWER_GROUP_ID" \
  --query "[].{displayName:displayName,userPrincipalName:userPrincipalName,id:id}" \
  -o table

ADMIN_GROUP_ID=$(az ad group show --group "TC-K8S-ClusterAdmins" --query id -o tsv)

az ad group member check \
  --group "$ADMIN_GROUP_ID" \
  --member-id "$VIEWER_USER_ID"
```

Expected:

- User є в `TC-K8S-Viewers`.
- Admin group membership check повертає `false`.

Portal path to create the user:

1. Open https://entra.microsoft.com.
2. In the left menu, open `Entra ID`.
3. Open `Users` > `All users`.
4. Select `New user` > `Create new user`.
5. Create a user named `Arc Viewer Test`.
6. Use tenant default domain for user principal name, наприклад `arc-viewer-test@<tenant-domain>`.
7. Use autogenerated або temporary strong password.
8. Keep the user non-admin. Do not assign an Entra admin role.
9. Save the user and record the temporary password only in a secure password store.

Portal path to add the user only to Viewer group:

1. Open https://entra.microsoft.com.
2. Open `Entra ID` > `Groups` > `All groups`.
3. Open `TC-K8S-Viewers`.
4. Open `Members`.
5. Select `Add members`.
6. Search for `Arc Viewer Test`, select the user, then confirm.
7. Open `TC-K8S-ClusterAdmins` > `Members` and verify `Arc Viewer Test` is absent.

## Capture evidence before cleanup

Виконати на `tiras-dev-cp1`:

```bash
mkdir -p "$HOME/arc-poc-evidence"

az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  -o json > "$HOME/arc-poc-evidence/connectedk8s-before-clean-reconnect.json"

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -n azure-arc -o wide \
  > "$HOME/arc-poc-evidence/azure-arc-pods-before-clean-reconnect.txt"

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get azureclusteridentityrequests.clusterconfig.azure.com -n azure-arc -o yaml \
  > "$HOME/arc-poc-evidence/azure-arc-identity-requests-before-clean-reconnect.yaml"
```

## Clean-delete broken Arc

Run:

```bash
az connectedk8s delete \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --kube-config "$ARC_KUBECONFIG" \
  --yes
```

Якщо command чекає понад 10-15 хвилин на:

```text
Confirming 'azure-arc' namespace got deleted.
```

натиснути `Ctrl+C`, потім inspect namespace:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc azure-arc-release

az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc
```

Якщо `az connectedk8s show` повертає not found, ARM resource deleted і лишається тільки Kubernetes cleanup.

Якщо `azure-arc` stuck in `Terminating`, collect:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc -o yaml

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get all -n azure-arc

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get events -n azure-arc --sort-by=.lastTimestamp | tail -80
```

Inspect namespace conditions і remaining namespaced resources:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc \
  -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{": "}{.message}{"\n"}{end}'

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get -n azure-arc --ignore-not-found
```

Inspect Helm release remnants:

```bash
if command -v helm >/dev/null 2>&1; then
  helm list -A | grep -E 'azure-arc|azure-arc-release|connectedk8s' || true
  helm list -n azure-arc || true
else
  echo "helm is not in PATH; skip Helm inspection and rely on Kubernetes namespace/resource checks"
fi
```

Якщо resources лишаються в `azure-arc`, спочатку delete owning workload resources і wait:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" delete deploy,statefulset,daemonset,job,cronjob -n azure-arc --all --ignore-not-found
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" delete pod -n azure-arc --all --ignore-not-found
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc -w
```

Namespace finalizer cleanup розглядати тільки коли всі умови true:

- `az connectedk8s show` повертає not found для `tiras-cloud-dev`.
- Helm release уже gone або uninstall більше не знаходить release.
- API resources sweep вище не показує meaningful remaining `azure-arc` resources.
- Namespace досі `Terminating` через namespace finalizers або unavailable API discovery.

Last-resort namespace finalizer cleanup:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc -o json \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); d.setdefault("spec",{})["finalizers"]=[]; print(json.dumps(d))' \
  > /tmp/azure-arc-ns-finalize.json

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" replace --raw "/api/v1/namespaces/azure-arc/finalize" \
  -f /tmp/azure-arc-ns-finalize.json
```

Verify cleanup:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get ns azure-arc azure-arc-release
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get crd | grep -E 'clusterconfig.azure.com|azure.com' || true
```

Якщо Azure Arc CRDs лишилися після namespace cleanup, не delete blindly. Спочатку inspect, чи вони own resources:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get crd | grep -E 'clusterconfig.azure.com|azure.com'
```

## Reconnect Arc

Перед reconnect виконати preflight checks.

Azure CLI and extension:

```bash
az version
az extension show --name connectedk8s -o table || az extension add --name connectedk8s
az extension update --name connectedk8s

az account show \
  --query "{name:name,tenantId:tenantId,id:id,user:user.name}" \
  -o table
```

Resource providers:

```bash
az provider show -n Microsoft.Kubernetes --query "{namespace:namespace,state:registrationState}" -o table
az provider show -n Microsoft.KubernetesConfiguration --query "{namespace:namespace,state:registrationState}" -o table
az provider show -n Microsoft.ExtendedLocation --query "{namespace:namespace,state:registrationState}" -o table
```

Expected:

```text
Registered
```

Clock synchronization:

```bash
timedatectl
date -u
```

Expected:

```text
System clock synchronized: yes
```

Local cluster health:

```bash
microk8s status --wait-ready

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get nodes -o wide

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -A \
  --field-selector=status.phase!=Running,status.phase!=Succeeded
```

Expected:

- MicroK8s is ready.
- Node is `Ready`.
- No unrelated workload consumes enough memory to prevent Arc pods from scheduling.

Outbound endpoint smoke checks:

```bash
curl -Iv https://gbl.his.arc.azure.com/weu/his
curl -Iv https://westeurope.dp.kubernetesconfiguration.azure.com
curl -Iv https://mcr.microsoft.com/v2/
curl -Iv https://login.microsoftonline.com
```

Expected:

- DNS resolves.
- TLS handshake succeeds.
- HTTP status can be `200`, `401`, `404` або інша service-level response залежно від endpoint/path.
- Connection timeout, DNS failure, TLS interception або certificate verification failure треба вирішити перед reconnect.

Reconnect:

```bash
az connectedk8s connect \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --location westeurope \
  --kube-config "$ARC_KUBECONFIG" \
  --onboarding-timeout 1800
```

Post-connect verification:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -n azure-arc

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret -n azure-arc -o name \
  | grep -E 'azure-identity-certificate|kube-aad-proxy-certificate'

az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --query "{provisioningState:provisioningState,connectivityStatus:connectivityStatus,agentVersion:agentVersion}" \
  -o table
```

Якщо reconnect fails або returns to `Connecting`, capture:

```bash
mkdir -p "$HOME/arc-poc-evidence/reconnect-$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR=$(ls -dt "$HOME"/arc-poc-evidence/reconnect-* | head -1)

az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  -o json > "$EVIDENCE_DIR/connectedk8s-show.json" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -n azure-arc -o wide \
  > "$EVIDENCE_DIR/azure-arc-pods.txt" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" describe pods -n azure-arc \
  > "$EVIDENCE_DIR/azure-arc-pods-describe.txt" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get events -n azure-arc --sort-by=.lastTimestamp \
  > "$EVIDENCE_DIR/azure-arc-events.txt" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" logs -n azure-arc deployment/clusteridentityoperator -c manager --tail=2000 \
  > "$EVIDENCE_DIR/clusteridentityoperator-manager.log" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" logs -n azure-arc deployment/config-agent -c config-agent --tail=2000 \
  > "$EVIDENCE_DIR/config-agent.log" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get azureclusteridentityrequests.clusterconfig.azure.com -n azure-arc -o yaml \
  > "$EVIDENCE_DIR/azureclusteridentityrequests.yaml" 2>&1 || true

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret -n azure-arc -o name \
  > "$EVIDENCE_DIR/azure-arc-secrets.txt" 2>&1 || true

echo "$EVIDENCE_DIR"
```

Якщо logs знову показують `HCRP403` і `Validation of signed message failed`, записати нові tracking IDs з `clusteridentityoperator-manager.log` і відкрити Microsoft support case з evidence directory.

## Enable Azure RBAC

Виконувати тільки після того, як Arc має `Connected`.

Set variables:

```bash
ARM_ID=$(az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --query id -o tsv)

CLUSTER_MSI_ID=$(az connectedk8s show \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --query identity.principalId -o tsv)

VIEWER_GROUP_ID=$(az ad group show --group "TC-K8S-Viewers" --query id -o tsv)
ADMIN_GROUP_ID=$(az ad group show --group "TC-K8S-ClusterAdmins" --query id -o tsv)
```

Якщо `az ad group show` не може reach Microsoft Graph з cluster host, скопіювати group Object IDs з Azure Portal:

1. Open https://portal.azure.com.
2. Open `Microsoft Entra ID` > `Groups`.
3. Open `TC-K8S-Viewers` and copy `Object ID`.
4. Open `TC-K8S-ClusterAdmins` and copy `Object ID`.
5. Set manually:

```bash
VIEWER_GROUP_ID="<TC-K8S-Viewers-object-id>"
ADMIN_GROUP_ID="<TC-K8S-ClusterAdmins-object-id>"
```

Allow Arc cluster managed identity to perform Azure RBAC access checks:

```bash
az role assignment create \
  --role "Connected Cluster Managed Identity CheckAccess Reader" \
  --assignee-object-id "$CLUSTER_MSI_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "$ARM_ID"
```

Використовувати `--assignee-object-id`, а не `--assignee`, для cluster managed identity. Це уникає Azure CLI Microsoft Graph lookup для service principal, який може fail on restricted networks, навіть коли Azure Resource Manager access працює.

Enable Azure RBAC feature:

```bash
az connectedk8s enable-features \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --features azure-rbac \
  --kube-config "$ARC_KUBECONFIG"
```

Verify Guard artifacts:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get deploy guard -n azure-arc

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret azure-arc-guard-manifests -n kube-system -o jsonpath='{.data.guard-authn-webhook\.yaml}' | wc -c

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret azure-arc-guard-manifests -n kube-system -o jsonpath='{.data.guard-authz-webhook\.yaml}' | wc -c
```

## Assign pilot Azure roles

Grant both connection role and Kubernetes data-plane role.

Viewer group:

```bash
az role assignment create \
  --role "Azure Arc Enabled Kubernetes Cluster User Role" \
  --assignee-object-id "$VIEWER_GROUP_ID" \
  --assignee-principal-type Group \
  --scope "$ARM_ID"

az role assignment create \
  --role "Azure Arc Kubernetes Viewer" \
  --assignee-object-id "$VIEWER_GROUP_ID" \
  --assignee-principal-type Group \
  --scope "$ARM_ID/namespaces/tirascloud-dev"
```

Admin group:

```bash
az role assignment create \
  --role "Azure Arc Enabled Kubernetes Cluster User Role" \
  --assignee-object-id "$ADMIN_GROUP_ID" \
  --assignee-principal-type Group \
  --scope "$ARM_ID"

az role assignment create \
  --role "Azure Arc Kubernetes Cluster Admin" \
  --assignee-object-id "$ADMIN_GROUP_ID" \
  --assignee-principal-type Group \
  --scope "$ARM_ID"
```

Role assignment propagation can take several minutes.

Portal path to assign pilot Azure roles:

1. Open https://portal.azure.com.
2. Search for `Azure Arc`.
3. Open `Azure Arc` > `Kubernetes clusters`.
4. Open `tiras-cloud-dev`.
5. Open `Access control (IAM)`.
6. Select `Add` > `Add role assignment`.
7. For `TC-K8S-Viewers`, add:
   - `Azure Arc Enabled Kubernetes Cluster User Role` at the cluster resource scope.
   - Use CLI command above for `Azure Arc Kubernetes Viewer` at `$ARM_ID/namespaces/tirascloud-dev`; Microsoft documents namespace-scoped Arc Kubernetes role assignments через CLI.
8. For `TC-K8S-ClusterAdmins`, add:
   - `Azure Arc Enabled Kubernetes Cluster User Role` at the cluster resource scope.
   - `Azure Arc Kubernetes Cluster Admin` at the cluster resource scope.
9. Use `Members` tab to select `User, group, or service principal`, then search group name.
10. On `Review + assign`, confirm assignment.

Portal path to verify role assignments:

1. Open the `tiras-cloud-dev` Arc Kubernetes resource.
2. Open `Access control (IAM)`.
3. Open `Role assignments`.
4. Search for:
   - `TC-K8S-Viewers`
   - `TC-K8S-ClusterAdmins`
5. Use `Check access` and search each group to confirm inherited and direct assignments at current scope.

## Configure kubectl for pilot users

Виконувати тільки після:

- Arc is `Connected`.
- Azure RBAC is enabled.
- MicroK8s API server configured to use Arc Guard authn/authz webhooks.
- Pilot role assignments had several minutes to propagate.

Preferred PoC method: use Arc cluster connect.

На pilot user workstation set known IDs supplied by admin:

```bash
TENANT_ID="<tenant-id>"
SUBSCRIPTION_ID="<subscription-id>"
KUBECONFIG_ARC="$HOME/.kube/tiras-cloud-dev-arc"
```

Log in as pilot user:

```bash
az login --tenant "$TENANT_ID"
az account set --subscription "$SUBSCRIPTION_ID"
```

Start Arc proxy and leave this terminal open:

```bash
az connectedk8s proxy \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --file "$KUBECONFIG_ARC"
```

In second terminal, send Kubernetes requests through generated kubeconfig:

```bash
export KUBECONFIG="$KUBECONFIG_ARC"

kubectl get pods -n tirascloud-dev
```

Expected:

- Browser/device login flow authenticates signed-in Entra user.
- `kube-aad-proxy` forwards request to cluster API server.
- Arc Guard authorizes request through Azure RBAC.

Якщо user отримує Azure access error до того, як Kubernetes request дійшов до cluster, перевірити `Azure Arc Enabled Kubernetes Cluster User Role` assignment на Arc cluster resource scope.

Якщо user отримує Kubernetes `forbidden`, перевірити Arc Kubernetes data-plane role assignment scope, наприклад `$ARM_ID/namespaces/tirascloud-dev` for Viewer.

## Configure MicroK8s API server

Виконувати тільки після:

- Arc is `Connected`.
- Azure RBAC is enabled.
- `guard` is running.
- `azure-arc-guard-manifests` exists in `kube-system`.
- Maintenance window is active.

Create rollback backup:

```bash
sudo mkdir -p /secure-backups/k8s-entra-arc-poc/apiserver

sudo cp /var/snap/microk8s/current/args/kube-apiserver \
  "/secure-backups/k8s-entra-arc-poc/apiserver/kube-apiserver.$(date -u +%Y%m%dT%H%M%SZ)"
```

Write Guard webhook files onto node:

```bash
sudo install -d -m 0755 /var/snap/microk8s/current/credentials/azure-arc-guard

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret azure-arc-guard-manifests -n kube-system -o jsonpath='{.data.guard-authn-webhook\.yaml}' \
  | base64 -d \
  | sudo tee /var/snap/microk8s/current/credentials/azure-arc-guard/guard-authn-webhook.yaml >/dev/null

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get secret azure-arc-guard-manifests -n kube-system -o jsonpath='{.data.guard-authz-webhook\.yaml}' \
  | base64 -d \
  | sudo tee /var/snap/microk8s/current/credentials/azure-arc-guard/guard-authz-webhook.yaml >/dev/null

sudo chmod 0644 /var/snap/microk8s/current/credentials/azure-arc-guard/*.yaml
```

Edit `/var/snap/microk8s/current/args/kube-apiserver`:

```bash
sudo vi /var/snap/microk8s/current/args/kube-apiserver
```

Ensure these settings are present:

```text
--authorization-mode=Node,RBAC,Webhook
--authentication-token-webhook-config-file=/var/snap/microk8s/current/credentials/azure-arc-guard/guard-authn-webhook.yaml
--authentication-token-webhook-cache-ttl=5m0s
--authentication-token-webhook-version=v1
--authorization-webhook-cache-authorized-ttl=5m0s
--authorization-webhook-config-file=/var/snap/microk8s/current/credentials/azure-arc-guard/guard-authz-webhook.yaml
--authorization-webhook-version=v1
```

Restart API server:

```bash
sudo snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
```

MicroK8s 1.21 and later consolidate API server into `daemon-kubelite`. Якщо service name differs, confirm first:

```bash
snap services microk8s
```

Verify local admin still works:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" auth can-i '*' '*' --all-namespaces
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get nodes
```

## Pilot verification matrix

Виконати user tests після role assignment propagation.

Viewer expected results:

```bash
export KUBECONFIG="$HOME/.kube/tiras-cloud-dev-arc"

kubectl get pods -n tirascloud-dev
kubectl get deploy -n tirascloud-dev
kubectl get secret -n tirascloud-dev
kubectl delete pod -n tirascloud-dev --all
```

Expected:

- `get pods` succeeds.
- `get deploy` succeeds.
- `get secret` is forbidden.
- `delete pod` is forbidden.

Cluster admin expected results:

```bash
export KUBECONFIG="$HOME/.kube/tiras-cloud-dev-arc"

kubectl get pods -A
kubectl auth can-i '*' '*' --all-namespaces
```

Expected:

- All commands succeed.

Revoke test:

```bash
az role assignment list \
  --assignee "$VIEWER_GROUP_ID" \
  --scope "$ARM_ID/namespaces/tirascloud-dev" \
  --query "[].id" \
  -o tsv
```

Delete returned Viewer assignment ID:

```bash
az role assignment delete --ids "<viewer-role-assignment-id>"
```

Expected after propagation:

```bash
kubectl get pods -n tirascloud-dev
```

Viewer user is forbidden.

## Audit path

Azure-side audit:

```bash
az monitor activity-log list \
  --resource-group rg-tirascloud-dev-arc-poc \
  --max-events 50 \
  -o table
```

Expected Azure-side evidence:

- role assignment create/delete events;
- Azure RBAC feature enable/disable events;
- actor, timestamp, resource scope and operation result.

Kubernetes API audit required before this PoC can claim end-to-end audit coverage. Kubernetes audit records are generated by `kube-apiserver`; if `--audit-policy-file` is omitted, no Kubernetes API audit events are logged.

Minimal local MicroK8s audit setup:

```bash
sudo mkdir -p /var/snap/microk8s/current/args/audit
sudo mkdir -p /var/log/kubernetes/audit

sudo tee /var/snap/microk8s/current/args/audit/audit-policy.yaml >/dev/null <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: None
    users:
      - system:kube-proxy
      - system:node-proxier
    verbs:
      - watch
  - level: Metadata
    resources:
      - group: ""
        resources:
          - secrets
          - configmaps
      - group: rbac.authorization.k8s.io
        resources:
          - roles
          - rolebindings
          - clusterroles
          - clusterrolebindings
  - level: Metadata
    verbs:
      - create
      - update
      - patch
      - delete
      - deletecollection
  - level: Metadata
EOF
```

Back up API server args before editing:

```bash
sudo mkdir -p /secure-backups/k8s-entra-arc-poc/apiserver

sudo cp /var/snap/microk8s/current/args/kube-apiserver \
  "/secure-backups/k8s-entra-arc-poc/apiserver/kube-apiserver.audit.$(date -u +%Y%m%dT%H%M%SZ)"
```

Add these flags to `/var/snap/microk8s/current/args/kube-apiserver`:

```text
--audit-policy-file=/var/snap/microk8s/current/args/audit/audit-policy.yaml
--audit-log-path=/var/log/kubernetes/audit/audit.log
--audit-log-maxage=30
--audit-log-maxbackup=10
--audit-log-maxsize=100
```

Restart and verify:

```bash
sudo snap restart microk8s.daemon-kubelite
microk8s status --wait-ready

microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -n tirascloud-dev

sudo test -s /var/log/kubernetes/audit/audit.log
sudo tail -20 /var/log/kubernetes/audit/audit.log
```

Expected Kubernetes-side evidence:

- local raw audit events include authenticated user in `user.username`;
- Filebeat/Kibana audit events include parsed audit object under `kubernetes.audit`, for example `kubernetes.audit.user.username`;
- events include `verb`, `objectRef`, `sourceIPs`, `responseStatus` and timestamps;
- denied Viewer requests appear with forbidden response status after Viewer denial test.

Kibana shipping status:

- GitOps Filebeat (`cluster/platform/eck-filebeat`) collects `/var/log/containers/*.log`.
- GitOps Filebeat also tails `/var/log/kubernetes/audit/*.log`, parses each JSON line into `kubernetes.audit`, and tags those events with `log_source: kubernetes_api_audit`.
- To claim Kibana audit coverage, Filebeat Argo CD app must be `Synced` and `Healthy`, MicroK8s API audit logging must be enabled, and audit events must appear in Kibana data view `logs-k8s-*`.

Kibana shipping verification:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" -n argocd get app eck-filebeat
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" -n elastic-stack get beat,pods | grep filebeat
FILEBEAT_POD=$(microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" -n elastic-stack get pods --no-headers | awk '/filebeat/ {print $1; exit}')
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" -n elastic-stack logs "$FILEBEAT_POD" --tail=100
```

Kibana query:

```text
log_source: kubernetes_api_audit
kubernetes.audit.responseStatus.code: 403
```

Audit ownership decision still open:

- who reviews denied access events;
- how long audit logs are retained in Elasticsearch;
- whether local host audit files are included in backups;
- whether Kubernetes audit logs should be split into a dedicated data stream.

## Rollback

Azure role rollback:

```bash
az role assignment list --scope "$ARM_ID" --query "[].id" -o tsv
az role assignment delete --ids "<role-assignment-id>"
```

Disable Azure RBAC feature if feature must be backed out:

```bash
az connectedk8s disable-features \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --features azure-rbac \
  --kube-config "$ARC_KUBECONFIG"
```

MicroK8s API server rollback:

```bash
sudo cp /secure-backups/k8s-entra-arc-poc/apiserver/<backup-file> \
  /var/snap/microk8s/current/args/kube-apiserver

sudo snap restart microk8s.daemon-kubelite
microk8s status --wait-ready
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get nodes
```

Full Arc cleanup:

```bash
az connectedk8s delete \
  --name tiras-cloud-dev \
  --resource-group rg-tirascloud-dev-arc-poc \
  --kube-config "$ARC_KUBECONFIG" \
  --yes
```

## Jenkins delivery

Для самого Arc access PoC Jenkins application delivery не очікується. Єдина GitOps-managed runtime change у цьому PoC - platform Filebeat input для MicroK8s API audit logs.

Verification:

```bash
git diff -- foundation/runbooks/entra-arc-microk8s-rbac-poc.md cluster/platform/eck-filebeat/filebeat.yaml cluster/platform/eck-filebeat/README.md
```

## Argo CD sync

Arc agents installed by Azure CLI and Helm, not by this repo. Argo CD sync expected only for existing `eck-filebeat` application after audit log input change is merged.

Verification:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get applications -n argocd
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" -n argocd get app eck-filebeat
```

Expected:

- Existing application health is unchanged.
- No new Argo CD child application required for Azure Arc.
- `eck-filebeat` becomes `Synced` and `Healthy` after audit input change is applied.

## Runtime workload checks

Verify existing app workload health is not regressed:

```bash
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get pods -n tirascloud-dev
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get svc -n tirascloud-dev
microk8s kubectl --kubeconfig "$ARC_KUBECONFIG" get events -n tirascloud-dev --sort-by=.lastTimestamp | tail -80
```

## Rendered kustomize output

This PoC updates existing GitOps-managed Filebeat manifest so Kubernetes API audit files can reach Logstash/Kibana. Validate rendered output before merge:

```bash
kubectl kustomize cluster/platform/eck-filebeat
kubectl kustomize cluster/clusters/dev
```

On Windows PowerShell, use Windows-style path if `kubectl kustomize` fails to resolve directory:

```powershell
kubectl kustomize .\cluster\platform\eck-filebeat
kubectl kustomize .\cluster\clusters\dev
```

## Production readiness limitations

Фіксувати ці обмеження навіть якщо PoC passes.

- Arc dependency: Entra-authenticated `kubectl` access залежить від Azure Arc agents, Azure control plane availability і outbound connectivity to Arc/Azure endpoints.
- Bootstrap fragility: перший install failed at identity certificate bootstrap with `HCRP403`; clean delete and reconnect resolved issue, але repeat failures треба escalate with HIS tracking IDs.
- MicroK8s CA issue: PoC kubeconfig uses `insecure-skip-tls-verify=true` to work around Azure CLI validation of MicroK8s API server certificate. Production requires proper trusted CA/certificate path.
- API server maintenance: enabling Azure RBAC requires editing MicroK8s `kube-apiserver` args and restarting API server during maintenance window.
- Break-glass access: keep local admin kubeconfig path that bypasses Entra/Arc available only to trusted cluster operators.
- Guard certificate rotation: Arc Guard webhook certificate files copied to disk must be refreshed before expiry and after Guard certificate renewal.
- Role propagation: Azure role assignments and revocations can take several minutes to affect Kubernetes authorization.
- Namespace-scoped roles: use Azure CLI for namespace-scoped Arc Kubernetes roles such as `$ARM_ID/namespaces/tirascloud-dev`.
- Audit gap: local Kubernetes API audit can be enabled in MicroK8s, and Filebeat is configured to collect `/var/log/kubernetes/audit/*.log`, but Kibana coverage is not proven until Filebeat change is synced and audit events are visible in `logs-k8s-*`.
- Group hygiene: keep pilot users in minimum required Entra groups; excessive group membership can complicate Entra token/authorization behavior.
- No public exposure: this PoC must not expose Kubernetes API publicly. Use Arc cluster connect for remote user access.

## Final decision template

Заповнити після live tests.

```text
Decision: PASS | FAIL | INCONCLUSIVE
Date:
Operator:

Arc bootstrap:
- Evidence:
- Result:

Azure RBAC feature:
- Evidence:
- Result:

Viewer grant:
- Evidence:
- Result:

Viewer deny:
- Evidence:
- Result:

Admin grant:
- Evidence:
- Result:

Revoke:
- Evidence:
- Result:

Azure activity audit:
- Evidence:
- Result:

Kubernetes API audit:
- Evidence:
- Result:

Rollback:
- Evidence:
- Result:

Production blockers:
-

Accepted limitations:
-
```

## Unresolved decisions

- Ports: no new inbound public port should be opened for this PoC.
- Persistence: Arc agent data is managed by Arc Helm release; no GitOps PVC planned.
- Secret workflow: Arc-generated secrets must remain generated by Arc; do not commit them.
- Public exposure: no public Kubernetes API exposure approved.
- Log retention: Kubernetes API audit retention is not defined.
- Health checks: Arc health gate is `ConnectivityStatus=Connected` plus running Arc pods and certificate secrets.
- MicroK8s CA issue: insecure PoC kubeconfig must be replaced with proper CA/certificate path before production use.
- Guard certificate rotation: Azure Arc Guard webhook certificates stored on disk require planned refresh before expiry.

## References

- Azure Arc-enabled Kubernetes quickstart: https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster
- Azure Arc-enabled Kubernetes troubleshooting: https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/troubleshooting
- Azure Arc-enabled Kubernetes network requirements: https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/network-requirements
- Azure RBAC on Azure Arc-enabled Kubernetes: https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/azure-rbac
- `az connectedk8s` CLI reference: https://learn.microsoft.com/en-us/cli/azure/connectedk8s
