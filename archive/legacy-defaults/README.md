# Legacy default configs

Factory-style RouterOS default scripts kept from when this repo was a flat
list of files. Content is unchanged; only the path moved.

| File | Device | Why it is archived |
|---|---|---|
| `RB960PGS-DefaultConfig.rsc` | hEX PoE (RB960PGS) | Stock defconf-style script, not the SOHO baseline |
| `RBmAP2nD-DefaultConfig.rsc` | mAP 2nD | Stock defconf, including the legacy `wireless` package (`wlan1`, `ap-bridge`) |

Do not use these as the pattern for new installs. New work is RouterOS v7
with `wifi-qcom` / `wifi-qcom-ac` only. See [docs/conventions.md](../../docs/conventions.md).

They are not published under `staging/` and field scripts should not fetch them.
