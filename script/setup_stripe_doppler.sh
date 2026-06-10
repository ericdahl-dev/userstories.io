#!/usr/bin/env bash
# Create Stripe Pro product/prices + webhook, store secrets in Doppler, sync to Coolify.
#
# Prerequisites:
#   - stripe CLI logged in (`stripe login`)
#   - doppler CLI logged in with access to project userstories
#   - coolify CLI configured
#
# Usage:
#   ./script/setup_stripe_doppler.sh
#   ./script/setup_stripe_doppler.sh --skip-coolify   # Doppler only
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

DOPPLER_PROJECT="userstories"
PRODUCT_NAME="userstories.io Pro"
WEBHOOK_EVENTS=(
  checkout.session.completed
  customer.subscription.updated
  customer.subscription.deleted
)
SKIP_COOLIFY=false

for arg in "$@"; do
  case "$arg" in
    --skip-coolify) SKIP_COOLIFY=true ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

stripe_api() {
  local mode="$1"; shift
  local -a args=("$@")
  if [[ "$mode" == "live" ]]; then
    if [[ -n "${STRIPE_LIVE_SECRET_KEY:-}" ]]; then
      stripe "${args[@]}" --live --api-key "$STRIPE_LIVE_SECRET_KEY"
    else
      stripe "${args[@]}" --live
    fi
  elif [[ -n "${STRIPE_TEST_SECRET_KEY:-}" ]]; then
    stripe "${args[@]}" --api-key "$STRIPE_TEST_SECRET_KEY"
  else
    stripe "${args[@]}"
  fi
}

stripe_check_auth() {
  local mode="$1"
  if ! stripe_api "$mode" products list --limit 1 >/dev/null 2>&1; then
    echo "Stripe CLI auth failed for ${mode} mode. Run: stripe login" >&2
    exit 1
  fi
}

find_product_id() {
  local mode="$1"
  stripe_api "$mode" products list --limit 100 | jq -r \
    --arg name "$PRODUCT_NAME" '.data[] | select(.name == $name and .active == true) | .id' | head -1
}

find_price_id() {
  local mode="$1" product_id="$2" interval="$3"
  stripe_api "$mode" prices list --product "$product_id" --limit 100 | jq -r \
    --arg interval "$interval" '.data[] | select(.active == true and .recurring.interval == $interval) | .id' | head -1
}

ensure_product() {
  local mode="$1"
  local product_id
  product_id=$(find_product_id "$mode")
  if [[ -z "$product_id" ]]; then
    product_id=$(stripe_api "$mode" products create \
      --name "$PRODUCT_NAME" \
      --description "Unlimited projects and 200 AI refinements per month" \
      | jq -er '.id')
    echo "  created product ($mode): $product_id" >&2
  else
    echo "  reusing product ($mode): $product_id" >&2
  fi
  echo "$product_id"
}

ensure_price() {
  local mode="$1" product_id="$2" interval="$3" amount="$4"
  local price_id
  price_id=$(find_price_id "$mode" "$product_id" "$interval")
  if [[ -z "$price_id" ]]; then
    price_id=$(stripe_api "$mode" prices create \
      --product "$product_id" \
      --unit-amount "$amount" \
      --currency usd \
      --recurring.interval "$interval" \
      | jq -er '.id')
    echo "  created ${interval} price ($mode): $price_id" >&2
  else
    echo "  reusing ${interval} price ($mode): $price_id" >&2
  fi
  echo "$price_id"
}

webhook_exists() {
  local mode="$1" url="$2"
  stripe_api "$mode" webhook_endpoints list --limit 100 | jq -er \
    --arg url "$url" '.data[] | select(.url == $url and .status == "enabled") | .id' | head -1
}

