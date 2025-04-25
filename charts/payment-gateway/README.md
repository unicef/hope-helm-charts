# HOPE Payment Gateway Helm Chart

This Helm chart is used to deploy the HOPE payment gateway service - [https://github.com/unicef/hope-payment-gateway](https://github.com/unicef/hope-payment-gateway). 

## Installation

To install the payment gateway service, use following commands:

```bash
helm repo add hope https://unicef.github.io/hope-helm-charts
helm install hope/payment-gateway -f values.yaml
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

### MoneyGram
If you want to use MoneyGram as FSP, make sure to set following environment variables:
```yaml
MONEYGRAM_HOST: ""
MONEYGRAM_CLIENT_ID: ""
MONEYGRAM_PARTNER_ID: ""
MONEYGRAM_REGISTRATION_NUMBER: ""
MONEYGRAM_PUBLIC_KEY: ""
MONEYGRAM_CLIENT_SECRET: "
```

### Western Union
If you want to use Western Union as FSP, make sure to set following environment variables:
```yaml
FTP_WESTERN_UNION_SERVER: ""
FTP_WESTERN_UNION_USERNAME: ""
FTP_WESTERN_UNION_PASSWORD: ""
TLS_CERT: ""
TLS_KEY: ""
WESTERN_UNION_BASE_URL: ""
WESTERN_UNION_CERT: ""
WESTERN_UNION_KEY: ""
```