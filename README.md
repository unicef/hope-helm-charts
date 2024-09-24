# HOPE Helm Charts

This repository contains Helm charts for deploying components of the HOPE project. The currently supported charts are:
- **Core**: Main infrastructure and application services.
- **Deduplication Engine**: Service to handle data deduplication.
- **Reporting**: Reporting services for data analytics.

## Prerequisites
- Kubernetes Cluster (Tested on AKS)
- Helm installed
- Supported architecture: `amd64`

## KeyVault
Typically, Azure KeyVault is used to retrieve secrets in deployments, but it is not a strict requirement. The charts use the [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) to communicate with Azure KeyVault for secure secret management across different services.

## Usage
Deploy the charts using Helm:
```bash
helm install <release-name> ./charts/<chart-name>
```

Make sure to configure the necessary values for each chart.

## Issues
As this is freshly open-sourced, some features may be missing in the charts. Please open an issue for additional details or feature requests regarding the charts or the README.
