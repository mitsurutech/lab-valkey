#!/usr/bin/env bash
# What the README promises, checked from inside the lab's own network: run by check.sh. It
# types what the lesson types, with the same one-line function over nc that the platform's
# terminal (which has no valkey-cli) is given, so a lab that passes here answers the lesson.
set -euo pipefail
: "${NET:?run through test/check.sh}"
probe() { docker run --rm --network "$NET" lab-check-probe bash -c "$1"; }
# The reply of each command, carriage returns removed, as the README shows them.
V='v() ( printf "%s\r\n" "$*" | nc -w 1 valkey 6379 | tr -d "\r" )'
expect() { [ "$1" = "$2" ] || { echo "expected [$2] got [$1]" >&2; exit 1; }; }

echo "- the server answers PING, and SET then GET returns what was stored"
probe "$V"'
set -eu
[ "$(v PING)" = "+PONG" ]
[ "$(v SET greeting hello)" = "+OK" ]
[ "$(v GET greeting | tail -n 1)" = "hello" ]
[ "$(v GET nothing-here)" = "\$-1" ]
echo "- a key with an expiry counts down and then is gone"
[ "$(v SET session abc EX 2)" = "+OK" ]
t=$(v TTL session | tr -d ":")
[ "$t" -ge 1 ] && [ "$t" -le 2 ]
sleep 3
[ "$(v GET session)" = "\$-1" ]
echo "- a list keeps its order"
v DEL queue >/dev/null
[ "$(v RPUSH queue first second third)" = ":3" ]
[ "$(v LRANGE queue 0 -1 | grep -v "^[*$]" | tr "\n" " ")" = "first second third " ]
[ "$(v LPOP queue | tail -n 1)" = "first" ]
echo "- a hash holds fields, and a counter counts"
v DEL user:1 visits >/dev/null
[ "$(v HSET user:1 name Ada age 36)" = ":2" ]
[ "$(v HGET user:1 name | tail -n 1)" = "Ada" ]
[ "$(v INCR visits)" = ":1" ]
[ "$(v INCR visits)" = ":2" ]
[ "$(v INCRBY visits 10)" = ":12" ]
echo "- persistence is on, in the append-only file"
[ "$(v CONFIG GET appendonly | tail -n 1)" = "yes" ]
'
echo "  ok"
