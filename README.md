# APK Monitoring - PLTU Pacitan

Aplikasi monitoring work order untuk PLTU Pacitan yang dibangun dengan Flutter dan Firebase.

## 🚀 Fitur Utama

### 📋 Work Order Management (PIC-Based System)
- **Admin**: Import Excel, input data task, melihat semua task, tidak bisa edit status
- **Member**: Hanya melihat task dengan PIC = username mereka, bisa close task
- **Performance Tracking**: Berdasarkan PIC (kolom PIC = username member)
- **Status Tracking**: Close, WShutt, WMatt, InProgress, Reschedule
- **Photo Upload**: Wajib upload foto untuk status Close
- **Date Filtering**: Filter per hari, bulan, tahun

### 📊 Role-Based Access Control

#### 🔴 **Admin**
- ✅ Import Excel task harian
- ✅ Input data task manual
- ✅ Melihat semua task
- ✅ Melihat halaman Manajemen Anggota (read-only)
- ❌ Tidak bisa mengubah status task
- ❌ Tidak bisa upload foto
- ❌ Tidak muncul dalam ranking kinerja

#### 🟢 **Member/Karyawan**
- ✅ Melihat task dengan PIC = username mereka
- ✅ Mengubah status task mereka
- ✅ Upload foto untuk task mereka
- ✅ Kinerja dimonitor berdasarkan task yang di-close
- ❌ Tidak bisa melihat task orang lain
- ❌ Tidak bisa import Excel

### 📈 Performance Logic (PIC-Based)
```
Kinerja (%) = (Task Close dengan PIC = username) / (Total Task dengan PIC = username) × 100

Contoh:
- Didian memiliki 10 task (PIC = "Didian")
- Didian sudah close 3 task
- Kinerja Didian = 3/10 × 100 = 30%
```

### 📦 Inventory Management
- **Pengambilan Barang**: Tracking barang yang diambil
- **Permintaan Barang**: Manajemen permintaan barang
- **Excel Integration**: Import/export data inventory

### 👥 User Management
- **Role-based Access**: Admin, Supervisor, Karyawan
- **Performance Monitoring**: Ranking berdasarkan PIC
- **User Creation**: Buat akun karyawan baru (Admin only)
- **Password Reset**: Reset password via email (Admin only)

### 📊 Analytics & Reports
- **Performance Dashboard**: Pie charts dan bar charts
- **Historical Data**: Tracking data historis
- **Ranking System**: Peringkat kinerja berdasarkan PIC
- **Date Filtering**: Filter per hari, bulan, tahun
- **Real-time Sync**: Sinkronisasi real-time dengan Firebase

## 🛠️ Teknologi

- **Frontend**: Flutter 3.7+
- **Backend**: Firebase (Auth, Firestore)
- **State Management**: Provider pattern
- **Charts**: FL Chart
- **File Management**: Excel, File Picker
- **Image**: Image Picker dengan compression

## 📱 Setup & Running

### 1. Prerequisites
```bash
# Install Flutter SDK 3.7+
# Install Android Studio
# Install JDK 17
# Install VS Code (optional)
```

### 2. Clone & Setup
```bash
git clone <repository-url>
cd apkmonitoring
flutter clean
flutter pub get
```

### 3. Firebase Configuration
1. Buat project Firebase baru
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Download `google-services.json` untuk Android
5. Download `GoogleService-Info.plist` untuk iOS
6. Update `firebase_options.dart`

### 4. Android Setup untuk JDK 17

#### Update Gradle Configuration:
- **Gradle Wrapper**: 8.4
- **Android Gradle Plugin**: 8.3.0
- **Kotlin**: 1.9.10
- **Compile SDK**: 34
- **Target SDK**: 34
- **Min SDK**: 21
- **Java Version**: 17

#### Set JAVA_HOME:
```bash
# Windows
set JAVA_HOME=C:\Java\jdk-17.0.1

# macOS/Linux
export JAVA_HOME=/path/to/jdk-17
```

### 5. Running the Application

#### Web Development:
```bash
flutter run -d web
```

#### Android Development:
```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run -d android

# Run on specific device
flutter run -d <device-id>
```

#### iOS Development:
```bash
flutter run -d ios
```

### 6. Running Android Emulator from VS Code

#### Setup Android Emulator:
1. Open Android Studio
2. Go to **Tools > AVD Manager**
3. Create Virtual Device
4. Choose device (Pixel 7, API 34 recommended)
5. Download system image if needed
6. Start emulator

#### VS Code Setup:
1. Install **Flutter** extension
2. Install **Dart** extension
3. Open Command Palette (`Ctrl+Shift+P`)
4. Type "Flutter: Launch Emulator"
5. Select your emulator
6. Run `F5` or `Ctrl+F5` to start debugging

#### Alternative VS Code Commands:
```bash
# Open terminal in VS Code
flutter devices
flutter run

# For hot reload during development
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
```

## 🏗️ Struktur Project

