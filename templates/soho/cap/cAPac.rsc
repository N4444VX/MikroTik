# =============================================================================
# WNC Upfit — SOHO baseline template
# Model:  cAP ac (RBcAPGi-5acD2nD) — ARM Wave2
# Role:   CAP (wifi-qcom-ac ONLY)
# Target: RouterOS 7.24.x stable syntax
# Driver: wifi-qcom-ac
# =============================================================================
#
# BEFORE APPLY
#   1. /system backup save name=pre-SOHO-cap
#   2. /export show-sensitive file=pre-SOHO-cap
#   3. Safe Mode (Ctrl-X)
#   4. Edit SITE_IDENTITY / CAPS_MAN_IP if not 192.168.88.1
#   5. Prefer: reset no-defaults, then paste
#        /system reset-configuration no-defaults=yes skip-backup=no
#
# Apply AFTER gateway CAPsMAN is up (or simultaneously on greenfield).
# Bridge is named "bridge" to match manager datapath bridge=bridge.
# Docs: templates/soho/README.md DESIGN.md CHECKLIST.md
# =============================================================================


# CRITICAL NOTES (wifi-qcom-ac)
#   - Uninstall legacy "wireless" package (disable is not enough). Reboot, then install
#     wifi-qcom-ac-<ver>-arm.npk matching RouterOS version. Do NOT install wifi-qcom (non-ac).
#   - 16 MB flash: only routeros + wifi-qcom-ac. Check /system resource print free-hdd-space
#     before every upgrade. Netinstall if flash fills.
#   - 128 MB RAM: keep this device as a pure CAP. Neighbor discovery mode=tx-only
#     (community workaround for kernel-failure reboots).
#   - NO datapath.vlan-id (driver cannot assign VLANs). Use bridge pvid on wifi ifaces
#     + slaves-static=yes so virtual SSIDs get static names/pvids.
#   - Provisioning on manager uses 5ghz-ac / 2ghz-n rules AFTER ax rules.

/system identity set name="SITE_CODE_cAPac_LOCATION"

# Community stability workaround for qcom-ac:
/ip neighbor discovery-settings set mode=tx-only discover-interface-list=none

/interface bridge
add name=bridge protocol-mode=rstp vlan-filtering=yes ingress-filtering=yes frame-types=admit-all

/interface bridge port
add bridge=bridge interface=ether1 pvid=1 frame-types=admit-all comment="trunk to GW" hw=yes
# ether2 optional access — default disabled for pure CAP
/interface ethernet set [find default-name=ether2] disabled=yes

/interface bridge vlan
add bridge=bridge tagged=bridge,ether1 vlan-ids=2,3,4,5,6,7,99

/ip dhcp-client
add interface=bridge disabled=no add-default-route=yes use-peer-dns=yes use-peer-ntp=yes

# Master wifi ports: pvid = CORPORATE (4). Guests/staff slaves get pvids after first join.
/interface bridge port
add bridge=bridge interface=wifi1 pvid=4 frame-types=admit-only-untagged-and-priority-tagged comment="ac master  → CORP"
add bridge=bridge interface=wifi2 pvid=4 frame-types=admit-only-untagged-and-priority-tagged comment="ac master  → CORP"

/interface bridge vlan
set [find vlan-ids=4] tagged=bridge,ether1 untagged=wifi1,wifi2

/interface wifi
set [find default-name=wifi1] configuration.manager=capsman disabled=no
set [find default-name=wifi2] configuration.manager=capsman disabled=no

/interface wifi cap
set enabled=yes discovery-interfaces=bridge caps-man-addresses=192.168.88.1 \
    slaves-static=yes certificate=request
# No slaves-datapath vlan-id — VLANs are bridge pvids only.

# AFTER first successful provision, list slave wifi names:
#   /interface wifi print
# Then add bridge ports + vlan untagged for STAFF(5), VENDOR(6), GUEST(7), e.g.:
#   /interface bridge port add bridge=bridge interface=wifi1-SITE_STAFF pvid=5 frame-types=admit-only-untagged-and-priority-tagged
#   /interface bridge vlan set [find vlan-ids=5] tagged=ether1 untagged=wifi1-SITE_STAFF,wifi2-SITE_STAFF
# (Exact slave names depend on name-format from CAPsMAN — check before scripting.)

# Hardening (neighbor discovery already tx-only above)
/user settings set minimum-password-length=12 minimum-categories=2
/tool bandwidth-server set enabled=no
/tool romon set enabled=no
/ip smb set enabled=no

/interface list
add name=MGMT
/interface list member add interface=bridge list=MGMT
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox available-from=192.168.88.0/24
set ssh available-from=192.168.88.0/24
set reverse-proxy disabled=yes

/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked
add chain=input action=drop connection-state=invalid
add chain=input action=accept src-address=192.168.88.0/24
add chain=input action=accept protocol=icmp
add chain=input action=drop

/ipv6 nd set [find default=yes] disabled=yes
/ipv6 settings set forward=no disable-ipv6=yes
/system ntp client set enabled=yes
/system ntp client servers add address=192.168.88.1

print "SOHO cAP ac CAP baseline loaded — set slave pvids after first provision; watch flash/RAM"
