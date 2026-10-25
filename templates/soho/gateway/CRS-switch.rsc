# =============================================================================
# WNC Upfit — SOHO baseline template
# Model:  CRS3xx / CRS5xx family
# Role:   Distribution switch (+ optional CAPsMAN)
# Target: RouterOS 7.24.x stable syntax
# Driver: none
# =============================================================================
#
# BEFORE APPLY
#   1. /system backup save name=pre-SOHO-baseline
#   2. /export show-sensitive file=pre-SOHO-baseline
#   3. Safe Mode (Ctrl-X)
#   4. Edit SITE_* / CHANGE_ME_* / BTH_SUBNET / COUNTRY below
#   5. Prefer fresh: /system reset-configuration no-defaults=yes skip-backup=no
#      then paste this script (console or WinBox Terminal)
#
# Never commit real PSKs or passwords. Set admin password locally after apply.
# See ../README.md ../DESIGN.md ../CHECKLIST.md ../COMMON.md
# =============================================================================


# IMPORTANT: This is NOT a NAT/WAN edge template.
# Pair with RB5009 / CCR / hAP ax as the edge router. This CRS:
#   - VLAN-aware bridge with HW offload (CRS3xx/5xx)
#   - Trunks to edge + CAP switches/APs
#   - Access ports for phones / NVR / mgmt
#   - Optional: CAPsMAN-only on mgmt IP (commented) if CPU allows — prefer CAPsMAN on edge
#
# Common models:
#   CRS326-24G-2S+   ether1–24, sfp-sfpplus1–2
#   CRS328-24P-4S+   PoE ether1–24, sfp 1–4
#   CRS317-1G-16S+   SFP+ dense
#   CRS309-1G-8S+    SFP+ 
#   CRS354-48G-4S+2Q+ …
# Confirm switch chip / hw-offload: /interface bridge port print (hw=yes with vlan-filtering)
#
# Example port roles (EDIT for site):
#   ether1        = uplink trunk to edge GW (tagged user VLANs + untagged mgmt OR tagged mgmt)
#   ether2–ether4 = CAP trunks
#   ether5        = PBX access VLAN3
#   ether6        = NVR-admin
#   ether24       = mgmt access
#   sfp-sfpplus1  = spare uplink

/system identity set name="SITE_CODE_CRS_SW"

/interface bridge
add name=bridge protocol-mode=rstp vlan-filtering=yes ingress-filtering=yes frame-types=admit-all \
    comment="CRS L2 — HW offload with vlan-filtering on CRS3xx/5xx"

/interface bridge port
add bridge=bridge interface=ether1 pvid=1 frame-types=admit-all comment="uplink to edge GW" hw=yes
add bridge=bridge interface=ether2 pvid=1 frame-types=admit-all comment="CAP trunk" hw=yes
add bridge=bridge interface=ether3 pvid=1 frame-types=admit-all comment="CAP trunk" hw=yes
add bridge=bridge interface=ether4 pvid=1 frame-types=admit-all comment="CAP trunk" hw=yes
add bridge=bridge interface=ether5 pvid=3 frame-types=admit-only-untagged-and-priority-tagged comment="PBX" hw=yes
add bridge=bridge interface=ether6 pvid=1 frame-types=admit-only-untagged-and-priority-tagged comment="NVR-admin" hw=yes
# add remaining ports disabled or as access — do not leave unused ports as open trunks

/interface bridge vlan
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=2
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=3
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=4
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=5
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=6
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=7
add bridge=bridge tagged=bridge,ether1,ether2,ether3,ether4 vlan-ids=99
/interface bridge vlan set [find vlan-ids=3] untagged=ether5

# Mgmt IP on bridge (untagged) — GW is .1; CRS is static
/ip address add address=192.168.88.2/24 interface=bridge comment=MGMT
/ip route add dst-address=0.0.0.0/0 gateway=192.168.88.1

/interface list
add name=MGMT
/interface list member add interface=bridge list=MGMT
/ip neighbor discovery-settings set discover-interface-list=MGMT
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/tool romon set enabled=no
/tool bandwidth-server set enabled=no
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
/user settings set minimum-password-length=12 minimum-categories=2

/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked
add chain=input action=drop connection-state=invalid
add chain=input action=accept src-address=192.168.88.0/24
add chain=input action=accept protocol=icmp
add chain=input action=drop

/ipv6 nd set [find default=yes] disabled=yes
/ipv6 settings set forward=no disable-ipv6=yes

# --- Optional: CAPsMAN-only on this CRS (usually prefer edge GW) ---
# Uncomment and paste WIFI blocks from RB5009.rsc if you intentionally host CAPsMAN here.
# Ensure /caps-pkgs has packages; CPU on smaller CRS is limited.
# /interface wifi capsman set enabled=yes interfaces=bridge ...

print "SOHO CRS switch baseline loaded — pair with edge router for NAT/DHCP/CAPsMAN"
