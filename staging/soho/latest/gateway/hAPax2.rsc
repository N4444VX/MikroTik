# =============================================================================
# WNC Upfit — SOHO baseline template
# Model:  hAP ax2 (C52iG-5HaxD2HaxD) — 5× ether
# Role:   Gateway + CAPsMAN + local wifi-qcom radios
# Target: RouterOS 7.24.x stable syntax
# Driver: wifi-qcom
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
# Docs: templates/soho/README.md DESIGN.md CHECKLIST.md COMMON.md
# =============================================================================


# Local radios: do NOT set configuration.manager=capsman on this box's own wifi.
# Apply the same ax-CORP-* configurations directly to wifi1/wifi2.
# Typically wifi1=5 GHz, wifi2=2.4 GHz — verify with /interface wifi print
# ether1 = WAN; ether2–3 CAP trunks (or use as LAN); ether4 PBX; ether5 mgmt/NVR

/system identity set name="SITE_CODE_HAPAX2_GW"

/interface bridge
add name=bridge protocol-mode=rstp vlan-filtering=yes ingress-filtering=yes frame-types=admit-all

/interface bridge port
add bridge=bridge interface=ether2 pvid=1 frame-types=admit-all comment="CAP trunk / LAN"
add bridge=bridge interface=ether3 pvid=1 frame-types=admit-all comment="CAP trunk / LAN"
add bridge=bridge interface=ether4 pvid=3 frame-types=admit-only-untagged-and-priority-tagged comment="PBX"
add bridge=bridge interface=ether5 pvid=1 frame-types=admit-only-untagged-and-priority-tagged comment="mgmt/NVR"

/interface bridge vlan
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=2
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=3
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=4
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=5
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=6
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=7
add bridge=bridge tagged=bridge,ether2,ether3 vlan-ids=99
/interface bridge vlan set [find vlan-ids=3] untagged=ether4

# --- VLAN interfaces on bridge ---
/interface vlan
add interface=bridge name=VLAN002 vlan-id=2 comment=CAMERAS
add interface=bridge name=VLAN003 vlan-id=3 comment=PBX
add interface=bridge name=VLAN004 vlan-id=4 comment=CORPORATE
add interface=bridge name=VLAN005 vlan-id=5 comment=STAFF
add interface=bridge name=VLAN006 vlan-id=6 comment=VENDOR
add interface=bridge name=VLAN007 vlan-id=7 comment=GUEST
add interface=bridge name=VLAN099 vlan-id=99 comment=REMOTE

# --- Interface lists (zones). LAN = trusted ONLY ---
/interface list
add name=WAN comment="SOHO WAN"
add name=LAN comment="SOHO trusted: mgmt bridge + CORPORATE"
add name=MGMT comment="SOHO management plane"
add name=CAMERA
add name=PBX
add name=STAFF
add name=VENDOR
add name=GUEST
add name=REMOTE

/interface list member
add interface=ether1 list=WAN
add interface=bridge list=LAN
add interface=bridge list=MGMT
add interface=VLAN004 list=LAN
add interface=VLAN002 list=CAMERA
add interface=VLAN003 list=PBX
add interface=VLAN005 list=STAFF
add interface=VLAN006 list=VENDOR
add interface=VLAN007 list=GUEST
add interface=VLAN099 list=REMOTE
# Optional: add back-to-home-vpn to MGMT after BTH is enabled
# /interface list member add interface=back-to-home-vpn list=MGMT comment="BTH mgmt"

# --- Addressing ---
/ip address
add address=192.168.88.1/24 interface=bridge comment=MGMT
add address=10.0.2.1/24 interface=VLAN002 comment=CAMERAS
add address=10.0.3.1/24 interface=VLAN003 comment=PBX
add address=10.0.4.1/24 interface=VLAN004 comment=CORPORATE
add address=10.0.5.1/24 interface=VLAN005 comment=STAFF
add address=10.0.6.1/24 interface=VLAN006 comment=VENDOR
add address=10.0.128.1/21 interface=VLAN007 comment=GUEST
add address=10.0.99.1/24 interface=VLAN099 comment=REMOTE

/ip pool
add name=pool-mgmt ranges=192.168.88.100-192.168.88.200
add name=pool-vlan002 ranges=10.0.2.10-10.0.2.225
add name=pool-vlan003 ranges=10.0.3.10-10.0.3.225
add name=pool-vlan004 ranges=10.0.4.10-10.0.4.225
add name=pool-vlan005 ranges=10.0.5.10-10.0.5.225
add name=pool-vlan006 ranges=10.0.6.10-10.0.6.225
add name=pool-vlan007 ranges=10.0.128.10-10.0.135.250
add name=pool-vlan099 ranges=10.0.99.10-10.0.99.225

