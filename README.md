# MikroTik

RouterOS v7 configuration templates and a stable staging tree that field
routers can pull with `/tool fetch`.

Editable baselines live under `templates/`. Devices fetch published copies
under `staging/`. Site-specific overlays live under `sites/` and must not
contain live secrets. This repository is public.

## Policy

- New installs target **RouterOS v7**. The SOHO baseline reference is stable
  **7.24.5** (long-term **7.23.8**). Keep a site's gateway and CAPs on the
  same minor.
- New Wi-Fi uses **`wifi-qcom`** (ax) or **`wifi-qcom-ac`** (IPQ-401x ac, such
  as cAP ac). Do not build new configs on the legacy `wireless` package.
- Never commit live PSKs, passwords, API tokens, or `/export show-sensitive`
  output. Templates keep `CHANGE_ME_*` placeholders. Fill those on the device
  or in a private copy.

Naming, VLAN IDs, and firewall zones: [docs/conventions.md](docs/conventions.md).

## Folder map

| Path | Role |
|---|---|
| [templates/soho/](templates/soho/) | Editable SOHO gateway + CAP baseline (source of truth) |
| [staging/](staging/) | Field-pull root. Stable paths for `/tool fetch` |
| [staging/soho/latest/](staging/soho/latest/) | Current recommended SOHO `.rsc` files |
| [staging/packages/](staging/packages/) | Notes for RouterOS / wifi `.npk` layout (binaries via Releases) |
| [staging/scripts/latest/](staging/scripts/latest/) | Fetchable shared scripts with stable names |
| [scripts/](scripts/) | Source for those shared scripts, plus the publish helper |
| [sites/](sites/) | Per-site overlays. Placeholder only; no live secrets |
| [docs/](docs/) | Conventions and field-pull contract |
| [reference/](reference/) | Driver notes and research stubs |
| [archive/legacy-defaults/](archive/legacy-defaults/) | Older factory-style defaults (not for new installs) |

Room is left for more families (`templates/isp/`, `templates/event/`, matching
`staging/` trees) without moving the SOHO pull paths.

## Field-pull quickstart

On a RouterOS v7 device (public repo, raw GitHub):

```
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/soho/latest/cap/cAPax.rsc" dst-path=cAPax.rsc
/import file-name=cAPax.rsc
```

Gateway files in that tree still contain `CHANGE_ME_*` passphrases. Edit a
site copy before importing one onto production gear. Prefer a no-defaults
reset over merging onto a live config.

Shared fetch/import helper and CAPsMAN package pull:

```
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/scripts/latest/apply_from_url.rsc" dst-path=apply_from_url.rsc
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/scripts/latest/pull_capsman_packages.rsc" dst-path=pull_capsman_packages.rsc
```

Full contract, private-repo auth, and Release assets: [docs/field-pull.md](docs/field-pull.md).

## Keeping staging in sync

Edit under `templates/soho/`, then from the repo root:

```
scripts/publish-soho-staging.sh
```

Commit the template change and the refreshed `staging/soho/latest/` copies
together. `latest` is a copy on purpose: a Git symlink would make raw GitHub
return the link text instead of the script.

## License

[Unlicense](LICENSE). Public domain.
