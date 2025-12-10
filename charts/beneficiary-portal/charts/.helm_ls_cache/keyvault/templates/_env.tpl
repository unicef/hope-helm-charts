{{- define "keyvault.secretRef" }}
{{- if .Values.keyvault.enabled }}
- secretRef:
    name: {{ .Values.keyvault.secretName | default "keyvault-secret" }}
{{- end }}
{{- end }}
