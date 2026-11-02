# Panduan LLM: sambungkan Linux ke IPB-ACCESS

Dokumen ini adalah runbook untuk asisten LLM. Tujuannya menyambungkan **komputer pengguna** ke Wi-Fi IPB-ACCESS menggunakan `access-connect.sh`. Jalankan langkah di bawah secara berurutan, baca hasilnya, dan lanjut hanya jika prasyarat langkah berikutnya terpenuhi. Jangan menjalankan seluruh dokumen sebagai satu skrip.

## Aturan pelaksanaan

- Gunakan terminal di komputer Linux yang akan disambungkan. Terminal cloud, container, WSL, atau komputer lain tidak mewakili Wi-Fi pengguna. Jika akses lokal tidak tersedia, berikan perintah satu per satu kepada pengguna dan tunggu hasilnya.
- Diperlukan akses internet untuk mengambil repo/paket, perangkat Wi-Fi, jangkauan IPB-ACCESS, serta akun ID-IPB yang valid. Jika internet belum tersedia, minta pengguna memakai koneksi sementara untuk instalasi.
- Jangan meminta password ID-IPB atau sudo di chat, menyimpannya ke file, memasukkannya ke argumen perintah, atau merekamnya di log. Pengguna harus mengetiknya langsung di terminal interaktif yang tidak merekam input rahasia. Jangan gunakan `set -x`, pipe, atau here-document untuk mengirim kredensial.
- Skrip menyimpan kredensial di profil NetworkManager secara persisten dan mengaktifkan autoconnect. Skrip juga menonaktifkan penggunaan sertifikat CA sistem tanpa mengonfigurasi CA server. Jelaskan perilaku ini sebelum menjalankannya; gunakan hanya jaringan IPB-ACCESS yang dipercaya.
- Menyambung Wi-Fi dapat memutus koneksi yang sedang dipakai, termasuk sesi asisten jarak jauh. Siapkan terminal lokal pengguna sebelum langkah sambung.
- Jangan menghapus profil, mengganti pengelola jaringan, atau mengubah skrip untuk mengatasi kegagalan. Berhenti pada langkah yang gagal, jelaskan hasilnya, lalu gunakan diagnosis di bagian akhir.

## 1. Periksa komputer dan dependensi

```sh
uname -s
cat /etc/os-release
```

Lanjut hanya pada GNU/Linux di komputer pengguna. Gunakan `ID` dan `ID_LIKE` dari `/etc/os-release` untuk memilih pengelola paket jika diperlukan.

```sh
for cmd in git nmcli awk od tr grep ip ping stty; do
    command -v "$cmd" || printf 'BELUM TERPASANG: %s\n' "$cmd"
done
```

Jika semuanya ada, lanjut ke langkah 2. Jika ada yang hilang, pasang hanya paket yang diperlukan. Nama paket berikut adalah acuan untuk distro umum; jangan menjalankan semua baris atau menebak pengelola paket pada distro lain:

| Distro | Paket acuan |
| --- | --- |
| Debian / Ubuntu / Mint / Kali | `git network-manager gawk coreutils grep iproute2 iputils-ping` |
| Fedora / RHEL / Rocky / AlmaLinux | `git NetworkManager NetworkManager-wifi gawk coreutils grep iproute iputils` |
| Arch / Manjaro / EndeavourOS | `git networkmanager gawk coreutils grep iproute2 iputils` |

Contoh Debian/Ubuntu jika `git` dan `nmcli` belum tersedia (jalankan satu per satu, berhenti jika gagal):

```sh
sudo apt update
sudo apt install git network-manager
```

Untuk distro lain, rujuk bagian **Dependensi** di `README.md` lokal setelah clone, atau baca https://raw.githubusercontent.com/IPBOS/access-connect/main/README.md. Ulangi pemeriksaan dependensi setelah instalasi. Jika sudah ada pengelola jaringan lain, jangan menggantinya otomatis dengan NetworkManager.

## 2. Periksa NetworkManager dan Wi-Fi

```sh
nmcli general status
nmcli radio wifi
nmcli -f DEVICE,TYPE,STATE device status
```

Jika NetworkManager belum berjalan, pastikan komputer memakai systemd dan tidak dikelola layanan jaringan lain sebelum menjalankan:

```sh
sudo systemctl enable --now NetworkManager
```

Pada sistem non-systemd, gunakan pengelola layanan distro tersebut. Jangan menjalankan `systemctl` tanpa pemeriksaan.

Jika radio Wi-Fi `disabled`, aktifkan:

```sh
nmcli radio wifi on
```

Ulangi pemeriksaan. Harus ada perangkat bertipe `wifi` yang dikelola NetworkManager. Jika tidak ada, atau statusnya `unmanaged`/`unavailable`, berhenti dan selesaikan masalah perangkat/layanan dahulu. Periksa SSID:

```sh
nmcli -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan yes
```

Jika IPB-ACCESS tidak terlihat, minta pengguna mendekati access point atau memastikan jaringan tersedia. Jangan mengganti SSID secara otomatis. Skrip memilih perangkat Wi-Fi pertama; jika ada lebih dari satu, jelaskan perangkat yang akan dipilih sebelum lanjut.

## 3. Siapkan repositori

Gunakan folder proyek pilihan pengguna; jika belum ditentukan, gunakan `~/Documents/Projects`:

