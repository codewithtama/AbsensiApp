# Prompt: Flutter + Hive Attendance App (Local Offline)

Buat aplikasi absensi Android menggunakan Flutter dan Hive (Local NoSQL Database).
Aturan Mutlak: TIDAK ADA AI. Gunakan Material 3 & Clean Architecture (BLoC).

## 1. Roles & Akses

1. **Karyawan:** Clock-in/out, pengajuan cuti.
2. **Leader:** Approve cuti (Lv 1), pantau kehadiran tim.
3. **Supervisor:** Approve cuti (Lv 2), plot shift, rekap site.
4. **Manager:** View-only makro, Final Approve cuti.
5. **Superuser:** Master data, bypass rules, Device Unbinding.

## 2. Fitur Utama & Anti-Fraud

- **Validasi Absen:** 1. Blokir Root & Mock GPS (`safe_device` / `freerasp`).
  2. Waktu menggunakan `DateTime.now()` (karena full offline).
  3. Geofencing: Jarak lokasi HP ke Site <= Radius (kalkulasi Haversine).
  4. Autentikasi Lokal: Wajib `local_auth` (Fingerprint/FaceID) sebelum simpan data.

## 3. Skema Hive (Local Storage)

Buat Hive Adapters (`@HiveType` & `@HiveField`) untuk model berikut:

- `Box<User>`: {id, name, email, role, device_id}
- `Box<Site>`: {id, name, lat, long, radius}
- `Box<Shift>`: {id, name, in_time, out_time}
- `Box<Attendance>`: {id, user_id, site_id, status(in/out), timestamp, lat, long}
- `Box<Leave>`: {id, user_id, start, end, status, doc_path}

Berdasarkan spek ini, generate struktur folder Clean Architecture, setup inisialisasi Hive (beserta build_runner), dan logic BLoC untuk alur Clock-In/Out.
