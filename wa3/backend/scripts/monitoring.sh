#!/usr/bin/env bash
# Log-based metrics + alert policies for Wasilha v1 (idempotent).
# Env: PROJECT_ID (required), ALERT_EMAIL (optional — without it, metrics are created but no alerts).
set -euo pipefail
: "${PROJECT_ID:?PROJECT_ID is required}"
gcloud config set project "$PROJECT_ID" >/dev/null
TMP=$(mktemp -d)

metric() { # metric NAME DESCRIPTION FILTER
  if gcloud logging metrics describe "$1" >/dev/null 2>&1; then
    gcloud logging metrics update "$1" --description="$2" --log-filter="$3" >/dev/null
  else
    gcloud logging metrics create "$1" --description="$2" --log-filter="$3" >/dev/null
  fi
  echo "metric $1 ok"
}

metric wa3_function_errors "Errors from Wasilha functions (excluding stuck-trip alerts)" \
  'resource.type="cloud_run_revision" AND severity>=ERROR AND NOT jsonPayload.message="trip.stuck"'
metric wa3_stuck_trips "Trips stuck in one state longer than the threshold (sweeper)" \
  'resource.type="cloud_run_revision" AND jsonPayload.message="trip.stuck"'
metric wa3_dispatch_no_drivers "Requests fanned out to zero drivers" \
  'resource.type="cloud_run_revision" AND jsonPayload.message="dispatch.fanout" AND jsonPayload.drivers=0'

# Distribution metric: seconds from request to driver assignment.
cat > "$TMP/tta.yaml" <<'EOF'
name: wa3_time_to_assign
description: Seconds from request (searching) to driver assignment
filter: resource.type="cloud_run_revision" AND jsonPayload.metric="time_to_assign_seconds"
valueExtractor: EXTRACT(jsonPayload.value)
metricDescriptor:
  metricKind: DELTA
  valueType: DISTRIBUTION
  unit: s
bucketOptions:
  exponentialBuckets: { numFiniteBuckets: 20, growthFactor: 1.5, scale: 5 }
EOF
if gcloud logging metrics describe wa3_time_to_assign >/dev/null 2>&1; then
  gcloud logging metrics update wa3_time_to_assign --config-from-file="$TMP/tta.yaml" >/dev/null
else
  gcloud logging metrics create wa3_time_to_assign --config-from-file="$TMP/tta.yaml" >/dev/null
fi
echo "metric wa3_time_to_assign ok"

if [[ -z "${ALERT_EMAIL:-}" ]]; then
  echo "ALERT_EMAIL not set — metrics created, alerts skipped."
  exit 0
fi

CHANNEL=$(gcloud beta monitoring channels list --filter="labels.email_address=\"$ALERT_EMAIL\"" --format='value(name)' | head -1)
if [[ -z "$CHANNEL" ]]; then
  CHANNEL=$(gcloud beta monitoring channels create --display-name="Wasilha ops ($ALERT_EMAIL)" --type=email \
    --channel-labels=email_address="$ALERT_EMAIL" --format='value(name)')
fi

policy() { # policy DISPLAY_NAME FILE
  if gcloud alpha monitoring policies list --filter="displayName=\"$1\"" --format='value(name)' | grep -q .; then
    echo "policy '$1' exists"
  else
    gcloud alpha monitoring policies create --policy-from-file="$2" >/dev/null && echo "policy '$1' created"
  fi
}

cat > "$TMP/p1.json" <<EOF
{ "displayName": "Wasilha: function errors", "combiner": "OR", "notificationChannels": ["$CHANNEL"],
  "conditions": [{ "displayName": "More than 5 errors in 5 minutes",
    "conditionThreshold": { "filter": "metric.type=\"logging.googleapis.com/user/wa3_function_errors\" resource.type=\"cloud_run_revision\"",
      "aggregations": [{ "alignmentPeriod": "300s", "perSeriesAligner": "ALIGN_SUM", "crossSeriesReducer": "REDUCE_SUM" }],
      "comparison": "COMPARISON_GT", "thresholdValue": 5, "duration": "0s" } }] }
EOF
cat > "$TMP/p2.json" <<EOF
{ "displayName": "Wasilha: stuck trips", "combiner": "OR", "notificationChannels": ["$CHANNEL"],
  "conditions": [{ "displayName": "A trip is stuck for 3 consecutive minutes",
    "conditionThreshold": { "filter": "metric.type=\"logging.googleapis.com/user/wa3_stuck_trips\" resource.type=\"cloud_run_revision\"",
      "aggregations": [{ "alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_SUM", "crossSeriesReducer": "REDUCE_SUM" }],
      "comparison": "COMPARISON_GT", "thresholdValue": 0, "duration": "180s" } }] }
EOF
cat > "$TMP/p3.json" <<EOF
{ "displayName": "Wasilha: slow driver assignment", "combiner": "OR", "notificationChannels": ["$CHANNEL"],
  "conditions": [{ "displayName": "Median time-to-assign above 3 minutes for 15 minutes",
    "conditionThreshold": { "filter": "metric.type=\"logging.googleapis.com/user/wa3_time_to_assign\" resource.type=\"cloud_run_revision\"",
      "aggregations": [{ "alignmentPeriod": "900s", "perSeriesAligner": "ALIGN_PERCENTILE_50", "crossSeriesReducer": "REDUCE_MEAN" }],
      "comparison": "COMPARISON_GT", "thresholdValue": 180, "duration": "0s" } }] }
EOF
policy "Wasilha: function errors" "$TMP/p1.json"
policy "Wasilha: stuck trips" "$TMP/p2.json"
policy "Wasilha: slow driver assignment" "$TMP/p3.json"
