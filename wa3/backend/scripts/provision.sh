#!/usr/bin/env bash
# Provisions a real Firebase project for Wasilha v1. Idempotent: safe to re-run.
#
# Needs: gcloud (authenticated as a service account with Owner on the project),
#        firebase-tools, node 22, curl, jq. Run from wa3/backend.
#
# Env:
#   PROJECT_ID          required, e.g. wa-3-1a2b3
#   REGION              default europe-west1 (functions, Firestore, Storage)
#   STAFF_EMAIL         optional: create/grant the first staff account
#   STAFF_ROLE          default admin
#   ALERT_EMAIL         optional: email channel for monitoring alerts
#   APP_CHECK_ENFORCE   default false (sideloaded beta APKs can't pass Play Integrity)
#   TEST_PHONES         optional JSON, e.g. {"+249900000001":"123456"} (fictional numbers for testing)
#   OUT                 output dir for generated client configs (default ./out)
set -euo pipefail

: "${PROJECT_ID:?PROJECT_ID is required}"
REGION="${REGION:-europe-west1}"
STAFF_ROLE="${STAFF_ROLE:-admin}"
APP_CHECK_ENFORCE="${APP_CHECK_ENFORCE:-false}"
OUT="${OUT:-$PWD/out}"
mkdir -p "$OUT"

log()  { printf '\n\033[1m▶ %s\033[0m\n' "$*"; }
warn() { printf '\033[33m⚠ %s\033[0m\n' "$*"; echo "- $*" >> "$OUT/WARNINGS.md"; }
TOKEN() { gcloud auth print-access-token; }
api() { # api METHOD URL [JSON]
  curl -sS -X "$1" "$2" -H "Authorization: Bearer $(TOKEN)" -H "x-goog-user-project: $PROJECT_ID" \
       -H "Content-Type: application/json" ${3:+-d "$3"}
}
: > "$OUT/WARNINGS.md"
gcloud config set project "$PROJECT_ID" >/dev/null

# ── 0. Billing (Blaze) is required for Functions, Secret Manager and Scheduler ──
log "Checking billing (Blaze plan)"
BILLING=$(gcloud billing projects describe "$PROJECT_ID" --format='value(billingEnabled)' 2>/dev/null || echo "")
if [[ "$BILLING" != "True" ]]; then
  echo "::error::Billing is not enabled. In Firebase Console → ⚙ Usage and billing → upgrade project '$PROJECT_ID' to the Blaze plan, then re-run."
  exit 1
fi

# ── 1. APIs ─────────────────────────────────────────────────────────
log "Enabling APIs"
gcloud services enable \
  firebase.googleapis.com firestore.googleapis.com cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com \
  eventarc.googleapis.com pubsub.googleapis.com cloudscheduler.googleapis.com \
  secretmanager.googleapis.com identitytoolkit.googleapis.com firebasestorage.googleapis.com \
  storage.googleapis.com firebasehosting.googleapis.com firebaseappcheck.googleapis.com \
  recaptchaenterprise.googleapis.com logging.googleapis.com monitoring.googleapis.com \
  apikeys.googleapis.com routes.googleapis.com places.googleapis.com \
  geocoding-backend.googleapis.com maps-android-backend.googleapis.com maps-ios-backend.googleapis.com

# ── 2. Firestore (default) in REGION, with PITR and daily backups ──
log "Firestore database"
LOC=$(gcloud firestore databases describe --database='(default)' --format='value(locationId)' 2>/dev/null || echo "")
if [[ -z "$LOC" ]]; then
  gcloud firestore databases create --database='(default)' --location="$REGION" --type=firestore-native
  LOC="$REGION"
fi
case "$LOC" in
  "$REGION"|eur3) echo "Firestore location: $LOC" ;;
  *) echo "::error::Firestore already exists in '$LOC'. Functions run in $REGION and Firestore triggers must share the location. Use a new project or set REGION to match."; exit 1 ;;