```sh
mkdir -p "$HOME/Documents/Projects"
cd "$HOME/Documents/Projects"
git clone https://github.com/IPBOS/access-connect.git
cd access-connect
```

Jalankan setiap baris terpisah dan pastikan berhasil, terutama `cd`. Jika folder `access-connect` sudah ada, jangan clone di atasnya, menghapusnya, atau melakukan reset/pull otomatis. Periksa `git -C access-connect remote -v` dan `git -C access-connect status --short` dari folder induk; gunakan checkout yang benar setelah meninjau perubahan lokal.

Baca `README.md`, instruksi proyek jika ada, dan `access-connect.sh` lokal sebelum eksekusi. Pastikan perilakunya sesuai panduan ini. Kemudian periksa sintaks dan bantuan tanpa mengubah jaringan:

```sh
sh -n access-connect.sh
sh access-connect.sh --help
```

## 4. Jalankan secara interaktif

Ingatkan pengguna tentang penyimpanan kredensial, konfigurasi CA, dan kemungkinan terputusnya koneksi seperti dijelaskan di atas. Profil default bernama `IPB-ACCESS`; profil dengan nama yang sama akan diperbarui. Periksa profil yang sudah ada dengan `nmcli -f NAME,TYPE connection show` sebelum menjalankan skrip. Jika profil lama perlu dipertahankan, gunakan opsi yang sudah tersedia, misalnya `sh access-connect.sh --name IPB-ACCESS-LLM`, lalu gunakan nama itu dalam semua pemeriksaan selanjutnya. Jangan gunakan `--forget` tanpa permintaan eksplisit pengguna.

Jalankan di terminal lokal interaktif yang dapat digunakan langsung oleh pengguna:

```sh
sh access-connect.sh
```

Pengguna mengetik ID-IPB (singkat atau lengkap `username@apps.ipb.ac.id`) dan password pada prompt skrip. Jangan meminta pengguna menempelkan password atau transkrip input ke chat. Jika tool terminal asisten tidak mendukung input rahasia langsung oleh pengguna, serahkan perintah ini kepada pengguna untuk dijalankan sendiri.

Jika pesan kesalahan secara spesifik menyatakan gagal menyimpan profil karena izin, jalankan ulang secara interaktif dengan:

```sh
sudo sh access-connect.sh
```

Jangan menaikkan izin hanya karena autentikasi Wi-Fi gagal. Jika memakai nama profil khusus, sertakan opsi `--name` yang sama saat menjalankan ulang dengan sudo.

## 5. Verifikasi hasil

Contoh berikut memakai nama profil default. Ganti nama jika langkah 4 memakai `--name`:

```sh
nmcli -f NAME,TYPE,DEVICE connection show --active
nmcli -f 802-11-wireless.ssid,ipv4.dhcp-client-id connection show IPB-ACCESS
nmcli -f GENERAL.DEVICE,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show
```

Pastikan profil aktif pada interface Wi-Fi yang dipilih skrip, SSID-nya IPB-ACCESS, alamat IPv4/gateway tersedia, dan DHCP client-id sama dengan MAC yang ditampilkan skrip (tanpa awalan byte `01:` tambahan). Baca alamat gateway **interface tersebut**, lalu jalankan `ping -c 1 -W 2` dengan alamat gateway itu sebagai argumen. Jangan memakai gateway dari interface lain seperti Ethernet atau VPN.

```sh
nmcli networking connectivity check
```

`full` menandakan pemeriksaan internet NetworkManager berhasil, tetapi periksa juga apakah interface lain masih aktif; hasil ini tidak membuktikan jalur Wi-Fi jika Ethernet/VPN ikut terhubung. `unknown` dapat berarti pemeriksaan dinonaktifkan. Ping gateway hanya memeriksa jaringan lokal dan dapat diblokir; jangan menyimpulkan akses internet hanya dari ping atau exit code skrip.

Laporkan terpisah: profil tersimpan, Wi-Fi tersambung, IPv4/gateway tersedia, serta akses internet terverifikasi atau belum. Jangan menyatakan berhasil jika belum ada bukti. Jangan menampilkan password atau menggunakan `nmcli --show-secrets`.

## Jika gagal

| Gejala | Tindakan berikutnya |
| --- | --- |
| `nmcli`/utilitas tidak ditemukan | Kembali ke langkah 1, pasang paket yang hilang. |
| NetworkManager tidak berjalan | Kembali ke langkah 2, periksa layanan dan pengelola jaringan yang digunakan. |
| Tidak ada interface Wi-Fi / SSID tidak terlihat | Periksa perangkat, radio, driver, dan jangkauan; jangan lanjut ke autentikasi. |
| Gagal menyimpan profil karena izin | Gunakan terminal lokal dengan sudo seperti langkah 4. |
| Gagal autentikasi | Minta pengguna memeriksa akun dan mengetik ulang kredensial langsung di terminal. |
| Tersambung tanpa internet | Periksa IPv4, gateway, DNS, dan DHCP client-id pada interface Wi-Fi di langkah 5; rujuk Troubleshooting di README. |

Setelah setiap perbaikan, ulangi langkah yang gagal lalu lanjutkan verifikasi. Akhiri dengan ringkasan hasil dan pemeriksaan yang belum dapat dilakukan; jangan mengklaim sudah menguji Wi-Fi kampus jika tidak berada di jaringan tersebut.
