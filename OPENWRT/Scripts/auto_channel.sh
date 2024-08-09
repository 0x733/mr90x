#!/bin/sh

# Tüm Wi-Fi arayüzlerinde kanal taraması yapar ve en uygun kanalı ayarlar

for iface in $(iw dev | awk '$1=="Interface"{print $2}'); do
    # En az kullanılan kanalı bul
    best_channel=$(iw dev $iface scan | grep frequency | sort | uniq -c | sort -n | awk '{print $3}' | head -1)
    
    # Kanalı ayarla
    uci set wireless.@wifi-device[0].channel=$best_channel
    uci commit wireless
    wifi reload
done
