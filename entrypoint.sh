#!/bin/sh
# Hummingbot Railway entrypoint
# 1. migrate runtime dirs into /home/hummingbot/data (the volume) via symlinks
#    (done on every boot so template updates propagate; user data persists)
# 2. seed simple_pmm.yml on first boot (never overwrites user edits)
# 3. start the stdlib health server on $PORT
# 4. exec hummingbot in native headless mode (HEADLESS_MODE=true)
set -e

HB=/home/hummingbot
DATA="$HB/data"
TPL=/opt/hb-template

echo "[hb-entrypoint] migrating runtime dirs to volume..."
mkdir -p "$DATA/conf" "$DATA/logs" "$DATA/certs" "$HB/logs"

for d in conf logs certs; do
  if [ -L "$HB/$d" ]; then
    # refresh stale symlink target
    rm -f "$HB/$d"
    ln -s "$DATA/$d" "$HB/$d"
  elif [ -d "$HB/$d" ] && [ -n "$(ls -A "$HB/$d" 2>/dev/null)" ] && [ ! -e "$DATA/$d/".migrated ]; then
    echo "[hb-entrypoint] migrating existing $d -> data/$d"
    cp -a "$HB/$d/." "$DATA/$d/" 2>/dev/null || true
    touch "$DATA/$d/.migrated"
    rm -rf "$HB/$d"
    ln -s "$DATA/$d" "$HB/$d"
  elif [ -d "$HB/$d" ]; then
    cp -a "$HB/$d/." "$DATA/$d/" 2>/dev/null || true
    rm -rf "$HB/$d"
    ln -s "$DATA/$d" "$HB/$d"
  else
    mkdir -p "$HB/$d"
    ln -sfn "$DATA/$d" "$HB/$d"
  fi
done

# Seed the sample strategy config on first boot (idempotent)
if [ ! -f "$DATA/conf/scripts/simple_pmm.yml" ]; then
  echo "[hb-entrypoint] Seeding simple_pmm.yml..."
  mkdir -p "$DATA/conf/scripts"
  cp "$TPL/seed/simple_pmm.yml" "$DATA/conf/scripts/simple_pmm.yml"
fi

# Apply HBOT_* env overrides onto the strategy config (type-coerced)
python3 "$TPL/patch_strategy.py" "$DATA/conf/scripts/simple_pmm.yml" || true

# First-boot keystore bootstrap: headless quickstart cannot create
# conf/.password_verification (that path only exists behind the interactive
# new-password prompt) and would crash in validate_password().
if [ ! -f "$DATA/conf/.password_verification" ]; then
  echo "[hb-entrypoint] First boot: initializing keystore password..."
  if [ -n "$CONFIG_PASSWORD" ]; then
    /opt/conda/envs/hummingbot/bin/python "$TPL/init_password.py" "$CONFIG_PASSWORD"
  else
    /opt/conda/envs/hummingbot/bin/python "$TPL/init_password.py" "$(head -c 24 /dev/urandom | base64 | tr -d '/+=' )"
  fi
fi

echo "[hb-entrypoint] Starting health server on port $PORT..."
python3 "$TPL/healthcheck_server.py" &
HEALTH_PID=$!
trap 'kill $HEALTH_PID 2>/dev/null || true' EXIT INT TERM

echo "[hb-entrypoint] Starting Hummingbot headless (SCRIPT_CONFIG=$SCRIPT_CONFIG)..."
cd "$HB"
# Launch via the conda env's python (system python lacks hummingbot deps).
# Flags mirror upstream docker-compose-headless: quickstart reads --v2 (file
# name in conf/scripts/), -p (keystore password), --headless (no CLI/TUI).
HB_ARGS="--headless --v2 \"$SCRIPT_CONFIG\""
if [ -n "$CONFIG_PASSWORD" ]; then
  HB_ARGS="$HB_ARGS -p \"$CONFIG_PASSWORD\""
fi
eval exec /opt/conda/envs/hummingbot/bin/python ./bin/hummingbot_quickstart.py $HB_ARGS 2>> "$HB/logs/errors.log"