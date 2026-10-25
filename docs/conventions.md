# Conventions

Repo-wide rules for new RouterOS work. The SOHO templates implement this
document. Platform port maps and the SSID table live in
[templates/soho/DESIGN.md](../templates/soho/DESIGN.md). Change both in the
same commit when the skeleton changes.

## RouterOS version

- New configs are RouterOS **v7** only.
- SOHO reference versions: stable **7.24.5**, long-term **7.23.8**.
- A site's gateway and CAPs stay on the same minor
  (`upgrade-policy=suggest-same-version`).
- When a family moves to a newer minor, publish matching `.npk` files for
  every architecture that family still deploys before pointing
  `staging/<family>/latest` at the new scripts. See
  [staging/packages/README.md](../staging/packages/README.md).

## No legacy wireless

New installs use the wifi menu only:

| Hardware | Package | Notes |
|---|---|---|
| ax (cAP ax, wAP ax, hAP ax²/ax³, and other qcom ax) | `wifi-qcom` | Datapath `vlan-id` is valid |
| IPQ-4018/4019 ac (cAP ac and similar) | `wifi-qcom-ac` | No datapath `vlan-id`; bridge PVID on the CAP. 16 MB flash: routeros + wifi-qcom-ac only |
| Wired-only (RB5009, most CCR/CRS) | neither | CAPsMAN still runs from the routeros bundle |

Do not install the legacy `wireless` package on new gear. Disabling it is not
enough on a board that still has it installed; uninstall and reboot, then add
the matching wifi package. Do not install `wifi-qcom` and `wifi-qcom-ac` on
the same device. Do not run two CAPsMAN implementations.

`archive/legacy-defaults/` contains older factory-style scripts, including one
that configures legacy wireless. Those files are historical.

## Naming

- Site tag: short uppercase code (`MHT`, `19H`). Token in scripts: `SITE_CODE`.
- Identities: `SITE_CODE_ROLE_LOCATION` (example shape `MHT_RB5009_GW`).
- VLAN interfaces: `VLAN002` … `VLAN099`, comment is the zone name.
- Interface lists: `WAN`, `LAN`, `MGMT`, `CAMERA`, `PBX`, `STAFF`, `VENDOR`,
  `GUEST`, `REMOTE`.
- Wi-Fi objects: `sec-*`, `ch-2g`, `ch-5g`, `dp-ax-*`, `dp-ac`, `ax-*`, `ac-*`.
- Template filenames are the model stem used in pull URLs: `RB5009.rsc`,
  `cAPax.rsc`, `CRS-switch.rsc`. Do not rename a file under
  `staging/*/latest/` without updating [docs/field-pull.md](field-pull.md)
  and leaving a note; field scripts depend on those names.
- Placeholders: `SITE_*` for names, `CHANGE_ME_*` for passphrases,
  `BTH_SUBNET` for an optional management CIDR, `COUNTRY` for the regulatory
  domain. Never replace placeholders with live secrets inside this repo.

## VLAN skeleton

Safe while empty means DHCP can exist for a zone that has no access ports yet,
except REMOTE, which stays without DHCP until it is wired. User traffic must
not land on the management subnet.

| ID | Name | Subnet | Interface list | DHCP default |
|---|---|---|---|---|
| 1 (untagged) | MGMT | 192.168.88.0/24 | `MGMT` + trusted `LAN` | yes |
| 2 | CAMERAS | 10.0.2.0/24 | `CAMERA` only | yes, short lease |
| 3 | PBX | 10.0.3.0/24 | `PBX` only | yes |
| 4 | CORPORATE | 10.0.4.0/24 | trusted `LAN` | yes, 12h30m |
| 5 | STAFF | 10.0.5.0/24 | `STAFF` only | yes |
| 6 | VENDOR | 10.0.6.0/24 | `VENDOR` only | yes |
| 7 | GUEST | 10.0.128.0/21 | `GUEST` only | yes, 2h |
| 99 | REMOTE | 10.0.99.0/24 | `REMOTE` only | disabled |

`LAN` is trusted only: the bridge (management) plus VLAN 4. Guest, vendor,
staff, camera, PBX, and remote must not also be members of `LAN`.

Pools use `.10`–`.225` for dynamic leases and reserve `.2`–`.9` for statics.
CAP static leases start at `192.168.88.10` on management. No user Wi-Fi client
should hold a management lease.

Management is never a PSK SSID.

## Firewall zones

Interface lists, not address-lists named like CIDRs.

Input (to the router):

1. accept established, related, untracked
2. drop invalid
3. accept ICMP
4. accept `in-interface-list=MGMT`
5. accept UDP 53, 67, 123 and TCP 53 from `!WAN`
6. drop

Forward:

1. accept established, related, untracked; drop invalid; fasttrack as desired
2. accept `in-interface-list=LAN`
3. accept `in-interface-list=MGMT`
4. accept STAFF, VENDOR, GUEST, PBX, CAMERA to `out-interface-list=WAN` only
5. REMOTE to WAN stays commented until VLAN 99 is in use
6. accept `connection-nat-state=dstnat`
7. drop

## Secrets

This repository is public. Do not commit:

- Wi-Fi PSKs or user passwords
- WireGuard / Back to Home private keys
- `/export show-sensitive` or binary backups
- Fetch tokens, even "temporary" ones

Site overlays under `sites/` follow the same rule. Put real values on the
device after import, or keep a private copy outside this repo.
