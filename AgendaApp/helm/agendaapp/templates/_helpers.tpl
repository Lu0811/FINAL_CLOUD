{{/*
Expand the name of the chart.
*/}}
{{- define "agendaapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "agendaapp.fullname" -}}
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
{{- define "agendaapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agendaapp.labels" -}}
helm.sh/chart: {{ include "agendaapp.chart" . }}
{{ include "agendaapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agendaapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agendaapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "agendaapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "agendaapp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "agendaapp.frontend.selectorLabels" -}}
{{ include "agendaapp.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "agendaapp.backend.selectorLabels" -}}
{{ include "agendaapp.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
MongoDB selector labels
*/}}
{{- define "agendaapp.mongodb.selectorLabels" -}}
{{ include "agendaapp.selectorLabels" . }}
app.kubernetes.io/component: mongodb
{{- end }}

{{/*
Image repository with registry
*/}}
{{- define "agendaapp.imageRepository" -}}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/%s" .Values.global.imageRegistry .repository }}
{{- else }}
{{- .repository }}
{{- end }}
{{- end }}