#!/bin/bash

# Konfigürasyon değişkenleri
INTERFACE="eth0"  # Kullanılan ağ arayüzü
DEFAULT_UPSTREAM_BW=55000  # Başlangıç yükleme bant genişliği (kbps)
DEFAULT_DOWNSTREAM_BW=940000  # Başlangıç indirme bant genişliği (kbps)
TARGET_LATENCY=10  # Hedef gecikme (ms)
QUEUE_LIMIT=100  # Kuyruk derinliği
PING_HOST="8.8.8.8"  # Ping testi için hedef (Google DNS)
TRACEROUTE_HOST="8.8.8.8"  # Traceroute testi için hedef (Google DNS)
SPEEDTEST_SERVER="example_speedtest_server"  # Speedtest sunucusu (örneğin, speedtest.net server)
PERFORMANCE_LOG="performance_log.txt"  # Performans log dosyası
TEMP_LOG="temp_log.txt"  # Geçici log dosyası
LATENCY_THRESHOLD=20  # Gecikme eşiği (ms)
MAX_LOG_SIZE=10240  # Log dosyasının maksimum boyutu (10 MB)
LOG_RETENTION_DAYS=7  # Log dosyalarının saklanma süresi (gün)
ANALYSIS_INTERVAL=60  # Ağ analizi için aralık (saniye)

# Log dosyası boyutunu kontrol et ve gerekirse döndür
function rotate_logs {
    if [ -f $PERFORMANCE_LOG ]; then
        local log_size=$(stat -c%s "$PERFORMANCE_LOG")
        if [ "$log_size" -ge "$MAX_LOG_SIZE" ]; then
            echo "[$(date)] Log dosyası çok büyük. Döndürülüyor..." | tee -a $PERFORMANCE_LOG
            mv $PERFORMANCE_LOG "${PERFORMANCE_LOG}.old"
            touch $PERFORMANCE_LOG
        fi
    fi
    find . -name "${PERFORMANCE_LOG}*" -mtime +$LOG_RETENTION_DAYS -exec rm -f {} \;
}

# Bant genişliği ayarlarını yap
function set_sqm {
    local up_bw=$1
    local down_bw=$2

    echo "[$(date)] SQM ayarlarını yapıyor: Upload BW = ${up_bw} kbps, Download BW = ${down_bw} kbps" | tee -a $PERFORMANCE_LOG
    tc qdisc del dev $INTERFACE root 2>/dev/null

    # Bandwidth ayarlarını yap
    tc qdisc add dev $INTERFACE root handle 1: htb default 12
    tc class add dev $INTERFACE parent 1: classid 1:1 htb rate ${up_bw}kbps
    tc class add dev $INTERFACE parent 1: classid 1:2 htb rate ${down_bw}kbps

    # Cake ayarları
    tc qdisc add dev $INTERFACE parent 1:1 handle 10: cake bandwidth ${up_bw}kbit
    tc qdisc add dev $INTERFACE parent 1:2 handle 20: cake bandwidth ${down_bw}kbit

    # Gecikme ve kuyruk ayarları
    tc qdisc add dev $INTERFACE parent 10: handle 30: netem delay ${TARGET_LATENCY}ms
    tc qdisc add dev $INTERFACE parent 20: handle 40: netem delay ${TARGET_LATENCY}ms

    # Kuyruk derinliği ayarları
    tc qdisc add dev $INTERFACE parent 30: handle 50: pfifo limit ${QUEUE_LIMIT}
    tc qdisc add dev $INTERFACE parent 40: handle 60: pfifo limit ${QUEUE_LIMIT}
}

# Gecikme ve jitter testlerini yap
function test_latency_and_jitter {
    echo "[$(date)] Gecikme ve jitter testleri başlıyor..." | tee -a $PERFORMANCE_LOG
    ping -c 10 $PING_HOST | tee -a $TEMP_LOG
    grep 'avg' $TEMP_LOG | awk -F '/' '{print "Ortalama gecikme: "$5" ms"}' | tee -a $PERFORMANCE_LOG
    grep 'min/avg/max' $TEMP_LOG | awk -F '/' '{print "Gecikme aralığı: "$1" - "$3" ms"}' | tee -a $PERFORMANCE_LOG
    echo "[$(date)] Traceroute testi başlıyor..." | tee -a $PERFORMANCE_LOG
    traceroute $TRACEROUTE_HOST | tee -a $PERFORMANCE_LOG
}

