#!/bin/sh

set -u

PROFILE="IPB-ACCESS"
SSID="IPB-ACCESS"
DOMAIN="apps.ipb.ac.id"
DO_CONNECT=1
DO_FORGET=0
NMC="$(command -v nmcli || echo /usr/bin/nmcli)"

usage() {
    cat <<EOF
Pakai: $(basename "$0") [opsi]

  -n, --name NAMA     Nama profil NetworkManager (default: $PROFILE)
      --ssid SSID     SSID target (default: $SSID)
      --no-connect    Hanya buat/perbarui profil, jangan menyambung
      --forget        Hapus profil lalu keluar
  -h, --help          Tampilkan bantuan ini
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--name)   PROFILE="${2:-}"; shift 2 ;;
        --ssid)      SSID="${2:-}";    shift 2 ;;
        --no-connect) DO_CONNECT=0;    shift ;;
        --forget)    DO_FORGET=1;      shift ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Argumen tidak dikenal: $1" >&2; usage; exit 1 ;;
    esac
done

[ -x "$NMC" ] || { echo "ERROR: nmcli tidak ditemukan." >&2; exit 1; }

# ---- mode hapus profil ----
if [ "$DO_FORGET" -eq 1 ]; then
    if $NMC -t -f NAME connection show | grep -qxF "$PROFILE"; then
        $NMC connection delete "$PROFILE" && echo "Profil '$PROFILE' dihapus."
    else
        echo "Profil '$PROFILE' tidak ada."
    fi
    exit 0
fi

# ---- deteksi interface Wi-Fi ----
IFACE="$($NMC -t -f DEVICE,TYPE dev status | awk -F: '$2=="wifi"{print $1; exit}')"
if [ -z "$IFACE" ]; then
    echo "ERROR: tidak ada interface Wi-Fi." >&2
    exit 1
fi
MAC="$(cat "/sys/class/net/$IFACE/address" | tr 'A-Z' 'a-z')"

# ---- input ID-IPB ----
printf 'ID-IPB (mis. username, atau lengkap: username@apps.ipb.ac.id): '
read -r ID
[ -n "${ID:-}" ] || { echo "ERROR: ID kosong." >&2; exit 1; }

case "$ID" in
    *@*) IDENTITY="$ID" ;;                 # sudah ada domain, pakai apa adanya
    *)   IDENTITY="$ID@$DOMAIN" ;;         # tambahkan domain default
esac

# ---- input password (disembunyikan) ----
printf 'Password ID-IPB: '
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
read -r PW
if [ -t 0 ]; then stty echo 2>/dev/null; printf '\n'; fi
[ -n "${PW:-}" ] || { echo "ERROR: password kosong." >&2; exit 1; }

# NetworkManager memakai 802-1x.password-raw (hex). Sediakan keduanya.
PWHEX="$(printf '%s' "$PW" | od -An -tx1 | tr -d ' \n')"

echo "-------------------------------------------------------------"
echo " Interface : $IFACE"
echo " SSID      : $SSID"
echo " Identity  : $IDENTITY"
echo " Profil    : $PROFILE"
echo "-------------------------------------------------------------"

# ---- buat atau perbarui profil (persisten) ----
if $NMC -t -f NAME connection show | grep -qxF "$PROFILE"; then
    echo ">> Memperbarui profil '$PROFILE' ..."
    $NMC connection modify "$PROFILE" \
        connection.autoconnect yes \
        802-11-wireless.ssid "$SSID" \
        802-11-wireless-security.key-mgmt wpa-eap \
        802-1x.eap peap \
        802-1x.phase2-auth gtc \
        802-1x.identity "$IDENTITY" \
        802-1x.system-ca-certs no \
        802-1x.password-flags 0 \
        802-1x.password "$PW" \
        802-1x.password-raw-flags 0 \
        802-1x.password-raw "$PWHEX" \
        ipv4.method auto \
        ipv4.dhcp-client-id "$MAC"
    RC=$?
else
    echo ">> Membuat profil '$PROFILE' ..."
    $NMC connection add \
        type wifi con-name "$PROFILE" ifname "$IFACE" ssid "$SSID" \
        connection.autoconnect yes \
        wifi-sec.key-mgmt wpa-eap \
        802-1x.eap peap \
        802-1x.phase2-auth gtc \
        802-1x.identity "$IDENTITY" \
        802-1x.system-ca-certs no \
        802-1x.password-flags 0 \
        802-1x.password "$PW" \
        802-1x.password-raw-flags 0 \
        802-1x.password-raw "$PWHEX" \
        ipv4.method auto \
        ipv4.dhcp-client-id "$MAC"
    RC=$?
fi

# Pastikan profil tidak terpaku ke satu AP tertentu (bssid) - bisa bikin gagal assosiasi.
$NMC connection modify "$PROFILE" 802-11-wireless.bssid "" >/dev/null 2>&1

PW=""; PWHEX=""   # bersihkan dari memori

if [ "$RC" -ne 0 ]; then
    echo "ERROR: gagal menyimpan profil (kode $RC)." >&2
    echo "Coba jalankan ulang dengan sudo." >&2
    exit 1
fi
echo ">> Profil tersimpan permanen."

# ---- opsional: cek isi penting ----
$NMC -f 802-11-wireless.ssid,802-1x.identity,802-1x.phase2-auth,ipv4.dhcp-client-id connection show "$PROFILE"

# ---- sambung ----
if [ "$DO_CONNECT" -eq 1 ]; then
    echo ">> Menyambung ke '$SSID' ..."
    if $NMC --wait 60 connection up "$PROFILE"; then
        echo ">> BERHASIL tersambung ke '$SSID'."
        ip -4 addr show "$IFACE" | grep 'inet ' || true
        GW="$(ip route | awk '/^default/{print $3; exit}')"
        if [ -n "${GW:-}" ]; then
            if ping -c 1 -W 2 "$GW" >/dev/null 2>&1; then
                echo ">> Gateway $GW OK (koneksi sehat)."
            else
                echo ">> Peringatan: gateway $GW tidak merespons."
            fi
        fi
    else
        echo ">> GAGAL menyambung. Periksa ID/password lalu coba lagi." >&2
        exit 1
    fi
fi
