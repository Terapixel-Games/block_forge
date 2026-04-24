# Cloud Run Deployment (Template)

This folder defines a Cloud Run-first deploy path for game Nakama backends.

## Files

- `nakama/cloudrun/service.template.yaml`: Knative service template with token placeholders.

## Build image

```bash
PROJECT_ID="<gcp-project>"
CLOUDRUN_SERVICE="block_forge-nakama"
IMAGE_URI="us-central1-docker.pkg.dev/${PROJECT_ID}/nakama/${CLOUDRUN_SERVICE}:$(git rev-parse --short HEAD)"

gcloud builds submit backend/nakama \
  --project "${PROJECT_ID}" \
  --tag "${IMAGE_URI}" \
  --file backend/nakama/Dockerfile.render
```

## Required Secret Manager secrets

- `nakama-db-address`
- `nakama-server-key`
- `nakama-session-encryption-key`
- `nakama-session-refresh-encryption-key`
- `nakama-runtime-http-key`
- `nakama-console-password`
- `platform-internal-key`
- `tpx-magic-link-notify-secret`

## Render and apply service

```bash
SERVICE_ACCOUNT_EMAIL="<cloud-run-runtime-service-account>"
TPX_BASE_URL="https://terapixel.games/api"
CLOUDSQL_INSTANCE_CONNECTION_NAME="<project>:<region>:<instance>"

sed \
  -e "s|__CLOUDRUN_SERVICE__|${CLOUDRUN_SERVICE}|g" \
  -e "s|__SERVICE_ACCOUNT_EMAIL__|${SERVICE_ACCOUNT_EMAIL}|g" \
  -e "s|__IMAGE_URI__|${IMAGE_URI}|g" \
  -e "s|__CLOUDSQL_INSTANCES__|${CLOUDSQL_INSTANCE_CONNECTION_NAME}|g" \
  -e "s|__PLATFORM_IDENTITY_URL__|${TPX_BASE_URL}|g" \
  -e "s|__PLATFORM_ACCOUNT_MAGIC_LINK_START_URL__|${TPX_BASE_URL}/v1/account/magic-link/start|g" \
  -e "s|__PLATFORM_ACCOUNT_MAGIC_LINK_COMPLETE_URL__|${TPX_BASE_URL}/v1/account/magic-link/complete|g" \
  -e "s|__PLATFORM_USERNAME_VALIDATE_URL__|${TPX_BASE_URL}/v1/identity/internal/username/validate|g" \
  -e "s|__PLATFORM_ACCOUNT_MERGE_CODE_URL__|${TPX_BASE_URL}/v1/account/merge/code|g" \
  -e "s|__PLATFORM_ACCOUNT_MERGE_REDEEM_URL__|${TPX_BASE_URL}/v1/account/merge/redeem|g" \
  -e "s|__PLATFORM_TELEMETRY_EVENTS_URL__|${TPX_BASE_URL}/v1/telemetry/events|g" \
  backend/nakama/cloudrun/service.template.yaml > /tmp/${CLOUDRUN_SERVICE}.yaml

gcloud run services replace /tmp/${CLOUDRUN_SERVICE}.yaml \
  --project "${PROJECT_ID}" \
  --region "us-central1"
```

Render workflows are retained as manual fallback only.
