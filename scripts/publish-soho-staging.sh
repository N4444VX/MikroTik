#!/bin/sh
# Copy SOHO apply scripts and shared RouterOS scripts into staging/.
# GitHub raw URLs do not follow symlinks, so staging holds real copies.
# Run from anywhere. Commit templates/ and staging/ together.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
src="$root/templates/soho"
dst="$root/staging/soho/latest"

for role in gateway cap; do
  mkdir -p "$dst/$role"
  cp -p "$src/$role/"*.rsc "$dst/$role/"
done

mkdir -p "$root/staging/scripts/latest"
cp -p "$root/scripts/"*.rsc "$root/staging/scripts/latest/"

echo "published templates/soho -> staging/soho/latest"
echo "published scripts/*.rsc -> staging/scripts/latest"
