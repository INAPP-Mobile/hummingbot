#!/usr/bin/env python3
"""First-boot keystore bootstrap for headless Hummingbot.

Upstream quickstart only CREATES the password verification file through the
interactive new-password prompt; headless mode with a pre-set CONFIG_PASSWORD
crashes on a fresh conf dir (validate_password -> FileNotFoundError on
conf/.password_verification). This script replicates the interactive first
run: store_password_verification(ETHKeyFileSecretManger(password)).

Run with the conda env python. Idempotent-safe: entrypoint only calls it when
the verification file is missing.
"""
import sys

sys.path.insert(0, "/home/hummingbot")

from hummingbot.client.config.config_crypt import (  # noqa: E402
    ETHKeyFileSecretManger,
    store_password_verification,
)

if len(sys.argv) != 2 or not sys.argv[1]:
    print("usage: init_password.py <password>", file=sys.stderr)
    sys.exit(2)

sm = ETHKeyFileSecretManger(sys.argv[1])
store_password_verification(sm)
print("[hb-init] keystore password verification file created")