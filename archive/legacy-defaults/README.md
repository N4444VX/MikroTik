# Legacy default configs

Historical MikroTik default-configuration scripts. They were the only configs in this repo before the `templates/` / `sites/` layout. Content is unchanged; only the path moved.

They are stock defconf scripts, not install baselines. Do not copy them into `templates/` or `sites/`.

| File | Device | Notes |
|---|---|---|
| `RB960PGS-DefaultConfig.rsc` | RB960PGS (hEX PoE) | Factory-style defconf: WAN on ether1, LAN bridge, DHCP |
| `RBmAP2nD-DefaultConfig.rsc` | RBmAP2nD (mAP 2nD) | Factory-style defconf, including the legacy `wireless` package |

New work is RouterOS v7 with `wifi-qcom` or `wifi-qcom-ac` only. See [docs/conventions.md](../../docs/conventions.md) and [templates/soho/](../../templates/soho/README.md).
