# Package staging

CAPsMAN upgrades a CAP from files in a **local** directory on the manager.
SOHO gateways set `package-path=/caps-pkgs`. This folder documents how those
files are named and where they come from. It does not hold the binaries.

Do not commit `.npk` files here unless we explicitly choose to. They are
large, they go stale in a hurry, and Git LFS would make a raw URL return a
pointer file instead of the package. GitHub Releases are the distribution
path.

## What a mixed SOHO fleet needs

One flat directory on the gateway. CAPsMAN picks the npk that matches the
CAP's architecture and variant. Official MikroTik filenames put the version
in the middle.

| CAP | Arch | Packages in `/caps-pkgs` |
|---|---|---|
| RB5009 / modern CCR acting only as manager | arm64 | The manager upgrades itself from `/system package`; CAPs do not use the manager's own arch unless a CAP is also arm64 |
| arm64 CAP or arm64 local radio, if any | arm64 | `routeros-<ver>-arm64.npk`, `wifi-qcom-<ver>-arm64.npk` |
| cAP ax, wAP ax, hAP ax², hAP ax³ | **arm** (32-bit) | `routeros-<ver>-arm.npk`, `wifi-qcom-<ver>-arm.npk` |
| cAP ac (wifi-qcom-ac) | arm | `routeros-<ver>-arm.npk`, `wifi-qcom-ac-<ver>-arm.npk` |

`wifi-qcom-ac` does not replace `wifi-qcom` for ax radios. A folder that only
has `wifi-qcom-ac` for arm will not upgrade a cAP ax. cAP ac must not be
given `wifi-qcom`.

Example for 7.24.5, all five files in `/caps-pkgs`:

```
routeros-7.24.5-arm64.npk
wifi-qcom-7.24.5-arm64.npk
routeros-7.24.5-arm.npk
wifi-qcom-7.24.5-arm.npk
wifi-qcom-ac-7.24.5-arm.npk
```

16 MB cAP ac boards: confirm free flash before the CAP accepts an upgrade.
Netinstall with only routeros + wifi-qcom-ac if the disk fills.

## If files are ever committed

Keep them out of the repository root and out of `latest` script directories.
Browse layout, by architecture then version:

```
staging/packages/arm64/7.24.5/routeros-7.24.5-arm64.npk
staging/packages/arm64/7.24.5/wifi-qcom-7.24.5-arm64.npk
staging/packages/arm/7.24.5/routeros-7.24.5-arm.npk
staging/packages/arm/7.24.5/wifi-qcom-7.24.5-arm.npk
staging/packages/arm/7.24.5/wifi-qcom-ac-7.24.5-arm.npk
```

Raw URL shape (only valid if the blob is actually in git, not LFS):

```
https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/packages/arm/7.24.5/wifi-qcom-7.24.5-arm.npk
```

The pull script's default is Releases, not this path. `*.npk` is gitignored
so a local drop into this tree is not committed by accident.

## GitHub Releases (preferred)

Create a release whose tag is:

```
soho-pkgs-<version>
```

Example: `soho-pkgs-7.24.5`. Attach the five npk files as assets. Asset names
must match the filenames above (flat; the arch is already in the name).

Public download URL:

```
https://github.com/N4444VX/MikroTik/releases/download/soho-pkgs-7.24.5/wifi-qcom-7.24.5-arm.npk
```

That URL redirects to the asset host. RouterOS v7 `/tool fetch` follows the
redirect. On failure, copy the files from a workstation into `/caps-pkgs`.

`scripts/pull_capsman_packages.rsc` (published at
`staging/scripts/latest/pull_capsman_packages.rsc`) creates `/caps-pkgs` if
needed and fetches the five names for the version you set. `source=release`
(the default) uses the Release URL above. `source=raw` uses:

```
https://raw.githubusercontent.com/N4444VX/MikroTik/main/staging/packages/<arch>/<ver>/<file>.npk
```

The script flattens either source into `/caps-pkgs`. It does not reboot the
gateway and it does not press "upgrade" on the CAPs.
`upgrade-policy=suggest-same-version` only offers the packages.

No `soho-pkgs-*` release is published by the layout change that added this
README. The script 404s until the assets exist.

## What does not belong in package-path

- A URL. `package-path` is a router directory.
- The legacy `wireless` package.
- Extra packages (container, zerotier, and the rest) unless a site actually
  uses them. cAP ac has no room.
