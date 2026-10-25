# Scripts

RouterOS scripts in this directory are safe to publish: no PSKs, no tokens.
`scripts/publish-soho-staging.sh` copies every `*.rsc` here to
`staging/scripts/latest/` and copies the SOHO templates to
`staging/soho/latest/`. Devices fetch the staging copies.

| Script | Purpose |
|---|---|
| [apply_from_url.rsc](apply_from_url.rsc) | Fetch one named file from `staging/<family>/latest/<role>/<model>.rsc` and `/import` it. Edit `siteCode`, `role`, and `model` at the top. |
| [pull_capsman_packages.rsc](pull_capsman_packages.rsc) | Download RouterOS + wifi npks from a GitHub Release into the gateway's `/caps-pkgs` (CAPsMAN `package-path`). |
| [publish-soho-staging.sh](publish-soho-staging.sh) | Maintainer helper. Not fetched by routers. |

Field URLs, the placeholder-PSK guard, and the private-repo case:
[docs/field-pull.md](../docs/field-pull.md).

Package filenames and the `soho-pkgs-<version>` tag:
[staging/packages/README.md](../staging/packages/README.md).
