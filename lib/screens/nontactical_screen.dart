import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class NonTacticalWOPage extends StatefulWidget {
  const NonTacticalWOPage({super.key});

  @override
  _NonTacticalWOPageState createState() => _NonTacticalWOPageState();
}

class _NonTacticalWOPageState extends State<NonTacticalWOPage> {
  Map<String, List<Map<String, dynamic>>> categorizedWorkOrders = {
    'Common': [],
    'Boiler': [],
    'Turbin': [],
  };

  Map<String, int> statusCount = {
    'Close': 0,
    'WShutt': 0,
    'WMatt': 0,
    'Inprogress': 0,
    'Reschedule': 0,
  };

  String selectedFileName = 'Tidak ada file yang dipilih';
  bool isLoadingFile = false;
  bool isSyncingFirebase = false;
  final ImagePicker _picker = ImagePicker();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  String? _currentUserId;
  UserModel? _currentUser;

  // Date filtering
  DateTime selectedDate = DateTime.now();
  String selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
  String selectedYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadSavedData();
    _initializeEmptyRows();
    _loadFromFirebase();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUser = await _authService.getCurrentUserData();
      print('Current User: ${_currentUser?.username} (${_currentUser?.role})');
    }
    setState(() {});
  }

  void _initializeEmptyRows() {
    // Only initialize if user is admin
    if (_currentUser?.isAdmin == true) {
      categorizedWorkOrders.forEach((key, value) {
        if (value.isEmpty) {
          value.add({
            'no': 1,
            'wo': '',
            'desc': '',
            'typeWO': '',
            'pic': '',
            'status': null,
            'photo': false,
            'photoPath': null,
            'photoData': null,
            'timestamp': DateTime.now().toIso8601String(),
            'assignedTo': '',
            'jenis_wo': 'Non Tactical',
            'date': DateTime.now().toIso8601String().split('T')[0],
          });
        }
      });
    }
  }

  // Load data from Firebase with filtering
  Future<void> _loadFromFirebase() async {
    if (_currentUserId == null || _currentUser == null) return;

    setState(() {
      isSyncingFirebase = true;
    });

    try {
      final nontacticalSnapshot =
          await _firestore
              .collection('nontactical_work_order')
              .doc('nontactical')
              .get();

      if (nontacticalSnapshot.exists) {
        final data = nontacticalSnapshot.data() as Map<String, dynamic>;

        Map<String, List<Map<String, dynamic>>> firebaseData = {
          'Common': [],
          'Boiler': [],
          'Turbin': [],
        };

        // Process each work order from Firebase
        data.forEach((key, value) {
          if (value is Map<String, dynamic> && value['category'] != null) {
            final category = value['category'] as String;
            
            // Filter based on user role
            bool shouldInclude = false;
            
            if (_currentUser!.isAdmin) {
              // Admin sees all tasks
              shouldInclude = true;
            } else {
              // Member only sees tasks assigned to them (PIC = username)
              final picName = value['pic']?.toString().toLowerCase() ?? '';
              final username = _currentUser!.username.toLowerCase();
              shouldInclude = picName == username;
            }

            // Date filtering
            final taskDate = value['date']?.toString() ?? '';
            if (taskDate.isNotEmpty) {
              final taskDateTime = DateTime.tryParse(taskDate);
              if (taskDateTime != null) {
                final taskMonth = taskDateTime.month.toString().padLeft(2, '0');
                final taskYear = taskDateTime.year.toString();
                
                if (taskMonth != selectedMonth || taskYear != selectedYear) {
                  shouldInclude = false;
                }
              }
            }

            if (shouldInclude && firebaseData.containsKey(category)) {
              firebaseData[category]!.add(Map<String, dynamic>.from(value));
            }
          }
        });

        // Sort by 'no' field
        firebaseData.forEach((category, workOrders) {
          workOrders.sort((a, b) => (a['no'] ?? 0).compareTo(b['no'] ?? 0));
        });

        setState(() {
          categorizedWorkOrders = firebaseData;
        });

        _initializeEmptyRows();
        _recalculateStatusCount();
      }
    } catch (e) {
      print('Error loading from Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading from Firebase: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        isSyncingFirebase = false;
      });
    }
  }

  // Save to Firebase
  Future<void> _saveToFirebase() async {
    if (_currentUserId == null || !(_currentUser?.isAdmin == true)) return;

    setState(() {
      isSyncingFirebase = true;
    });

    try {
      Map<String, dynamic> nontacticalData = {};
      int counter = 0;

      categorizedWorkOrders.forEach((category, workOrders) {
        for (var wo in workOrders) {
          if (wo['wo'].toString().trim().isNotEmpty) {
            counter++;
            nontacticalData['wo_$counter'] = {
              'category': category,
              'no': wo['no'],
              'wo': wo['wo'],
              'desc': wo['desc'],
              'pic': wo['pic'],
              'status': wo['status'],
              'photo': wo['photo'],
              'photoPath': wo['photoPath'],
              'photoData': wo['photoData'],
              'timestamp': wo['timestamp'],
              'assignedTo': wo['pic'], // PIC = assignedTo
              'jenis_wo': 'Non Tactical',
              'date': wo['date'] ?? DateTime.now().toIso8601String().split('T')[0],
            };
          }
        }
      });

      await _firestore
          .collection('nontactical_work_order')
          .doc('nontactical')
          .set(nontacticalData);

      await _saveCompletedToHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil disinkronisasi ke Firebase'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving to Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving to Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSyncingFirebase = false;
      });
    }
  }

  // Save completed work orders to history
  Future<void> _saveCompletedToHistory() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();

      categorizedWorkOrders.forEach((category, workOrders) {
        for (var wo in workOrders) {
          if (wo['status'] == 'Close' && wo['wo'].toString().isNotEmpty) {
            final historyRef = _firestore
                .collection('work_order_history')
                .doc('wo_${wo['wo']}_${wo['timestamp']}');

            batch.set(historyRef, {
              'tanggal': wo['timestamp'],
              'wo': wo['wo'],
              'desc': wo['desc'],
              'typeWO': wo['typeWO'],
              'status': wo['status'],
              'jenis_wo': 'Non Tactical',
              'pic': wo['pic'],
              'assignedTo': wo['pic'], // PIC = assignedTo
              'category': category,
              'photoData': wo['photoData'],
              'date': wo['date'] ?? DateTime.now().toIso8601String().split('T')[0],
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      await batch.commit();
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  // Load data yang tersimpan dari SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('nontactical_work_order');

      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);
        setState(() {
          categorizedWorkOrders = decodedData.map(
            (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(
                value.map((item) => Map<String, dynamic>.from(item)),
              ),
            ),
          );
        });
        _recalculateStatusCount();
      }
    } catch (e) {
      print('Error loading saved data: $e');
      _initializeEmptyRows();
    }
  }

  // Recalculate status count from existing data
  void _recalculateStatusCount() {
    Map<String, int> newStatusCount = {
      'Close': 0,
      'WShutt': 0,
      'WMatt': 0,
      'Inprogress': 0,
      'Reschedule': 0,
    };

    categorizedWorkOrders.forEach((category, workOrders) {
      for (var wo in workOrders) {
        if (wo['status'] != null && wo['wo'].toString().isNotEmpty) {
          String status = wo['status'];
          if (newStatusCount.containsKey(status)) {
            newStatusCount[status] = newStatusCount[status]! + 1;
          }
        }
      }
    });

    setState(() {
      statusCount = newStatusCount;
    });
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'nontactical_work_orders',
        json.encode(categorizedWorkOrders),
      );

      await _saveToHistory();
      await _saveToFirebase();
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _saveToHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> historyList =
          prefs.getStringList('work_order_history') ?? [];

      categorizedWorkOrders.forEach((category, workOrders) {
        for (var wo in workOrders) {
          if (wo['status'] == 'Close' && wo['wo'].toString().isNotEmpty) {
            final historyItem = {
              'category': category,
              'workOrder': wo['wo'],
              'description': wo['desc'],
              'typeWO': wo['typeWO'],
              'pic': wo['pic'],
              'status': wo['status'],
              'hasPhoto': wo['photo'],
              'photoData': wo['photoData'],
              'timestamp': wo['timestamp'] ?? DateTime.now().toIso8601String(),
              'type': 'Non Tactical',
              'date': wo['date'] ?? DateTime.now().toIso8601String().split('T')[0],
              'assignedTo': wo['pic'],
            };

            bool exists = false;
            for (int i = 0; i < historyList.length; i++) {
              try {
                final decoded = json.decode(historyList[i]);
                if (decoded['workOrder'] == wo['wo'] &&
                    decoded['type'] == 'Non Tactical') {
                  historyList[i] = json.encode(historyItem);
                  exists = true;
                  break;
                }
              } catch (e) {
                print('Error decoding history item: $e');
              }
            }

            if (!exists) {
              historyList.add(json.encode(historyItem));
            }
          }
        }
      });

      await prefs.setStringList('work_order_history', historyList);
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  Widget _buildPieChart() {
    final colors = {
      'Close': Colors.green,
      'WShutt': Colors.orange,
      'WMatt': Colors.yellow,
      'Inprogress': Colors.blue,
      'Reschedule': Colors.red,
    };

    final validEntries =
        statusCount.entries.where((entry) => entry.value > 0).toList();

    if (validEntries.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data status',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections:
            validEntries.map((entry) {
              final double value = entry.value.toDouble();
              return PieChartSectionData(
                color: colors[entry.key] ?? Colors.grey,
                value: value,
                title: '${entry.key}\n(${entry.value})',
                radius: 60,
                titleStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Future<void> _pickFile() async {
    // Only admin can import files
    if (!(_currentUser?.isAdmin == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hanya Admin yang dapat mengimport file Excel'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoadingFile = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes != null) {
          await _readExcelFile(file.bytes!);
          setState(() {
            selectedFileName = file.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File Excel berhasil dimuat: ${file.name}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('File bytes is null');
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membaca file Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingFile = false;
      });
    }
  }

  Future<void> _readExcelFile(Uint8List bytes) async {
    try {
      final excel = ex.Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('File Excel kosong atau tidak valid');
      }

      setState(() {
        categorizedWorkOrders = {'Common': [], 'Boiler': [], 'Turbin': []};
        statusCount = {
          'Close': 0,
          'WShutt': 0,
          'WMatt': 0,
          'Inprogress': 0,
          'Reschedule': 0,
        };
      });

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Sheet Excel kosong');
      }

      print('Reading Excel file with ${sheet.maxRows} rows');

      String currentCategory = '';
      Map<String, int> categoryCounters = {
        'Common': 1,
        'Boiler': 1,
        'Turbin': 1,
      };

      for (int i = 0; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];

        if (row.isEmpty) continue;

        String rowText = '';
        for (int j = 0; j < row.length && j < 100; j++) {
          final cellValue = row[j]?.value?.toString().trim() ?? '';
          if (cellValue.isNotEmpty) {
            rowText += '$cellValue ';
          }
        }
        rowText = rowText.trim().toUpperCase();

        if (rowText.contains('DIVISI COMMON')) {
          currentCategory = 'Common';
          continue;
        } else if (rowText.contains('DIVISI BOILER')) {
          currentCategory = 'Boiler';
          continue;
        } else if (rowText.contains('DIVISI TURBIN')) {
          currentCategory = 'Turbin';
          continue;
        }

        if (currentCategory.isEmpty) continue;

        if (rowText.contains('NO') && rowText.contains('WORK ORDER')) {
          continue;
        }

        String no = '';
        String wo = '';
        String desc = '';
        String typeWO = '';
        String pic = '';
        String status = '';

        // Find Work Order
        int woColumnIndex = -1;
        for (int j = 0; j < row.length && j < 8; j++) {
          final cellValue = row[j]?.value?.toString().trim() ?? '';
          if (cellValue.toUpperCase().startsWith('WO') &&
              cellValue.length > 2) {
            woColumnIndex = j;
            wo = cellValue;
            break;
          }
        }

        if (wo.isEmpty) continue;

        // Get number
        if (woColumnIndex > 0) {
          no = row[woColumnIndex - 1]?.value?.toString().trim() ?? '';
          if (!RegExp(r'^\d+$').hasMatch(no)) {
            no = categoryCounters[currentCategory].toString();
          }
        } else {
          no = categoryCounters[currentCategory].toString();
        }

        // Get description
        if (woColumnIndex >= 0 && woColumnIndex + 1 < row.length) {
          desc = row[woColumnIndex + 1]?.value?.toString().trim() ?? '';
        }

        // Find PAM type and PIC
        for (int j = 0; j < row.length; j++) {
          final cellValue =
              row[j]?.value?.toString().trim().toUpperCase() ?? '';
          if (cellValue == 'PAM') {
            typeWO = cellValue;

            if (j + 1 < row.length) {
              pic = row[j + 1]?.value?.toString().trim() ?? '';
            }

            if (j + 2 < row.length) {
              final statusValue = row[j + 2]?.value?.toString().trim() ?? '';
              if (statusValue.isNotEmpty) {
                switch (statusValue.toLowerCase()) {
                  case 'close':
                    status = 'Close';
                    break;
                  case 'wshut':
                  case 'wshut mill':
                  case 'wshutt':
                    status = 'WShutt';
                    break;
                  case 'wmatt':
                    status = 'WMatt';
                    break;
                  case 'inprogress':
                  case 'in progress':
                    status = 'Inprogress';
                    break;
                  case 'reschedule':
                    status = 'Reschedule';
                    break;
                }
              }
            }
            break;
          }
        }

        // Look for PAM in other formats
        if (typeWO.isEmpty) {
          for (int j = 0; j < row.length; j++) {
            final cellValue =
                row[j]?.value?.toString().trim().toUpperCase() ?? '';
            if (cellValue.contains('PAM')) {
              typeWO = 'PAM';
              break;
            }
          }
        }

        // Find PIC if not found
        if (pic.isEmpty) {
          for (int j = 0; j < row.length; j++) {
            final cellValue = row[j]?.value?.toString().trim() ?? '';
            if (cellValue.isNotEmpty &&
                !cellValue.toUpperCase().startsWith('WO') &&
                ![
                  'PM',
                  'CM',
                  'PAM',
                  'CLOSE',
                  'WSHUT',
                  'WMATT',
                  'INPROGRESS',
                  'RESCHEDULE',
                ].contains(cellValue.toUpperCase()) &&
                !RegExp(r'^\d+$').hasMatch(cellValue) &&
                cellValue.length > 2) {
              pic = cellValue;
              break;
            }
          }
        }

        // Process PAM work orders
        if (wo.isNotEmpty && typeWO == 'PAM') {
          final newEntry = {
            'no': int.tryParse(no) ?? categoryCounters[currentCategory]!,
            'wo': wo,
            'desc': desc.isNotEmpty ? desc : 'Deskripsi tidak tersedia',
            'typeWO': typeWO,
            'pic': pic.isNotEmpty ? pic : 'PIC tidak tersedia',
            'status': status.isNotEmpty ? status : null,
            'photo': false,
            'photoPath': null,
            'photoData': null,
            'timestamp': DateTime.now().toIso8601String(),
            'assignedTo': pic.isNotEmpty ? pic : 'PIC tidak tersedia',
            'jenis_wo': 'Non Tactical',
            'date': DateTime.now().toIso8601String().split('T')[0],
          };

          setState(() {
            categorizedWorkOrders[currentCategory]!.add(newEntry);

            if (status.isNotEmpty && statusCount.containsKey(status)) {
              statusCount[status] = statusCount[status]! + 1;
            }
          });

          categoryCounters[currentCategory] =
              categoryCounters[currentCategory]! + 1;
          print(
            'Added PAM WO: $wo to category: $currentCategory with PIC: $pic',
          );
        }
      }

      // Add empty row for admin
      if (_currentUser?.isAdmin == true) {
        categorizedWorkOrders.forEach((key, value) {
          value.add({
            'no': value.length + 1,
            'wo': '',
            'desc': '',
            'typeWO': '',
            'pic': '',
            'status': null,
            'photo': false,
            'photoPath': null,
            'photoData': null,
            'timestamp': DateTime.now().toIso8601String(),
            'assignedTo': '',
            'jenis_wo': 'Non Tactical',
            'date': DateTime.now().toIso8601String().split('T')[0],
          });
        });
      }

      await _saveData();

      int totalItems = categorizedWorkOrders.values.fold(
        0,
        (sum, list) => sum + list.length - 1,
      );
      print('Excel import completed. Total PAM items: $totalItems');
    } catch (e) {
      print('Error reading Excel file: $e');
      throw Exception('Error reading Excel file: $e');
    }
  }

  void _updateStatus(String kategori, int index, String? newStatus) async {
    final row = categorizedWorkOrders[kategori]![index];
    final oldStatus = row['status'];

    // Admin cannot change status
    if (_currentUser?.isAdmin == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin tidak dapat mengubah status task'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Member can only change status of their own tasks
    final picName = row['pic']?.toString().toLowerCase() ?? '';
    final username = _currentUser?.username.toLowerCase() ?? '';
    
    if (picName != username) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda hanya dapat mengubah status task yang ditugaskan kepada Anda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newStatus == 'Close') {
      if (row['wo'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Work Order tidak boleh kosong untuk status Close'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (row['photo'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload foto terlebih dahulu sebelum memilih status Close',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      if (oldStatus != null && statusCount.containsKey(oldStatus)) {
        statusCount[oldStatus] =
            (statusCount[oldStatus]! - 1).clamp(0, double.infinity).toInt();
      }

      if (newStatus != null && statusCount.containsKey(newStatus)) {
        statusCount[newStatus] = statusCount[newStatus]! + 1;
      }

      row['status'] = newStatus;
      row['timestamp'] = DateTime.now().toIso8601String();
    });

    await _saveData();
  }

  void _uploadPhoto(String kategori, int index) async {
    final row = categorizedWorkOrders[kategori]![index];
    
    // Admin cannot upload photos
    if (_currentUser?.isAdmin == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin tidak dapat mengupload foto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Member can only upload photos for their own tasks
    final picName = row['pic']?.toString().toLowerCase() ?? '';
    final username = _currentUser?.username.toLowerCase() ?? '';
    
    if (picName != username) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda hanya dapat mengupload foto untuk task yang ditugaskan kepada Anda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pilih Sumber Foto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        setState(() {
          categorizedWorkOrders[kategori]![index]['photo'] = true;
          categorizedWorkOrders[kategori]![index]['photoPath'] = image.path;
          categorizedWorkOrders[kategori]![index]['photoData'] = base64Image;
          categorizedWorkOrders[kategori]![index]['timestamp'] =
              DateTime.now().toIso8601String();
        });

        await _saveData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto berhasil diupload!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Lihat',
              onPressed: () => _showPhotoPreview(kategori, index),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhotoPreview(String kategori, int index) {
    final row = categorizedWorkOrders[kategori]![index];
    final String? photoData = row['photoData'];

    if (photoData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada foto untuk ditampilkan')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Foto Work Order: ${row['wo']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Image.memory(
                    base64Decode(photoData),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Tutup'),
                    ),
                    if (!(_currentUser?.isAdmin == true))
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _uploadPhoto(kategori, index);
                        },
                        child: Text('Ganti Foto'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkAndAddNewRow(String kategori) async {
    // Only admin can add new rows
    if (!(_currentUser?.isAdmin == true)) return;

    final list = categorizedWorkOrders[kategori]!;
    if (list.isEmpty) return;

    final last = list.last;

    if (last['wo'].toString().trim().isNotEmpty &&
        last['desc'].toString().trim().isNotEmpty &&
        last['pic'].toString().trim().isNotEmpty) {
      setState(() {
        list.add({
          'no': list.length + 1,
          'wo': '',
          'desc': '',
          'typeWO': '',
          'pic': '',
          'status': null,
          'photo': false,
          'photoPath': null,
          'photoData': null,
          'timestamp': DateTime.now().toIso8601String(),
          'assignedTo': '',
          'jenis_wo': 'Non Tactical',
          'date': DateTime.now().toIso8601String().split('T')[0],
        });
      });
      await _saveData();
    }
  }

  void _updateRowData(
    String kategori,
    int index,
    String field,
    String value,
  ) async {
    // Only admin can edit task data
    if (!(_currentUser?.isAdmin == true)) return;

    setState(() {
      categorizedWorkOrders[kategori]![index][field] = value;
      categorizedWorkOrders[kategori]![index]['timestamp'] =
          DateTime.now().toIso8601String();
      
      // Update assignedTo when PIC is changed
      if (field == 'pic') {
        categorizedWorkOrders[kategori]![index]['assignedTo'] = value;
      }
    });

    _checkAndAddNewRow(kategori);
    await _saveData();
  }

  // Date filter functions
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedMonth = picked.month.toString().padLeft(2, '0');
        selectedYear = picked.year.toString();
      });
      await _loadFromFirebase();
    }
  }

  Widget _buildDateFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text(
                'Filter Tanggal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: Icon(Icons.calendar_today, size: 16),
                  label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadFromFirebase,
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(String kategori) {
    final list = categorizedWorkOrders[kategori]!;

    // Add empty row only for admin
    if (_currentUser?.isAdmin == true && 
        (list.isEmpty || list.last['wo'].toString().trim().isNotEmpty)) {
      list.add({
        'no': list.length + 1,
        'wo': '',
        'desc': '',
        'typeWO': '',
        'pic': '',
        'status': null,
        'photo': false,
        'photoPath': null,
        'photoData': null,
        'timestamp': DateTime.now().toIso8601String(),
        'assignedTo': '',
        'jenis_wo': 'Non Tactical',
        'date': DateTime.now().toIso8601String().split('T')[0],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.work, color: Colors.green.shade700),
              SizedBox(width: 8),
              Text(
                '$kategori (${list.where((item) => item['wo'].toString().trim().isNotEmpty).length} items)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.green.shade100),
            headingTextStyle: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
            dataRowHeight: 60,
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Work Order')),
              DataColumn(label: Text('Deskripsi')),
              DataColumn(label: Text('Tipe WO')),
              DataColumn(label: Text('PIC')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Foto')),
            ],
            rows: List.generate(list.length, (index) {
              final row = list[index];
              final isEmptyRow = row['wo'].toString().trim().isEmpty;
              final isAdminMode = _currentUser?.isAdmin == true;
              final picName = row['pic']?.toString().toLowerCase() ?? '';
              final username = _currentUser?.username.toLowerCase() ?? '';
              final isMyTask = picName == username;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (isEmptyRow) return Colors.grey.shade50;
                  if (!isAdminMode && isMyTask) return Colors.blue.shade50;
                  return null;
                }),
                cells: [
                  DataCell(Text('${row['no']}')),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: isAdminMode ? TextFormField(
                        initialValue: row['wo'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'WO-001',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged:
                            (val) => _updateRowData(kategori, index, 'wo', val),
                      ) : Text(row['wo'].toString()),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: isAdminMode ? TextFormField(
                        initialValue: row['desc'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Deskripsi pekerjaan...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        maxLines: 2,
                        onChanged:
                            (val) =>
                                _updateRowData(kategori, index, 'desc', val),
                      ) : Text(
                        row['desc'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: isAdminMode ? TextFormField(
                        initialValue: row['typeWO'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type WO',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged:
                            (val) =>
                                _updateRowData(kategori, index, 'typeWO', val),
                      ) : Text(row['typeWO'].toString()),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: isAdminMode ? TextFormField(
                        initialValue: row['pic'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'PIC',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged:
                            (val) =>
                                _updateRowData(kategori, index, 'pic', val),
                      ) : Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMyTask ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          row['pic'].toString(),
                          style: TextStyle(
                            color: isMyTask ? Colors.blue.shade700 : Colors.grey.shade700,
                            fontWeight: isMyTask ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: DropdownButton<String?>(
                        value: row['status'],
                        hint: Text(
                          'Pilih Status',
                          style: TextStyle(fontSize: 12),
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Pilih Status'),
                          ),
                          ...[
                            'Close',
                            'WShutt',
                            'WMatt',
                            'Inprogress',
                            'Reschedule',
                          ].map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          ),
                        ],
                        onChanged: (isEmptyRow || isAdminMode || !isMyTask)
                            ? null
                            : (val) => _updateStatus(kategori, index, val),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap:
                                row['photo']
                                    ? () => _showPhotoPreview(kategori, index)
                                    : null,
                            child: Icon(
                              row['photo'] ? Icons.check_circle : Icons.cancel,
                              color: row['photo'] ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              row['photo'] ? Icons.photo : Icons.camera_alt,
                              size: 20,
                              color: row['photo'] ? Colors.green : Colors.grey,
                            ),
                            onPressed: (isEmptyRow || isAdminMode || !isMyTask)
                                ? null
                                : () => _uploadPhoto(kategori, index),
                            tooltip:
                                row['photo']
                                    ? 'Lihat/Ganti Foto'
                                    : 'Upload Foto',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Non Tactical WO - ${_currentUser!.role.toUpperCase()}',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.green.shade700),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.green.shade700),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
        ],
      ),
      endDrawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Date Filter
            _buildDateFilter(),
            SizedBox(height: 16),

            // File Upload Section (Admin Only)
            if (_currentUser!.isAdmin) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Upload File Excel Pekerjaan (Admin Only)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoadingFile ? null : _pickFile,
                      icon:
                          isLoadingFile
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : Icon(Icons.file_upload),
                      label: Text(
                        isLoadingFile ? 'Loading...' : 'Pilih File Excel',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      selectedFileName,
                      style: TextStyle(
                        color:
                            selectedFileName == 'Tidak ada file yang dipilih'
                                ? Colors.grey.shade600
                                : Colors.green.shade700,
                        fontWeight:
                            selectedFileName != 'Tidak ada file yang dipilih'
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],

            // Info for Members
            if (!_currentUser!.isAdmin) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo ${_currentUser!.username}!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Anda hanya dapat melihat dan mengelola task PAM yang ditugaskan kepada Anda',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],

            // Tables
            _buildTable('Common'),
            _buildTable('Boiler'),
            _buildTable('Turbin'),

            // Pie Chart Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Status Work Orders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 300, child: _buildPieChart()),
                  SizedBox(height: 16),
                  // Status Summary
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children:
                        statusCount.entries.map((entry) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                entry.key,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getStatusColor(entry.key),
                              ),
                            ),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(entry.key),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Close':
        return Colors.green;
      case 'WShutt':
        return Colors.orange;
      case 'WMatt':
        return Colors.yellow.shade700;
      case 'Inprogress':
        return Colors.blue;
      case 'Reschedule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}