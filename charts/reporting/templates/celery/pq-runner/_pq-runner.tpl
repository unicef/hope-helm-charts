{{/*
pq-runner: dedicated Celery worker for user Python code.
Isolated from the backend: own ConfigMap, own Key Vault SecretProviderClass/Secret,
own ServiceAccount, no shared backend Secret or ConfigMap. The pod and container
security context is fixed in deployment.yaml; values only choose the ids.
*/}}

{{- define "reporting.pqRunner.enabled" -}}
{{- if dig "enabled" false (.Values.pqRunner | default dict) }}true{{ end }}
{{- end }}

{{- define "reporting.pqRunner.fullname" -}}
{{- printf "%s-pq-runner" (include "reporting.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "reporting.pqRunner.labels" -}}
{{ include "reporting.labels" . }}
service: "pq-runner"
{{- end }}

{{- define "reporting.pqRunner.selectorLabels" -}}
{{ include "reporting.selectorLabels" . }}
service: "pq-runner"
{{- end }}

{{- define "reporting.pqRunner.serviceAccountName" -}}
{{- if .Values.pqRunner.serviceAccount.create }}
{{- default (include "reporting.pqRunner.fullname" .) .Values.pqRunner.serviceAccount.name }}
{{- else }}
{{- .Values.pqRunner.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image: pqRunner.image.* falls back to the main image and tag (the tag set by the pipeline).
*/}}
{{- define "reporting.pqRunner.image" -}}
{{- $img := .Values.pqRunner.image }}
{{- printf "%s:%s" ($img.repository | default .Values.image.repository) ($img.tag | default .Values.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Values for the keyvault library chart, rendered as YAML (use with fromYaml).
Key Vault name, tenant and identity fall back to the top-level keyvault block;
envMappings, resourceName and secretName never do.
*/}}
{{- define "reporting.pqRunner.keyvault" -}}
{{- $pkv := .Values.pqRunner.keyvault }}
{{- $base := .Values.keyvault | default dict }}
{{- $name := include "reporting.pqRunner.fullname" . }}
{{- $out := dict
  "enabled" ($pkv.enabled | default false)
  "resourceName" ($pkv.resourceName | default $name)
  "secretName" ($pkv.secretName | default (printf "%s-secret" $name))
  "mountPath" ($pkv.mountPath | default "/mnt/secrets")
  "envMappings" ($pkv.envMappings | default list) }}
{{- range $k := list "name" "tenantId" "userAssignedIdentityID" "provider" "usePodIdentity" "useVMManagedIdentity" }}
{{- $v := get $pkv $k | default (get $base $k) }}
{{- if $v }}
{{- $_ := set $out $k $v }}
{{- end }}
{{- end }}
{{- toYaml $out }}
{{- end }}

{{/*
Fails rendering on missing or unsafe pq-runner settings. Messages name keys and
Key Vault object names only, never values. Called from every pq-runner template,
so the first error is always one of these, whatever the render order.
*/}}
{{- define "reporting.pqRunner.validate" -}}
{{- $pq := .Values.pqRunner }}
{{- $forbidden := "^(MAILJET_.*|AZURE_CLIENT_.*|AZURE_TENANT_ID|(.*_)?AZURE_ACCOUNT_KEY|HOPE_AZURE_SAS_TOKEN|FLOWER_BASIC_AUTH)$" }}
{{- $secretOnly := list "DATABASE_URL" "DATABASE_HOPE_URL" "SECRET_KEY" }}
{{- $mainQueue := .Values.celery.keda.listName | default "" | toString }}
{{- $count := "^[0-9]+$" }}

{{- /* shape: null or scalar blocks would otherwise fail as nil pointers */}}
{{- range $b := list "image" "keyvault" "keda" "serviceAccount" "podSecurityContext" "tmpVolume" }}
{{- if not (kindIs "map" (get $pq $b)) }}
{{- fail (printf "pqRunner.%s must be a map" $b) }}
{{- end }}
{{- end }}
{{- range $f := list "command" "args" "backendConfigKeys" "extraVolumes" "extraVolumeMounts" }}
{{- if and (get $pq $f) (not (kindIs "slice" (get $pq $f))) }}
{{- fail (printf "pqRunner.%s must be a list" $f) }}
{{- end }}
{{- end }}
{{- if and $pq.config (not (kindIs "map" $pq.config)) }}
{{- fail "pqRunner.config must be a map" }}
{{- end }}
{{- range $k := list "securityContext" "podAnnotations" "podLabels" "env" "envFrom" "volumes" "volumeMounts" }}
{{- if hasKey $pq $k }}
{{- fail (printf "pqRunner.%s is not supported: the runner's security context, env and volumes are fixed by the chart" $k) }}
{{- end }}
{{- end }}

{{- /* queue and start command: must come from the developers */}}
{{- if not (and (kindIs "string" $pq.queue) (trim (toString $pq.queue))) }}
{{- fail "pqRunner.queue is required when pqRunner.enabled=true: the runner's Celery queue name, to be confirmed by the country-report developers" }}
{{- end }}
{{- if eq $pq.queue $mainQueue }}
{{- fail (printf "pqRunner.queue must differ from celery.keda.listName (%s), the regular worker's queue" $mainQueue) }}
{{- end }}
{{- if not (or $pq.command $pq.args) }}
{{- fail "pqRunner.command and/or pqRunner.args are required when pqRunner.enabled=true: without them the container runs the image's default process; the runner start command must come from the country-report developers" }}
{{- end }}

{{- /* numbers */}}
{{- if and (not $pq.keda.enabled) (not (regexMatch $count (toString $pq.replicaCount))) }}
{{- fail "pqRunner.replicaCount must be a non-negative integer when pqRunner.keda.enabled=false" }}
{{- end }}
{{- if and (not (kindIs "invalid" $pq.terminationGracePeriodSeconds)) (not (regexMatch $count (toString $pq.terminationGracePeriodSeconds))) }}
{{- fail "pqRunner.terminationGracePeriodSeconds must be a non-negative integer or null" }}
{{- end }}

{{- /* ids: the rest of the security context is fixed in deployment.yaml */}}
{{- range $k, $_ := $pq.podSecurityContext }}
{{- if not (has $k (list "runAsUser" "runAsGroup" "fsGroup")) }}
{{- fail (printf "pqRunner.podSecurityContext.%s is not configurable: only runAsUser, runAsGroup and fsGroup are" $k) }}
{{- end }}
{{- end }}
{{- range $k := list "runAsUser" "runAsGroup" "fsGroup" }}
{{- if not (regexMatch "^[1-9][0-9]*$" (toString (get $pq.podSecurityContext $k))) }}
{{- fail (printf "pqRunner.podSecurityContext.%s must be a non-zero id (default 1030)" $k) }}
{{- end }}
{{- end }}

{{- /* service account: never the backend's or the namespace default */}}
{{- $sa := include "reporting.pqRunner.serviceAccountName" . }}
{{- if not $sa }}
{{- fail "pqRunner.serviceAccount.name is required when pqRunner.serviceAccount.create=false" }}
{{- end }}
{{- if or (eq $sa "default") (eq $sa (include "reporting.serviceAccountName" .)) }}
{{- fail (printf "pqRunner must use its own ServiceAccount, not %s" $sa) }}
{{- end }}

{{- /* volumes: writable emptyDir only, so no Secret, ConfigMap, CSI, hostPath or token can be mounted */}}
{{- if and $pq.tmpVolume.enabled (not $pq.tmpVolume.mountPath) }}
{{- fail "pqRunner.tmpVolume.mountPath is required when pqRunner.tmpVolume.enabled=true" }}
{{- end }}
{{- range $v := ($pq.extraVolumes | default list) }}
{{- if not (and (kindIs "map" $v) $v.name (hasKey $v "emptyDir") (eq (len (keys $v)) 2)) }}
{{- fail "pqRunner.extraVolumes: only {name, emptyDir} volumes are allowed" }}
{{- end }}
{{- if has $v.name (list "tmp" "secrets-store01-inline") }}
{{- fail (printf "pqRunner.extraVolumes: volume name %s is reserved" $v.name) }}
{{- end }}
{{- end }}

{{- /* Key Vault: own SecretProviderClass and Secret, runner-only objects */}}
{{- if $pq.keyvault.enabled }}
{{- $kv := include "reporting.pqRunner.keyvault" . | fromYaml }}
{{- range $f := list "name" "tenantId" "userAssignedIdentityID" }}
{{- if not (get $kv $f) }}
{{- fail (printf "pqRunner.keyvault.%s (or keyvault.%s) is required when pqRunner.keyvault.enabled=true" $f $f) }}
{{- end }}
{{- end }}
{{- if not $kv.envMappings }}
{{- fail "pqRunner.keyvault.envMappings is required when pqRunner.keyvault.enabled=true: the runner-only Key Vault objects (the list must come from the developers)" }}
{{- end }}
{{- if eq $kv.resourceName (.Values.keyvault.resourceName | default "default-secretproviderclass") }}
{{- fail "pqRunner.keyvault.resourceName must differ from keyvault.resourceName" }}
{{- end }}
{{- if eq $kv.secretName (.Values.keyvault.secretName | default "keyvault-secret") }}
{{- fail "pqRunner.keyvault.secretName must differ from keyvault.secretName" }}
{{- end }}
{{- /* backend object -> keys it feeds; Key Vault object names are case-insensitive */}}
{{- $mainObjects := dict }}
{{- range $m := (.Values.keyvault.envMappings | default list) }}
{{- $n := upper (toString $m.name) }}
{{- $_ := set $mainObjects $n (append (get $mainObjects $n | default list) (upper (toString $m.key))) }}
{{- end }}
{{- $seen := dict }}
{{- range $i, $m := $kv.envMappings }}
{{- if not (and (kindIs "map" $m) $m.name $m.key) }}
{{- fail (printf "pqRunner.keyvault.envMappings[%d] needs both name and key" $i) }}
{{- end }}
{{- $key := upper (toString $m.key) }}
{{- if regexMatch $forbidden $key }}
{{- fail (printf "pqRunner.keyvault.envMappings: key %s is not allowed for pq-runner (Mailjet/Azure/Flower credentials)" $m.key) }}
{{- end }}
{{- if hasKey $seen $key }}
{{- fail (printf "pqRunner.keyvault.envMappings: duplicate key %s" $m.key) }}
{{- end }}
{{- $_ := set $seen $key true }}
{{- range $mk := (get $mainObjects (upper (toString $m.name)) | default list) }}
{{- if or (regexMatch $forbidden $mk) (has $mk (list "DATABASE_URL" "DATABASE_HOPE_URL")) }}
{{- fail (printf "pqRunner.keyvault.envMappings: Key Vault object %s is the backend's %s and is not allowed for pq-runner (own credentials and PostgreSQL role required)" $m.name $mk) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- /* runner ConfigMap: allowlisted backend.config keys and pqRunner.config */}}
{{- $backendConfig := .Values.backend.config | default dict }}
{{- $cmKeys := keys ($pq.config | default dict) }}
{{- range $k := ($pq.backendConfigKeys | default list) }}
{{- if not (hasKey $backendConfig (toString $k)) }}
{{- fail (printf "pqRunner.backendConfigKeys: %s is not set in backend.config" $k) }}
{{- end }}
{{- $cmKeys = append $cmKeys (toString $k) }}
{{- end }}
{{- range $k := $cmKeys }}
{{- if regexMatch $forbidden (upper $k) }}
{{- fail (printf "pqRunner: %s is not allowed in the runner ConfigMap (backendConfigKeys/config)" $k) }}
{{- end }}
{{- if has (upper $k) $secretOnly }}
{{- fail (printf "pqRunner: %s must come from pqRunner.keyvault, not the runner ConfigMap" $k) }}
{{- end }}
{{- end }}

{{- /* KEDA */}}
{{- if $pq.keda.enabled }}
{{- if not ($pq.keda.address | default .Values.celery.keda.address) }}
{{- fail "pqRunner.keda.enabled needs pqRunner.keda.address or celery.keda.address" }}
{{- end }}
{{- if eq (toString ($pq.keda.listName | default $pq.queue)) $mainQueue }}
{{- fail (printf "pqRunner.keda.listName must differ from celery.keda.listName (%s)" $mainQueue) }}
{{- end }}
{{- $min := toString $pq.keda.minReplicaCount }}
{{- $max := toString $pq.keda.maxReplicaCount }}
{{- if not (and (regexMatch $count $min) (regexMatch $count $max) (ge (int $max) 1) (ge (int $max) (int $min))) }}
{{- fail "pqRunner.keda.minReplicaCount/maxReplicaCount must be integers with maxReplicaCount >= 1 and >= minReplicaCount" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
POWER_QUERY_RUNNER lets a process execute preview_query (user Python code), so it
must never reach the regular backend, worker, beat, flower or release job, which
all load backend.config and the backend Key Vault Secret. Checked on every render,
whether pqRunner is enabled or not. The runner's own flag goes in pqRunner.config
(or pqRunner.keyvault), which is not checked here.
- backend.config: rejected unless explicitly inactive (empty, 0, false, no, off, n).
- keyvault.envMappings: rejected whatever the Key Vault secret holds (unknown to Helm).
Messages name keys only, never values.
*/}}
{{- define "reporting.pqRunner.validateBackend" -}}
{{- $flag := "POWER_QUERY_RUNNER" }}
{{- $inactive := list "" "0" "false" "no" "off" "n" }}
{{- range $k, $v := (.Values.backend.config | default dict) }}
{{- if eq (upper (toString $k)) $flag }}
{{- if not (or (kindIs "invalid" $v) (has (lower (trim (toString $v))) $inactive)) }}
{{- fail (printf "backend.config.%s must not be active: it would let the regular backend/worker run Power Query code; set it only in pqRunner.config" $k) }}
{{- end }}
{{- end }}
{{- end }}
{{- range $m := (.Values.keyvault.envMappings | default list) }}
{{- if and (kindIs "map" $m) (eq (upper (toString (get $m "key"))) $flag) }}
{{- fail (printf "keyvault.envMappings: key %s is not allowed: the backend Key Vault Secret is loaded by the regular backend/worker; map it only in pqRunner.keyvault.envMappings" (get $m "key")) }}
{{- end }}
{{- end }}
{{- end }}
