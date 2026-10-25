# =============================================================================
# pull_capsman_packages.rsc
# Download RouterOS + wifi packages into /caps-pkgs for CAPsMAN package-path.
#
# SOHO gateways already set:
#   /interface wifi capsman set package-path=/caps-pkgs upgrade-policy=suggest-same-version
#
# This file does not reboot and does not start the CAP upgrade. It only
# stores npk files. Edit rosVersion to the minor the site is moving to.
# Gateway and CAPs stay on the same minor.
#
# source (edit this):
#   release  DEFAULT. GitHub Release tag soho-pkgs-<rosVersion>, flat assets.
#            Binaries are not in git. See staging/packages/README.md.
#   raw      Fetch the staging/packages/<arch>/<ver>/ tree on this repo:
#              .../staging/packages/arm64/<ver>/routeros-<ver>-arm64.npk
#              .../staging/packages/arm64/<ver>/wifi-qcom-<ver>-arm64.npk
#              .../staging/packages/arm/<ver>/routeros-<ver>-arm.npk
#              .../staging/packages/arm/<ver>/wifi-qcom-<ver>-arm.npk
#              .../staging/packages/arm/<ver>/wifi-qcom-ac-<ver>-arm.npk
#            Those paths 404 until the npk blobs are actually committed.
#            Do not use Git LFS for them: raw.githubusercontent.com would
#            return the pointer text, and CAPsMAN would not accept it.
#
# Files stored flat in /caps-pkgs (CAPsMAN does not walk subdirectories):
#   routeros-<ver>-arm64.npk
#   wifi-qcom-<ver>-arm64.npk
#   routeros-<ver>-arm.npk
#   wifi-qcom-<ver>-arm.npk          32-bit ax: cAP ax, wAP ax, hAP ax
#   wifi-qcom-ac-<ver>-arm.npk       cAP ac only; do not use on ax
#
# No soho-pkgs-* release is created by the repo layout itself. fetch stops
# on the first 404.
#
# Run from the gateway (public repo):
#   /tool fetch url="https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/scripts/latest/pull_capsman_packages.rsc" dst-path=pull_capsman_packages.rsc
#   /import file-name=pull_capsman_packages.rsc
# =============================================================================

:local rosVersion "7.24.5"
:local source "release"
:local repo "N4444VX/MikroTik"
:local rawBase "https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/packages"
:local dstDir "caps-pkgs"
:local releaseTag ""
:local fArm64Ros ""
:local fArm64Wifi ""
:local fArmRos ""
:local fArmWifi ""
:local fArmWifiAc ""
:local arch ""
:local dst ""
:local url ""
# Set after the declarations. RouterOS initializes locals up front, so one
# local's value is not visible while another :local on the next line runs.
:set releaseTag ("soho-pkgs-" . $rosVersion)
:set fArm64Ros ("routeros-" . $rosVersion . "-arm64.npk")
:set fArm64Wifi ("wifi-qcom-" . $rosVersion . "-arm64.npk")
:set fArmRos ("routeros-" . $rosVersion . "-arm.npk")
:set fArmWifi ("wifi-qcom-" . $rosVersion . "-arm.npk")
:set fArmWifiAc ("wifi-qcom-ac-" . $rosVersion . "-arm.npk")

:if (($source != "release") && ($source != "raw")) do={
  :error "pull_capsman_packages: source must be release or raw"
}

:if ([:len [/file find where name=$dstDir and type="directory"]] = 0) do={
  /file add name=$dstDir type=directory
}

:foreach name in={$fArm64Ros;$fArm64Wifi;$fArmRos;$fArmWifi;$fArmWifiAc} do={
  :set arch "arm"
  :if ([:typeof [:find $name "-arm64"]] != "nil") do={
    :set arch "arm64"
  }
  :set dst ($dstDir . "/" . $name)
  :if ($source = "raw") do={
    :set url ($rawBase . "/" . $arch . "/" . $rosVersion . "/" . $name)
  } else={
    :set url ("https://github.com/" . $repo . "/releases/download/" . $releaseTag . "/" . $name)
  }
  :put ("pull_capsman_packages: GET " . $url)
  :log info ("pull_capsman_packages: fetching " . $url)
  :if ([:len [/file find where name=$dst]] > 0) do={
    /file remove [find where name=$dst]
  }
  /tool fetch url=$url dst-path=$dst mode=https check-certificate=yes
}

:put ("pull_capsman_packages: stored 5 packages under /" . $dstDir . " for " . $rosVersion . " via " . $source)
:put "CAPsMAN package-path=/caps-pkgs upgrade-policy=suggest-same-version offers them to CAPs."
:put "Confirm /file print and free space on 16MB cAP ac before accepting an upgrade."
