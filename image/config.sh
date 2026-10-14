#!/bin/bash
# Cathode image configuration. KIWI runs this inside the new root filesystem
# after all packages are installed and image/root/ has been copied in.
set -euxo pipefail

# shellcheck disable=SC1091
test -f /.kconfig && . /.kconfig
# shellcheck disable=SC1091
test -f /.profile && . /.profile

#--------------------------------------------------- live session (livesys)
# livesys-scripts creates the "liveuser" account at boot and logs it into
# the desktop named here.
if [ -f /etc/sysconfig/livesys ]; then
    sed -i 's/^livesys_session=.*/livesys_session="kde"/' /etc/sysconfig/livesys
    grep -q '^livesys_session=' /etc/sysconfig/livesys || echo 'livesys_session="kde"' >> /etc/sysconfig/livesys
else
    echo 'livesys_session="kde"' > /etc/sysconfig/livesys
fi
systemctl enable livesys.service livesys-late.service

#---------------------------------------------------------------- services
systemctl set-default graphical.target
systemctl enable sddm.service
systemctl enable NetworkManager.service
systemctl enable bluetooth.service || true
systemctl enable cathode-firstboot.service

# fluff we never want running
for unit in abrtd.service abrt-journal-core.service packagekit.service \
            packagekit-offline-update.service; do
    systemctl disable "$unit" 2>/dev/null || true
    systemctl mask "$unit" 2>/dev/null || true
done

#----------------------------------------------- NVIDIA module, prebuilt
# akmod-nvidia normally compiles the driver on first boot. Build it now for
# the image's kernel so the installed system has it right away. If it fails
# here, cathode-firstboot builds it on the first boot instead.
kver=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -1)
if command -v akmods >/dev/null; then
    akmods --force --kernels "$kver" || echo "WARNING: NVIDIA akmod build failed in the image; will retry on first boot"
fi

#---------------------------------------------------------------- branding
echo cathode > /etc/hostname

#------------------------------------------------------------------ tidy up
dnf5 clean all || true
rm -rf /var/cache/dnf/* /var/cache/libdnf5/* || true

exit 0
