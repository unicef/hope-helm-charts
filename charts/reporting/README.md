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
