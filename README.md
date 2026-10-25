# MikroTik configs

RouterOS v7 configuration templates, with room for per-site overlays and shared scripts. Templates are paste-ready `.rsc` baselines. A live site is a copy of a template plus local tokens — those filled values stay off this repo.

## Start here

- [SOHO gateway + CAP baseline](templates/soho/README.md) — current template family (edge routers, a CRS distribution switch, and CAP boards).
- [Conventions](docs/conventions.md) — naming, VLAN skeleton, firewall zones, RouterOS version policy, and the no-legacy-wireless rule.
- [Site overlays](sites/README.md) — where a real install diverges from a template.
- [Legacy defaults](archive/legacy-defaults/README.md) — historical device default configs. Not a pattern for new installs.

## Folder map

```
/
  README.md
  LICENSE                              # Unlicense
  docs/
    conventions.md                     # naming, VLANs, zones, version + wireless policy
  templates/
    soho/                              # gateway + CAP baseline (see templates/soho/README.md)
      gateway/                         # RB5009, L009, hAP ax²/ax³, CCR, CRS-switch
      cap/                             # cAP ax, hAP ax²/ax³, wAP ax, cAP ac
    # future families: templates/isp/, templates/event/, …
  sites/                               # per-site overlays (sites/MHT/, sites/19H/, …) — no secrets
  scripts/                             # shared RouterOS scripts (stub)
  reference/                           # driver notes and research (stub)
  archive/
    legacy-defaults/                   # historical *.rsc defaults
```

Add another template family as `templates/<family>/` with its own README and device scripts. Add a site as `sites/<SITE_CODE>/`. Put scripts used by more than one family in `scripts/`.

## Policy

- **RouterOS v7** for every new template and site overlay. The SOHO pack’s current reference versions are in [templates/soho/README.md](templates/soho/README.md).
- **wifi-qcom / wifi-qcom-ac only.** New installs use `wifi-qcom` on ax and `wifi-qcom-ac` on ac. Do not add the legacy `wireless` package, and do not run a second CAPsMAN beside the v7 wifi CAPsMAN.
- **No secrets in git.** Never commit live PSKs, passwords, certificates, or exports (including `/export show-sensitive` and binary backups). Copy [templates/soho/SITE-VARS.example](templates/soho/SITE-VARS.example) beside a site and leave `CHANGE_ME_*` tokens in anything that is committed. Set passphrases on the device.
