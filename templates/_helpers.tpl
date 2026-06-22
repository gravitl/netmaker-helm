{{/*
Expand the name of the chart.
*/}}
{{- define "netmaker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "netmaker.fullname" -}}
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
{{- define "netmaker.masterKey" -}}
{{- randAlphaNum 12 | nospace -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "netmaker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "netmaker.labels" -}}
helm.sh/chart: {{ include "netmaker.chart" . }}
{{ include "netmaker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "netmaker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netmaker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "netmaker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "netmaker.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL resource name (truncated to satisfy the 63-character DNS label limit).
*/}}
{{- define "netmaker.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "netmaker.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Resolve the PostgreSQL host for application pods.
*/}}
{{- define "netmaker.dbHost" -}}
{{- if .Values.db.host -}}
{{- .Values.db.host -}}
{{- else if .Values.postgres.enabled -}}
{{- printf "%s.%s.svc.cluster.local" (include "netmaker.postgresql.fullname" .) .Release.Namespace -}}
{{- else if .Values.db.existingSecret.enabled -}}
{{- "" -}}
{{- else -}}
{{- fail "db.host must be set when postgres.enabled is false" -}}
{{- end -}}
{{- end -}}

{{/*
Validate bundled PostgreSQL configuration.
*/}}
{{- define "netmaker.validatePostgres" -}}
{{- if and .Values.postgres.enabled .Values.db.host -}}
{{- fail "postgres.enabled and db.host are mutually exclusive; set postgres.enabled=false when using an external database" -}}
{{- end -}}
{{- end -}}

{{/*
Validate db.existingSecret configuration.
*/}}
{{- define "netmaker.validateExistingSecret" -}}
{{- if .Values.db.existingSecret.enabled -}}
{{- if not .Values.db.existingSecret.name -}}
{{- fail "db.existingSecret.name must be set when db.existingSecret.enabled=true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate ingress and gateway routing are not both enabled.
*/}}
{{- define "netmaker.validateRouting" -}}
{{- if and .Values.ingress.enabled .Values.gateway.enabled -}}
{{- fail "ingress.enabled and gateway.enabled are mutually exclusive; enable only one routing mode" -}}
{{- end -}}
{{- end -}}

{{/*
Validate Gateway API parentRefs when gateway routing is enabled.
*/}}
{{- define "netmaker.validateGatewayParentRefs" -}}
{{- if .Values.gateway.enabled -}}
{{- if not .Values.gateway.parentRefs -}}
{{- fail "gateway.enabled=true requires gateway.parentRefs to be configured (see values.yaml)" -}}
{{- end -}}
{{- range .Values.gateway.parentRefs -}}
{{- if not .name -}}
{{- fail "gateway.parentRefs[].name must be set when gateway.enabled=true" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
