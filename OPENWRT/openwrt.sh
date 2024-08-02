#!/bin/bash

# Yönlendirici bilgileri
ROUTER_IP="192.168.1.1"
ROUTER_SSH_PORT="20001"
ROUTER_PASSWORD="YOUR_ROUTER_PASSWORD"

# OpenWrt dosyaları
INITRAMFS_FILE="initramfs-kernel.bin"
SYSUPGRADE_FILE="sysupgrade.bin"
BUSYBOX_URL="http://mirror.archlinuxarm.org/aarch64/extra/busybox-1.36.1-2-aarch64.pkg.tar.xz"
BUSYBOX_FILE="busybox-1.36.1-2-aarch64.pkg.tar.xz"
BUSYBOX_BIN="usr/bin/busybox"

# SSH bağlantısı
ssh_command() {
    ssh -p "$ROUTER_SSH_PORT" root@"$ROUTER_IP" "$@"
}

# Boot indeksi kontrolü
tp_boot_idx=$(ssh_command "fw_printenv | grep tp_boot_idx")

if [[ $tp_boot_idx == "tp_boot_idx=1" ]]; then
    echo "Stok yazılımı yüklü. Lütfen web arayüzünden MERCUSYS stok yazılımını yükleyip tekrar deneyin."
    exit 1
fi

# 65-iptv dosyasını düzenleme ve telnetd başlatma
ssh_command "echo 'telnetd -l /bin/login.sh' >> /etc/hotplug.d/iface/65-iptv"
ssh_command "uci set network.lan.iptv='1' && uci commit network && /etc/init.d/network reload"

# initramfs-kernel.bin dosyasını yükleme
cat "$INITRAMFS_FILE" | ssh -p "$ROUTER_SSH_PORT" root@"$ROUTER_IP" "cat > /tmp/$INITRAMFS_FILE"

# busybox'ı indirme ve çıkartma
wget "$BUSYBOX_URL"
tar xvf "$BUSYBOX_FILE"

# busybox'ı yönlendiriciye gönderme
cat "$BUSYBOX_BIN" | ssh -p "$ROUTER_SSH_PORT" root@"$ROUTER_IP" "cat > /tmp/busybox"

# busybox'ı çalıştırılabilir yapma
ssh_command "cd /tmp && chmod a+x busybox"

# initramfs-kernel.bin boyutunu kontrol etme ve yeni birim oluşturma
initramfs_size=$(ssh_command "du -h /tmp/$INITRAMFS_FILE | awk '{print $1}'")
ubi_size=$(echo "$initramfs_size" | sed 's/[^0-9]*//')
ssh_command "ubirmvol /dev/ubi0 -N kernel && ubimkvol /dev/ubi0 -n 1 -N kernel -s $((ubi_size + 1))MiB"

# OpenWrt initramfs yazma ve yeniden başlatma
ssh_command "./tmp/busybox ubiupdatevol /dev/ubi0_1 /tmp/$INITRAMFS_FILE && reboot"

# OpenWrt env değişkenlerini ayarlama (SSH bağlantısı için biraz bekleme)
sleep 30
ssh -p 22 root@"$ROUTER_IP" "fw_setenv baudrate 115200; fw_setenv bootargs 'ubi.mtd=ubi0 console=ttyS0,115200n1 loglevel=8 earlycon=uart8250,mmio32,0x11002000 init=/etc/preinit'; fw_setenv fdtcontroladdr 5ffc0e70; fw_setenv ipaddr 192.168.1.1; fw_setenv loadaddr 0x46000000; fw_setenv mtdids 'spi-nand0=spi-nand0'; fw_setenv mtdparts 'spi-nand0:2M(boot),1M(u-boot-env),50M(ubi0),50M(ubi1),8M(userconfig),4M(tp_data)'; fw_setenv netmask 255.255.255.0; fw_setenv serverip 192.168.1.2; fw_setenv stderr serial@11002000; fw_setenv stdin serial@11002000; fw_setenv stdout serial@11002000; fw_setenv tp_boot_idx 0"

# sysupgrade.bin dosyasını yükleme ve sysupgrade çalıştırma
cat "$SYSUPGRADE_FILE" | ssh -p 22 root@"$ROUTER_IP" "cat > /tmp/$SYSUPGRADE_FILE"
ssh -p 22 root@"$ROUTER_IP" "sysupgrade -n /tmp/$SYSUPGRADE_FILE"

echo "OpenWrt kurulumu tamamlandı!"