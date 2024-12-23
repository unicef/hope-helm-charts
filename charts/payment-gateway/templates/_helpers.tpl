{{/*
Expand the name of the chart.
*/}}
{{- define "payment-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "payment-gateway.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "payment-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "payment-gateway.labels" -}}
helm.sh/chart: {{ include "payment-gateway.chart" . }}
{{ include "payment-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "payment-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "payment-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "payment-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "payment-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "payment-gateway.decodeCerts" -}}
- name: decode-certs
  image: busybox
  command:
    - sh
    - -c
    - |
      mkdir -p /certs
      base64 -d /certs-encoded/tls.crt > /certs/tls.crt
      base64 -d /certs-encoded/tls.key > /certs/tls.key
  volumeMounts:
    - name: tls-certs-encoded
      mountPath: /certs-encoded
    - name: tls-certs
      mountPath: /certs
{{- end }}

{{- define "payment-gateway.tlsVolumes" -}}
- name: tls-certs
  emptyDir: {}

- name: tls-certs-encoded
  secret:
    secretName: {{ .Values.keyvault.secretName | default "keyvault-secret" }}
    items:
      - key: TLS_CERT
        path: tls.crt
      - key: TLS_KEY
        path: tls.key
{{- end }}

{{- define "payment-gateway.tlsVolumeMounts" -}}
- name: tls-certs
  mountPath: /certs
  readOnly: true
{{- end }}