# HOPE Workspace Helm Chart

This Helm chart is used to deploy the HOPE workspace service - [https://github.com/unicef/hope-country-workspace](https://github.com/unicef/hope-country-workspace).

## Installation

To install the workspace service, use following commands:

```bash
helm repo add hope https://unicef.github.io/hope-helm-charts
helm install hope/workspace -f values.yaml
```

## Configuration

### Key Vault

If you want to get your secrets from Azure Key Vault, you can. Just set the necessary values: `keyvault.enabled`, `keyvault.name`, `keyvault.userAssignedIdentityID` and `keyvault.tenantId`. With that provided, you fill the `envMappings` like that:

```yaml
keyvault:
  enabled: true
  name: name-of-my-kv
  # userAssignedIdentityID: ...
  # tenantId: ...
  envMappings:
    - name: NAME-OF-SECRET-IN-KV
      key: KEY_IN_K8S_SECRET
```
