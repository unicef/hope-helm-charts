{{- define "keyvault.secretProviderClass" }}

{{- if not .Values.keyvault.envMappings }}
{{- fail "envMappings are required" }}
{{- end }}

{{- if not .Values.keyvault.tenantId }}
{{- fail "tenantId is required" }}
{{- end }}

{{- if not .Values.keyvault.name }}
{{- fail "keyvaultName (name) is required" }}
{{- end }}

{{- if not .Values.keyvault.userAssignedIdentityID }}
{{- fail "userAssignedIdentityID is required" }}
{{- end }}

apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: {{ .Values.keyvault.resourceName | default "default-secretproviderclass" }}-secret-provider
spec:
  provider: {{ .Values.keyvault.provider | default "azure" }}
  parameters:
    usePodIdentity: {{ quote .Values.keyvault.usePodIdentity | default "false" }}
    useVMManagedIdentity: {{ quote .Values.keyvault.useVMManagedIdentity | default "true" }}
    userAssignedIdentityID: {{ .Values.keyvault.userAssignedIdentityID }}
    keyvaultName: {{ .Values.keyvault.name }}
    tenantId: {{ .Values.keyvault.tenantId }}
    objects: |
      array:
{{- range .Values.keyvault.envMappings }}
        - objectName: {{ .name }}
          objectType: secret
          objectVersion: {{ .version | default "" }}
{{- end }}
  secretObjects:
  - secretName: {{ .Values.keyvault.secretName | default "keyvault-secret" }}
    type: Opaque
    data:
{{- range .Values.keyvault.envMappings }}
      - objectName: {{ .name }}
        key: {{ .key }}
{{- end }}
{{- end }}
