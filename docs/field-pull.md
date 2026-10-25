# Field pull

`staging/` is the tree devices fetch. Paths under `staging/*/latest/` are a
contract: renames and moves break routers that already have the URL saved.

Edit baselines in `templates/`. Publish `.rsc` copies into `staging/` with
`scripts/publish-soho-staging.sh`, then commit both. Do not point `latest` at
symlinks. GitHub's raw file URL returns the symlink text (the target path),
not the script, so `/import` would fail.

Docs (`DESIGN.md`, `CHECKLIST.md`, and the rest) are not mirrored. Devices
pull scripts only.

## Raw URLs (this repo is public)

Base:

```
https://raw.githubusercontent.com/N4444VX/MikroTik/main/
```

`main` is the branch. A raw URL always serves the file as it exists on that
branch tip. `staging/soho/latest/` is how we keep a stable name while the
bytes change; it is not a separate Git ref.

### Fetch a config and import it

CAP example, run on the device:

```
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/soho/latest/cap/cAPax.rsc" dst-path=cAPax.rsc
/import file-name=cAPax.rsc
```

Gateway example (placeholders still in the file — read the warning below):

```
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/soho/latest/gateway/RB5009.rsc" dst-path=RB5009.rsc
/import file-name=RB5009.rsc
```

`/tool fetch` writes `dst-path` on the router. `/import file-name=` runs that
file as RouterOS commands. These baselines expect a no-defaults reset, not a
merge onto a router that already has bridges, DHCP, and firewall rules.
Take a backup and use Safe Mode first.

SOHO gateway scripts set `passphrase="CHANGE_ME_*"`. Importing one unchanged
installs those literal placeholders. Replace them on a private copy before a
production import. CAP scripts do not contain PSKs; CAPsMAN pushes security
after the CAP joins. They do set identity to `SITE_CODE_...` until you edit
that line.

`check-certificate=yes` is appropriate for `raw.githubusercontent.com` on
RouterOS v7 with the built-in CA bundle. If fetch fails the TLS check, fix
the clock (`/system ntp client`) before considering anything else.

### Expected SOHO paths

| Device | URL path under `main/` |
|---|---|
| RB5009 gateway | `staging/soho/latest/gateway/RB5009.rsc` |
| L009 | `staging/soho/latest/gateway/L009.rsc` |
| hAP ax² as gateway | `staging/soho/latest/gateway/hAPax2.rsc` |
| hAP ax³ as gateway | `staging/soho/latest/gateway/hAPax3.rsc` |
| CCR | `staging/soho/latest/gateway/CCR.rsc` |
| CRS distribution switch | `staging/soho/latest/gateway/CRS-switch.rsc` |
| cAP ax | `staging/soho/latest/cap/cAPax.rsc` |
| hAP ax² as CAP | `staging/soho/latest/cap/hAPax2.rsc` |
| hAP ax³ as CAP | `staging/soho/latest/cap/hAPax3.rsc` |
| wAP ax | `staging/soho/latest/cap/wAPax.rsc` |
| cAP ac | `staging/soho/latest/cap/cAPac.rsc` |
| Fetch + import helper | `staging/scripts/latest/apply_from_url.rsc` |
| CAPsMAN package pull | `staging/scripts/latest/pull_capsman_packages.rsc` |

Future families use the same shape: `staging/<family>/latest/gateway/` and
`staging/<family>/latest/cap/`. A pinned snapshot, if we add one later, would
be `staging/soho/<version>/...` with the same filenames. `latest` stays the
moving recommended set.

## Helper script

`apply_from_url.rsc` fetches one of the paths above and imports it. Edit the
`siteCode`, `role`, and `model` locals at the top (comments in the file list
the legal values). Default is a cAP ax pull.

```
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/scripts/latest/apply_from_url.rsc" dst-path=apply_from_url.rsc
```

Open the file (or `/import` it after editing the locals). Gateway role refuses
to import until `allowPlaceholderPsk` is set to `yes`, so a lab can load the
unedited baseline and a production router does not silently take
`CHANGE_ME_*` passphrases.

Source copy: [scripts/apply_from_url.rsc](../scripts/apply_from_url.rsc).
The staging copy is what devices fetch.

## CAPsMAN packages

Gateway templates set:

```
/interface wifi capsman set package-path=/caps-pkgs upgrade-policy=suggest-same-version
```

`/caps-pkgs` is a directory **on the gateway**, not a URL. CAPsMAN serves
whatever `.npk` files are in that directory and only upgrades a CAP that
matches its own architecture. The pull script downloads a known set into that
directory from a GitHub Release.

```
/tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/scripts/latest/pull_capsman_packages.rsc" dst-path=pull_capsman_packages.rsc
/import file-name=pull_capsman_packages.rsc
```

Edit `rosVersion` in the script first. `source` defaults to `release`
(tag `soho-pkgs-<version>`). Set `source` to `raw` to fetch
`staging/packages/<arch>/<version>/<file>.npk` instead. This repository does
not commit `.npk` binaries, so the raw path 404s until blobs are actually
added, and a Release asset 404s until that tag is published. Layout and
filenames: [staging/packages/README.md](../staging/packages/README.md).

RouterOS `/tool fetch` follows redirects on current v7, which GitHub Releases
use. If a release asset fetch fails after the redirect, download the npks on
a workstation and upload them to the gateway's `/caps-pkgs` (WinBox, SCP, or
FTP). Do not point `package-path` at a URL.

## Private repositories

This repo is public, so raw URLs work with no credentials. A private repo
does not. `raw.githubusercontent.com` then returns 404 to anonymous clients.

Options, in the order we want them:

1. Keep publishing field-pull files from a public repo (this one) and keep
   secrets out of it. Production PSKs are applied on the device after import.
2. Attach a secret-bearing site script as a Release asset on a **private**
   repository and fetch it with a fine-scoped read token. The token will be
   stored on the router and will show up in an export. Do not commit that
   export here.

Header shape (replace the token locally; do not commit it):

```
/tool fetch url="https://raw.githubusercontent.com/ORG/PRIVATE/main/path/file.rsc" \
    http-header-field="Authorization: Bearer <TOKEN>" \
    dst-path=file.rsc check-certificate=yes
```

Release assets on a private repo use the API (`Accept: application/octet-stream`
and the same `Authorization` header) rather than the public
`/releases/download/` URL. Prefer a workstation upload into `/caps-pkgs` over
embedding a token in a script that gets saved on the router.

## What not to fetch

- `templates/` — source of truth for humans. The bytes should match `latest`,
  but the supported URL is `staging/.../latest/...`.
- `sites/` — overlays are not a pull root, and they must not grow real PSKs.
- `archive/` — old defaults, including legacy wireless.
- `staging/packages/**/*.npk` — not in git. Use Releases.