/ip dhcp-server
add name=dhcp-mgmt interface=bridge address-pool=pool-mgmt lease-time=30m
add name=dhcp-vlan002 interface=VLAN002 address-pool=pool-vlan002 lease-time=10m
add name=dhcp-vlan003 interface=VLAN003 address-pool=pool-vlan003 lease-time=12h
add name=dhcp-vlan004 interface=VLAN004 address-pool=pool-vlan004 lease-time=12h30m
add name=dhcp-vlan005 interface=VLAN005 address-pool=pool-vlan005 lease-time=12h30m
add name=dhcp-vlan006 interface=VLAN006 address-pool=pool-vlan006 lease-time=12h30m
add name=dhcp-vlan007 interface=VLAN007 address-pool=pool-vlan007 lease-time=2h
add name=dhcp-vlan099 interface=VLAN099 address-pool=pool-vlan099 lease-time=10m disabled=yes

/ip dhcp-server network
add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=192.168.88.1 \
    ntp-server=192.168.88.1 caps-manager=192.168.88.1 comment=MGMT
add address=10.0.2.0/24 gateway=10.0.2.1 dns-server=10.0.2.1 ntp-server=10.0.2.1 comment=CAMERAS
add address=10.0.3.0/24 gateway=10.0.3.1 dns-server=10.0.3.1 ntp-server=10.0.3.1 comment=PBX
add address=10.0.4.0/24 gateway=10.0.4.1 dns-server=10.0.4.1 ntp-server=10.0.4.1 comment=CORPORATE
add address=10.0.5.0/24 gateway=10.0.5.1 dns-server=10.0.5.1 ntp-server=10.0.5.1 comment=STAFF
add address=10.0.6.0/24 gateway=10.0.6.1 dns-server=10.0.6.1 ntp-server=10.0.6.1 comment=VENDOR
add address=10.0.128.0/21 gateway=10.0.128.1 dns-server=10.0.128.1 ntp-server=10.0.128.1 comment=GUEST
add address=10.0.99.0/24 gateway=10.0.99.1 dns-server=10.0.99.1 ntp-server=10.0.99.1 comment=REMOTE

# Example CAP static leases (edit MAC / address per site):
# /ip dhcp-server lease add address=192.168.88.10 mac-address=AA:BB:CC:DD:EE:01 server=dhcp-mgmt comment="SITE_cAPax"
# /ip dhcp-server lease add address=192.168.88.11 mac-address=AA:BB:CC:DD:EE:02 server=dhcp-mgmt comment="SITE_wAPax"

# --- Wi-Fi security + channels (COMMON) ---
# Set passphrases locally. Do not leave CHANGE_ME in production.
/interface wifi security
add name=sec-CORP authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_CORP" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable management-protection=allowed
add name=sec-STAFF authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_STAFF" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable management-protection=allowed
add name=sec-VENDOR authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_VENDOR" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable management-protection=allowed
add name=sec-GUEST authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_GUEST" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable management-protection=allowed
add name=sec-CAMERAS authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_CAMERAS" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable
add name=sec-PBX authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_PBX" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable
add name=sec-REMOTE authentication-types=wpa2-psk,wpa3-psk passphrase="CHANGE_ME_REMOTE" \
    ft=yes ft-over-ds=no connect-priority=0/1 wps=disable

/interface wifi channel
add name=ch-2g frequency=2412,2437,2462 width=20mhz
add name=ch-5g frequency=5180,5260,5500,5745 width=20/40/80mhz skip-dfs-channels=10min-cac
# No channel.band — let each radio use its best mode (ax vs ac)

# --- Datapaths: ax (wifi-qcom) use vlan-id; ac use dp-ac without vlan-id ---
/interface wifi datapath
add name=dp-ax-CAMERAS bridge=bridge vlan-id=2
add name=dp-ax-PBX bridge=bridge vlan-id=3
add name=dp-ax-CORP bridge=bridge vlan-id=4
add name=dp-ax-STAFF bridge=bridge vlan-id=5
add name=dp-ax-VENDOR bridge=bridge vlan-id=6 client-isolation=yes
add name=dp-ax-GUEST bridge=bridge vlan-id=7 client-isolation=yes
add name=dp-ax-REMOTE bridge=bridge vlan-id=99
add name=dp-ac bridge=bridge comment="wifi-qcom-ac: VLAN via CAP bridge pvid only"

# --- Configurations (SSID templates). Rename SITE_* SSIDs per site. ---
# MANAGEMENT SSID intentionally omitted (never PSK onto mgmt).
/interface wifi configuration
# ax masters (provisioned)
add name=ax-CORP-5G ssid="SITE_CORPORATE" country="United States" \
    security=sec-CORP channel=ch-5g datapath=dp-ax-CORP \
    security.ft-preserve-vlanid=yes
