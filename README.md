# Aplikasi Absensi Karyawan Offline-First

Aplikasi absensi karyawan berbasis Flutter yang dirancang untuk beroperasi secara mandiri dan offline menggunakan penyimpanan lokal Hive. Aplikasi ini dilengkapi dengan proteksi keamanan tingkat tinggi untuk mencegah kecurangan absensi serta mendukung berbagai tingkatan peran (role) pengguna.

## Fitur Utama

### 1. Keamanan dan Anti-Kecurangan (Anti-Fraud)
* Deteksi Perangkat Root: Sistem menolak proses absensi apabila mendeteksi perangkat dalam keadaan root.
* Deteksi Lokasi Palsu (Mock GPS): Memastikan koordinat lokasi yang digunakan adalah koordinat asli dari satelit GPS, bukan dari aplikasi simulasi lokasi.
* Haversine Geofencing: Membatasi area absensi hanya di dalam radius lokasi kerja (site) yang telah ditentukan.
* Verifikasi Biometrik: Mewajibkan autentikasi sidik jari atau wajah sebelum menyimpan absensi.
* Proteksi Manipulasi Waktu: Sistem akan menolak absensi jika jam perangkat dimundurkan melewati catatan transaksi terakhir di database.

### 2. Logika Kerja
* Shift Malam Lintas Hari (Overnight Shift): Mendukung pencarian data absen masuk aktif dalam rentang waktu 18 jam terakhir, sehingga karyawan shift malam dapat melakukan absen keluar keesokan harinya tanpa terblokir sistem.
* Batas Toleransi Keterlambatan: Otomatis menghitung status terlambat jika melewati toleransi waktu shift yang telah ditetapkan.

### 3. Pengajuan Cuti, Sakit, dan Izin
* Pengelompokan jenis permohonan ke dalam Cuti, Sakit, dan Izin.
* Unggah berkas dokumen pendukung untuk permohonan sakit atau izin.
* Alur Persetujuan Fleksibel (Override Flow): Memungkinkan tingkatan yang lebih tinggi (Supervisor atau Manajer) untuk langsung menyetujui permohonan berstatus pending tanpa harus menunggu persetujuan dari tingkatan di bawahnya jika berhalangan.

### 4. Pembagian Peran Pengguna (Role-Based Access Control)
* Karyawan: Melakukan absen masuk/keluar, mengajukan izin/cuti, dan melihat riwayat pribadi.
* Leader: Memiliki kemampuan Karyawan ditambah persetujuan cuti tingkat 1 dan memantau kehadiran tim.
* Supervisor: Memiliki kemampuan Leader ditambah persetujuan cuti tingkat 2, manajemen data master shift, dan plotting jadwal kerja karyawan.
* Manajer: Memiliki kemampuan Karyawan ditambah persetujuan cuti tingkat final (menyetujui langsung semua level pending) dan memantau kehadiran tim.
* Superuser: Melakukan manajemen data master karyawan, lokasi kerja (site), master shift, plotting jadwal, melepas tautan perangkat (unbind device ID), serta memproses persetujuan cuti langsung sebagai role tertentu melalui override dialog.

### 5. Menu Pengaturan dan Diagnostik Perangkat
* Menampilkan informasi profil pengguna dan badge peran aktif.
* Menampilkan detail ID perangkat terikat dan fitur salin ID.
* Melakukan pemeriksaan diagnostik keamanan perangkat secara realtime (Status Root, Status Lokasi Palsu, dan Ketersediaan Biometrik).
* Informasi versi aplikasi dan lokalisasi bahasa.

## Teknologi Utama yang Digunakan
* Core Framework: Flutter
* State Management: Flutter BLoC
* Local Database: Hive CE (Offline-First)
* Lokasi & Keamanan: Geolocator, Safe Device, Local Auth
