#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source '/auto_arch/variables.sh'

echo "==> setting hostname to $NEW_HOSTNAME"
echo $NEW_HOSTNAME > /etc/hostname
HOSTS_LINE='127.0.0.1 localhost.localdomain localhost'
sed -i "s/${HOSTS_LINE}/${HOSTS_LINE}    ${NEW_HOSTNAME}/" /etc/hosts

echo "==> setting up time (localtime = $LOCALTIME)"
hwclock --systohc --utc
ln -s /usr/share/zoneinfo/$LOCALTIME /etc/localtime

echo "==> setting locale to $LOCALE"
LOCALE_GEN="${LOCALE} UTF-8"
sed -i "s/#${LOCALE_GEN}/${LOCALE_GEN}/" /etc/locale.gen
locale-gen
echo "LANG=\"$LOCALE\"" > /etc/locale.conf

echo "==> generating initramfs"
mkinitcpio -p linux

echo "==> setting root password to $DEFAULT_PASSWORD"
echo "root:$DEFAULT_PASSWORD" | chpasswd

echo "==> setup ssh access for root"
cp /auto_arch/authorized_keys /root/authorized_keys

echo "==> allow members of wheel to be sudoers"
pacman -S --noconfirm sudo
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

echo "==> setting up network"
systemctl enable dhcpcd

echo "==> installing bootloader"
pacman -S --noconfirm gptfdisk syslinux
sed -i "s/sda[0-9]/sda1/" /boot/syslinux/syslinux.cfg
sed -i 's/TIMEOUT 50/TIMEOUT 10/' "/boot/syslinux/syslinux.cfg"
syslinux-install_update -i -a -m

echo "==> setting up ssh"
pacman -S  --noconfirm --needed openssh
# TODO: disable password auth
systemctl enable sshd

