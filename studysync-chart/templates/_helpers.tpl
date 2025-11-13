{{/*
============================================
Template Helpers
============================================
Reusable template snippets
Define once, use everywhere
============================================
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "studysync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this.
*/}}
{{- define "studysync.fullname" -}}
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
{{- define "studysync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "studysync.labels" -}}
helm.sh/chart: {{ include "studysync.chart" . }}
{{ include "studysync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "studysync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "studysync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Backend labels
*/}}
{{- define "studysync.backend.labels" -}}
{{ include "studysync.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "studysync.backend.selectorLabels" -}}
{{ include "studysync.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "studysync.frontend.labels" -}}
{{ include "studysync.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "studysync.frontend.selectorLabels" -}}
{{ include "studysync.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "studysync.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "studysync.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Backend secret name
*/}}
{{- define "studysync.backend.secretName" -}}
{{- if .Values.backend.secrets.existingSecret }}
{{- .Values.backend.secrets.existingSecret }}
{{- else }}
{{- printf "%s-backend-secrets" (include "studysync.fullname" .) }}
{{- end }}
{{- end }}

{{/*
LEARNING NOTES:
================

What are these templates?
- Reusable snippets of YAML
- Like functions in programming
- Call with: {{ include "studysync.name" . }}

Why use helpers?
- DRY principle (Don't Repeat Yourself)
- Consistent naming across resources
- Easy to update in one place

Template syntax:
- {{- ... -}} removes whitespace
- . (dot) is the root context
- .Values accesses values.yaml
- .Chart accesses Chart.yaml
- .Release accesses release info

Example usage in other templates:
```yaml
metadata:
  name: {{ include "studysync.fullname" . }}-backend
  labels:
    {{- include "studysync.backend.labels" . | nindent 4 }}
```
*/}}