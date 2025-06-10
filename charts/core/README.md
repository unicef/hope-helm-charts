# HOPE Core Helm Chart

This is the helm chart for the HOPE core service - [https://github.com/unicef/hope](https://github.com/unicef/hope).

## Installation

To install the chart, you can use the following command:

```bash
helm repo add hope https://unicef.github.io/hope-helm-charts
helm install hope/core -f values.yaml --timeout 10m0s
```

You should set the timeout to 10m because 5m (default) can be not enough in a default setup - tested in AKS cluster.
You can port-forward the service to access it locally:

```bash
kubectl port-forward svc/core-backend 8000:80
```

And visit [http://localhost:8000](http://localhost:8000) to see the service.

From that point, you'll need to create the BusinessArea via admin (`/api/unicorn`), assign the role (e.g. with all permissions) to the user and visit the home page.

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

Remember that Azure does not allow you to use underscores in the secret names.

### Flower

If you want to enable Flower, you can set the following values:

```yaml
flower:
  enabled: true
  secret:
    FLOWER_BASIC_AUTH: "username:password"
```

### Backend

If you want to make your environment a demonstrative one, you can set the following values:

```yaml
backend:
  job:
    preUpgrade:
      command: python3 manage.py initdemo
```

This will clear your database each time you upgrade and fill it with some demo data. Use with caution.

### Ingress & Nginx

If you want to expose your service to the internet (e.g. with Azure Application Gateway), you can set the following values:

```yaml
ingress:
  enabled: true
  host: your.domain.com
  className: azure-application-gateway
  annotations:
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    appgw.ingress.kubernetes.io/appgw-ssl-certificate: name-of-your-cert

nginx:
  enabled: false
```

By default, nginx is enabled and ingress disabled, meaning that the service will be exposed internally only.
