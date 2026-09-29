<div align="center">

<!--<img src="https://ict.ipb.ac.id/wp-content/uploads/2020/12/Logo-ICT.png" alt="ICT IPB" height="52">-->

# [ Access Connect ]

<img src="https://img.shields.io/github/stars/IPBOS/access-connect?style=for-the-badge&color=5A58DE&logoColor=DCE3FF&labelColor=0A0930&logo=github" alt="stars">
<img src="https://img.shields.io/github/last-commit/IPBOS/access-connect?style=for-the-badge&color=4A48D2&logo=git&logoColor=DCE3FF&labelColor=0A0930" alt="last commit">
<img src="https://img.shields.io/github/license/IPBOS/access-connect?style=for-the-badge&color=3A38C6&logoColor=DCE3FF&labelColor=0A0930&logo=opensourceinitiative" alt="license">
<img src="https://img.shields.io/badge/sh-POSIX-2624B6?style=for-the-badge&logo=gnubash&logoColor=DCE3FF&labelColor=0A0930" alt="sh">
<img src="https://img.shields.io/badge/Linux-0C0B8A?style=for-the-badge&logo=linux&logoColor=DCE3FF&labelColor=0A0930" alt="linux">

</div>

<div align="center">

## • Overview •

Skrip satu perintah untuk menyambung ke Wi-Fi **IPB-ACCESS** di GNU/Linux. Skrip ini dibuat karena ICT IPB **tidak melihat Linux sebagai OS umum** yang biasa dipakai mahasiswa, sehingga tidak menyediakan layanan terbaik untuk connect ke wifi `ipb-access` melalui GNU/Linux.

</div>

<div align="center">

## • Kenapa Skrip Ini Ada? •

</div>

Di GNU/Linux, `IPB-ACCESS` terhubung dan lolos autentikasi 802.1X, tetapi **tidak mendapat internet**. Windows, macOS, dan Android aman.

**Akar masalahnya di DHCP IPB, bukan konfigurasi pengguna.** Klien Linux mengirim DHCP client-id `01:<MAC>` (byte tipe `0x01` di depan MAC, RFC 4361). DHCP/NAC IPB salah menanganinya, jadi klien Linux dilempar ke scope rusak `10.2.160.0/20` yang gateway-nya mati. Windows/macOS/Android mengirim client-id tanpa prefix itu, jadi dapat scope benar `10.1.192.0/20` dan langsung jalan.

> [!WARNING]
> Tanpa `ipv4.dhcp-client-id`, profil Linux apa pun — termasuk yang dibuat manual — akan tersambung tapi tanpa internet. Skrip ini menanganinya otomatis.

Solusinya: paksa Linux mengirim DHCP client-id seperti OS lain — **MAC mentah tanpa byte `01:`**:

```
ipv4.dhcp-client-id = <MAC interface, tanpa prefix 01>
```

Setelah itu gateway, DNS, dan internet normal.

### Harapan (dengan sedikit doa)

Semoga ICT IPB **tidak segera** memperbaiki celah ini — selama bug-nya masih ada, skrip ini punya alasan untuk hidup.

Kalau skrip ini membantumu, beri ⭐ **star**. Setiap bintang menambah peluang mahasiswa GNU/Linux lain menemukannya.

<div align="center">

## • Prasyarat •

</div>

