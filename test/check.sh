#!/usr/bin/env bash
# Starts the lab the way the platform runs it and checks it does what the README says.
#   test/check.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
project="lab-check"
override="$root/test/hardened.generated.yaml"

# Every service gets the hardening, and memory-swap equal to its memory limit.
services=$(docker compose -f "$root/compose.yaml" config --services)
{
  cat "$root/test/hardened.yaml"
  echo "services:"
  for s in $services; do
    mem=$(docker compose -f "$root/compose.yaml" config --format json \
      | python3 -c "import json,sys; d=json.load(sys.stdin)['services']['$s']; print(((d.get('deploy') or {}).get('resources') or {}).get('limits',{}).get('memory') or 536870912)")
    printf '  %s:\n    <<: *hardened\n    hostname: %s\n    memswap_limit: %s\n' "$s" "$s" "$mem"
  done
} > "$override"

compose() { docker compose -p "$project" -f "$root/compose.yaml" -f "$override" "$@"; }
cleanup() { docker compose -p "$project" down -v --remove-orphans >/dev/null 2>&1 || true; rm -f "$override"; }
trap cleanup EXIT
docker compose -p "$project" down -v --remove-orphans >/dev/null 2>&1 || true

# local.yaml, the file the README tells you to run on your own machine, is valid beside it.
docker compose -f "$root/compose.yaml" -f "$root/local.yaml" config --quiet

docker build -q -t lab-check-probe -f "$root/test/Dockerfile.probe" "$root/test" >/dev/null
compose up -d --wait --wait-timeout 300

# The hardening really took: a check that ran without it proves nothing.
for c in $(compose ps -q); do
  docker inspect "$c" --format '{{.Name}} {{.HostConfig.CapDrop}} {{.HostConfig.SecurityOpt}} {{.HostConfig.PidsLimit}} {{.HostConfig.Memory}}={{.HostConfig.MemorySwap}}' \
    | tee /dev/stderr | grep -q '\[ALL\] \[no-new-privileges\] 256 \([0-9]*\)=\1$' || { echo "not hardened" >&2; exit 1; }
done
NET="${project}_lab" bash "$root/test/lab.sh"

# What was written survives the lab being stopped and started, because the append-only file
# is in a named volume: the same promise the README makes about persistence.
probe() { docker run --rm --network "${project}_lab" lab-check-probe bash -c "$1"; }
V='v() ( printf "%s\r\n" "$*" | nc -w 1 valkey 6379 | tr -d "\r" )'
probe "$V"'; v SET keepme still-here >/dev/null'
compose down
compose up -d --wait --wait-timeout 300
echo "- a key written before a stop is still there after the start"
out=$(probe "$V"'; v GET keepme | tail -n 1')
[ "$out" = "still-here" ] || { echo "lost the key across a restart: [$out]" >&2; exit 1; }
echo "- there is no way out to the internet"
if probe 'curl -s -m 4 -o /dev/null https://example.com'; then echo "the lab reached the internet" >&2; exit 1; fi
echo "ok"
