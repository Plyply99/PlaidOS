#!/bin/bash

set -ouex pipefail

dnf5 -y install dnf5-plugins
dnf5 -y config-manager setopt updates-testing.enabled=true
dnf5 -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm   
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld --allowerasing --enablerepo=rpmfusion-free-updates-testing
dnf5 -y install libavcodec-freeworld #mesa-va-drivers-freeworld
dnf5 -y install @multimedia
dnf5 -y swap ffmpeg-free ffmpeg --allowerasing
dnf5 -y update

# Additional repos
dnf5 -y copr enable ublue-os/akmods 
dnf5 -y copr enable cyqsimon/bat-extras
dnf5 -y copr enable kmarinos/amdgpu_top 
#dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Terra uses file:// gpg keys that break bootc-image-builder's ISO depsolve
# (the key paths don't exist in BIB's container). Install was already
# --nogpgcheck, so keep the baked repo usable for disk-image builds.
#sed -i 's/^gpgcheck=1/gpgcheck=0/; s/^repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/terra.repo
#sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/terra.repo   
#sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/terra-extras.repo   

### Install packages
dnf5 -y install qemu-device-display-virtio-gpu-gl qemu-device-display-virtio-gpu-pci-gl qemu-system-x86-core qemu-ui-gtk virglrenderer # For VM testing
dnf5 -y install bat bat-extras cava chafa emacs eza gamemode gh ghostty gnome-software gnome-software-rpm-ostree htop kitty mpv nodejs24 
dnf5 -y install adw-gtk3-theme akmods btop distrobox fastfetch fzf gdm input-remapper kernel-devel libva-utils mangohud nautilus rpmdevtools steam steam-devices vkBasalt xwininfo
dnf5 -y install nethogs iotop amdgpu_top # Astra Monitor extension
#dnf5 -y remove firefox bazaar
dnf5 clean all

# Set os-release
HOME_URL="https://github.com/Plyply99/PlaidOS"
sed -i -f - /usr/lib/os-release <<EOF
s|^NAME=.*|NAME=\"PlaidOS\"|
s|^PRETTY_NAME=.*|PRETTY_NAME=\"PlaidOS built $(date +"%y-%m-%d")\"|
s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$(rpm -E %fedora)\"|
s|^VARIANT_ID=.*|VARIANT_ID=""|
s|^HOME_URL=.*|HOME_URL=\"${HOME_URL}\"|
s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"${HOME_URL}/issues\"|
s|^SUPPORT_URL=.*|SUPPORT_URL=\"${HOME_URL}/issues\"|
s|^CPE_NAME=\".*\"|CPE_NAME=\"cpe:/o:plaidos-dev:plaidos\"|
s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"${HOME_URL}\"|
#s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="plyply-pc"|

/^REDHAT_BUGZILLA_PRODUCT=/d
/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d
/^REDHAT_SUPPORT_PRODUCT=/d
/^REDHAT_SUPPORT_PRODUCT_VERSION=/d
EOF
echo "VARIANT_ID=container" >> /usr/lib/os-release
ln -s fedora-release /usr/lib/system-release
