#!/usr/bin/env bash
# Sync secrets from Doppler prd config → Coolify app env vars
# Usage: ./script/sync_doppler_to_coolify.sh
set -euo pipefail

APP_UUID="zj5rf8d29wpz8dbxtbxphyrv"
PROJECT="userstories"
CONFIG="prd"

echo "Fetching secrets from Doppler ($PROJECT/$CONFIG)..."
SECRETS=$(doppler secrets download --project "$PROJECT" --config "$CONFIG" --no-file --format env 2>/dev/null | grep -v "^DOPPLER_")

echo "Fetching existing env var UUIDs from Coolify..."
ENV_JSON=$(coolify app env list "$APP_UUID" --format json -s 2>/dev/null)

echo "Syncing..."
while IFS='=' read -r key raw_value; do
  [[ -z "$key" ]] && continue
  value="${raw_value%\"}"
  value="${value#\"}"

  uuid=$(echo "$ENV_JSON" | jq -r --arg k "$key" '.[] | select(.key == $k) | .uuid' 2>/dev/null || echo "")

  if [[ -n "$uuid" ]]; then
    coolify app env update "$APP_UUID" "$uuid" --value "$value" 2>/dev/null && echo "  updated: $key" || echo "  skipped: $key"
  else
    coolify app env create "$APP_UUID" --key "$key" --value "$value" 2>/dev/null && echo "  created: $key" || echo "  skipped: $key"
  fi
done <<< "$SECRETS"

echo "Restarting app..."
coolify app restart "$APP_UUID"
echo "Done."
