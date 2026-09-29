<div align="center">

<!--<img src="https://ict.ipb.ac.id/wp-content/uploads/2020/12/Logo-ICT.png" alt="ICT IPB" height="52">-->

# Access Connect

![sh](https://img.shields.io/badge/sh-POSIX-4EAA25?logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)

Skrip untuk menyambung ke Wi-Fi **IPB-ACCESS** di GNU/Linux lewat NetworkManager (`nmcli`), lengkap dengan pembuatan profil 802.1X yang persisten. Skrip ini dibuat karena ICT IPB **tidak melihat Linux sebagai OS umum** yang biasa dipakai mahasiswa, sehingga tidak menyediakan layanan terbaik untuk connect ke wifi `ipb-access` melalui GNU/Linux.

</div>

## Kenapa Skrip Ini Ada?

Di GNU/Linux, `IPB-ACCESS` sebenarnya **bisa terhubung dan lolos autentikasi 802.1X**, tetapi **tidak mendapat akses internet**. Windows, macOS, dan Android tidak mengalami hal ini.

**Akar masalahnya ada di sisi DHCP `IPB-ACCESS`, bukan di konfigurasi pengguna.** Klien Linux mengirim DHCP client-id dengan format `01:<MAC>` — byte tipe perangkat keras `0x01` di depan MAC (format RFC 4361). DHCP/NAC IPB belum menangani format ini dengan benar, sehingga klien Linux dilempar ke scope rusak (`10.2.160.0/20`) yang gateway-nya tidak merespons. Klien Windows/macOS/Android yang mengirim client-id **tanpa** prefix tipe mendapat scope normal (`10.1.192.0/20`) dan langsung jalan.

Skrip ini mengatasinya dengan memaksa klien Linux mengirim DHCP client-id seperti OS lain — **MAC mentah tanpa byte `01:`**:

```
ipv4.dhcp-client-id = <MAC interface, tanpa prefix 01>
```

Setelah itu gateway, DNS, dan internet kembali normal.

### Harapan (dengan sedikit doa)

Semoga ICT IPB **tidak segera** memperbaiki celah ini. Bukan karena kami menolak pelayanan yang lebih baik — justru sebaliknya — tetapi selama celah ini masih ada, skrip ini tetap punya alasan untuk hidup.

Kalau skrip ini membantumu, bantu kami dengan memberi ⭐ **star** di repositori ini. Setiap bintang menambah peluang skrip ini ditemukan mahasiswa GNU/Linux lain yang sedang berjuang menyambung ke `IPB-ACCESS`, dan semoga suatu hari ia muncul di daftar populer GitHub. Warisan kecil dari sebuah keterbatasan.

[![GitHub stars](https://img.shields.io/github/stars/IPBOS/access-connect?style=social)](https://github.com/IPBOS/access-connect)

## Prasyarat

- GNU/Linux dengan NetworkManager (perintah `nmcli`) — lihat cara memasangnya di [Dependensi](#dependensi).
- Interface Wi-Fi aktif.
- Akun `ID-IPB` yang valid.
- Utilitas standar: `awk`, `od`, `tr`, `grep`, `ip`, `ping` (umumnya sudah tersedia).

## Instalasi

### Opsi A — clone repositori

```sh
git clone https://github.com/IPBOS/access-connect.git
cd access-connect
chmod +x access-connect.sh
```

### Opsi B — unduh satu file saja

Kalau hanya butuh skripnya:

```sh
curl -fsSLO https://raw.githubusercontent.com/IPBOS/access-connect/main/access-connect.sh
chmod +x access-connect.sh
```

### Dependensi

Skrip membutuhkan **NetworkManager** (penyedia `nmcli`) dan utilitas standar
(`awk`, `od`, `tr`, `grep`, `ip`, `ping`, `stty`). Sebagian besar distro desktop
sudah menyertakannya.

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

Pada distro berbasis systemd, aktifkan juga layanannya:

```sh
sudo systemctl enable --now NetworkManager
```

Setelah terpasang, cek dengan `nmcli device status` — interface Wi-Fi harus muncul
bertipe `wifi`.

</details>

## Cara Pakai

Jalankan skrip, lalu masukkan `ID-IPB` dan password saat diminta:

```sh
./access-connect.sh
```

Skrip akan mendeteksi interface Wi-Fi, membuat profil `IPB-ACCESS`, dan langsung
menyambung. Jika penyimpanan profil gagal karena izin, jalankan ulang dengan `sudo`:

```sh
sudo ./access-connect.sh
```

### Opsi

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

## Fitur

- Membuat/memperbarui profil NetworkManager untuk `IPB-ACCESS` (persisten, autoconnect).
- Konfigurasi WPA-Enterprise otomatis: EAP `PEAP` dengan Phase 2 `GTC`.
- Menerima `ID-IPB` singkat (mis. `username`) maupun lengkap (`username@apps.ipb.ac.id`).
- `dhcp-client-id` diset ke MAC mentah tanpa prefix `01:` — ini inti perbaikannya, lihat [Kenapa Skrip Ini Ada?](#kenapa-skrip-ini-ada).
- Verifikasi koneksi setelah tersambung (alamat IPv4 dan ping ke gateway).
- Mode hapus profil (`--forget`) dan mode hanya-buat-profil (`--no-connect`).

## Alur Kerja

1. Cek ketersediaan `nmcli`.
2. Deteksi interface Wi-Fi dan ambil MAC address-nya.
3. Baca `ID-IPB` dan password (password disembunyikan saat diketik).
4. Buat atau perbarui profil NetworkManager dengan konfigurasi 802.1X.
5. Sambung ke `IPB-ACCESS` dan verifikasi alamat IPv4 serta gateway.

## Troubleshooting

- **`nmcli tidak ditemukan`** — pastikan NetworkManager terpasang dan `nmcli` ada di `PATH`.
- **`tidak ada interface Wi-Fi`** — aktifkan/muat driver interface Wi-Fi (`nmcli dev status`).
- **Gagal menyimpan profil** — jalankan skrip dengan `sudo`.
- **Gagal menyambung** — periksa kembali `ID-IPB` dan password, lalu jalankan ulang.
- **Tersambung tapi tidak ada internet / gateway tidak merespons** — inilah akar masalah DHCP client-id. Skrip sudah menanganinya; pastikan profil memuatnya dengan `nmcli -f ipv4.dhcp-client-id connection show IPB-ACCESS`.
- **Ingin memulai dari nol** — hapus profil lalu buat ulang:

  ```sh
  ./access-connect.sh --forget
  ./access-connect.sh
  ```

## Lisensi

Didistribusikan di bawah lisensi [MIT](LICENSE).