add name=ax-CORP-2G ssid="SITE_CORPORATE" country="United States" \
    security=sec-CORP channel=ch-2g datapath=dp-ax-CORP \
    security.ft-preserve-vlanid=yes
add name=ax-STAFF ssid="SITE_STAFF" country="United States" \
    security=sec-STAFF datapath=dp-ax-STAFF security.ft-preserve-vlanid=yes
add name=ax-VENDOR ssid="SITE_VENDOR" country="United States" \
    security=sec-VENDOR datapath=dp-ax-VENDOR security.ft-preserve-vlanid=yes
add name=ax-GUEST ssid="SITE_GUEST" country="United States" \
    security=sec-GUEST datapath=dp-ax-GUEST security.ft-preserve-vlanid=yes
# ax skeleton (NOT in provisioning — safe empty)
add name=ax-CAMERAS ssid="SITE_CAMERAS" country="United States" \
    security=sec-CAMERAS datapath=dp-ax-CAMERAS disabled=yes
add name=ax-PBX ssid="SITE_PHONES" country="United States" \
    security=sec-PBX datapath=dp-ax-PBX disabled=yes
add name=ax-REMOTE ssid="SITE_REMOTE" country="United States" \
    security=sec-REMOTE datapath=dp-ax-REMOTE disabled=yes
# ac profiles (for wifi-qcom-ac CAPs; no vlan-id on datapath)
add name=ac-CORP-5G ssid="SITE_CORPORATE" country="United States" \
    security=sec-CORP channel=ch-5g datapath=dp-ac security.ft-preserve-vlanid=no
add name=ac-CORP-2G ssid="SITE_CORPORATE" country="United States" \
    security=sec-CORP channel=ch-2g datapath=dp-ac security.ft-preserve-vlanid=no
add name=ac-STAFF ssid="SITE_STAFF" country="United States" \
    security=sec-STAFF datapath=dp-ac security.ft-preserve-vlanid=no
add name=ac-VENDOR ssid="SITE_VENDOR" country="United States" \
    security=sec-VENDOR datapath=dp-ac datapath.client-isolation=yes security.ft-preserve-vlanid=no
add name=ac-GUEST ssid="SITE_GUEST" country="United States" \
    security=sec-GUEST datapath=dp-ac datapath.client-isolation=yes security.ft-preserve-vlanid=no

# ORDER MATTERS: ax before ac (ax radios also match 5ghz-ac / 2ghz-n)
/interface wifi provisioning
add action=create-dynamic-enabled supported-bands=5ghz-ax \
    master-configuration=ax-CORP-5G slave-configurations=ax-STAFF,ax-VENDOR,ax-GUEST \
    name-format=%I-5ax comment="ax 5G"
add action=create-dynamic-enabled supported-bands=2ghz-ax \
    master-configuration=ax-CORP-2G slave-configurations=ax-STAFF,ax-VENDOR,ax-GUEST \
    name-format=%I-2ax comment="ax 2G"
add action=create-dynamic-enabled supported-bands=5ghz-ac \
    master-configuration=ac-CORP-5G slave-configurations=ac-STAFF,ac-VENDOR,ac-GUEST \
    name-format=%I-5ac comment="ac 5G (qcom-ac)"
add action=create-dynamic-enabled supported-bands=2ghz-n \
    master-configuration=ac-CORP-2G slave-configurations=ac-STAFF,ac-VENDOR,ac-GUEST \
    name-format=%I-2ac comment="ac 2G (qcom-ac)"

/interface wifi capsman
set enabled=yes interfaces=bridge ca-certificate=auto certificate=auto \
    package-path=/caps-pkgs upgrade-policy=suggest-same-version \
    require-peer-certificate=no
# After all CAPs show issued certs:
# /interface wifi capsman set require-peer-certificate=yes
# Fill /caps-pkgs from staging/packages via scripts/pull_capsman_packages.rsc
# (published at staging/scripts/latest/). 32-bit ax CAPs need wifi-qcom for arm.

# --- Local radios (same SSIDs as CAPsMAN masters) ---
/interface wifi
set [find default-name=wifi1] configuration=ax-CORP-5G disabled=no \
    configuration.manager=local datapath=dp-ax-CORP
set [find default-name=wifi2] configuration=ax-CORP-2G disabled=no \
    configuration.manager=local datapath=dp-ax-CORP
