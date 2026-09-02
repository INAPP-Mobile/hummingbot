#!/usr/bin/env python3
"""Apply HBOT_* env overrides onto the seeded strategy config (line-level,
no YAML dependency). Values are type-coerced: numeric/bool stay bare, others
get quoted. Only keys present in the file are patched.
"""
import os
import sys

ENV_MAP = {
    "exchange": "HBOT_EXCHANGE",
    "trading_pair": "HBOT_TRADING_PAIR",
    "order_amount": "HBOT_ORDER_AMOUNT",
    "bid_spread": "HBOT_BID_SPREAD",
    "ask_spread": "HBOT_ASK_SPREAD",
    "order_refresh_time": "HBOT_ORDER_REFRESH_TIME",
    "price_type": "HBOT_PRICE_TYPE",
    "kill_switch_enabled": "HBOT_KILL_SWITCH_ENABLED",
    "kill_switch_rate": "HBOT_KILL_SWITCH_RATE",
}


def _is_number(val: str):
    try:
        float(val)
        return True
    except ValueError:
        return False


def main(path: str) -> None:
    lines = open(path).read().splitlines()
    out = []
    applied = []
    for line in lines:
        key = line.split(":", 1)[0].strip()
        env_key = ENV_MAP.get(key)
        if env_key and os.environ.get(env_key):
            val = os.environ[env_key].strip()
            if val.lower() in ("true", "false") or _is_number(val):
                line = f"{key}: {val}"
            else:
                line = f'{key}: "{val}"'
            applied.append(f"{key}={val}")
        out.append(line)
    open(path, "w").write("\n".join(out) + "\n")
    if applied:
        print("[hb-entrypoint] strategy overrides: " + ", ".join(applied))


if __name__ == "__main__":
    main(sys.argv[1])