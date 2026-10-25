# Conventions

Repo-wide rules for new RouterOS work. The SOHO pack in [`templates/soho/`](../templates/soho/README.md) is the reference implementation. Another template family may add VLANs or zones, but it should extend this skeleton and document the exception in that family’s own design notes.

## RouterOS version policy

- New templates and site overlays target **RouterOS v7** only.
- Keep a CAPsMAN gateway and its CAPs on the **same minor** (`upgrade-policy=suggest-same-version`).
- SOHO reference track: stable **7.24.5**, long-term **7.23.8**. See the upgrade notes in [`templates/soho/README.md`](../templates/soho/README.md) for mixed arm64 (ax) and arm (ac) package sets.
- Do not add v6-only syntax (`/interface wireless`, legacy CAPsMAN) to new files.

## No legacy wireless

New installs use the v7 wifi drivers only:

| Hardware | Package |
|---|---|
| 802.11ax (cAP ax, hAP ax²/ax³, wAP ax, …) | `wifi-qcom` |
| 802.11ac managed by CAPsMAN (cAP ac, …) | `wifi-qcom-ac` |

Do not install the legacy `wireless` package. Do not provision a second, legacy CAPsMAN next to `/interface wifi capsman`. ax datapaths may set `vlan-id`; ac configs must not — they use bridge `pvid` and `slaves-static`.

`archive/legacy-defaults/RBmAP2nD-DefaultConfig.rsc` is a historical stock default that still speaks legacy wireless. Leave it in the archive. Do not copy it into `templates/` or `sites/`.

## Naming

| Object | Pattern | Example |
|---|---|---|
| Site tag | short code, used as a token | `SITE_CODE` → `MHT`, `19H` |
| Identity | `SITE_CODE_ROLE_LOCATION` | `SITE_CODE_RB5009_GW` |
| VLAN interface | `VLAN` + three-digit ID, comment = role | `VLAN004` comment `CORPORATE` |
| Interface lists | fixed zone names | `WAN`, `LAN`, `MGMT`, `CAMERA`, `PBX`, `STAFF`, `VENDOR`, `GUEST`, `REMOTE` |
| Wi-Fi security | `sec-<ROLE>` | `sec-CORP`, `sec-GUEST` |
| Channels | `ch-2g`, `ch-5g` | |
| Datapaths | `dp-ax-<ROLE>`, `dp-ac` | `dp-ax-CORP`; one shared `dp-ac` (no vlan-id) |
| Configurations | `ax-*`, `ac-*` | provisioning order: ax rules, then ac |
| Template path | `templates/<family>/gateway/` or `.../cap/` | `templates/soho/gateway/RB5009.rsc` |
| Site overlay | `sites/<SITE_CODE>/` | `sites/MHT/` |

`LAN` is trusted only: the bridge (management, untagged) plus `VLAN004`. Guest, vendor, staff, camera, PBX, and remote must not also be members of `LAN`.

Passphrases and admin passwords are tokens (`CHANGE_ME_CORP`, `SET_LOCALLY`), never real values in git. Per-site fill-in sheet: [`templates/soho/SITE-VARS.example`](../templates/soho/SITE-VARS.example).

## VLAN skeleton

Safe while empty: a VLAN may exist on the bridge and have a DHCP server, and still stay off access ports. Disable DHCP on any VLAN that is not in use (VLAN 99 ships that way).

| ID | Name | Subnet | Interface list | DHCP default | Notes |
|---|---|---|---|---|---|
| 1 (untagged) | MGMT | 192.168.88.0/24 | `MGMT` + trusted `LAN` | yes (defconf-style) | Bridge PVID 1. CAP static leases .10+ |
| 2 | CAMERAS | 10.0.2.0/24 | `CAMERA` only | yes (short lease) | Skeleton; NVR-admin may use mgmt **or** this VLAN |
| 3 | PBX | 10.0.3.0/24 | `PBX` only | yes | Phone access ports: untagged only |
| 4 | CORPORATE | 10.0.4.0/24 | trusted `LAN` | yes, 12h30m | Primary business LAN |
| 5 | STAFF | 10.0.5.0/24 | `STAFF` only | yes | Internet only |
| 6 | VENDOR | 10.0.6.0/24 | `VENDOR` only | yes | Internet only; client-isolation on Wi-Fi |
| 7 | GUEST | 10.0.128.0/21 | `GUEST` only | yes, **2h** | Large pool; client-isolation; internet only |
| 99 | REMOTE | 10.0.99.0/24 | `REMOTE` only | **disabled** | Future Back to Home / WireGuard landing; safe-empty |

Pools: `.10`–`.225` dynamic; reserve `.2`–`.9` for statics. Size the guest pool to the /21.

There is no management SSID. Management stays on the wired MGMT plane (and an optional `BTH_SUBNET` in `available-from`).

SSID names, port roles, and per-platform differences: [`templates/soho/DESIGN.md`](../templates/soho/DESIGN.md).

## Firewall zones

Interface lists, not address-lists named like CIDRs.

### Input (to the router)

1. accept established, related, untracked
2. drop invalid
3. accept ICMP (optional rate-limit)
4. accept `in-interface-list=MGMT` (WinBox / SSH / API)
5. accept UDP 53, 67, 123 and TCP 53 from `!WAN` (DHCP, DNS, NTP for every internal zone)
6. drop everything else

### Forward

1. accept established, related, untracked; drop invalid; fasttrack as desired
2. accept `in-interface-list=LAN` (trusted anywhere)
3. accept `in-interface-list=MGMT` (management plane anywhere — optional tighten later)
4. accept STAFF / VENDOR / GUEST / PBX / CAMERA toward `out-interface-list=WAN` only
5. REMOTE → WAN stays commented until VLAN 99 is wired
6. accept `connection-nat-state=dstnat` (no DNAT rules by default)
7. drop (final)

CAPs get a smaller input filter: established/related, the management subnet, ICMP, then drop. Their services are `available-from` the management subnet only.

Ordered comment labels used in the SOHO gateway scripts: `SOHO: accept established`, `SOHO: drop invalid`, `SOHO: MGMT to router`, `SOHO: DHCP/DNS/NTP internal`, `SOHO: trusted forward`, `SOHO: zone->WAN`, `SOHO: dstnat`, `SOHO: default drop`.

## Secrets

Never commit:

- live PSKs, user passwords, or API tokens
- a filled site-vars file
- `/export`, `/export show-sensitive`, or binary backups
- certificates or private keys

Committed scripts keep `SITE_*`, `CHANGE_ME_*`, `BTH_SUBNET`, and `COUNTRY` tokens. Resolve them on the copy you paste to the router, or in a private file that is not pushed.