# Speedtest performansını ölç
function test_speed {
    echo "[$(date)] Speedtest performansı ölçülüyor..." | tee -a $PERFORMANCE_LOG
    speedtest-cli --server $SPEEDTEST_SERVER | tee -a $PERFORMANCE_LOG
}

# Ağ trafiğini analiz et
function analyze_bandwidth_usage {
    echo "[$(date)] Bant genişliği kullanımı analizi başlıyor..." | tee -a $PERFORMANCE_LOG
    ifstat -i $INTERFACE 1 10 | tee -a $PERFORMANCE_LOG
}

function analyze_packet_loss_and_rtt {
    echo "[$(date)] Paket kaybı ve RTT analizi başlıyor..." | tee -a $PERFORMANCE_LOG
    ping -c 10 8.8.8.8 | tee -a $TEMP_LOG
    grep 'packet loss' $TEMP_LOG | tee -a $PERFORMANCE_LOG
    grep 'avg' $TEMP_LOG | awk -F '/' '{print "Ortalama RTT: "$5" ms"}' | tee -a $PERFORMANCE_LOG
}

function analyze_traffic {
    echo "[$(date)] Ağ trafiği analizi başlıyor..." | tee -a $PERFORMANCE_LOG
    echo "IP bağlantı istatistikleri:" | tee -a $PERFORMANCE_LOG
    ip -s link show dev $INTERFACE | tee -a $PERFORMANCE_LOG
    echo "Ağ arayüzü istatistikleri:" | tee -a $PERFORMANCE_LOG
    netstat -i | tee -a $PERFORMANCE_LOG
    echo "Ağ istatistikleri:" | tee -a $PERFORMANCE_LOG
    ss -s | tee -a $PERFORMANCE_LOG
}

# Performans testlerini yap ve en iyi ayarları bulacak fonksiyon
function optimize_sqm {
    local up_bw_start=50000
    local down_bw_start=930000
    local step=5000
    local best_latency=999999
    local best_up_bw=$up_bw_start
    local best_down_bw=$down_bw_start

    rotate_logs  # Log döndürmeyi başlat

    for ((i=0; i<10; i++)); do
        local up_bw=$(($up_bw_start + $i * $step))
        local down_bw=$(($down_bw_start + $i * $step))
        set_sqm $up_bw $down_bw
        
        echo "[$(date)] Test ediliyor: Upload BW = $up_bw kbps, Download BW = $down_bw kbps" | tee -a $PERFORMANCE_LOG
        sleep 3m  # Ayarların oturması için bekle

        test_latency_and_jitter
        test_speed
        analyze_bandwidth_usage
        analyze_packet_loss_and_rtt
        analyze_traffic

        local current_latency=$(grep 'Ortalama gecikme' $PERFORMANCE_LOG | awk '{print $3}')
        if [[ -z "$current_latency" ]]; then
            current_latency=999999  # Eğer latency bilgisi alınamadıysa büyük bir değer ata
        fi

        if (( $(echo "$current_latency < $best_latency" | bc -l) )); then
            best_latency=$current_latency
            best_up_bw=$up_bw
            best_down_bw=$down_bw
            echo "[$(date)] Yeni en iyi gecikme bulundu: ${best_latency} ms" | tee -a $PERFORMANCE_LOG
        fi

        # Performans raporları oluştur
        echo "[$(date)] Performans Raporu: Upload BW = $best_up_bw kbps, Download BW = $best_down_bw kbps, Gecikme = ${best_latency} ms" | tee -a $PERFORMANCE_LOG
    done

    echo "[$(date)] En iyi ayarlar: Upload BW = ${best_up_bw} kbps, Download BW = ${best_down_bw} kbps, Gecikme = ${best_latency} ms" | tee -a $PERFORMANCE_LOG
    set_sqm $best_up_bw $best_down_bw
}

# Performans testi ve ağ analizi başlat
function run_analysis {
    optimize_sqm
    echo "[$(date)] Bant genişliği ve ağ analizi başlıyor..." | tee -a $PERFORMANCE_LOG
    while true; do
        analyze_bandwidth_usage
        analyze_packet_loss_and_rtt
        analyze_traffic
        sleep $ANALYSIS_INTERVAL
    done
}

# Başlat
run_analysis
