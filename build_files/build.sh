#!/bin/bash

set -ouex pipefail

# Additional repos
dnf5 -y copr enable ublue-os/akmods 
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Terra uses file:// gpg keys that break bootc-image-builder's ISO depsolve
# (the key paths don't exist in BIB's container). Install was already
# --nogpgcheck, so keep the baked repo usable for disk-image builds.
sed -i 's/^gpgcheck=1/gpgcheck=0/; s/^repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/terra.repo

### Install packages
dnf5 -y install bat bat-extras btop cava chafa emacs fastfetch ghostty htop input-remapper mangohud mpv nodejs24 vkBasalt unzip
dnf5 clean all

### Bake in Plaid (latest release from GitHub)
mkdir -p /usr/share/gnome-shell/extensions
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
echo "Baking Plaid from: $PLAID_URL"
curl -sL -o /tmp/plaid.zip "$PLAID_URL"
mkdir -p /usr/share/gnome-shell/extensions/plaid@plyply99
unzip -q -o /tmp/plaid.zip -d /usr/share/gnome-shell/extensions/plaid@plyply99
rm -f /tmp/plaid.zip
glib-compile-schemas /usr/share/gnome-shell/extensions/plaid@plyply99/schemas

### Fonts
mkdir -p /usr/share/fonts/plaidos/MapleMono-NF /usr/share/fonts/plaidos/Balsamiq_Sans
cp /ctx/fonts/MapleMono-NF/*.ttf /usr/share/fonts/plaidos/MapleMono-NF/
cp /ctx/fonts/Balsamiq_Sans/*.ttf /usr/share/fonts/plaidos/Balsamiq_Sans/
fc-cache -f /usr/share/fonts/plaidos

### Skeleton user config (ghostty, environment.d, bashrc)
mkdir -p /etc/skel/.config
cp -r /ctx/skel/.config/ghostty /etc/skel/.config/
mkdir -p /etc/skel/.config/environment.d
cp /ctx/skel/.config/environment.d/plaid-blur.conf /etc/skel/.config/environment.d/
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
s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"44\"|
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
