# Staging (field-pull root)

Devices fetch this tree. Humans edit `templates/` and `scripts/`, then publish
copies here.

## Contract

- Paths under `soho/latest/` and `scripts/latest/` stay put. Add new files;
  do not rename or relocate a file a router might already request.
- `latest` means the current recommended baseline for that family. It is a
  directory of real file copies, not a Git branch and not a symlink.
  `raw.githubusercontent.com` does not follow symlinks.
- Contents of `soho/latest/gateway/*.rsc` and `soho/latest/cap/*.rsc` must
  match `templates/soho/`. Refresh them with `scripts/publish-soho-staging.sh`
  and commit the copies in the same change as the template edit.
- `scripts/latest/*.rsc` must match the `.rsc` files in `scripts/`. The
  publish helper copies those too. Maintainer shell scripts are not published.
- Markdown in `templates/soho/` is not copied here. Field URLs are for
  `.rsc` (and, later, Release `.npk` assets).
- Do not put secrets, filled PSKs, or `.npk` binaries in this tree.
  Packages are described in [packages/README.md](packages/README.md) and
  shipped as GitHub Releases.

## Layout

```
staging/
  soho/latest/gateway/*.rsc    published SOHO edge / switch scripts
  soho/latest/cap/*.rsc        published SOHO CAP scripts
  packages/                    layout notes only (no npk in git)
  scripts/latest/*.rsc         published fetch helpers
```

Future families (`isp`, `event`) get `staging/<family>/latest/` the same way.

Pull examples and the private-repo case: [docs/field-pull.md](../docs/field-pull.md).
