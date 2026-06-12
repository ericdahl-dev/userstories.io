#!/usr/bin/env bash
# Sync secrets from Doppler → Coolify app env vars.
#
#   prd → production deploys (is_preview=false)
#   stg → PR preview deploys (is_preview=true)
#
# Usage: ./script/sync_doppler_to_coolify.sh
set -euo pipefail

# Prefer user-local Coolify CLI (1.x) over stale /usr/local/bin installs (0.x).
export PATH="${HOME}/.local/bin:${PATH}"

APP_UUID="zj5rf8d29wpz8dbxtbxphyrv"
PROJECT="userstories"

sync_config() {
  local config="$1"
  local is_preview="$2" # true | false
  local label preview_flag preview_json

  if [[ "$is_preview" == "true" ]]; then
    label="preview"
    preview_flag="--preview"
    preview_json="true"
  else
    label="production"
    preview_flag=""
    preview_json="false"
  fi

  echo "Fetching secrets from Doppler ($PROJECT/$config) for $label..."
  local secrets
  secrets=$(doppler secrets download --project "$PROJECT" --config "$config" --no-file --format env 2>/dev/null | grep -v "^DOPPLER_")

  echo "Syncing $label env vars..."
  while IFS='=' read -r key raw_value; do
    [[ -z "$key" ]] && continue
    local value="${raw_value%\"}"
    value="${value#\"}"

    local uuid
    uuid=$(echo "$ENV_JSON" | jq -r --arg k "$key" --argjson preview "$preview_json" \
      '.[] | select(.key == $k and .is_preview == $preview) | .uuid' 2>/dev/null || echo "")

    if [[ -n "$uuid" && "$uuid" != "null" ]]; then
      if coolify app env update "$APP_UUID" "$uuid" --value "$value" $preview_flag 2>/dev/null; then
        echo "  updated ($label): $key"
      else
        echo "  skipped ($label): $key"
      fi
    elif coolify app env create "$APP_UUID" --key "$key" --value "$value" $preview_flag 2>/dev/null; then
      echo "  created ($label): $key"
      ENV_JSON=$(coolify app env list "$APP_UUID" --all --format json -s 2>/dev/null)
    else
      echo "  skipped ($label): $key"
    fi
  done <<< "$secrets"
}

echo "Fetching existing env var UUIDs from Coolify..."
# --all required: default list omits preview-scoped vars (is_preview=true).
ENV_JSON=$(coolify app env list "$APP_UUID" --all --format json -s 2>/dev/null)

sync_config "prd" false
sync_config "stg" true

echo "Restarting app..."
coolify app restart "$APP_UUID"
echo "Done."
