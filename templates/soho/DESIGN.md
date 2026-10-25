# DESIGN — SOHO baseline

## VLAN table (skeleton; safe while empty)

| ID | Name | Subnet | Interface list | DHCP default | Notes |
|---|---|---|---|---|---|
| 1 (untagged) | MGMT | 192.168.88.0/24 | `MGMT` + trusted `LAN` | yes (defconf-style) | Untagged on bridge PVID 1. CAP static leases .10+ |
| 2 | CAMERAS | 10.0.2.0/24 | `CAMERA` only | yes (short lease) | Skeleton OK; NVR-admin may use mgmt **or** this VLAN |
| 3 | PBX | 10.0.3.0/24 | `PBX` only | yes | Phone access ports: untagged only |
| 4 | CORPORATE | 10.0.4.0/24 | trusted `LAN` | yes 12h30m | Primary business LAN |
| 5 | STAFF | 10.0.5.0/24 | `STAFF` only | yes | Internet only |
| 6 | VENDOR | 10.0.6.0/24 | `VENDOR` only | yes | Internet only; client-isolation on Wi-Fi |
| 7 | GUEST | 10.0.128.0/21 | `GUEST` only | yes **2h** | Large pool; client-isolation; internet only |
| 99 | REMOTE | 10.0.99.0/24 | `REMOTE` only | **disabled** | Future BTH/WG landing; safe-empty |

**Trusted `LAN` list = bridge (mgmt) + VLAN004 only.** Guest/vendor/staff/camera/pbx/remote
must **never** also be members of `LAN`.

Pools: `.10`–`.225` dynamic; reserve `.2`–`.9` for statics. Guest: size the /21 pool accordingly.

## Firewall zones

### Input (router itself)
1. accept established,related,untracked
2. drop invalid
3. accept ICMP (optional rate-limit)
4. accept `in-interface-list=MGMT` (WinBox/SSH/API plane)
5. accept UDP 53,67,123 and TCP 53 from `!WAN` (DHCP/DNS/NTP for all internal zones)
6. drop everything else

### Forward
1. accept established,related,untracked; drop invalid; fasttrack as desired
2. accept `in-interface-list=LAN` (trusted anywhere)
3. accept `in-interface-list=MGMT` (mgmt plane anywhere — optional tighten later)
4. accept STAFF/VENDOR/GUEST/PBX/CAMERA → `out-interface-list=WAN` only
5. REMOTE → WAN commented until VLAN99 is wired
6. accept `connection-nat-state=dstnat` (no DNAT rules by default)
7. **drop** (final)

No address-list names that look like CIDRs. Use interface-lists.

## SSID → VLAN map

| Config name | SSID template | VLAN | Provisioned by default? | Notes |
|---|---|---|---|---|
| CORP-5G / CORP-2G | `SITE_CORPORATE` | 4 | yes (master) | Split band masters; FT over-air |
| STAFF | `SITE_STAFF` | 5 | yes (slave) | |
| VENDOR | `SITE_VENDOR` | 6 | yes (slave) | client-isolation |
| GUEST | `SITE_GUEST` | 7 | yes (slave) | client-isolation |
| CAMERAS | `SITE_CAMERAS` | 2 | no | skeleton |
| PBX / PHONES | `SITE_PHONES` | 3 | no | skeleton |
| REMOTE | `SITE_REMOTE` | 99 | no | skeleton |
| ~~MANAGEMENT~~ | — | — | **omitted** | Never broadcast mgmt as PSK SSID |

ax datapaths use `vlan-id=`. ac configs use datapath **without** vlan-id; CAP sets pvid.

## Port roles (RB5009 reference)

| Port | Role |
|---|---|
| ether1 | WAN (not bridged) |
| ether2 | CAP trunk #1 (untagged mgmt + tagged 2–7,99) |
| ether3 | CAP trunk #2 |
| ether4 | PBX access (VLAN 3 untagged only) |
| ether5–6 | Spare trunks (TBD) |
| ether7 | NVR-admin: choose PVID 1 (mgmt) **or** PVID 2 (CAMERA); never tag 4/5/99 |
| ether8, sfp-sfpplus1 | Mgmt access only |

Other platforms: see comments inside each `.rsc`.

## Platform differences

| Platform | Ports (typical) | Wi-Fi | CAPsMAN | Notes |
|---|---|---|---|---|
| RB5009 | 8×1G + SFP+ | no | yes (preferred host) | Primary reference |
| L009UiGS | 8×1G + SFP | no (2HaxD variant has wifi) | yes | Fewer PoE options; document port map |
| hAP ax² | 5× ether | wifi-qcom | yes + local radios | Local radios: apply same configs directly (`manager` local), not as CAP to self |
| hAP ax³ | 5× ether | wifi-qcom | yes + local | Same pattern |
| CCR2004/2116/… | many copper/SFP | no | yes | Arch arm64 (modern) vs tile (older CCR1009/1016) — packages differ |
| CRS3xx/5xx | many | no | optional | **Switch + VLAN bridge**; pair with edge router for NAT |
| cAP ax | 2× ether | wifi-qcom | CAP | ether1 trunk |
| hAP ax²/ax³ as CAP | 5× ether | wifi-qcom | CAP | ether2+ access TBD |
| wAP ax | 1–2× ether | wifi-qcom | CAP | Disable unused ether2 mgmt |
| cAP ac | 2× ether | **wifi-qcom-ac** | CAP | Bridge pvid; tx-only neighbor discovery; 16 MB flash care |

## Naming

- VLAN interfaces: `VLAN002` … `VLAN099` with comments `CAMERAS`, `PBX`, …
- Lists: `WAN`, `LAN`, `MGMT`, `CAMERA`, `PBX`, `STAFF`, `VENDOR`, `GUEST`, `REMOTE`
- Wi-Fi objects: `sec-*`, `ch-2g`, `ch-5g`, `dp-ax-*`, `dp-ac`, `ax-*`, `ac-*`
- Identities: `SITE_CODE_ROLE_LOCATION`
