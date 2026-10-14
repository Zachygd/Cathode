# Cathode

A "sleeper" desktop OS: Windows 98 on the outside, a modern Fedora 44 system
underneath. Plasma 6 on Wayland provides HDR, variable refresh rate, NVIDIA
support and Steam. Cathode strips away everything else and dresses what's
left in a Windows 98-style look, with its own apps.

Cathode is built on Fedora but is not an official Fedora product. It uses
generic logos instead of Fedora's trademarked ones.

## Status

**Phase 1: base system.** A lean Plasma 6 Wayland desktop with no extras.

| Phase | What | Status |
|---|---|---|
| 1 | Base system: minimal Plasma Wayland, NVIDIA, Steam, HDR-ready, no extras | **in progress** |
| 2 | The look: Cathode widget style, title bars, taskbar + Start menu, icons, cursors, sounds, login screen, boot splash | planned |
| 3 | Apps: Notepad, Calculator, Terminal, Explorer (PCManFM-Qt fork), Control Panel, code editor | planned |
| 4 | Polish: installer branding, startup/shutdown, packaging into a COPR repo | planned |

What phase 1 leaves out: the software store (Discover), KDE Connect, the
email/calendar backend, the file indexer, the welcome app, crash reporter,
PackageKit, Fedora's wallpapers and look-and-feel, the Plasma splash screen,
and window animations, blur and fades. Double-click to open files, like 98.

What it keeps: Plasma 6 on Wayland (HDR, VRR, scaling), the NVIDIA driver
(prebuilt in the image), Steam and GameMode, Wi-Fi, Bluetooth, PipeWire
audio, firmware for Intel/NVIDIA laptops, Flatpak, and the RPM Fusion repos.
Konsole, KWrite and PCManFM-Qt are temporary until Cathode's own apps exist.

## Building the ISO

Build on a Fedora 44 machine with internet and about 25 GB free.

```
# one-time setup
sudo dnf install kiwi-cli kiwi-systemdeps rpm-build createrepo_c libxml2
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
```

(Skip the second command if you already have RPM Fusion; it's only needed
for its signing keys.)

```
tools/preflight.sh     # checks tools, keys and every package name (optional)
tools/build-image.sh   # runs preflight, builds Cathode's RPMs, then the ISO
```

The ISO ends up in `out/image/`. The first build takes a while, because it
downloads everything and compiles the NVIDIA driver into the image.

### Trying it

- **Virtual machine:** in virt-manager or GNOME Boxes, make a VM with UEFI
  firmware, 4+ GB RAM and the ISO as its CD.
- **USB stick:** write the ISO with Fedora Media Writer, or
  `sudo dd if=out/image/*.iso of=/dev/sdX bs=4M status=progress conv=fsync`.
- The live session logs in automatically. "Install to Hard Drive" starts
  Fedora's installer (Anaconda), which shows the name Cathode.

### NVIDIA and Secure Boot

The NVIDIA module is built by akmods and isn't signed by Fedora. With Secure
Boot on, the kernel won't load it, though the Intel graphics still work.
Either turn Secure Boot off, or after installing run
`sudo kmodgenca && sudo mokutil --import /etc/pki/akmods/certs/public_key.der`,
reboot, and enroll the key in the blue MOK screen.

## Layout

```
image/config.kiwi      what goes into the image (packages, repos, ISO settings)
image/config.sh        runs inside the image at build time (services, NVIDIA)
image/root/            files copied into the image (/etc/xdg defaults, first boot)
packages/              Cathode's own RPMs (built into out/repo by tools/build-rpms.sh)
tools/                 preflight, RPM and image build scripts
```

## What's tested so far

The image description passes KIWI's own schema and consistency checks. The
scripts pass ShellCheck. The `cathode-branding` RPM builds and its install,
upgrade and removal scripts were tested against a stand-in Fedora release
package. The full ISO build hasn't been run yet; it needs Fedora's package
servers. `tools/preflight.sh` exists to catch wrong package names before the
long build starts.
