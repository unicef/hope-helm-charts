{{/*
Expand the name of the chart.
*/}}
{{- define "core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "core.fullname" -}}
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
{{- define "core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "core.labels" -}}
helm.sh/chart: {{ include "core.chart" . }}
{{ include "core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common backend environment configuration
*/}}
{{- define "core.backend.envConfig" -}}
- secretRef:
    name: {{ include "core.fullname" . }}-backend
- configMapRef:
    name: {{ include "core.fullname" . }}-backend
{{ include "keyvault.secretRef" . }}
{{- end }}

{{/*
Full image name for the core app
*/}}
{{- define "core.backend.image" -}}
{{- printf "%s:%s" .Values.backend.image.repository .Values.backend.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "core.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "core.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "core.scriptVolume" -}}
- name: script-volume
  configMap:
    name: {{ include "core.fullname" . }}-scripts
    items:
      - key: check.sh
        path: check.sh
{{- end -}}

{{- define "core.scriptVolumeMount" -}}
- name: script-volume
  mountPath: /scripts/check.sh
  subPath: check.sh
{{- end -}}

{{- define "core.checkingContainer" -}}
- name: init
  image: postgres:15-alpine
  command: ["sh", "/scripts/check.sh"]
  volumeMounts:
  {{- include "core.scriptVolumeMount" . | nindent 4 }}
  env:
    {{- if .Values.postgresql.enabled }}
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: {{ include "core.fullname" . }}-backend
          key: DATABASE_URL
    {{- else if not .Values.keyvault.enabled -}}
    - name: DATABASE_URL
      value: {{ .Values.backend.databaseUrl | quote }}
    {{- else }}
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: {{ .Values.keyvault.secretName }}
          key: DATABASE_URL
    {{- end }}

    {{- if .Values.valkey.enabled }}
    - name: CELERY_BROKER_URL
      valueFrom:
        secretKeyRef:
          name: {{ include "core.fullname" . }}-backend
          key: CELERY_BROKER_URL
    - name: CELERY_RESULT_BACKEND
      valueFrom:
        secretKeyRef:
          name: {{ include "core.fullname" . }}-backend
          key: CELERY_RESULT_BACKEND
    - name: CACHE_LOCATION
      valueFrom:
        secretKeyRef:
          name: {{ include "core.fullname" . }}-backend
          key: CACHE_LOCATION
    - name: CONSTANCE_REDIS_CONNECTION
      valueFrom:
        secretKeyRef:
          name: {{ include "core.fullname" . }}-backend
          key: CONSTANCE_REDIS_CONNECTION
    {{- else if not .Values.keyvault.enabled -}}
    - name: CELERY_BROKER_URL
      value: {{ .Values.backend.celeryBrokerUrl | quote }}
    - name: CELERY_RESULT_BACKEND
      value: {{ .Values.backend.celeryResultBackend | quote }}
    - name: CACHE_LOCATION
      value: {{ .Values.backend.cacheLocation | quote }}
    - name: CONSTANCE_REDIS_CONNECTION
      value: {{ .Values.backend.constanceRedisConnection | quote }}
    {{- else }}
    - name: CELERY_BROKER_URL
      valueFrom:
        secretKeyRef:
          name: {{ .Values.keyvault.secretName }}
          key: CELERY_BROKER_URL
    - name: CELERY_RESULT_BACKEND
      valueFrom:
        secretKeyRef:
          name: {{ .Values.keyvault.secretName }}
          key: CELERY_RESULT_BACKEND
    - name: CACHE_LOCATION
      valueFrom:
        secretKeyRef:
          name: {{ .Values.keyvault.secretName }}
          key: CACHE_LOCATION
    - name: CONSTANCE_REDIS_CONNECTION
      valueFrom:
        secretKeyRef:
          name: {{ .Values.keyvault.secretName }}
          key: CONSTANCE_REDIS_CONNECTION
    {{- end }}

    {{- if .Values.keyvault.enabled }}
    {{- end }}

    {{- if .Values.elasticsearch.enabled }}
    - name: ELASTICSEARCH_HOST
      valueFrom:
        secretKeyRef:
          name: {{ include "core.fullname" . }}-backend
          key: ELASTICSEARCH_HOST
    {{- else if not .Values.keyvault.enabled -}}
    - name: ELASTICSEARCH_HOST
      value: {{ .Values.backend.elasticsearchHost | quote }}
    {{- else }}
    - name: ELASTICSEARCH_HOST
      valueFrom:
        secretKeyRef:
          name: {{ .Values.keyvault.secretName }}
          key: ELASTICSEARCH_HOST
    {{- end }}
{{- end -}}

{{- define "databaseSslCertificate.volumes" -}}
{{- if .Values.databaseSslCertificate.enabled }}
- name: db-ssl-cert-volume
  configMap:
    name: {{ include "core.fullname" . }}-db-ssl-cert
{{- end }}
{{- end -}}

{{- define "databaseSslCertificate.volumeMounts" -}}
{{- if .Values.databaseSslCertificate.enabled }}
- name: db-ssl-cert-volume
  mountPath: /data/psql-cert.crt
  subPath: psql-cert.crt
  readOnly: true
{{- end }}
{{- end -}}