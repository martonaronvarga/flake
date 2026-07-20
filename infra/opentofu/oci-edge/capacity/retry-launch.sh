#!/usr/bin/env bash
set -euo pipefail

attempts="${ATTEMPTS:-0}"
sleep_seconds="${SLEEP_SECONDS:-900}"
sleep_jitter="${SLEEP_JITTER:-100}"
ad_indices="${AD_INDICES:-0 1 2}"
try_once() {
  local ad_index="$1"
  local stamp
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  local log_file
  log_file="$(mktemp)"

  echo "[$stamp] trying A1 capacity in a1_availability_domain_index=$ad_index"

  if tofu apply -auto-approve -lock-timeout=60s \
    -var="availability_domain_index=$ad_index" \
    2>&1 | tee "$log_file"
  then
    rm -f "$log_file"
    echo "A1 launch succeeded. Reserved public IP remains attached to AMD until active_backend=a1."
    return 0
  fi

  if grep -Eiq 'out of host capacity|capacity|too many requests|throttl|timeout|temporar|internal error|5[0-9][0-9]' "$log_file"; then
    rm -f "$log_file"
    echo "retryable OCI capacity/API failure" >&2
    return 75
  fi

  rm -f "$log_file"
  echo "non-retryable OpenTofu failure" >&2
  return 1
}

if [[ ! -f terraform.tfvars ]]; then
  echo "missing terraform.tfvars; copy terraform.tfvars.example and fill real OCIDs first" >&2
  exit 1
fi

tofu init

count=0
while :; do
  for ad_index in $ad_indices; do
    if try_once "$ad_index"; then
      exit 0
    else
      rc=$?
    fi

    if [[ "$rc" != 75 ]]; then
      exit "$rc"
    fi

    count=$((count + 1))
    if [[ "$attempts" != 0 && "$count" -ge "$attempts" ]]; then
      echo "reached ATTEMPTS=$attempts without capacity" >&2
      exit 75
    fi

    jitter=$(( RANDOM % (sleep_jitter + 1) ))
    actual_sleep=$(( sleep_seconds + jitter ))
    echo "sleeping ${actual_sleep}s before next attempt"
    sleep "$actual_sleep"
  done
done