# Add slave SSIDs on local radios to match CAP provisioning:
/interface wifi
add master-interface=[find default-name=wifi1] name=wifi1-STAFF configuration=ax-STAFF disabled=no
add master-interface=[find default-name=wifi1] name=wifi1-VENDOR configuration=ax-VENDOR disabled=no
add master-interface=[find default-name=wifi1] name=wifi1-GUEST configuration=ax-GUEST disabled=no
add master-interface=[find default-name=wifi2] name=wifi2-STAFF configuration=ax-STAFF disabled=no
add master-interface=[find default-name=wifi2] name=wifi2-VENDOR configuration=ax-VENDOR disabled=no
add master-interface=[find default-name=wifi2] name=wifi2-GUEST configuration=ax-GUEST disabled=no

# --- DNS / NTP / WAN client ---
/ip dns set allow-remote-requests=yes servers=1.1.1.1,8.8.8.8
/ip dns static add name=router.lan address=192.168.88.1 type=A
/system ntp client set enabled=yes
/system ntp client servers add address=time.cloudflare.com
/system ntp server set enabled=yes broadcast=no multicast=no manycast=no

# WAN: DHCP client on ether1 (edit for PPPoE/static)
/ip dhcp-client add interface=ether1 disabled=no add-default-route=yes use-peer-dns=yes use-peer-ntp=no comment=WAN

# --- Firewall (COMMON zone model) ---
/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked comment="SOHO: accept established"
add chain=input action=drop connection-state=invalid comment="SOHO: drop invalid"
add chain=input action=accept protocol=icmp comment="SOHO: ICMP"
add chain=input action=accept in-interface-list=MGMT comment="SOHO: MGMT to router"
add chain=input action=accept protocol=udp dst-port=53,67,123 in-interface-list=!WAN comment="SOHO: DHCP/DNS/NTP internal"
add chain=input action=accept protocol=tcp dst-port=53 in-interface-list=!WAN comment="SOHO: DNS tcp internal"
add chain=input action=drop comment="SOHO: input default drop"

add chain=forward action=fasttrack-connection connection-state=established,related hw-offload=yes comment="SOHO: fasttrack"
add chain=forward action=accept connection-state=established,related,untracked comment="SOHO: forward established"
add chain=forward action=drop connection-state=invalid comment="SOHO: forward invalid"
add chain=forward action=accept in-interface-list=LAN comment="SOHO: trusted anywhere"
add chain=forward action=accept in-interface-list=MGMT comment="SOHO: mgmt anywhere"
add chain=forward action=accept in-interface-list=STAFF out-interface-list=WAN comment="SOHO: staff->WAN"
add chain=forward action=accept in-interface-list=VENDOR out-interface-list=WAN comment="SOHO: vendor->WAN"
add chain=forward action=accept in-interface-list=GUEST out-interface-list=WAN comment="SOHO: guest->WAN"
add chain=forward action=accept in-interface-list=PBX out-interface-list=WAN comment="SOHO: pbx->WAN"
add chain=forward action=accept in-interface-list=CAMERA out-interface-list=WAN comment="SOHO: camera->WAN (skeleton; remove if LAN-only)"
# add chain=forward action=accept in-interface-list=REMOTE out-interface-list=WAN comment="SOHO: remote->WAN (enable with VLAN99 BTH)"
add chain=forward action=accept connection-nat-state=dstnat comment="SOHO: dstnat (no DNAT by default)"
add chain=forward action=drop comment="SOHO: forward default drop"

/ip firewall nat
add chain=srcnat action=masquerade out-interface-list=WAN comment="SOHO: WAN masquerade"

# Optional: disable unused helpers (SIP left enabled comment — disable if ALG breaks VoIP)
/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set h323 disabled=yes
set pptp disabled=yes
# set sip disabled=yes

# IPv6: drop until designed; disable ND advertise on all
/ipv6 settings set disable-ipv6=yes forward=no
/ipv6 nd set [find default=yes] disabled=yes

# --- Hardening / services ---
/user settings set minimum-password-length=12 minimum-categories=2
# /user set [find name=admin] password="SET_LOCALLY"  — or rename admin

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set www-ssl disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set winbox available-from=192.168.88.0/24 disabled=no
# If BTH clients manage the router, append ,BTH_SUBNET to winbox available-from=
# set winbox available-from=192.168.88.0/24,BTH_SUBNET
set ssh available-from=192.168.88.0/24 disabled=no
# reverse-proxy (443): disable unless you use it
set reverse-proxy disabled=yes

/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/ip neighbor discovery-settings set discover-interface-list=MGMT
/tool bandwidth-server set enabled=no
/tool romon set enabled=no
/ip smb set enabled=no
/disk settings set auto-smb-sharing=no auto-media-sharing=no

/ip cloud set back-to-home-vpn=enabled
# Prefer landing BTH on VLAN99 later; avoid peer allow-lan=yes as long-term design
# /interface list member add interface=back-to-home-vpn list=MGMT

print "SOHO hAP ax2 (C52iG-5HaxD2HaxD) — 5× ether GW baseline loaded"
