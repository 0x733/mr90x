MERCUSYS MW301R V1'e OpenWrt Kurulumu
 * Ağ Kablosu Bağlantısı: Ağ kablosunu yönlendiricinin LAN1 portuna bağlayın.
 * SSH ile Oturum Açma: SSH aracılığıyla root olarak oturum açın (yönlendirici IP'si, port 20001, şifre - web arayüzü şifreniz).
 * Boot Endeksi Kontrolü: Aşağıdaki komutu çalıştırın:
   fw_printenv | grep tp_boot_idx

   Eğer sonuç tp_boot_idx=1 ise, web arayüzünü kullanarak MERCUSYS stok yazılımını yükleyin ve 2. adımdan başlayın. Aksi halde bir sonraki adıma geçin.
 * 65-iptv Dosyasını Düzenleme: /etc/hotplug.d/iface/65-iptv dosyasını düzenlemek için açın (örneğin, WinSCP ve SSH ayarlarını kullanarak).
 * Telnetd Komutu Ekleme: #!/bin/sh'den sonra yeni bir satır ekleyin:
   telnetd -l /bin/login.sh

 * Dosyayı Kaydetme ve Ayarları Değiştirme: 65-iptv dosyasını kaydedin. Yönlendirici web arayüzünde IPTV/VLAN Etkinleştir onay kutusunu değiştirin ve kaydedin.
 * Telnetd Kontrolü: Telnetd'nin çalıştığından emin olun:
   netstat -ltunp | grep 23

 * Telnet ile Giriş: Telnet aracılığıyla yönlendirici IP'sine, port 23'e giriş yapın (kullanıcı adı ve şifre gerekmez).
 * OpenWrt Dosyasını Yükleme: OpenWrt initramfs-kernel.bin dosyasını yönlendiricinin /tmp klasörüne yükleyin (örneğin, WinSCP ve SSH ayarlarını kullanarak veya aşağıdaki komutla):
   cat initramfs-kernel.bin | ssh -p 20001 root@YOUR_ROUTER_IP "cat > /tmp/initramfs-kernel.bin"

 * Busybox Yükleme: Stok meşgul kutusu ubiupdatevol komutunu içermez. Bu nedenle, meşgul kutunun tam sürümünü yönlendiriciye indirip yüklememiz gerekiyor. Örneğin, ArchLinux'tan - busybox.pkg.tar.xz dosyasını indirin, tar xvf busybox-1.36.1-1-aarch64.pkg.tar.xz ile paketini açın, ardından usr/bin/busybox'ı yönlendiricinin /tmp dizinine yükleyin ve telnet'te çalıştırın:
   cd /tmp 
chmod a+x busybox

 * Dosya Boyutu Kontrolü: initramfs-kernel.bin boyutunu kontrol edin:
   du -h initramfs-kernel.bin

 * Yeni Birim Oluşturma: Eski birimi silin ve uygun boyutta (initramfs-kernel.bin boyutundan büyük) yeni bir çekirdek birimi oluşturun:
   ubirmvol /dev/ubi0 -N kernel 
ubimkvol /dev/ubi0 -n 1 -N kernel -s 9MiB

 * OpenWrt Yazma: Flash'a OpenWrt initramfs-kernel.bin yazın:
   ./busybox ubiupdatevol /dev/ubi0_1 /tmp/initramfs-kernel.bin

 * Yeniden Başlatma: OpenWrt initramfs'ı yeniden başlatın:
   reboot

 * SSH ile Oturum Açma: SSH aracılığıyla root olarak oturum açın (IP 192.168.1.1, port 22).
 * Env Değişkenlerini Ayarlama: OpenWrt'a girdikten sonra env değişkenlerini ayarlayın (veya güncelleyin):
   fw_setenv baudrate 115200
fw_setenv bootargs "ubi.mtd=ubi0 console=ttyS0,115200n1 loglevel=8 earlycon=uart8250,mmio32,0x11002000 init=/etc/preinit"
fw_setenv fdtcontroladdr 5ffc0e70
fw_setenv ipaddr 192.168.1.1
fw_setenv loadaddr 0x46000000
fw_setenv mtdids "spi-nand0=spi-nand0"
fw_setenv mtdparts "spi-nand0:2M(boot),1M(u-boot-env),50M(ubi0),50M(ubi1),8M(userconfig),4M(tp_data)"
fw_setenv netmask 255.255.255.0
fw_setenv serverip 192.168.1.2
fw_setenv stderr serial@11002000
fw_setenv stdin serial@11002000
fw_setenv stdout serial@11002000
fw_setenv tp_boot_idx 0

 * Sysupgrade Dosyasını Yükleme: OpenWrt sysupgrade.bin görüntüsünü yönlendiricinin /tmp dizinine yükleyin.
 * Sysupgrade Çalıştırma: Sysupgrade'i çalıştırın:
   sysupgrade -n /tmp/sysupgrade.bin

