{{- define "keyvault.volumeMounts" }}
{{- if .Values.keyvault.enabled }}
- name: secrets-store01-inline
  mountPath: {{ .Values.keyvault.mountPath | default "/mnt/secrets" }}
  readOnly: true
{{- end }}
{{- end }}

{{- define "keyvault.volumes" }}
{{- if .Values.keyvault.enabled }}
- name: secrets-store01-inline
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ .Values.keyvault.resourceName | default "default-secretproviderclass" }}-secret-provider
{{- end }}
{{- end }}
