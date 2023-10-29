{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "helm-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-chart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create app version
*/}}
{{- define "helm-chart.defaultTag" -}}
latest
{{- end -}}

{{/*
Return valid version label
*/}}
{{- define "helm-chart.versionLabelValue" -}}
{{ regexReplaceAll "[^-A-Za-z0-9_.]" (include "helm-chart.defaultTag" .) "-" | trunc 63 | trimAll "-" | trimAll "_" | trimAll "." | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "helm-chart.labels" -}}
helm.sh/chart: {{ include "helm-chart.chart" . }}
{{ include "helm-chart.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ include "helm-chart.versionLabelValue" . }}
{{- with .Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common affinity definition
Pod affinity
  - Soft prefers different nodes
  - Hard requires different nodes and prefers different availibility zones
Node affinity
  - Soft prefers given user expressions
  - Hard requires given user expressions
*/}}
{{- define "helm-chart.affinity" -}}
{{- with .affinity -}}
  {{- toYaml . -}}
{{- else -}}
{{- $preset := .Values.global.affinity -}}
{{- if (eq $preset.podAntiAffinity "soft") }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "helm-chart.name" . }}
      topologyKey: kubernetes.io/hostname
{{- else if (eq $preset.podAntiAffinity "hard") }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "helm-chart.name" . }}
      topologyKey: topology.kubernetes.io/zone
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ include "helm-chart.name" . }}
    topologyKey: kubernetes.io/hostname
{{- end }}
{{- with $preset.nodeAffinity.matchExpressions }}
{{- if (eq $preset.nodeAffinity.type "soft") }}
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    preference:
      matchExpressions:
      {{- toYaml . | nindent 6 }}
{{- else if (eq $preset.nodeAffinity.type "hard") }}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      {{- toYaml . | nindent 6 }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common deployment strategy definition
- Recreate don't have additional fields, we need to remove them if added by the mergeOverwrite
*/}}
{{- define "helm-chart.strategy" -}}
{{- $preset := . -}}
{{- if (eq (toString $preset.type) "Recreate") }}
type: Recreate
{{- else if (eq (toString $preset.type) "RollingUpdate") }}
type: RollingUpdate
{{- with $preset.rollingUpdate }}
rollingUpdate:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}
