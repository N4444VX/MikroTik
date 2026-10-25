# SOHO baseline templates (RouterOS 7.24.x)

Reusable gateway + CAP configs for WNC Upfit small-business / SOHO installs.
Derived from project **MHT** (RB5009 + cAP ax + wAP ax) plus the hardening fixes
from the MHT review. **No legacy `wireless` package.** ax = `wifi-qcom`;
cAP ac = `wifi-qcom-ac` only.

## Layout

This pack lives at `templates/soho/` in the configs repo.

```
templates/soho/
  README.md          ← you are here
  DESIGN.md          ← VLAN / zones / SSID map / per-platform notes
  CHECKLIST.md       ← post-apply verification
  COMMON.md          ← shared design blocks (ROS has no #include)
  SITE-VARS.example  ← copy per site; fill tokens (no real secrets in git)
  gateway/
    RB5009.rsc       ← primary reference (CAPsMAN + edge)
    L009.rsc
    hAPax2.rsc       ← edge + local wifi-qcom + CAPsMAN
    hAPax3.rsc
    CCR.rsc          ← CCR family, no wifi, CAPsMAN only
    CRS-switch.rsc   ← CRS variants as L2 distribution (+ optional CAPsMAN); not NAT edge
  cap/
    cAPax.rsc
    hAPax2.rsc       ← CAP + ether access-port placeholders
    hAPax3.rsc
    wAPax.rsc
    cAPac.rsc        ← wifi-qcom-ac; bridge PVID VLANs; no datapath vlan-id
```

## How to customize for a new site

1. Copy `templates/soho/` (or the files you need) into a site overlay such as `sites/MHT/` or `sites/19H/`. Do not commit that copy once it contains real PSKs or passwords.
2. In every `.rsc` you will apply, search-replace:
   - `SITE_CODE` → short site tag (`MHT`, `19H`, …)
   - `SITE_IDENTITY_*` → device identity strings
   - `CHANGE_ME_*` passphrases → set **locally**, never commit
   - `BTH_SUBNET` → your Back To Home / WG client range (or remove from `available-from`)
   - `COUNTRY` → regulatory domain (`"United States"` for NC)
   - Port roles: CAP trunks, phone access, NVR-admin, spares (see DESIGN.md)
3. Decide which skeleton VLANs are **active** vs **safe-empty** (DHCP disabled, not on access ports).
4. Apply order (fresh site):
   1. Gateway first (edge + CAPsMAN)
   2. Reset each CAP to CAP mode / paste CAP template
   3. Confirm CAPs join (`/interface wifi capsman remote-cap print`)
   4. Optionally enable `require-peer-certificate=yes` after certs issue
5. Run **CHECKLIST.md**.

## Apply order (existing site)

Backup → Safe Mode → CAP hardening/VLAN filtering first if already live → gateway
firewall/zone changes last (lockout risk). Prefer console or known mgmt IP.

## Upgrade policy

- Keep GW and CAPs on the **same** RouterOS minor (suggest-same-version).
- Current stable reference: **7.24.5**; long-term **7.23.8**.
- Mixed ax (arm64) + ac (arm): fill `/caps-pkgs` (or `/updates`) with
  `routeros-arm64`, `wifi-qcom-arm64`, `routeros-arm`, `wifi-qcom-ac-arm`
  for the target version. CAPsMAN alone only upgrades same-arch as itself.
- On 16 MB ac boards: check free flash before every upgrade; Netinstall with
  only routeros + wifi-qcom-ac if flash fills.

## Mixed ax + ac notes (short)

- Provisioning: **ax rules first** (`5ghz-ax`, `2ghz-ax`), then ac (`5ghz-ac`, `2ghz-n`).
- `datapath.vlan-id` only on wifi-qcom (ax). ac CAPs: bridge `pvid` + `slaves-static=yes`.
- FT across mixed fleets: `ft-preserve-vlanid=yes` on ax profiles, `=no` on ac (forum; test).
- Neighbor discovery `mode=tx-only` on qcom-ac CAPs (kernel-failure workaround).
- No legacy `wireless` / no dual CAPsMAN in these templates.

## CRS note

`templates/soho/gateway/CRS-switch.rsc` is a **VLAN-aware distribution switch**, not a NAT edge.
Pair it with RB5009 / CCR / hAP ax as the WAN router. Optional CAPsMAN-on-CRS
comments are included; prefer CAPsMAN on the edge router’s CPU.
