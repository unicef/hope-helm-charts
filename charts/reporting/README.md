# HOPE Reporting Helm Chart

This Helm chart is used to deploy the HOPE reporting service - [https://github.com/unicef/hope-country-report](https://github.com/unicef/hope-country-report). The reporting service depends on the HOPE core service and requires access to its database. Additionally, it needs a valid Azure SAS token to function correctly.

## Installation

To install the reporting service, use the following command:

```bash
helm repo add hope https://unicef.github.io/hope-helm-charts
helm install hope/reporting -f values.yaml
```

Ensure the HOPE core service is running and accessible before deploying the reporting service.

## Configuration

### Environment Variables

The reporting service requires the following environment variables to be configured:

```yaml
env:
  DATABASE_HOPE_URL: "postgres://your-user:your-password@your-db-host:5432/your-database"
  HOPE_AZURE_SAS_TOKEN: "your-azure-sas-token"
```

- `DATABASE_HOPE_URL`: This should be the URL to the HOPE core service's database.
- `HOPE_AZURE_SAS_TOKEN`: This token is required to access Azure resources securely.

You can provide them via the keyvault.

### Dependencies

Make sure the HOPE core service is running and properly configured before deploying the reporting service. The reporting service depends on the core service's database and other resources to function correctly.

## pq-runner (user Python code)

`pqRunner` adds a dedicated Celery worker, `<fullname>-pq-runner`, that executes user Python code when the application runs with `POWER_QUERY_EXECUTION_MODE=runner`. It is disabled by default; while `pqRunner.enabled: false` the chart renders the same manifests as before, apart from the `helm.sh/chart` version label.

The chart never sets `POWER_QUERY_EXECUTION_MODE`. Set it per environment in `backend.config` (and for the runner via `pqRunner.backendConfigKeys` or `pqRunner.config`) only after the runner is deployed and consuming its queue.

### What gets rendered

| Resource | Name |
|---|---|
| Deployment | `<fullname>-pq-runner` (pod label `service: pq-runner`) |
| ConfigMap | `<fullname>-pq-runner` |
| SecretProviderClass | `<pqRunner.keyvault.resourceName>-secret-provider`, default `<fullname>-pq-runner-secret-provider` |
| Secret (synced by the CSI driver) | `pqRunner.keyvault.secretName`, default `<fullname>-pq-runner-secret` |
| ServiceAccount | `<fullname>-pq-runner` (when `pqRunner.serviceAccount.create`) |
| ScaledObject | `<fullname>-pq-runner` (when `pqRunner.keda.enabled`) |

### Isolation

- The runner's `envFrom` holds only its own Secret and its own ConfigMap. It never gets the backend `keyvault-secret`, the backend SecretProviderClass or the `<fullname>-backend` ConfigMap. There is no `env`, `envFrom`, `podAnnotations` or `podLabels` value; setting one fails the render.
- Non-secret env: only the keys listed in `pqRunner.backendConfigKeys` are copied from `backend.config` (each must exist there), plus `pqRunner.config`, which wins on conflict.
- Secrets: only `pqRunner.keyvault.envMappings`. Key Vault name, tenant and identity fall back to the top-level `keyvault` block; mappings never do.
- Rejected in `envMappings`, `backendConfigKeys` and `config` (case-insensitive): `MAILJET_*`, `AZURE_CLIENT_*`, `AZURE_TENANT_ID`, `*_AZURE_ACCOUNT_KEY`, `HOPE_AZURE_SAS_TOKEN`, `FLOWER_BASIC_AUTH`. `DATABASE_URL`, `DATABASE_HOPE_URL` and `SECRET_KEY` are allowed only from Key Vault, never from a ConfigMap.
- `envMappings` may not reuse a backend Key Vault object (names compared case-insensitively, as in Key Vault) that the backend maps to one of the keys above, or to `DATABASE_URL` / `DATABASE_HOPE_URL`: the runner needs its own PostgreSQL role and its own Key Vault object. Reusing other backend objects, such as `SECRET_KEY`, is not blocked.
- `POWER_QUERY_RUNNER` (it lets a process run `preview_query`) belongs to the runner only: `pqRunner.config` or `pqRunner.keyvault.envMappings`. On every render, also with `pqRunner.enabled: false`, the chart rejects it for the regular backend/worker/beat/flower/job: in `backend.config` unless explicitly inactive (empty, `0`, `false`, `no`, `off`, `n`), and in `keyvault.envMappings` whatever the secret holds. Enforced by `values.schema.json` (so `helm lint` fails too; `helm lint` ignores `fail()`) and by a template check that still applies with `--skip-schema-validation`.
- Always a dedicated ServiceAccount (never `default` or the backend's). `automountServiceAccountToken: false` on both the pod and the ServiceAccount.
- Security context, fixed in the template: pod `runAsNonRoot: true`, `seccompProfile: RuntimeDefault`; container `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `privileged: false`, `capabilities.drop: [ALL]`. Only `pqRunner.podSecurityContext.runAsUser`, `runAsGroup` and `fsGroup` are configurable (non-zero integers, default 1030); any other key, or a `pqRunner.securityContext`, fails the render.
- Writable paths: `/tmp` (`pqRunner.tmpVolume`, an `emptyDir`), plus `extraVolumes` / `extraVolumeMounts`. `extraVolumes` entries may only be `{name, emptyDir}`, so no Secret, ConfigMap, CSI, projected (ServiceAccount token) or hostPath volume can be added.
- `nodeSelector`, `affinity` and `tolerations` are passed through as-is; they choose where the pod runs, so review them like any other scheduling change.

Known limitations, not solved by this chart:

- Azure: the keyvault library uses the node's user-assigned managed identity (`useVMManagedIdentity`), so a separate SecretProviderClass isolates Kubernetes Secrets, not Azure access. Code running in the pod can still reach the instance metadata endpoint (169.254.169.254) unless network policy blocks it. Managed identity isolation (Workload Identity, a separate identity or Key Vault) is not implemented.
- Network: the chart adds no NetworkPolicy. The runner needs the Celery broker, so code in it can reach Redis (unauthenticated in these deployments) and could publish tasks to other queues, including the regular worker's, which runs with the full backend secrets.
- The key checks match env var names only. A secret under a harmless name from a Key Vault object the backend does not map, or a credential embedded in an allowlisted `backend.config` value, is not detected.

### Required values (to be confirmed by the country-report developers)

The chart does not guess application parameters. With `pqRunner.enabled: true`, `helm template` fails until these are set:

- `pqRunner.queue`: the runner's Celery queue. It must differ from `celery.keda.listName`, the regular worker's queue.
- `pqRunner.command` and/or `pqRunner.args`: the runner start command. The chart does not add `-Q <queue>`, so the queue has to be part of the command. The regular worker runs `args: ["worker"]` and its queues are set by the image, so the developers must confirm that it does not also consume the runner queue.
- `pqRunner.keyvault.envMappings`: the runner-only Key Vault objects (for example its own `DATABASE_URL` with a restricted PostgreSQL role), unless `pqRunner.keyvault.enabled: false`.
- `pqRunner.backendConfigKeys` / `pqRunner.config`: the non-secret settings the runner needs.

Also to confirm: the image has UID/GID 1030 and works on a read-only root filesystem (extra writable paths go to `extraVolumes`), plus resources, concurrency (`pqRunner.keda.listLength`) and `terminationGracePeriodSeconds`.

### Scaling

- Without KEDA (`pqRunner.keda.enabled: false`) the Deployment has a fixed `pqRunner.replicaCount`.
- With KEDA, the ScaledObject watches the runner queue (`pqRunner.keda.listName`, default `pqRunner.queue`). Empty `address`, `databaseIndex` and `enableTLS` fall back to `celery.keda`. Keep `minReplicaCount` at 1 or more: the CSI driver syncs the runner Secret only while a pod mounts it.

### Example

```yaml
pqRunner:
  enabled: true
  queue: <runner queue>             # from the developers
  args: [<runner start command>]    # from the developers
  backendConfigKeys:
    - CELERY_BROKER_URL
  keyvault:
    envMappings:
      - name: <KV object with the runner's restricted DATABASE_URL>
        key: DATABASE_URL
  keda:
    enabled: true                   # or false with replicaCount for clusters without KEDA
```

### Enabling order

1. Developers confirm the values above; DBA creates the restricted PostgreSQL role; Ops creates the runner Key Vault objects.
2. Deploy with `pqRunner.enabled: true`, without changing `POWER_QUERY_EXECUTION_MODE`. Check that the pod runs as 1030, has no Mailjet/Azure variables and consumes its queue.
3. Then set `POWER_QUERY_EXECUTION_MODE=runner`, one environment at a time. Roll back the same way: switch the mode back first, then disable the runner.
