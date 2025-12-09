# HOPE Deduplication Engine Helm Chart

This is the helm chart for the HOPE deduplication engine service - [https://github.com/unicef/hope-beneficiary-portal/](https://github.com/unicef/hope-beneficiary-portal/) which handles data deduplication tasks within the HOPE project.

## Installation

To install the chart, you can use the following command:

```bash
helm install hope-beneficiary-portal https://unicef.github.io/hope-helm-charts/ -f values.yaml
```

The engine's config should be reflected in the Core chart as backend's environment: `BENEFICIARY_PORTAL_API_URL` and `BENEFICIARY_PORTAL_API_KEY` (typically configured via configmap and kevault secret, respectively).

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

### Flower

If you want to enable Flower, you can set the following values:

```yaml
flower:
  enabled: true
  secret:
    FLOWER_BASIC_AUTH: "basic:auth"
```

### Ingress

If you want to expose the service via Ingress, you can set the following values:

```yaml
ingress:
  enabled: true
  annotations:
    appgw.ingress.kubernetes.io/appgw-ssl-certificate: cert-name
  host: your.domain.com
```

