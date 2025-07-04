# APK Monitoring - PLTU Pacitan

Aplikasi monitoring work order untuk PLTU Pacitan yang dibangun dengan Flutter dan Firebase.

## 🚀 Fitur Utama

### 📋 Work Order Management
- **Tactical Work Order**: Manajemen PM, CM dengan kategori Common, Boiler, Turbin
- **Non-Tactical Work Order**: Manajemen PAM dengan kategori yang sama
- **Status Tracking**: Close, WShutt, WMatt, InProgress, Reschedule
- **Photo Upload**: Wajib upload foto untuk status Close
- **Excel Import/Export**: Import data dari Excel dan export hasil

### 📦 Inventory Management
- **Pengambilan Barang**: Tracking barang yang diambil
- **Permintaan Barang**: Manajemen permintaan barang
- **Excel Integration**: Import/export data inventory

### 👥 User Management (Admin/Supervisor)
- **Role-based Access**: Admin, Supervisor, Karyawan
- **Performance Monitoring**: Tracking kinerja karyawan berdasarkan user yang close task
- **User Creation**: Buat akun karyawan baru
- **Password Reset**: Reset password via email

### 📊 Analytics & Reports
- **Performance Dashboard**: Pie charts dan bar charts
- **Historical Data**: Tracking data historis
- **Ranking System**: Peringkat kinerja karyawan berdasarkan task yang di-close
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
- Full access ke semua fitur
- Manajemen user (create, delete, reset password)
- Monitoring kinerja semua karyawan
- **TIDAK muncul** dalam tabel monitoring kinerja

### 🟡 Supervisor
- Monitoring kinerja karyawan
- Manajemen user terbatas
- Access ke work order dan inventory
- **Kinerja dimonitor** berdasarkan task yang di-close

### 🟢 Karyawan
- Manajemen work order (tactical & non-tactical)
- Inventory management (pengambilan & permintaan)
- **Kinerja dimonitor** berdasarkan task yang di-close
- Update profile sendiri

## 📊 Performance Metrics Logic

### ✅ **Alur Kinerja yang Benar:**
1. **Member Login** → Sistem catat userId
2. **Member Close Task** → userId tercatat di task tersebut
3. **Kinerja Dihitung** → Berdasarkan task yang di-close oleh userId tersebut
4. **Admin Monitoring** → Melihat kinerja semua anggota (kecuali admin)

### Calculation Formula:
```
Kinerja (%) = (Total Completed Tasks / Total Tasks) × 100

Where:
- Completed Tasks = Tasks with status "Close" by specific userId
- Total Tasks = All tasks assigned to specific userId
- PIC field = Hanya nama, tidak mempengaruhi kinerja
- userId = Yang menentukan siapa yang menyelesaikan task
```

### Ranking System:
- **🥇 Rank 1**: Highest performance percentage
- **🥈 Rank 2-3**: Top performers
- **📊 Others**: Ranked by performance descending
- **Admin tidak muncul** dalam ranking

## 🔧 Troubleshooting

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
   - Pastikan user sudah login
   - Check userId tersimpan di task
   - Verify Firebase rules
   - Check console logs untuk debug

## 📝 Data Structure

### Work Order dengan userId:
```dart
{
  'wo': 'WO-001',
  'desc': 'Description',
  'typeWO': 'PM/CM/PAM',
  'pic': 'Person in Charge', // Hanya nama, tidak mempengaruhi kinerja
  'status': 'Close/WShutt/WMatt/InProgress/Reschedule',
  'category': 'Common/Boiler/Turbin',
  'jenis_wo': 'Tactical/Non Tactical',
  'photo': true/false,
  'photoData': 'base64_string',
  'timestamp': 'ISO_date_string',
  'userId': 'firebase_user_id', // PENTING: Menentukan siapa yang close task
  'no': 1
}
```

### User Performance:
```dart
{
  'userId': 'firebase_user_id',
  'totalTasks': 10,
  'completedTasks': 8,
  'percentage': 80.0,
  'incompleteTasks': [...]
}
```

## 🚀 Build & Deployment

### Android APK:
```bash
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

---

**© 2025 PLTU Pacitan - APK Monitoring System**

**Updated for JDK 17 & Correct Performance Logic**