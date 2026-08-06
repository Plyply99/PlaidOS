#!/bin/bash

set -ouex pipefail

# Additional repos
dnf5 -y copr enable ublue-os/akmods 
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

### Install packages
dnf5 -y install bat bat-extras btop cava chafa emacs fastfetch htop input-remapper mangohud mpv nodejs24 vkBasalt
dnf5 clean all

# Ly login manager
#systemctl disable getty@tty2.service
#semanage fcontext -a -t xdm_exec_t /usr/bin/ly
#restorecon -v /usr/bin/ly

#### Example for enabling a System Unit File
#systemctl disable gdm # Enabled automatically when installing gnome # ly@tty2.service

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