- GNU/Linux dengan NetworkManager (`nmcli`) — cara memasangnya di [Dependensi](#dependensi).
- Interface Wi-Fi aktif.
- Akun `ID-IPB` yang valid.
- Utilitas standar: `awk`, `od`, `tr`, `grep`, `ip`, `ping`.

<div align="center">

## • Instalasi •

</div>

### A — clone repositori

```sh
git clone https://github.com/IPBOS/access-connect.git
cd access-connect
chmod +x access-connect.sh
```

### B — unduh satu file

```sh
curl -fsSLO https://raw.githubusercontent.com/IPBOS/access-connect/main/access-connect.sh
chmod +x access-connect.sh
```

### Dependensi

Skrip butuh **NetworkManager** (`nmcli`) dan utilitas standar (`awk`, `od`, `tr`, `grep`, `ip`, `ping`, `stty`) — umumnya sudah ada di distro desktop.

<details>
<summary>Pasang NetworkManager sesuai distro (klik untuk membuka)</summary>

**Debian / Ubuntu / Linux Mint / Kali**

```sh
sudo apt update && sudo apt install network-manager
```

**Fedora / RHEL / CentOS / Rocky / AlmaLinux**

```sh
sudo dnf install NetworkManager
```

**Arch Linux / Manjaro / EndeavourOS**

```sh
sudo pacman -S networkmanager
sudo systemctl enable --now NetworkManager
```

**openSUSE Leap / Tumbleweed**

```sh
sudo zypper install NetworkManager
```

**Alpine Linux**

```sh
sudo apk add networkmanager
```

**Void Linux**

```sh
sudo xbps-install -S NetworkManager
```

Pada distro systemd, aktifkan layanannya:

```sh
sudo systemctl enable --now NetworkManager
```

Cek dengan `nmcli device status` — interface Wi-Fi harus bertipe `wifi`.

</details>

<div align="center">

## • Cara Pakai •

</div>

Jalankan skrip, lalu masukkan `ID-IPB` dan password:

```sh
./access-connect.sh
```

Skrip mendeteksi interface Wi-Fi, membuat profil `IPB-ACCESS`, lalu menyambung. Kalau gagal karena izin, pakai `sudo`:

```sh
sudo ./access-connect.sh
```

<details>
<summary>Opsi</summary>

| Opsi | Keterangan |
| --- | --- |
| `-n, --name NAMA` | Nama profil NetworkManager (default: `IPB-ACCESS`). |
| `--ssid SSID` | SSID target (default: `IPB-ACCESS`). |
| `--no-connect` | Hanya membuat/memperbarui profil, tanpa menyambung. |
| `--forget` | Menghapus profil lalu keluar. |
| `-h, --help` | Menampilkan bantuan. |

Contoh:

```sh
# hanya membuat profil, tidak langsung menyambung
./access-connect.sh --no-connect

# menghapus profil
./access-connect.sh --forget
```

</details>

<details>
<summary>Fitur</summary>

- Membuat/memperbarui profil NetworkManager `IPB-ACCESS` (persisten, autoconnect).
- WPA-Enterprise otomatis: EAP `PEAP`, Phase 2 `GTC`.
- Menerima `ID-IPB` singkat (`username`) atau lengkap (`username@apps.ipb.ac.id`).
- `dhcp-client-id` = MAC mentah tanpa prefix `01:` — inti perbaikannya (lihat [Kenapa Skrip Ini Ada?](#kenapa-skrip-ini-ada)).
- Verifikasi koneksi: alamat IPv4 + ping gateway.
- Mode `--forget` (hapus profil) dan `--no-connect`.

</details>

<div align="center">

## • Alur Kerja •

</div>

1. Cek `nmcli`.
2. Deteksi interface Wi-Fi + ambil MAC.
3. Baca `ID-IPB` dan password (disembunyikan).
4. Buat/perbarui profil dengan konfigurasi 802.1X.
5. Sambung ke `IPB-ACCESS`, verifikasi IPv4 dan gateway.

<div align="center">

## • Troubleshooting •

</div>

- **`nmcli tidak ditemukan`** — pasang NetworkManager, pastikan `nmcli` ada di `PATH`.
- **`tidak ada interface Wi-Fi`** — nyalakan/muat driver Wi-Fi (`nmcli dev status`).
- **Gagal menyimpan profil** — jalankan dengan `sudo`.
- **Gagal menyambung** — cek ulang `ID-IPB` dan password, jalankan lagi.
- **Tersambung tapi tanpa internet** — akar masalah DHCP client-id; skrip sudah menanganinya. Cek dengan `nmcli -f ipv4.dhcp-client-id connection show IPB-ACCESS`.
- **Mulai dari nol** — hapus lalu buat ulang:

  ```sh
  ./access-connect.sh --forget
  ./access-connect.sh
  ```

<div align="center">

## • Lisensi •

</div>

Didistribusikan di bawah lisensi [MIT](LICENSE).
