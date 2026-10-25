# Sites

Per-site overlays go here, one directory per site tag:

```
sites/MHT/
sites/19H/
```

Those names are examples from the SOHO notes. This tree does not contain
live site data.

What belongs in an overlay:

- A copy of the `.rsc` files you actually applied, still with `CHANGE_ME_*`
  if the repo can see them
- A filled `SITE-VARS` sheet that omits passphrases (copy
  [templates/soho/SITE-VARS.example](../templates/soho/SITE-VARS.example))
- Port-role notes and which skeleton VLANs are active

What does not belong here, ever:

- Wi-Fi PSKs, user passwords, WireGuard or Back to Home private keys
- `/export show-sensitive`, binary `.backup` files, or support output
- Fetch tokens

This repository is public. A site that needs secret-bearing scripts keeps
them off this remote (private repo or the device only). `sites/` is not a
field-pull root; routers fetch `staging/`.
