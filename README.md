<div align="center">

<img src="https://ict.ipb.ac.id/wp-content/uploads/2020/12/Logo-ICT.png" alt="ICT IPB" height="52">

# Access Connect

Skrip untuk menyambung ke Wi-Fi **IPB-ACCESS** di GNU/Linux lewat NetworkManager (`nmcli`), lengkap dengan pembuatan profil 802.1X yang persisten. Skrip ini dibuat karena ICT IPB **tidak melihat Linux sebagai OS umum** yang biasa dipakai mahasiswa, sehingga tidak menyediakan layanan terbaik untuk connect ke wifi `ipb-access` melalui GNU/Linux.

</div>

## Fitur

- Membuat/memperbarui profil NetworkManager untuk `IPB-ACCESS` (persisten, autoconnect).
- Konfigurasi WPA-Enterprise otomatis: EAP `PEAP` dengan Phase 2 `GTC`.
- Menerima `ID-IPB` singkat (mis. `username`) maupun lengkap (`username@apps.ipb.ac.id`).
- `dhcp-client-id` diset ke MAC address interface Wi-Fi.
- Verifikasi koneksi setelah tersambung (alamat IPv4 dan ping ke gateway).
- Mode hapus profil (`--forget`) dan mode hanya-buat-profil (`--no-connect`).

## Prasyarat

- GNU/Linux dengan NetworkManager (perintah `nmcli`).
- Interface Wi-Fi aktif.
- Akun `ID-IPB` yang valid.

## Instalasi

```sh
git clone git@github.com:IPBOS/access-connect.git
cd access-connect
chmod +x access-connect.sh
```

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
- **Ingin memulai dari nol** — hapus profil lalu buat ulang:

  ```sh
  ./access-connect.sh --forget
  ./access-connect.sh
  ```

## Lisensi

Didistribusikan di bawah lisensi [MIT](LICENSE).
