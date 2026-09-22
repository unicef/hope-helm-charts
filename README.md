# HOPE Helm Charts

Helm charts for deploying the [HOPE (Humanitarian Open-Source Platform for Everybody)](https://github.com/unicef/hope) project on Kubernetes. HOPE is a UNICEF initiative for humanitarian cash-based interventions (CBI) and social protection programs.

Charts are hosted as a Helm repository at:
```
https://unicef.github.io/hope-helm-charts/
```

## Charts

| Chart | Version | Description |
|-------|---------|-------------|
| [core](#core) | 0.14.7 | Main HOPE backend (Django), Celery workers, Redis, Elasticsearch, PostgreSQL |
| [aurora](#aurora) | 0.2.2 | Beneficiary data collection tool |
| [deduplication-engine](#deduplication-engine) | 0.14.8 | Data deduplication service with ML model support |
| [payment-gateway](#payment-gateway) | 0.9.4 | Financial Service Provider (FSP) integration |
| [reporting](#reporting) | 0.14.4 | Reporting and data analytics |
| [workspace](#workspace) | 0.5.4 | Data imports and beneficiary management |
| [status](#status) | 0.1.3 | Service status monitoring |
| [keyvault](#keyvault) | 0.1.3 | Shared library chart for Azure KeyVault integration |

## Prerequisites

- Kubernetes cluster (tested on AKS)
- [Helm](https://helm.sh/docs/intro/install/) v3
- Supported architecture: `amd64`
- [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) installed on the cluster (if using Azure KeyVault)

## Quick Start

### Add the Helm repository

```bash
helm repo add hope https://unicef.github.io/hope-helm-charts
helm repo update
```

### Deploy a chart

```bash
helm install <release-name> hope/<chart-name> \
  --set keyvault.tenantId=<azure-tenant-id> \
  --set keyvault.userAssignedIdentityID=<identity-id> \
  --set keyvault.keyvaultName=<keyvault-name> \
  --set keyvault.envMappings=null
```

Or install from the local repository:

```bash
helm install <release-name> ./charts/<chart-name> -f <custom-values-file>
```

## Chart Details

### KeyVault

All application charts depend on the `keyvault` library chart, which provides shared Helm templates for Azure KeyVault integration via the [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/).

The library provides three templates:
- **SecretProviderClass** - Defines how to fetch secrets from KeyVault
- **Environment injection** - Mounts `secretRef` into container `envFrom`
- **Volume mounts** - Attaches CSI volumes to pods

KeyVault is **optional but recommended**. Charts can also use standard Kubernetes Secrets.

```yaml
keyvault:
  enabled: true
  tenantId: "<azure-tenant-id>"
  userAssignedIdentityID: "<managed-identity-client-id>"
  keyvaultName: "<keyvault-name>"
  envMappings:
    DATABASE_URL: "db-url"
    REDIS_URL: "redis-url"
```

### Core

The main HOPE backend service. Deploys a Django application with Celery workers, Redis, Elasticsearch, and PostgreSQL.

**Dependencies:** PostgreSQL, Redis, Elasticsearch, Prometheus Redis Exporter, KeyVault

**Components:**
- **Backend** - Django application with Nginx sidecar for static files
- **Celery Worker** - Default task worker
- **Celery Periodic Worker** - Scheduled task worker
- **Celery Beat** - Task scheduler
- **Flower** - (optional) Celery monitoring UI

**Key features:**
- Pre-flight init containers that verify DB, Redis, and ES connectivity before startup
- Pre-upgrade jobs for database migrations
- Health checks on `/api/_health`
- Horizontal Pod Autoscaler support
- Ingress support (including Azure Application Gateway)
- Dual Elasticsearch cluster support (ES 8 to ES 9 migration)

```yaml
core:
  backend:
    replicaCount: 2
    image:
      repository: unicef/hope
      tag: core-2.10.1
  celery:
    defaultWorker:
      replicaCount: 2
    periodicWorker:
      replicaCount: 1
  flower:
    enabled: false
  ingress:
    enabled: true
    hosts:
      - host: hope.example.com
        paths:
          - path: /
            pathType: Prefix
```

### Aurora

Beneficiary data collection tool.

**Dependencies:** PostgreSQL, Redis, KeyVault

**Components:** Deployment, Service, ConfigMap, HPA, Ingress, Celery worker/beat, Flower

### Deduplication Engine

Handles data deduplication within HOPE, including ML model support.

**Dependencies:** PostgreSQL, Redis, KeyVault

**Unique features:**
- Model data PVC (Azure Files, 4Gi default) for ML model storage
- Optional data PVC (10Gi) for persistent data at `/var/data`
- Pre-upgrade/post-install job for model downloading (`syncmodels`)
- Rollme support for pod restarts

### Payment Gateway

Integrates the core service with Financial Service Providers (FSPs).

**Dependencies:** PostgreSQL, Redis, KeyVault

**FSP integrations:** MoneyGram, Western Union (configurable via environment variables)

**Docker image:** `unicef/hope-payment-gateway`

### Reporting

Reporting and data analytics service.

**Dependencies:** PostgreSQL, Redis, KeyVault

**Prerequisites:** Requires access to the HOPE core database and an Azure SAS token.

**Docker image:** `unicef/hope-country-report`

### Workspace

Manages data imports and beneficiaries.

**Dependencies:** PostgreSQL, Redis, KeyVault

**Docker image:** `unicef/hope-country-workspace`

### Status

Status monitoring of other HOPE services. The simplest chart in the repository.

**Dependencies:** Redis, KeyVault (no PostgreSQL)

## Configuration

Each chart has its own `values.yaml`. Common configuration patterns across charts:

### Secret Management

Secrets can be provided via:
1. **Azure KeyVault** (recommended) - Set `keyvault.enabled: true`
2. **Kubernetes Secrets** - Set `keyvault.enabled: false` and provide secrets directly

### Redis

All charts deploy Redis with a custom configuration mounted via ConfigMap:
- Append-only mode enabled
- 32 databases
- No authentication (internal cluster only)

### PostgreSQL

Each chart can optionally deploy its own PostgreSQL instance or connect to an external one:

```yaml
postgresql:
  enabled: true          # Set false to use external DB
  auth:
    postgresPassword: "..."
    database: "hope"
```

### Horizontal Pod Autoscaler

Most charts support HPA:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Ingress

```yaml
ingress:
  enabled: true
  className: "azure-application-gateway"
  hosts:
    - host: hope.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: hope-tls
      hosts:
        - hope.example.com
```

## Development

### Testing Charts Locally

**Update dependencies and lint** (same as CI):

```bash
for chart in core deduplication-engine reporting workspace payment-gateway status aurora; do
  helm dependency update charts/$chart
  helm lint charts/$chart \
    --set keyvault.tenantId=foo \
    --set keyvault.userAssignedIdentityID=bar \
    --set keyvault.keyvaultName=baz \
    --set keyvault.envMappings=null
done
```

**Render templates** (no cluster needed):

```bash
# Render full chart
helm template hope charts/core -f charts/core/values.yaml \
  --set keyvault.tenantId=foo \
  --set keyvault.userAssignedIdentityID=bar \
  --set keyvault.keyvaultName=baz \
  --set keyvault.envMappings=null

# Render a specific template
helm template hope charts/core -f charts/core/values.yaml \
  -s templates/redis-config-configmap.yaml
```

**Dry-run install** (validates against a live cluster):

```bash
helm install hope charts/core -f charts/core/values.yaml --dry-run --debug \
  --set keyvault.tenantId=foo \
  --set keyvault.userAssignedIdentityID=bar \
  --set keyvault.keyvaultName=baz \
  --set keyvault.envMappings=null
```

### CI Pipeline

GitHub Actions runs on every push/PR to `main`:
1. Sets up Helm
2. Loops through all charts
3. Runs `helm dependency update` and `helm lint` with KeyVault placeholder values

See [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml).

## Releasing

1. Bump the chart version in `Chart.yaml`
2. Package and publish:
   ```bash
   ./scripts/package.sh <chart-name>
   ```
   This will:
   - Update chart dependencies
   - Package the chart as a `.tgz` into `docs/`
   - Update the Helm repository index (`docs/index.yaml`)

3. Commit and push to `main`
4. Update the chart version in your deployment pipeline configuration

## Repository Structure

```
hope-helm-charts/
├── charts/                    # Helm charts
│   ├── aurora/                # Beneficiary data collection
│   ├── core/                  # Main HOPE backend
│   ├── deduplication-engine/  # Data deduplication
│   ├── keyvault/              # Shared KeyVault library
│   ├── payment-gateway/       # FSP integration
│   ├── reporting/             # Data analytics
│   ├── status/                # Status monitoring
│   └── workspace/             # Data imports
├── docs/                      # Helm repository (GitHub Pages)
│   ├── index.yaml             # Repository index
│   └── *.tgz                  # Packaged chart archives
├── scripts/
│   └── package.sh             # Chart packaging script
└── .github/workflows/
    └── ci.yaml                # CI pipeline
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally using the development instructions above
4. Ensure CI passes
5. Submit a pull request

## Issues

Please open an issue for feature requests, bug reports, or questions about the charts.
