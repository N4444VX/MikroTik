# =============================================================================
# WNC Upfit — SOHO baseline template
# Model:  wAP ax (wAPG-5HaxD2HaxD)
# Role:   Outdoor CAP
# Target: RouterOS 7.24.x stable syntax
# Driver: wifi-qcom
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


/system identity set name="SITE_CODE_wAPax_LOCATION"

# ether1 = PoE-in trunk to GW
# ether2 = if present, minimize exposure — disable or non-mgmt VLAN (default: disabled)

/interface bridge
add name=bridge protocol-mode=rstp vlan-filtering=yes ingress-filtering=yes frame-types=admit-all

/interface bridge port
add bridge=bridge interface=ether1 pvid=1 frame-types=admit-all comment="trunk to GW" hw=yes
# ether2: do NOT leave as live mgmt on outdoor AP
# /interface bridge port add bridge=bridge interface=ether2 pvid=7 frame-types=admit-only-untagged-and-priority-tagged comment="guest drop if needed"
/interface ethernet set [find default-name=ether2] disabled=yes

/interface bridge vlan
add bridge=bridge tagged=bridge,ether1 vlan-ids=2,3,4,5,6,7,99

/ip dhcp-client
add interface=bridge disabled=no add-default-route=yes use-peer-dns=yes use-peer-ntp=yes

/interface wifi datapath
add name=capdp bridge=bridge

/interface wifi
set [find default-name=wifi1] configuration.manager=capsman datapath=capdp disabled=no
set [find default-name=wifi2] configuration.manager=capsman datapath=capdp disabled=no

/interface wifi cap
set enabled=yes discovery-interfaces=bridge caps-man-addresses=192.168.88.1 \
    slaves-datapath=capdp certificate=request

# --- Hardening ---
/user settings set minimum-password-length=12 minimum-categories=2
/tool bandwidth-server set enabled=no
/tool romon set enabled=no
/ip smb set enabled=no
/disk settings set auto-smb-sharing=no auto-media-sharing=no

/interface list
add name=MGMT
/interface list member
add interface=bridge list=MGMT

/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/ip neighbor discovery-settings set discover-interface-list=MGMT

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox available-from=192.168.88.0/24 disabled=no
set ssh available-from=192.168.88.0/24 disabled=no
set reverse-proxy disabled=yes

/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked comment="SOHO CAP"
add chain=input action=drop connection-state=invalid comment="SOHO CAP"
add chain=input action=accept src-address=192.168.88.0/24 comment="SOHO CAP mgmt"
add chain=input action=accept protocol=icmp comment="SOHO CAP"
add chain=input action=drop comment="SOHO CAP default drop"

/ipv6 nd set [find default=yes] disabled=yes
/ipv6 settings set forward=no disable-ipv6=yes

/system ntp client set enabled=yes
/system ntp client servers add address=192.168.88.1

print "SOHO wAP ax CAP baseline loaded"