```
lib/
├── models/           # Data models
│   ├── user_model.dart
│   └── work_order_model.dart
├── services/         # Business logic
│   ├── auth_service.dart
│   └── work_order_service.dart
├── screens/          # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── history_screen.dart
│   └── profilanggota_screen.dart
├── widgets/          # Reusable widgets
│   ├── role_based_widget.dart
│   └── scrollable_data_table.dart
└── main.dart         # Entry point
```

## 👤 User Roles & Performance Logic

### 🔴 Admin
- Import Excel task harian
- Input data task dengan PIC = username member
- Melihat semua task (read-only)
- Melihat halaman Manajemen Anggota (read-only)
- **TIDAK bisa** mengubah status atau upload foto
- **TIDAK muncul** dalam ranking kinerja

### 🟡 Supervisor
- Melihat task dengan PIC = username mereka
- Mengubah status dan upload foto untuk task mereka
- **Kinerja dimonitor** berdasarkan task yang di-close

### 🟢 Karyawan
- Melihat task dengan PIC = username mereka
- Mengubah status dan upload foto untuk task mereka
- **Kinerja dimonitor** berdasarkan task yang di-close

## 📊 Performance Metrics Logic

### ✅ **Alur Kinerja yang Benar:**
1. **Admin Import Excel** → PIC diisi dengan username member
2. **Member Login** → Melihat task dengan PIC = username mereka
3. **Member Close Task** → Kinerja member naik
4. **Admin Monitoring** → Melihat ranking berdasarkan PIC

### Calculation Formula:
```
Kinerja (%) = (Total Completed Tasks dengan PIC = username) / (Total Tasks dengan PIC = username) × 100

Where:
- PIC = Username member (kolom PIC di Excel = username member)
- Completed Tasks = Tasks with status "Close" dengan PIC = username
- Total Tasks = All tasks dengan PIC = username
```

### Ranking System:
- **🥇 Rank 1**: Highest performance percentage
- **🥈 Rank 2-3**: Top performers
- **📊 Others**: Ranked by performance descending
- **Admin tidak muncul** dalam ranking

## 🔧 Build & Deployment

### Android APK:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

### Android Bundle:
```bash
flutter build appbundle --release
```

### Web:
```bash
flutter build web --release
```

### Tahapan Build APK:

#### 1. **Persiapan Environment:**
```bash
# Pastikan JDK 17 terinstall
java -version

# Set JAVA_HOME
export JAVA_HOME=/path/to/jdk-17

# Pastikan Android SDK terinstall
flutter doctor
```

#### 2. **Clean & Get Dependencies:**
```bash
flutter clean
flutter pub get
```

#### 3. **Build APK:**
```bash
# Debug APK (untuk testing)
flutter build apk --debug

# Release APK (untuk production)
flutter build apk --release
```

#### 4. **Lokasi APK:**
```bash
# Debug APK
build/app/outputs/flutter-apk/app-debug.apk

# Release APK
build/app/outputs/flutter-apk/app-release.apk
```

#### 5. **Install APK ke Device:**
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Atau copy file APK ke device dan install manual
```

## 🚀 Troubleshooting

### Common Issues

1. **Gradle Build Failed (JDK 17)**
   ```bash
   # Set JAVA_HOME
   export JAVA_HOME=/path/to/jdk-17
   
   # Clean and rebuild
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter build apk
   ```

2. **Android Emulator Issues**
   ```bash
   # Check available devices
   flutter devices
   
   # Cold boot emulator
   # In Android Studio: AVD Manager > Cold Boot Now
   
   # Restart ADB
   flutter doctor
   adb kill-server
   adb start-server
   ```

3. **Firebase Connection Issues**
   - Check `google-services.json` placement
   - Verify Firebase project configuration
   - Check internet connection
   - Verify API keys in `firebase_options.dart`

4. **Performance Tracking Issues**
   - Pastikan PIC di Excel = username member
   - Check Firebase rules
   - Check console logs untuk debug

## 📝 Data Structure

### Work Order dengan PIC-based tracking:
```dart
{
  'wo': 'WO-001',
  'desc': 'Description',
  'typeWO': 'PM/CM/PAM',
  'pic': 'username_member', // PENTING: Harus sama dengan username
  'status': 'Close/WShutt/WMatt/InProgress/Reschedule',
  'category': 'Common/Boiler/Turbin',
  'jenis_wo': 'Tactical/Non Tactical',
  'photo': true/false,
  'photoData': 'base64_string',
  'timestamp': 'ISO_date_string',
  'assignedTo': 'username_member', // Same as PIC
  'date': 'YYYY-MM-DD',
  'no': 1
}
```

### User Performance:
```dart
{
  'username': 'member_username',
  'totalTasks': 10, // Tasks dengan PIC = username
  'completedTasks': 8, // Tasks Close dengan PIC = username
  'percentage': 80.0,
  'incompleteTasks': [...]
}
```

---

**© 2025 PLTU Pacitan - APK Monitoring System**

**Updated for PIC-Based Performance Logic & JDK 17**