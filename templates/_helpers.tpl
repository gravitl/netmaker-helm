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
Username for postgresql
*/}}
{{- define "netmaker.database.username" -}}
{{- if .Values.database.internal }}
{{- index .Values "postgresql-ha" "postgresql" "username" }}
{{- else }}
{{- index .Values "external-postgresql" "username" }}
{{- end }}
{{- end }}

{{/*
Password for postgresql
*/}}
{{- define "netmaker.database.password" -}}
{{- if .Values.database.internal }}
{{- index .Values "postgresql-ha" "postgresql" "password" }}
{{- else }}
{{- index .Values "external-postgresql" "password" }}
{{- end }}
{{- end }}

{{/*
Host for postgresql
*/}}
{{- define "netmaker.database.host" -}}
{{- if .Values.database.internal }}
{{- .Release.Name }}-postgresql-ha-pgpool.{{ .Release.Namespace }}
{{- else }}
{{- index .Values "external-postgresql" "host" }}
{{- end }}
{{- end }}

{{/*
Port for postgresql
*/}}
{{- define "netmaker.database.port" -}}
{{- if .Values.database.internal }}
{{- index .Values "postgresql-ha" "postgresql" "containerPorts" "postgresql" }}
{{- else }}
{{- index .Values "external-postgresql" "port" }}
{{- end }}
{{- end }}

{{/*
Database for postgresql
*/}}
{{- define "netmaker.database.database" -}}
{{- if .Values.database.internal }}
{{- index .Values "postgresql-ha" "postgresql" "database" }}
{{- else }}
{{- index .Values "external-postgresql" "database" }}
{{- end }}
{{- end }}