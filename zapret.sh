#!/bin/bash

# Gerekli paketlerin kontrolü ve yüklenmesi
echo "wget ve unzip paketlerinin olup olmadığını kontrol ediyoruz..."

# wget kontrolü
if ! command -v wget &> /dev/null; then
    echo "wget bulunamadı, yükleniyor..."
    opkg update
    opkg install wget
else
    echo "wget zaten yüklü."
fi

# unzip kontrolü
if ! command -v unzip &> /dev/null; then
    echo "unzip bulunamadı, yükleniyor..."
    opkg update
    opkg install unzip
else
    echo "unzip zaten yüklü."
fi

# /tmp dizinine zip dosyasını indirme
echo "Zapret zip dosyası indiriliyor..."
wget -O /tmp/master.zip https://github.com/bol-van/zapret/archive/refs/heads/master.zip

if [ $? -eq 0 ]; then
    echo "Dosya başarıyla indirildi."
else
    echo "Dosya indirilemedi. Lütfen bağlantınızı kontrol edin."
    exit 1
fi

# Zip dosyasını /tmp dizininde çıkartma
echo "Zip dosyası çıkarılıyor..."
unzip /tmp/master.zip -d /tmp

# İndirilen zip dosyasını silme
if [ $? -eq 0 ]; then
    echo "Zip dosyası çıkarıldı, master.zip siliniyor..."
    rm /tmp/master.zip
else
    echo "Zip dosyası çıkarılamadı."
    exit 1
fi

# zapret-master dizinine geçiş
echo "zapret-master dizinine geçiliyor..."
cd /tmp/zapret-master || { echo "Dizin değiştirilemedi."; exit 1; }

# install_prereq.sh dosyasını çalıştırma
echo "install_prereq.sh dosyası çalıştırılıyor..."
chmod +x install_prereq.sh
./install_prereq.sh

if [ $? -eq 0 ]; then
    echo "install_prereq.sh başarıyla çalıştırıldı."
else
    echo "install_prereq.sh çalıştırılırken bir hata oluştu."
    exit 1
fi

# install_bin.sh dosyasını çalıştırma
echo "install_bin.sh dosyası çalıştırılıyor..."
chmod +x install_bin.sh
./install_bin.sh

if [ $? -eq 0 ]; then
    echo "install_bin.sh başarıyla çalıştırıldı."
else
    echo "install_bin.sh çalıştırılırken bir hata oluştu."
    exit 1
fi

# blockcheck.sh dosyasını çalıştırma
echo "blockcheck.sh dosyası çalıştırılıyor..."
chmod +x blockcheck.sh
./blockcheck.sh

if [ $? -eq 0 ]; then
    echo "blockcheck.sh başarıyla çalıştırıldı."
else
    echo "blockcheck.sh çalıştırılırken bir hata oluştu."
    exit 1
fi

# install_easy.sh dosyasını çalıştırma
echo "install_easy.sh dosyası çalıştırılıyor..."
chmod +x install_easy.sh
./install_easy.sh

if [ $? -eq 0 ]; then
    echo "install_easy.sh başarıyla çalıştırıldı."
else
    echo "install_easy.sh çalıştırılırken bir hata oluştu."
    exit 1
fi