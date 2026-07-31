#!/bin/bash

set -ouex pipefail

# Add dnf plugins
dnf5 -y install dnf5-plugins

# Add hardware codecs and multimedia
dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install @multimedia
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld --allowerasing --enablerepo=rpmfusion-free-updates-testing
dnf5 -y swap ffmpeg-free ffmpeg --allowerasing

# Add COPR and TERRA repos
dnf5 -y copr enable avengemedia/dms-git 
dnf5 -y copr enable yalter/niri-git
dnf5 -y copr enable lionheartp/Hyprland #nett00n/hyprland
dnf5 -y copr enable ublue-os/akmods 
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Use niri-git instead of fedora repo
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo

### Install packages
dnf5 -y install steam-devices
dnf5 -y install plymouth plymouth-theme-spinner ly rpmdevtools akmods audit pciutils nethogs iotop
dnf5 -y install alsa-firmware cups-pk-helper fprintd fprintd-pam i2c-tools kf6-kimageformats khal power-profiles-daemon gnome-software gnome-software-rpm-ostree htop xwininfo glibc-locale-source glibc-langpack-en libva-utils
dnf5 -y install cups cups-filters system-config-printer gutenprint gutenprint-cups bluez-cups NetworkManager-wifi avahi-dnsconfd firewalld firewall-offline-cmd distrobox smartmontools speech-dispatcher
dnf5 -y install adw-gtk3-theme bat bat-extras btop chafa cliphist dgop dms dsearch emacs eza fastfetch gamemode ghostty gnome-disk-utility grim input-remapper mangohud mpv nautilus niri npm nwg-look python3-dbus-next qt6-qtmultimedia slurp vkBasalt
dnf5 -y install hyprland hyprland-guiutils hyprpicker #--allowerasing --skip-broken
dnf5 -y install gnome-shell

# Remove niri-git and hyprland optional dependencies
dnf5 -y remove alacritty fuzzel kitty mako swaybg swayidle swaylock SwayNotificationCenter waybar wofi
dnf5 clean all

#### Example for enabling a System Unit File
systemctl disable gdm # Enabled automatically when installing gnome
systemctl enable avahi-daemon.service firewalld.service NetworkManager.service ly@tty2.service rtkit-daemon.service plymouth-start.service
systemctl enable cups.socket
systemctl mask bootc-fetch-apply-updates.timer #turn off update timer

# Ly login manager
systemctl disable getty@tty2.service
semanage fcontext -a -t xdm_exec_t /usr/bin/ly
chcon system_u:object_r:xdm_exec_t:s0 /usr/bin/ly
restorecon -v /usr/bin/ly

# Plymouth prettiness
systemctl enable plymouth-start.service
set -x; \
    kver=$(cd /usr/lib/modules && echo *); \
    dracut -vf --no-machineid /usr/lib/modules/$kver/initramfs.img $kver

#Set locale and environment
localedef -i en_US -f UTF-8 en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set os-release
HOME_URL="https://github.com/Plyply99/PlyplyOS"
sed -i -f - /usr/lib/os-release <<EOF
s|^NAME=.*|NAME=\"PlyplyOS\"|
s|^PRETTY_NAME=.*|PRETTY_NAME=\"PlyplyOS built $(date +"%y/%m/%d")\"|
s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"44\"|
s|^VARIANT_ID=.*|VARIANT_ID=""|
s|^HOME_URL=.*|HOME_URL=\"${HOME_URL}\"|
s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"${HOME_URL}/issues\"|
s|^SUPPORT_URL=.*|SUPPORT_URL=\"${HOME_URL}/issues\"|
s|^CPE_NAME=\".*\"|CPE_NAME=\"cpe:/o:plyplyos-dev:plyplyos\"|
s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"${HOME_URL}\"|
#s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="plyply-pc"|

/^REDHAT_BUGZILLA_PRODUCT=/d
/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d
/^REDHAT_SUPPORT_PRODUCT=/d
/^REDHAT_SUPPORT_PRODUCT_VERSION=/d
EOF
echo "VARIANT_ID=container" >> /usr/lib/os-release
ln -s fedora-release /usr/lib/system-release





