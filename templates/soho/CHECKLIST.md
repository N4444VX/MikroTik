# CHECKLIST — post-apply verification

## Prep
- [ ] Backup saved off-box (`/export show-sensitive` + binary backup)
- [ ] Safe Mode used for risky sections
- [ ] All `CHANGE_ME` / `SITE_*` / `BTH_SUBNET` tokens resolved on **this** site’s copies
- [ ] Admin user renamed/strong password; `minimum-password-length=12`

## Layer 2 / VLANs
- [ ] GW bridge `vlan-filtering=yes`, `ingress-filtering=yes`
- [ ] CAP bridges `vlan-filtering=yes`, ether1 trunk tagged for user VLANs
- [ ] Phone port: single VLAN untagged, `admit-only-untagged-and-priority-tagged`
- [ ] NVR/camera access port: no tagged CORPORATE/STAFF/REMOTE
- [ ] VLAN99 not on access ports; DHCP disabled until used

## DHCP / clients
- [ ] CAP leases only on 192.168.88.0/24 (static .10+)
- [ ] **No user Wi-Fi devices** in 192.168.88.x leases (if yes → CAP VLAN filtering / datapath broken)
- [ ] Corporate clients on 10.0.4.0/24; staff 10.0.5.0/24; guest 10.0.128.0/21
- [ ] Each DHCP network has `ntp-server=` = that VLAN’s GW IP
- [ ] Guest lease ≤ 4h

## Firewall / services
- [ ] From GUEST: cannot WinBox to 10.0.128.1 or 192.168.88.1
- [ ] From GUEST: cannot ping/reach 10.0.4.x or 192.168.88.x
- [ ] From STAFF/VENDOR: WAN works; corporate does not
- [ ] WinBox/SSH `available-from` = mgmt + BTH only
- [ ] reverse-proxy disabled unless needed
- [ ] RoMON off or forbidden on WAN
- [ ] Neighbor discovery = MGMT only
- [ ] Bandwidth-server off; SMB off / guest SMB user disabled

## CAPsMAN / Wi-Fi
- [ ] `/interface wifi capsman remote-cap print` shows all CAPs
- [ ] Provisioning order: ax before ac
- [ ] Guest/vendor `client-isolation=yes`
- [ ] FT `ft=yes ft-over-ds=no` on roaming SSIDs
- [ ] Channels: 2G 20 MHz; 5G ≤80 MHz; no accidental 160 in dense SOHO
- [ ] Country set on every configuration
- [ ] MANAGEMENT SSID absent / not provisioned
- [ ] Certificates: after `certificate=request` on CAPs, optionally `require-peer-certificate=yes`
- [ ] cAP ac: no `datapath.vlan-id`; bridge pvids set; neighbor `tx-only`

## IPv6
- [ ] Only the gateway may send RAs when IPv6 is enabled
- [ ] CAP `/ipv6 nd` disabled; CAP `forward=no` until designed

## Ops
- [ ] Identity / note / clock / NTP OK
- [ ] Logging: wifi topics not excluded; remote syslog if available
- [ ] Firmware script parses; `/caps-pkgs` has correct arch packages
- [ ] RouterBOOT upgraded after ROS upgrade
