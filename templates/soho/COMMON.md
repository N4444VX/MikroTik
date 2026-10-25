# COMMON — shared design blocks

RouterOS has **no include / import of partial scripts** in the sense of Unix `#include`.
Every gateway `.rsc` duplicates the firewall + VLAN + CAPsMAN blocks so a single
file is paste-ready. Keep this document and the primary reference
`gateway/RB5009.rsc` in sync; diff other gateways against RB5009 when changing policy.

## Tokens

| Token | Meaning |
|---|---|
| `SITE_CODE` | Short site tag |
| `SITE_IDENTITY_*` | `/system identity` |
| `SITE_CORPORATE` / `SITE_STAFF` / `SITE_VENDOR` / `SITE_GUEST` | SSID strings |
| `CHANGE_ME_CORP` etc. | PSK placeholders — set locally |
| `BTH_SUBNET` | Optional second CIDR for `available-from` |
| `COUNTRY` | wifi `country=` |

## Interface lists (canonical)

```
WAN, LAN, MGMT, CAMERA, PBX, STAFF, VENDOR, GUEST, REMOTE
```

`LAN` = trusted only (bridge + VLAN004).

## Firewall sketch (IPv4)

See DESIGN.md. All GW files implement the same ordered comments:
`SOHO: accept established`, `SOHO: drop invalid`, `SOHO: MGMT to router`,
`SOHO: DHCP/DNS/NTP internal`, `SOHO: trusted forward`, `SOHO: zone->WAN`,
`SOHO: dstnat`, `SOHO: default drop`.

## CAPsMAN sketch

- Channels `ch-2g` (20 MHz), `ch-5g` (20/40/80, skip-dfs 10min-cac)
- Security per SSID, WPA2+WPA3-PSK, `ft=yes`, `ft-over-ds=no`, `wps=disable`, `connect-priority=0/1`
- Datapaths ax: `dp-ax-VLAN` with `vlan-id` + `client-isolation` on guest/vendor
- Datapath ac: `dp-ac` bridge only (no vlan-id)
- Provisioning order ax → ac
- `package-path=/caps-pkgs`, `upgrade-policy=suggest-same-version`
- `interfaces=bridge`, certs auto; `require-peer-certificate` commented

## CAP sketch

- Bridge name **`bridge`** (matches manager datapath `bridge=bridge`)
- `vlan-filtering=yes`, ether1 trunk
- `caps-man-addresses=192.168.88.1`, `discovery-interfaces=bridge`
- Input firewall: est/rel, mgmt subnet, ICMP, drop
- Services available-from 192.168.88.0/24
- IPv6 ND off; RoMON off; bandwidth-server off; SMB off