esac
gcloud firestore databases update --database='(default)' --enable-pitr >/dev/null 2>&1 || warn "Could not enable point-in-time recovery"
if ! gcloud firestore backups schedules list --database='(default)' --format='value(name)' 2>/dev/null | grep -q .; then
  gcloud firestore backups schedules create --database='(default)' --recurrence=daily --retention=14d >/dev/null \
    || warn "Could not create the daily backup schedule"
fi

# ── 3. Cloud Storage default bucket (KYC uploads) ──
log "Storage bucket"
BUCKET="$PROJECT_ID.firebasestorage.app"
if ! gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then
  R=$(api POST "https://firebasestorage.googleapis.com/v1alpha/projects/$PROJECT_ID/defaultBucket" "{\"location\":\"$REGION\"}")
  echo "$R" | jq -e '.name' >/dev/null 2>&1 || warn "Create the Storage bucket in Firebase Console → Storage → Get started (location $REGION), then re-run. API said: $(echo "$R" | jq -c '.error.message' 2>/dev/null)"
fi

# ── 4. Authentication: Identity Platform, phone + email/password, TOTP MFA, SMS region ──
log "Authentication (phone sign-in, staff email + TOTP)"
api POST "https://identitytoolkit.googleapis.com/v2/projects/$PROJECT_ID/identityPlatform:initializeAuth" '{}' >/dev/null || true
TEST_PHONES="${TEST_PHONES:-}"
PHONE_CFG='{"enabled":true}'
MASK="signIn.phoneNumber.enabled,signIn.email.enabled,signIn.email.passwordRequired,mfa.providerConfigs,smsRegionConfig"
if [[ -n "$TEST_PHONES" ]]; then
  PHONE_CFG=$(jq -nc --argjson t "$TEST_PHONES" '{enabled:true, testPhoneNumbers:$t}')
  MASK="$MASK,signIn.phoneNumber.testPhoneNumbers"
fi
BODY=$(jq -nc --argjson phone "$PHONE_CFG" '{
  signIn: { phoneNumber: $phone, email: { enabled: true, passwordRequired: true } },
  mfa: { providerConfigs: [ { state: "ENABLED", totpProviderConfig: { adjacentIntervals: 5 } } ] },
  smsRegionConfig: { allowlistOnly: { allowedRegions: ["SD"] } }
}')
R=$(api PATCH "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/config?updateMask=$MASK" "$BODY")
echo "$R" | jq -e '.name' >/dev/null 2>&1 || warn "Auth config update failed: $(echo "$R" | jq -c '.error.message' 2>/dev/null)"

# ── 5. Maps keys: server key → Secret Manager; Android key → client build ──
log "Maps API keys"
key_string() { # key_string DISPLAY_NAME → prints keyString, creating the key if needed
  local name; name=$(gcloud services api-keys list --filter="displayName=\"$1\"" --format='value(name)' | head -1)
  if [[ -z "$name" ]]; then
    shift_args=("${@:2}")
    gcloud services api-keys create --display-name="$1" "${shift_args[@]}" >/dev/null
    sleep 5
    name=$(gcloud services api-keys list --filter="displayName=\"$1\"" --format='value(name)' | head -1)
  fi
  gcloud services api-keys get-key-string "$name" --format='value(keyString)'
}
SERVER_KEY=$(key_string "wa3 server (routes, places, geocoding)" \
  --api-target=service=routes.googleapis.com --api-target=service=places.googleapis.com \
  --api-target=service=geocoding-backend.googleapis.com)
if ! gcloud secrets describe GOOGLE_MAPS_SERVER_KEY >/dev/null 2>&1; then
  printf '%s' "$SERVER_KEY" | gcloud secrets create GOOGLE_MAPS_SERVER_KEY --replication-policy=automatic --data-file=- >/dev/null
fi
ANDROID_MAPS_KEY=$(key_string "wa3 android maps sdk" --api-target=service=maps-android-backend.googleapis.com)
printf '%s' "$ANDROID_MAPS_KEY" > "$OUT/maps-android-key.txt"

