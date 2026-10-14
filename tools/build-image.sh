#!/bin/bash
# Build the Cathode ISO.  Run on a Fedora 44 machine:
#   tools/build-image.sh            (asks for sudo for the kiwi step)
# Output: out/image/Cathode.x86_64-44.1.0.iso
set -euo pipefail
top=$(cd "$(dirname "$0")/.." && pwd)

"$top/tools/preflight.sh" || { echo "Fix the problems above first."; exit 1; }
"$top/tools/build-rpms.sh" "$top/out/repo"

# kiwi reads the description from a directory; fill in the local repo path
desc=$top/out/description
rm -rf "$desc"; mkdir -p "$desc"
cp -a "$top/image/config.sh" "$top/image/root" "$desc/"
sed "s|@CATHODE_LOCAL_REPO@|$top/out/repo|" "$top/image/config.kiwi" > "$desc/config.kiwi"

sudo rm -rf "$top/out/image"
sudo kiwi-ng --type iso system build \
    --description "$desc" \
    --target-dir "$top/out/image"
sudo chown -R "$(id -u):$(id -g)" "$top/out/image" 2>/dev/null || true
echo
ls -lh "$top"/out/image/*.iso
