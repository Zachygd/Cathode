#!/bin/bash
# Build Cathode's own RPMs (packages/*/*.spec) into a local repository that
# the image build installs from.  Usage: tools/build-rpms.sh [outdir]
set -euo pipefail
top=$(cd "$(dirname "$0")/.." && pwd)
out=${1:-$top/out/repo}
work=$top/out/rpmbuild
mkdir -p "$out" "$work"

for spec in "$top"/packages/*/*.spec; do
    dir=$(dirname "$spec")
    echo ">> building $(basename "$spec")"
    rpmbuild -bb "$spec" \
        --define "_topdir $work" \
        --define "_sourcedir $dir" \
        --define "_rpmdir $out" \
        --quiet
done

createrepo_c --quiet "$out"
echo ">> local repository ready: $out"
