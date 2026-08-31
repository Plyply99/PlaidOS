#!/bin/bash

set -ouex pipefail

#dnf5 -y install dnf5-plugins
dnf5 -y config-manager enable updates-testing
dnf5 -y update
dnf5 -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm   
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld --allowerasing --enablerepo=rpmfusion-free-updates-testing
dnf5 -y install libavcodec-freeworld #mesa-va-drivers-freeworld
dnf5 -y install @multimedia
dnf5 -y swap ffmpeg-free ffmpeg --allowerasing

# Additional repos
dnf5 -y copr enable ublue-os/akmods 
#dnf5 -y copr enable cyqsimon/bat-extras
#dnf5 -y copr enable mineiro/ghostty
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Terra uses file:// gpg keys that break bootc-image-builder's ISO depsolve
# (the key paths don't exist in BIB's container). Install was already
# --nogpgcheck, so keep the baked repo usable for disk-image builds.
sed -i 's/^gpgcheck=1/gpgcheck=0/; s/^repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/terra.repo

### Install packages
dnf5 -y install adw-gtk3-theme akmods bat bat-extras btop cava chafa distrobox emacs fastfetch fzf gdm gh ghostty gnome-software gnome-software-rpm-ostree htop input-remapper kernel-devel kitty libva-utils mangohud mpv nautilus nodejs24 rpmdevtools steam-devices vkBasalt xwininfo --allowerasing
dnf5 -y install nethogs iotop amdgpu_top # Astra Monitor extension
dnf5 -y remove firefox
dnf5 clean all

### Plaid for new users (installed into ~/.local via /etc/skel)
# Plaid runs from the user's home directory, not /usr/share. skel copies it
# into each new user's ~/.local at account creation; the dconf defaults below
# enable it on first login. Updates flow through the extension's auto-update.
PLAID_JSON=$(curl -sL https://api.github.com/repos/Plyply99/Plaid/releases/latest)
PLAID_URL=$(echo "$PLAID_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for a in d.get('assets', []):
    if a['name'] == 'plaid@plyply99.zip':
        print(a['browser_download_url'])
        break
")
if [ -z "$PLAID_URL" ]; then
    echo "ERROR: could not find Plaid release zip" >&2
    exit 1
fi
echo "Staging Plaid from: $PLAID_URL"
curl -sL -o /tmp/plaid.zip "$PLAID_URL"
PLAID_SKEL=/etc/skel/.local/share/gnome-shell/extensions/plaid@plyply99
mkdir -p /etc/skel/.local/share/gnome-shell/extensions
unzip -q -o /tmp/plaid.zip -d "$PLAID_SKEL"
rm -f /tmp/plaid.zip
glib-compile-schemas "$PLAID_SKEL/schemas"

### Fonts
mkdir -p /usr/share/fonts/plaidos/MapleMono-NF /usr/share/fonts/plaidos/Balsamiq_Sans
cp /ctx/fonts/MapleMono-NF/*.ttf /usr/share/fonts/plaidos/MapleMono-NF/
cp /ctx/fonts/Balsamiq_Sans/*.ttf /usr/share/fonts/plaidos/Balsamiq_Sans/
fc-cache -f /usr/share/fonts/plaidos

### Skeleton user config (ghostty, bashrc)
mkdir -p /etc/skel/.config
cp -r /ctx/skel/.config/ghostty /etc/skel/.config/
cp /ctx/skel/.bashrc /etc/skel/.bashrc

### dconf defaults: enable Plaid + reference config
mkdir -p /etc/dconf/profile /etc/dconf/db/local.d
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF
cp /ctx/dconf/00-plaidos /etc/dconf/db/local.d/00-plaidos
dconf update

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
