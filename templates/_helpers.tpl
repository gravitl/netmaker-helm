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
Kubernetes Service short name for the MQTT broker (used in ingress backend and in-cluster DNS).
*/}}
{{- define "netmaker.brokerServiceName" -}}
{{- if eq .Values.mq.backend "emqx" }}
{{- if .Values.mq.emqx.serviceName }}
{{- .Values.mq.emqx.serviceName }}
{{- else }}
{{- printf "%s-emqx" .Release.Name }}
{{- end }}
{{- else if eq .Values.mq.backend "external" }}
{{- .Values.mq.external.serviceName }}
{{- else }}
{{- printf "%s-mqtt" (include "netmaker.fullname" .) }}
{{- end }}
{{- end }}

{{/*
SERVER_BROKER_ENDPOINT for Netmaker server pods.
*/}}
{{- define "netmaker.serverBrokerEndpoint" -}}
{{- if eq .Values.mq.backend "external" }}
{{- required "mq.external.serverBrokerEndpoint is required when mq.backend is external" .Values.mq.external.serverBrokerEndpoint }}
{{- else if eq .Values.mq.backend "emqx" }}
{{- $host := include "netmaker.brokerServiceName" . }}
{{- $port := .Values.mq.internal.wsPort | default 8083 }}
{{- $path := .Values.mq.internal.wsPath | default "/mqtt" }}
{{- printf "ws://%s.%s.svc.cluster.local:%v%s" $host .Release.Namespace $port $path }}
{{- else }}
{{- printf "ws://%s-mqtt.%s.svc.cluster.local:1883" (include "netmaker.fullname" .) .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Ingress backend port for broker (TLS terminated at ingress; forwards to broker WebSocket listener).
*/}}
{{- define "netmaker.ingressBrokerPort" -}}
{{- if not (empty .Values.mq.ingress.brokerTargetPort) }}
{{- .Values.mq.ingress.brokerTargetPort }}
{{- else if eq .Values.mq.backend "emqx" }}
{{- .Values.mq.internal.wsPort | default 8083 }}
{{- else if eq .Values.mq.backend "external" }}
{{- .Values.mq.external.ingressPort }}
{{- else }}
8883
{{- end }}
{{- end }}
