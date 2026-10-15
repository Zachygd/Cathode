#!/bin/bash
# Checks the build machine before a Cathode image build: tools, signing
# keys, and that every package named in image/config.kiwi actually exists
# in the Fedora 44 + RPM Fusion repositories.
set -uo pipefail
top=$(cd "$(dirname "$0")/.." && pwd)
desc=$top/image/config.kiwi
fail=0
ok()   { printf '  \e[32mok\e[0m    %s\n' "$*"; }
bad()  { printf '  \e[31mFAIL\e[0m  %s\n' "$*"; fail=1; }
warn() { printf '  \e[33mwarn\e[0m  %s\n' "$*"; }

echo "Build host"
# shellcheck disable=SC1091
if grep -q '^ID=fedora' /etc/os-release; then ok "Fedora $(. /etc/os-release; echo "$VERSION_ID")"; else bad "not a Fedora system"; fi
for cmd in kiwi-ng rpmbuild createrepo_c dnf5 xmllint; do
    if command -v "$cmd" >/dev/null; then ok "$cmd"; else bad "$cmd missing"; fi
done
# KIWI has to run on a real Fedora install. Inside toolbox/distrobox/podman
# it can't mount, label SELinux files or create users in the image properly.
if [ -f /run/.containerenv ] || [ -f /.dockerenv ] || systemd-detect-virt -cq 2>/dev/null; then
    if [ "${CATHODE_ALLOW_CONTAINER:-0}" = 1 ]; then
        warn "running inside a container (allowed by CATHODE_ALLOW_CONTAINER=1)"
    else
        bad "running inside a container (toolbox/distrobox?). Run the build in a normal terminal on the host"
    fi
else
    ok "not in a container"
fi
# RPM 4.20+ creates the image's users and groups by running the HOST's
# systemd-sysusers with --root. If it's missing, installing the very first
# package (setup) fails with "%sysusers ... scriptlet failed, exit status 127".
sysusers=$(rpm --eval '%{?__systemd_sysusers}' 2>/dev/null)
if [ -z "$sysusers" ]; then
    ok "rpm user creation helper disabled"
elif [ -x "$sysusers" ]; then
    ok "$sysusers"
else
    bad "$sysusers missing; install it with: sudo dnf install $sysusers"
fi
free_gb=$(df -BG --output=avail "$top" | tail -1 | tr -dc 0-9)
if [ "${free_gb:-0}" -ge 25 ]; then ok "${free_gb} GB free"; else warn "only ${free_gb:-?} GB free here; a build needs about 25 GB"; fi

echo "Signing keys"
# shellcheck disable=SC2013
for key in $(grep -o 'file:///[^"]*' "$desc" | sed 's|file://||' | sort -u); do
    if [ -r "$key" ]; then ok "$key"; else bad "$key missing"; fi
done

echo "Packages (checking the repositories, this takes a minute)"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/cathode.repo" <<REPO
[fedora]
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-44&arch=x86_64
[updates]
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f44&arch=x86_64
[rpmfusion-free]
metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-44&arch=x86_64
[rpmfusion-free-updates]
metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-44&arch=x86_64
[rpmfusion-nonfree]
metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-44&arch=x86_64
[rpmfusion-nonfree-updates]
metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-44&arch=x86_64
REPO
dnf=(dnf5 -q --setopt=reposdir="$tmp" --setopt=cachedir="$tmp/cache" --setopt=gpgcheck=0 --releasever=44)
wanted=$(xmllint --xpath '//packages/package/@name' "$desc" | grep -o '"[^"]*"' | tr -d '"' | grep -v '^cathode-' | sort -u)
# shellcheck disable=SC2086  # one argument per package name
found=$("${dnf[@]}" repoquery --available --qf '%{name}\n' $wanted 2>/dev/null | sort -u)
missing=$(comm -23 <(echo "$wanted") <(echo "$found"))
if [ -z "$missing" ]; then ok "all $(echo "$wanted" | wc -l) packages found"; else
    for p in $missing; do bad "package not found: $p"; done
fi
if "${dnf[@]}" group info core >/dev/null 2>&1; then ok "group: core"; else bad "group 'core' not found"; fi

echo
if [ $fail = 0 ]; then echo "Preflight passed."; else echo "Preflight found problems (see FAIL lines)."; fi
exit $fail
