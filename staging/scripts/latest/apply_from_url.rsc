# =============================================================================
# apply_from_url.rsc
# Fetch one published config from staging/ and /import it.
#
# Published copy (this file, after publish-soho-staging.sh):
#   staging/scripts/latest/apply_from_url.rsc
#   https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/scripts/latest/apply_from_url.rsc
#
# SITE / model - edit the locals below before /import. Do not put PSKs here.
#   siteCode   short site tag, logged only (MHT, 19H, ...). The imported
#              template still contains SITE_CODE until you edit that file.
#   role       gateway | cap
#   model      file stem, no .rsc:
#                gateway: RB5009 L009 hAPax2 hAPax3 CCR CRS-switch
#                cap:     cAPax hAPax2 hAPax3 wAPax cAPac
#   family     soho (later: isp, event) - directory under staging/
#
# Gateway baselines ship with passphrase="CHANGE_ME_*". This script will not
# import role=gateway until allowPlaceholderPsk is "yes" (lab only).
# Production gateways: edit a private copy, then fetch that file yourself.
#
# These .rsc files expect /system reset-configuration no-defaults=yes.
# They are not a merge onto a configured router. Backup and Safe Mode first.
#
# Manual equivalent (no helper), cAP ax:
#   /tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/soho/latest/cap/cAPax.rsc" dst-path=cAPax.rsc
#   /import file-name=cAPax.rsc
# =============================================================================

:local siteCode "SITE_CODE"
:local role "cap"
:local model "cAPax"
:local family "soho"
:local allowPlaceholderPsk "no"
:local baseUrl "https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging"
:local dst ""
:local url ""
# Set after the declarations. RouterOS initializes locals up front, so one
# local's value is not visible while another :local on the next line runs.
:set dst ($model . ".rsc")
:set url ($baseUrl . "/" . $family . "/latest/" . $role . "/" . $dst)

:if (($role != "gateway") && ($role != "cap")) do={
  :error "apply_from_url: role must be gateway or cap"
}
:if (($role = "gateway") && ($allowPlaceholderPsk != "yes")) do={
  :log error ("apply_from_url: site=" . $siteCode . " model=" . $model . " still has CHANGE_ME placeholders")
  :error "apply_from_url: set allowPlaceholderPsk to yes for a lab gateway import"
}

:put ("apply_from_url: site=" . $siteCode . " GET " . $url)
:log info ("apply_from_url: site=" . $siteCode . " fetching " . $url)

:if ([:len [/file find where name=$dst]] > 0) do={
  /file remove [find where name=$dst]
}

/tool fetch url=$url dst-path=$dst mode=https check-certificate=yes
/import file-name=$dst

:put ("apply_from_url: imported " . $dst . " for site " . $siteCode)
:put "Next: replace SITE_* / CHANGE_ME_* on the device, then templates/soho/CHECKLIST.md"
