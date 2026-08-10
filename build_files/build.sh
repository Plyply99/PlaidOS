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
dnf5 -y install nethogs iotop amdgpu_top # Astra Monitor extension
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

### Rebuild the bundled blur library against this image's mutter
# The release zip ships a .so built for the release machine's mutter; this
# image may run a different mutter major version, so recompile from the
# Plaid blur fork (pinned commit) against the local mutter ABI.
dnf5 -y install --setopt=install_weak_deps=False \
  meson ninja-build gcc glib2-devel gobject-introspection-devel mutter-devel
cd /tmp
git clone https://github.com/Plyply99/Plaid-rounded-blur blur-lib
cd blur-lib
git checkout "${BLUR_PIN:-2bce7db}"
MUTTER_API="$(ls /usr/lib64/libmutter-*.so 2>/dev/null | grep -oE 'mutter-[0-9]+' | head -1 | grep -oE '[0-9]+$')"
MUTTER_LIBDIR="$(pkg-config --variable=libdir mutter-clutter-$MUTTER_API 2>/dev/null || echo /usr/lib64/mutter-$MUTTER_API)"
meson setup build -Dc_link_args="-Wl,-rpath,$MUTTER_LIBDIR" -Dmutter-api="$MUTTER_API"
meson compile -C build
meson install -C build --destdir /tmp/stage
cp /tmp/stage/usr/local/lib64/libblur-effect-1.0.so.1.0.0 "$PLAID_SKEL/lib/libblur-effect-1.0.so.1"
GIR_FILE=/tmp/stage/usr/local/share/gir-1.0/Blur-1.0.gir
sed "s|shared-library=\"libblur-effect-1.0.so.1\"|shared-library=\"$PLAID_SKEL/lib/libblur-effect-1.0.so.1\"|" "$GIR_FILE" > /tmp/Blur-abs.gir
g-ir-compiler /tmp/Blur-abs.gir -o "$PLAID_SKEL/lib/Blur-1.0.typelib"
cd /tmp && rm -rf blur-lib /tmp/stage
dnf5 clean all

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