# ── 6. Register the three apps and fetch their (non-secret) client configs ──
log "Registering apps"
apps_json() { firebase apps:list --project "$PROJECT_ID" --json 2>/dev/null | jq '.result // []'; }
ensure_app() { # ensure_app PLATFORM DISPLAY [PACKAGE] → prints appId
  local id
  id=$(apps_json | jq -r --arg d "$2" '.[] | select(.displayName==$d) | .appId' | head -1)
  if [[ -z "$id" ]]; then
    if [[ "$1" == ANDROID ]]; then firebase apps:create ANDROID "$2" --package-name "$3" --project "$PROJECT_ID" >/dev/null
    else firebase apps:create WEB "$2" --project "$PROJECT_ID" >/dev/null; fi
    id=$(apps_json | jq -r --arg d "$2" '.[] | select(.displayName==$d) | .appId' | head -1)
  fi
  echo "$id"
}
RIDER_APP=$(ensure_app ANDROID "Wasilha Rider" sd.wasilha.rider)
DRIVER_APP=$(ensure_app ANDROID "Wasilha Driver" sd.wasilha.driver)
OPS_APP=$(ensure_app WEB "Wasilha Ops")
firebase apps:sdkconfig ANDROID "$RIDER_APP" --project "$PROJECT_ID" -o "$OUT/rider-google-services.json" >/dev/null
firebase apps:sdkconfig ANDROID "$DRIVER_APP" --project "$PROJECT_ID" -o "$OUT/driver-google-services.json" >/dev/null
firebase apps:sdkconfig WEB "$OPS_APP" --project "$PROJECT_ID" --json | jq '.result.sdkConfig' > "$OUT/ops-web-config.json"

# Register the APK signing certificate (needed for phone sign-in without reCAPTCHA, and App Check).
if [[ -n "${SIGNING_SHA1:-}" ]]; then
  for app in "$RIDER_APP" "$DRIVER_APP"; do
    firebase apps:android:sha:create "$app" "$SIGNING_SHA1" --project "$PROJECT_ID" >/dev/null 2>&1 || true
    [[ -n "${SIGNING_SHA256:-}" ]] && firebase apps:android:sha:create "$app" "$SIGNING_SHA256" --project "$PROJECT_ID" >/dev/null 2>&1 || true
  done
fi

# ── 7. App Check for the ops console (reCAPTCHA Enterprise) ──
log "App Check (operations console)"
SITE_KEY=$(gcloud recaptcha keys list --format='value(name,displayName)' 2>/dev/null | awk -F'\t' '$2=="wa3 ops console"{print $1}' | head -1 | sed 's#.*/##')
if [[ -z "$SITE_KEY" ]]; then
  SITE_KEY=$(gcloud recaptcha keys create --display-name="wa3 ops console" --web --integration-type=score \
    --domains="$PROJECT_ID.web.app,$PROJECT_ID.firebaseapp.com,localhost" --format='value(name)' | sed 's#.*/##')
fi
api PATCH "https://firebaseappcheck.googleapis.com/v1/projects/$PROJECT_ID/apps/$OPS_APP/recaptchaEnterpriseConfig?updateMask=siteKey" \
  "{\"siteKey\":\"$SITE_KEY\"}" >/dev/null || warn "Could not register the App Check site key"
jq --arg k "$SITE_KEY" '. + {appCheckSiteKey: $k}' "$OUT/ops-web-config.json" > "$OUT/ops.tmp" && mv "$OUT/ops.tmp" "$OUT/ops-web-config.json"

# ── 8. Functions environment (non-secret) ──
log "Functions configuration"
cat > "functions/.env.$PROJECT_ID" <<EOF
MAPS_FAKE=false
REQUIRE_STAFF_MFA=true
APP_CHECK_ENFORCE=$APP_CHECK_ENFORCE
EOF
[[ "$APP_CHECK_ENFORCE" == "true" ]] || warn "App Check is NOT enforced (APP_CHECK_ENFORCE=false). Turn it on once the apps ship through Google Play / TestFlight."

echo "RIDER_APP=$RIDER_APP DRIVER_APP=$DRIVER_APP OPS_APP=$OPS_APP" > "$OUT/apps.env"
log "Provisioning done → client configs in $OUT"
