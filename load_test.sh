#!/usr/bin/env bash

set -euo pipefail

URL="${URL:-https://d2nopx32yk57y6.cloudfront.net/}"
REQUESTS="${REQUESTS:-100}"
CONCURRENCY="${CONCURRENCY:-10}"

if ! [[ "$REQUESTS" =~ ^[1-9][0-9]*$ ]]; then
  printf 'REQUESTS must be a positive integer.\n' >&2
  exit 1
fi

if ! [[ "$CONCURRENCY" =~ ^[1-9][0-9]*$ ]]; then
  printf 'CONCURRENCY must be a positive integer.\n' >&2
  exit 1
fi

printf 'Sending %s requests to %s with concurrency %s.\n' "$REQUESTS" "$URL" "$CONCURRENCY"

for ((request_number = 1; request_number <= REQUESTS; request_number++)); do
  curl \
    --connect-timeout 5 \
    --max-time 30 \
    --retry 2 \
    --silent \
    --show-error \
    --output /dev/null \
    --user-agent "CVAsCode-load-test/1.0" \
    --write-out "request=${request_number} status=%{http_code} time=%{time_total}s\n" \
    "$URL" &

  if ((request_number % CONCURRENCY == 0)); then
    wait
  fi
done

wait
printf 'Load test complete.\n'
