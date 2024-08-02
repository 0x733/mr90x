### OpenWrt Kurulumu İçin Gerekli Adımlar

#### 1. Ağ Kablosu Bağlantısı
- Ağ kablosunu yönlendiricinin LAN1 portuna bağlayın.

#### 2. SSH ile Oturum Açma
- SSH aracılığıyla root olarak oturum açın:
  ```
  ssh -p 20001 root@YOUR_ROUTER_IP
  ```
  - Şifre, web arayüzü şifrenizdir.

#### 3. Boot Endeksi Kontrolü
- Eğer sonuç `tp_boot_idx=1` ise, web arayüzünü kullanarak MERCUSYS stok yazılımını yükleyin ve 2. adımdan başlayın.
- Eğer sonuç `tp_boot_idx=0` ise, bir sonraki adıma geçin.

#### 4. 65-iptv Dosyasını Düzenleme
- /etc/hotplug.d/iface/65-iptv dosyasını düzenlemek için açın (örneğin, WinSCP ve SSH ayarlarını kullanarak).
- Dosyanın başına `#!/bin/sh` satırından hemen sonra aşağıdaki komutu ekleyin:
  ```
  telnetd -l /bin/login.sh
  ```
- Dosyayı kaydedin.

#### 5. Ayarları Değiştirme
- Yönlendirici web arayüzünde IPTV/VLAN Etkinleştir onay kutusunu değiştirin ve kaydedin.

#### 6. Telnetd Kontrolü
- Telnetd'nin çalıştığını kontrol edin:
  ```
  netstat -ltunp | grep 23
  ```

#### 7. Telnet ile Giriş
- Telnet aracılığıyla yönlendirici IP'sine, port 23'e giriş yapın (kullanıcı adı ve şifre gerekmez).

#### 8. OpenWrt Dosyasını Yükleme
- OpenWrt initramfs kernel dosyasını yükleyin:
  ```
  cat initramfs-kernel.bin | ssh -p 20001 root@YOUR_ROUTER_IP "cat > /tmp/initramfs-kernel.bin"
  ```

#### 9. Busybox Yükleme
- Busybox'ı yükleyin:
  ```
  cd /tmp
  chmod a+x busybox
  ```

#### 10. Dosya Boyutu Kontrolü
- initramfs kernel dosyasının boyutunu kontrol edin:
  ```
  du -h initramfs-kernel.bin
  ```

#### 11. Yeni Birim Oluşturma
- Yeni birim oluşturun:
  ```
  ubirmvol /dev/ubi0 -N kernel
  ubimkvol /dev/ubi0 -n 1 -N kernel -s 9MiB
  ```

#### 12. OpenWrt Yazma
- OpenWrt'yi yazın:
  ```
  ./busybox ubiupdatevol /dev/ubi0_1 /tmp/initramfs-kernel.bin
  ```

#### 13. Yeniden Başlatma
- Yönlendiriciyi yeniden başlatın:
  ```
  reboot
  ```

#### 14. SSH ile Oturum Açma
- SSH aracılığıyla root olarak oturum açın (IP 192.168.1.1, port 22).

#### 15. Env Değişkenlerini Ayarlama
- Gerekli ortam değişkenlerini ayarlayın:
  ```
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
  ```

#### 16. Sysupgrade Dosyasını Yükleme
- OpenWrt sysupgrade.bin görüntüsünü yönlendiricinin /tmp dizinine yükleyin.

#### 17. Sysupgrade Çalıştırma
- Sysupgrade'i çalıştırın:
  ```
  sysupgrade -n /tmp/sysupgrade.bin
  ```

