# HOPE Helm Charts

This repository contains Helm charts for deploying components of the HOPE project. The currently supported charts are:
- **Aurora**: Beneficiary Data collection tool
- **Core**: Main infrastructure and application services.
- **Deduplication Engine**: Service to handle data deduplication.
- **Payment Gateway**: Service to integrate core service with FSPs.
- **Reporting**: Reporting services for data analytics.
- **Status**: Service for status monitoring of other services.
- **Workspace**: Service managing data imports and beneficiaries.

## Prerequisites
- Kubernetes Cluster (Tested on AKS)
- Helm installed
- Supported architecture: `amd64`

## KeyVault
Typically, Azure KeyVault is used to retrieve secrets in deployments, but it is not a strict requirement. The charts use the [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) to communicate with Azure KeyVault for secure secret management across different services.

## Testing charts locally

Before publishing, you can validate and render charts locally:

1. **Update dependencies and lint** (same as CI):
   ```bash
   cd hope-helm-charts
   for chart in core deduplication-engine reporting workspace payment-gateway status aurora; do
     helm dependency update charts/$chart
     helm lint charts/$chart \
       --set keyvault.tenantId=foo \
       --set keyvault.userAssignedIdentityID=bar \
       --set keyvault.keyvaultName=baz \
       --set keyvault.envMappings=null
   done
   ```

2. **Render templates** (no cluster needed) to inspect manifests:
   ```bash
   # Render full chart (use keyvault placeholders if keyvault.enabled)
   helm template hope charts/core -f charts/core/values.yaml \
     --set keyvault.tenantId=foo --set keyvault.userAssignedIdentityID=bar \
     --set keyvault.keyvaultName=baz --set keyvault.envMappings=null \
     --set redis.master.extraVolumes[0].name=redis-conf \
     --set redis.master.extraVolumes[0].configMap.name=hope-redis-config \
     | head -200
   ```
   To only check the Redis ConfigMap: `helm template hope charts/core -f charts/core/values.yaml -s templates/redis-config-configmap.yaml`

3. **Dry-run install** (validates against a real cluster if you have one):
   ```bash
   helm install hope charts/core -f charts/core/values.yaml --dry-run --debug \
     --set keyvault.tenantId=foo --set keyvault.userAssignedIdentityID=bar \
     --set keyvault.keyvaultName=baz --set keyvault.envMappings=null
   ```

## Usage
Add Helm repo:
```bash
helm repo add hope https://unicef.github.io/hope-helm-charts
```

Deploy the charts using Helm:
```bash
helm install <release-name> ./charts/<chart-name>
```

Make sure to configure the necessary values for each chart.

## Releasing new chart version

1. Bump chart version manually in `Chart.yaml` file within the chart folder.
2. Release new version with `./scripts/package.sh <name-of-chart>`.
3. Bump used chart version to the new one in deployment pipeline configuration.

## Issues
As this is freshly open-sourced, some features may be missing in the charts. Please open an issue for additional details or feature requests regarding the charts or the README.