ensure_webhook() {
  local mode="$1" url="$2" doppler_config="$3"
  local secret endpoint_id

  endpoint_id=$(webhook_exists "$mode" "$url" 2>/dev/null || true)
  if [[ -n "$endpoint_id" ]]; then
    secret=$(doppler secrets get STRIPE_WEBHOOK_SECRET --project "$DOPPLER_PROJECT" --config "$doppler_config" --plain 2>/dev/null || true)
    if [[ -n "$secret" && "$secret" != "null" ]]; then
      echo "  reusing webhook ($mode): $url ($endpoint_id)" >&2
      echo "$secret"
      return
    fi
    echo "  webhook exists ($endpoint_id) but secret not in Doppler — copy whsec_... from Stripe Dashboard" >&2
    exit 1
  fi

  local -a webhook_args=(--url "$url")
  local event
  for event in "${WEBHOOK_EVENTS[@]}"; do
    webhook_args+=(--enabled-events "$event")
  done

  local response
  response=$(stripe_api "$mode" webhook_endpoints create "${webhook_args[@]}")
  secret=$(echo "$response" | jq -er '.secret')
  echo "  created webhook ($mode): $url" >&2
  echo "$secret"
}

stripe_secret_key() {
  local mode="$1"
  local key=""

  if [[ "$mode" == "live" ]]; then
    key="${STRIPE_LIVE_SECRET_KEY:-}"
    if [[ -z "$key" ]]; then
      key=$(security find-generic-password -s "StripeCLI" -a "default.live_mode_api_key" -w 2>/dev/null || true)
    fi
  else
    key="${STRIPE_TEST_SECRET_KEY:-}"
    if [[ -z "$key" ]]; then
      key=$(awk -F"'" '
        /^\[default\]/ { section=1; next }
        /^\[/ { section=0 }
        section && /^test_mode_api_key/ { print $2; exit }
      ' "${HOME}/.config/stripe/config.toml")
    fi
  fi

  if [[ -z "$key" || "$key" == *"*"* ]]; then
    echo "Missing Stripe ${mode} secret key. Run stripe login or set STRIPE_LIVE_SECRET_KEY / STRIPE_TEST_SECRET_KEY." >&2
    exit 1
  fi

  echo "$key"
}

setup_mode() {
  local mode="$1" doppler_config="$2" webhook_url="$3"

  echo ""
  echo "=== Stripe ${mode} → Doppler ${doppler_config} ==="

  stripe_check_auth "$mode"

  if [[ "$mode" == "live" && -z "${STRIPE_LIVE_SECRET_KEY:-}" ]]; then
    echo "Production requires STRIPE_LIVE_SECRET_KEY=sk_live_... (CLI login only stores a restricted rk_live key)." >&2
    echo "Create the key in Stripe Dashboard → Developers → API keys, then re-run." >&2
    return 1
  fi

  local product_id monthly annual webhook_secret secret_key
  product_id=$(ensure_product "$mode")
  monthly=$(ensure_price "$mode" "$product_id" month 1200)
  annual=$(ensure_price "$mode" "$product_id" year 9900)
  webhook_secret=$(ensure_webhook "$mode" "$webhook_url" "$doppler_config")
  secret_key=$(stripe_secret_key "$mode")

  echo "Setting Doppler secrets ($doppler_config)..."
  doppler secrets set \
    --project "$DOPPLER_PROJECT" \
    --config "$doppler_config" \
    "STRIPE_SECRET_KEY=$secret_key" \
    "STRIPE_PRICE_MONTHLY=$monthly" \
    "STRIPE_PRICE_ANNUAL=$annual" \
    "STRIPE_WEBHOOK_SECRET=$webhook_secret"

  echo "Doppler updated: $doppler_config"
}

require_cmd stripe
require_cmd jq
require_cmd doppler

echo "Setting up Stripe billing secrets..."

setup_mode test stg "https://userstories.io/stripe/webhooks"
setup_mode live prd "https://userstories.io/stripe/webhooks" || echo "Skipped production — set STRIPE_LIVE_SECRET_KEY and re-run."

if [[ "$SKIP_COOLIFY" == "true" ]]; then
  echo "Skipping Coolify sync (--skip-coolify)."
else
  echo ""
  echo "Syncing Doppler → Coolify..."
  "$(dirname "$0")/sync_doppler_to_coolify.sh"
fi

echo ""
echo "Stripe billing secrets configured in Doppler (stg=test, prd=live)."
