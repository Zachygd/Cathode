Name:           cathode-branding
Version:        44.1
Release:        1%{?dist}
Summary:        Cathode name and identity on top of Fedora
License:        MIT
BuildArch:      noarch
Source0:        os-release

Requires:       generic-logos
Conflicts:      fedora-logos

%description
Gives the system the name Cathode in /etc/os-release, which is what the
installer, the boot menu, KDE's "About this System" page and other tools
show. The OS keeps ID=fedora so Fedora repositories and tools keep working.
Fedora's trademarked logos are replaced by generic-logos.

%prep

%build

%install
install -Dm644 %{SOURCE0} %{buildroot}%{_datadir}/cathode/os-release

%files
%{_datadir}/cathode/os-release

# Fedora's release package owns /etc/os-release (a symlink to
# /usr/lib/os-release) and puts it back on every upgrade, so re-apply ours
# whenever that package is installed or updated, and once now.
%triggerin -- fedora-release-common
rm -f %{_sysconfdir}/os-release
cp -f %{_datadir}/cathode/os-release %{_sysconfdir}/os-release

%posttrans
rm -f %{_sysconfdir}/os-release
cp -f %{_datadir}/cathode/os-release %{_sysconfdir}/os-release

%postun
if [ "$1" = 0 ] && [ -e %{_prefix}/lib/os-release ]; then
    rm -f %{_sysconfdir}/os-release
    ln -s ../usr/lib/os-release %{_sysconfdir}/os-release
fi

%changelog
* Wed Oct 14 2026 Zach - 44.1-1
- Phase 1: Cathode name in os-release
