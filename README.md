# HOPE Helm Charts

This repository contains Helm charts for deploying components of the HOPE project. The currently supported charts are:
- **Core**: Main infrastructure and application services.
- **Deduplication Engine**: Service to handle data deduplication.
- **Payment Gateway**: Service to integrate core service with FSPs.
- **Reporting**: Reporting services for data analytics.
- **Workspace**: Service managing data imports and beneficiaries.

## Prerequisites
- Kubernetes Cluster (Tested on AKS)
- Helm installed
- Supported architecture: `amd64`

## KeyVault
Typically, Azure KeyVault is used to retrieve secrets in deployments, but it is not a strict requirement. The charts use the [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) to communicate with Azure KeyVault for secure secret management across different services.

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
