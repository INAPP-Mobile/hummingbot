# Hummingbot — Automated Crypto Market-Making & Trading Bots

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.com/deploy/hummingbot)

> ⚠️ **Trading involves risk.** Paper trading (simulated fills, no real funds) is the default in this template. Always validate a strategy in paper mode before connecting real exchange accounts. Use at your own risk.

Hummingbot is the open-source framework for building and running automated trading strategies — market making, arbitrage, and custom scripts — across 140+ centralized and decentralized exchanges. This template runs the official pinned Docker image (`hummingbot/hummingbot:version-2.16.0`) in **headless mode**: the bot boots straight into a pure market-making strategy on Kraken paper trading, no interactive terminal or SSH required. <!-- Template icon: https://files.catbox.moe/p5rrtv.svg -->

# Deploy and Host

Deploy with one click. On first boot the container seeds a sample strategy config (`simple_pmm` — pure market making) onto a persistent Railway volume, applies any `HBOT_*` environment overrides, starts an HTTP health endpoint, and launches the bot headlessly. Strategy configs, connector credentials, logs, and trade data persist on the volume across redeploys.

## About Hosting

- Single service, official pinned `hummingbot/hummingbot:version-2.16.0` image — no source build
- Runs in headless mode via the image's native `HEADLESS_MODE`/`SCRIPT_CONFIG` env vars (no TTY needed)
- Default strategy: `simple_pmm` on `kraken_paper_trade` — simulated fills, zero exchange keys needed
- Persistent Railway volume at `/home/hummingbot/data` — strategy configs, encrypted keystore, logs, data
- Built-in HTTP health endpoint on port 8080 (`/health` reports bot process liveness)
- Tune strategy parameters via `HBOT_*` env vars — no need to edit YAML by hand
- `hbot` CLI is available inside the container for advanced control: `hbot status --json`, `hbot stop`, `hbot connect kraken`, etc.

## Why Deploy

- **Zero-touch always-on market making**: your quoting strategy runs 24/7 with automatic restarts and persistent state, instead of a terminal session on your laptop
- **Paper-trade first**: every `*_paper_trade` connector simulates order fills against live market data — learn and tune with zero risk before wiring real funds
- **Config-as-environment**: change exchange, pair, spreads, and order size from Railway's variable editor; the entrypoint applies them on each deploy
- **Strategy files on a volume**: hot-swap strategies by editing YAML on the volume or pushing new scripts, then restart

## Common Use Cases

- **Paper trading market making**: validate spread/refresh parameters on `kraken_paper_trade` before going live
- **Live spot market making**: add Kraken (or any supported CEX) API keys via the encrypted keystore
- **Custom V2 strategies**: drop your own script into `conf/scripts/` on the volume, point `SCRIPT_CONFIG` at it, redeploy
- **Strategy prototyping**: use the bundled sample scripts (`simple_pmm`, `simple_vwap`, `v2_funding_rate_arb`, ...) as starting points

## Dependencies for Hummingbot

**Public Dependencies:** None — everything runs in a single container with state on the attached volume.

**Private Dependencies:**
- Exchange API key + secret (only for live trading — paper trading needs none)
- Optional: Hummingbot Gateway (self-hosted DEX middleware) for DEX connectors — not included in this single-service template

### Deployment Dependencies

- **hummingbot/hummingbot:version-2.16.0** — official pinned Docker image (Docker Hub)
- **Kraken REST/WebSocket API** — market data + simulated fills for the default paper-trade connector
- **SQLite + file storage** — trade history and configs live on the attached Railway volume (no external database service needed)

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | Health endpoint port — must match the Railway domain target port |
| `HEADLESS_MODE` | `true` | Headless mode (no TUI). Keep true on Railway |
| `SCRIPT_CONFIG` | `simple_pmm.yml` | Strategy config file to run (from `conf/scripts/`) |
| `CONFIG_PASSWORD` | auto-generated | Keystore password encrypting connector API keys on the volume |
| `HBOT_EXCHANGE` | `kraken_paper_trade` | Connector id (any `*_paper_trade` needs no keys) |
| `HBOT_TRADING_PAIR` | `ETH-USD` | Market to make |
| `HBOT_ORDER_AMOUNT` | `0.05` | Order size (base currency) |
| `HBOT_BID_SPREAD` / `HBOT_ASK_SPREAD` | `0.5` / `0.5` | Spreads from mid price, in percent |
| `HBOT_ORDER_REFRESH_TIME` | `30` | Seconds between order refreshes |
| `HBOT_PRICE_TYPE` | `mid` | `mid`, `last`, `best_bid`, or `best_ask` |
| `HBOT_KILL_SWITCH_ENABLED` / `HBOT_KILL_SWITCH_RATE` | `false` / `-10.0` | Emergency stop on drawdown |

## Post-Deploy Setup

1. Watch the deploy logs — the bot seeds its config, connects to Kraken paper trading, and starts quoting
2. Check `/health` on your deployment URL — it reports the bot process liveness
3. Verify trading activity: `railway run --service hummingbot -- hbot status --json` (or `hbot logs`)
4. Go live when ready: `railway run --service hummingbot -- hbot connect kraken`, set `HBOT_EXCHANGE=kraken`, and redeploy
5. Swap strategies: edit `conf/scripts/*.yml` on the volume (or add new scripts), then redeploy

## Links

- [Hummingbot documentation](https://hummingbot.org)
- [V2 strategy scripts](https://hummingbot.org/v2-strategies/)
- [Sample scripts repo](https://github.com/hummingbot/hummingbot/tree/master/scripts)
- [Hummingbot GitHub](https://github.com/hummingbot/hummingbot)
- [hbot CLI reference](https://hummingbot.org)