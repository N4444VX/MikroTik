# Site overlays

One directory per site, named with that site’s short code:

```
sites/MHT/
sites/19H/
```

Copy the template files you will actually apply (today, from [`templates/soho/`](../templates/soho/README.md)) into the site directory and adjust port roles, identity strings, and which skeleton VLANs are active. Leave unused VLANs safe-empty rather than deleting the skeleton.

Do not commit any of the following:

- live PSKs or admin passwords (`CHANGE_ME_*` stays a token in git)
- a filled `SITE-VARS` file
- `/export` output or binary backups, including `show-sensitive`
- certificates or private keys

Track the site code, device identities, port-role comments, and which VLANs are active. Set passphrases on the router.

`sites/` is empty on purpose until a site overlay is ready to share without secrets.
