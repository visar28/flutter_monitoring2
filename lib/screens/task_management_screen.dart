import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/performance_charts.dart';
import 'drawer.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  late TabController _tabController;
  
  UserModel? _currentUser;
  String _selectedDate = '';
  Map<String, dynamic> _technicalTasks = {};
  Map<String, dynamic> _nonTechnicalTasks = {};
  Map<String, Map<String, dynamic>> _weeklyPerformance = {};
  Map<String, Map<String, dynamic>> _monthlyPerformance = {};
  List<String> _availableDates = [];
  
  bool _isLoading = false;
  bool _isLoadingPerformance = false;
  String _selectedFileName = 'Tidak ada file yang dipilih';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user
      _currentUser = await _authService.getCurrentUserData();
      
      if (_currentUser != null) {
        // Set today as default date
        final today = DateTime.now();
        _selectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        // Get available dates based on user role
        _availableDates = _taskService.getAvailableDates(_currentUser!.isAdmin);
        
        // Load tasks for selected date
        await _loadTasksForDate(_selectedDate);
        
        // Load performance data
        await _loadPerformanceData();
      }
    } catch (e) {
      print('Error initializing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTasksForDate(String date) async {
    try {
      final allTasks = await _taskService.getAllTasksForDate(date);
      
      // Filter tasks based on user role
      Map<String, dynamic> filteredTechnicalTasks = {};
      Map<String, dynamic> filteredNonTechnicalTasks = {};
      
      if (_currentUser!.isAdmin) {
        // Admin sees all tasks
        filteredTechnicalTasks = allTasks['technical']!;
        filteredNonTechnicalTasks = allTasks['nontechnical']!;
      } else {
        // Members only see their own tasks
        final username = _currentUser!.username.toLowerCase();
        
        allTasks['technical']!.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final taskPIC = value['pic']?.toString().toLowerCase() ?? '';
            if (taskPIC == username) {
              filteredTechnicalTasks[key] = value;
            }
          }
        });
        
        allTasks['nontechnical']!.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final taskPIC = value['pic']?.toString().toLowerCase() ?? '';
            if (taskPIC == username) {
              filteredNonTechnicalTasks[key] = value;
            }
          }
        });
      }
      
      setState(() {
        _technicalTasks = filteredTechnicalTasks;
        _nonTechnicalTasks = filteredNonTechnicalTasks;
      });
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoadingPerformance = true);
    
    try {
      final weeklyData = await _taskService.getWeeklyPerformance();
      final monthlyData = await _taskService.getMonthlyPerformance();
      
      setState(() {
        _weeklyPerformance = weeklyData;
        _monthlyPerformance = monthlyData;
      });
    } catch (e) {
      print('Error loading performance data: $e');
    } finally {
      setState(() => _isLoadingPerformance = false);
    }
  }

  Future<void> _generateDummyData() async {
    if (!_currentUser!.isAdmin) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _taskService.generateDummyData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dummy data berhasil dibuat untuk 2 bulan terakhir'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload data
      await _loadTasksForDate(_selectedDate);
      await _loadPerformanceData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating dummy data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickExcelFile(bool isTechnical) async {
    if (!_currentUser!.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hanya Admin yang dapat mengimport file Excel'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes != null) {
          await _readExcelFile(file.bytes!, isTechnical);
          setState(() {
            _selectedFileName = file.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File Excel ${isTechnical ? 'Technical' : 'Non-Technical'} berhasil dimuat: ${file.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membaca file Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _readExcelFile(Uint8List bytes, bool isTechnical) async {
    try {
      final excel = ex.Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        throw Exception('File Excel kosong atau tidak valid');
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Sheet Excel kosong');
      }

      // Convert Excel rows to List<List<dynamic>>
      List<List<dynamic>> excelRows = [];
      for (var row in sheet.rows) {
        List<dynamic> rowData = [];
        for (var cell in row) {
          rowData.add(cell?.value);
        }
        excelRows.add(rowData);
      }

      // Process Excel data for selected date
      if (isTechnical) {
        await _taskService.processTechnicalExcelData(excelRows, _selectedDate);
      } else {
        await _taskService.processNonTechnicalExcelData(excelRows, _selectedDate);
      }
      
      // Reload tasks and performance data
      await _loadTasksForDate(_selectedDate);
      await _loadPerformanceData();

    } catch (e) {
      print('Error reading Excel file: $e');
      throw Exception('Error reading Excel file: $e');
    }
  }

  Future<void> _addNewTask(bool isTechnical) async {
    if (!_currentUser!.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hanya Admin yang dapat menambahkan task'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_taskService.canEditTasksForDate(_selectedDate, _currentUser!.isAdmin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task hanya dapat ditambahkan pada tanggal hari ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddTaskDialog(isTechnical: isTechnical),
    );

    if (result != null) {
      try {
        final taskData = {
          'wo': result['wo']!,
          'desc': result['desc']!,
          'typeWO': result['typeWO']!,
          'pic': result['pic']!,
          'status': 'InProgress',
          'category': result['category']!,
          'photo': false,
          'photoData': null,
          'assignedTo': result['pic']!,
          'createdAt': DateTime.now().toIso8601String(),
        };

        if (isTechnical) {
          await _taskService.addTechnicalTask(_selectedDate, taskData);
        } else {
          await _taskService.addNonTechnicalTask(_selectedDate, taskData);
        }
        
        await _loadTasksForDate(_selectedDate);
        await _loadPerformanceData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isTechnical ? 'Technical' : 'Non-Technical'} task berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(String taskKey, String newStatus, bool isTechnical) async {
    try {
      await _taskService.updateTaskStatus(
        _selectedDate, 
        taskKey, 
        newStatus, 
        _currentUser!.username,
        isTechnical
      );
      
      await _loadTasksForDate(_selectedDate);
      await _loadPerformanceData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status task berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPhoto(String taskKey, bool isTechnical) async {
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

        await _taskService.updateTaskPhoto(
          _selectedDate,
          taskKey,
          base64Image,
          _currentUser!.username,
          isTechnical
        );

        await _loadTasksForDate(_selectedDate);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto berhasil diupload!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Task Management - ${_currentUser!.role.toUpperCase()}',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.grey.shade800),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade700,
          tabs: [
            Tab(
              icon: Icon(Icons.engineering),
              text: 'Technical Tasks',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Non-Technical Tasks',
            ),
          ],
        ),
      ),
      endDrawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Selection and Controls
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDateSelector(),
                      
                      if (_currentUser!.isAdmin) ...[
                        SizedBox(height: 16),
                        _buildAdminControls(),
                      ],
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Technical Tasks Tab
                      _buildTaskTab(
                        tasks: _technicalTasks,
                        isTechnical: true,
                        emptyMessage: 'Tidak ada technical task untuk tanggal ini',
                      ),
                      
                      // Non-Technical Tasks Tab
                      _buildTaskTab(
                        tasks: _nonTechnicalTasks,
                        isTechnical: false,
                        emptyMessage: 'Tidak ada non-technical task untuk tanggal ini',
                      ),
                    ],
                  ),
                ),
                
                // Performance Charts (Admin only)
                if (_currentUser!.isAdmin && !_isLoadingPerformance)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Analytics (Gabungan Technical + Non-Technical)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 400,
                          child: PerformanceCharts(
                            weeklyPerformance: _weeklyPerformance,
                            monthlyPerformance: _monthlyPerformance,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Tanggal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDate,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _availableDates.map((date) {
            final dateTime = DateTime.parse(date);
            final isToday = date == DateTime.now().toIso8601String().split('T')[0];
            final canEdit = _taskService.canEditTasksForDate(date, _currentUser!.isAdmin);
            
            return DropdownMenuItem(
              value: date,
              child: Row(
                children: [
                  Text(
                    '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.blue : Colors.black,
                    ),
                  ),
                  if (isToday) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  if (canEdit && !isToday) ...[
                    SizedBox(width: 8),
                    Icon(Icons.edit, size: 16, color: Colors.green),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDate = value;
              });
              _loadTasksForDate(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdminControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Controls',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickExcelFile(true),
                icon: Icon(Icons.file_upload),
                label: Text('Import Technical Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickExcelFile(false),
                icon: Icon(Icons.file_upload),
                label: Text('Import Non-Technical Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generateDummyData,
            icon: Icon(Icons.data_usage),
            label: Text('Generate Dummy Data (2 Bulan)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_selectedFileName != 'Tidak ada file yang dipilih') ...[
          SizedBox(height: 8),
          Text(
            'File: $_selectedFileName',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskTab({
    required Map<String, dynamic> tasks,
    required bool isTechnical,
    required String emptyMessage,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadTasksForDate(_selectedDate);
        await _loadPerformanceData();
      },
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Add Task Button (Admin only, today only)
          if (_currentUser!.isAdmin && _taskService.canEditTasksForDate(_selectedDate, _currentUser!.isAdmin))
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => _addNewTask(isTechnical),
                icon: Icon(Icons.add),
                label: Text('Tambah ${isTechnical ? 'Technical' : 'Non-Technical'} Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTechnical ? Colors.blue.shade600 : Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          // Tasks Table
          _buildTasksTable(tasks, isTechnical, emptyMessage),
        ],
      ),
    );
  }

  Widget _buildTasksTable(Map<String, dynamic> tasks, bool isTechnical, String emptyMessage) {
    if (tasks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                isTechnical ? Icons.engineering : Icons.admin_panel_settings, 
                size: 64, 
                color: Colors.grey.shade400
              ),
              SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final taskEntries = tasks.entries.toList();
    final canEdit = _taskService.canEditTasksForDate(_selectedDate, _currentUser!.isAdmin);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isTechnical ? Colors.blue.shade50 : Colors.purple.shade50
          ),
          headingTextStyle: TextStyle(
            color: isTechnical ? Colors.blue.shade800 : Colors.purple.shade800,
            fontWeight: FontWeight.bold,
          ),
          columns: [
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Work Order')),
            DataColumn(label: Text('Deskripsi')),
            DataColumn(label: Text('Type WO')),
            DataColumn(label: Text('PIC')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Foto')),
            if (canEdit && !_currentUser!.isAdmin) DataColumn(label: Text('Aksi')),
          ],
          rows: taskEntries.map((entry) {
            final taskKey = entry.key;
            final task = entry.value as Map<String, dynamic>;
            final isMyTask = task['pic']?.toString().toLowerCase() == _currentUser!.username.toLowerCase();

            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (isMyTask && !_currentUser!.isAdmin) {
                  return isTechnical ? Colors.blue.shade50 : Colors.purple.shade50;
                }
                return null;
              }),
              cells: [
                DataCell(Text('${task['no']}')),
                DataCell(Text(task['wo'] ?? '')),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      task['desc'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(task['typeWO'] ?? '')),
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMyTask 
                          ? (isTechnical ? Colors.blue.shade100 : Colors.purple.shade100)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task['pic'] ?? '',
                      style: TextStyle(
                        color: isMyTask 
                            ? (isTechnical ? Colors.blue.shade700 : Colors.purple.shade700)
                            : Colors.grey.shade700,
                        fontWeight: isMyTask ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task['status'] ?? 'InProgress',
                      style: TextStyle(
                        color: _getStatusColor(task['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task['photo'] == true ? Icons.check_circle : Icons.cancel,
                        color: task['photo'] == true ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      if (canEdit && isMyTask && !_currentUser!.isAdmin) ...[
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.camera_alt, size: 16),
                          onPressed: () => _uploadPhoto(taskKey, isTechnical),
                          tooltip: 'Upload Foto',
                        ),
                      ],
                    ],
                  ),
                ),
                if (canEdit && !_currentUser!.isAdmin)
                  DataCell(
                    isMyTask
                        ? DropdownButton<String>(
                            value: task['status'],
                            hint: Text('Status'),
                            items: [
                              'InProgress',
                              'Close',
                              'Reschedule',
                              'WMatt',
                              'WShutt',
                            ].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                _updateTaskStatus(taskKey, newStatus, isTechnical);
                              }
                            },
                          )
                        : SizedBox.shrink(),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Close':
        return Colors.green;
      case 'InProgress':
        return Colors.orange;
      case 'Reschedule':
        return Colors.red;
      case 'WMatt':
        return Colors.amber.shade700;
      case 'WShutt':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _AddTaskDialog extends StatefulWidget {
  final bool isTechnical;

  const _AddTaskDialog({required this.isTechnical});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _woController = TextEditingController();
  final _descController = TextEditingController();
  final _picController = TextEditingController();
  
  String _selectedTypeWO = 'PM';
  String _selectedCategory = 'Common';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah ${widget.isTechnical ? 'Technical' : 'Non-Technical'} Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _woController,
              decoration: InputDecoration(
                labelText: 'Work Order',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Work Order wajib diisi';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi wajib diisi';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            if (widget.isTechnical)
              DropdownButtonFormField<String>(
                value: _selectedTypeWO,
                decoration: InputDecoration(
                  labelText: 'Type WO',
                  border: OutlineInputBorder(),
                ),
                items: ['PM', 'CM', 'PAM'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypeWO = value!;
                  });
                },
              )
            else
              TextFormField(
                initialValue: 'Administrative',
                decoration: InputDecoration(
                  labelText: 'Type WO',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
            SizedBox(height: 12),
            TextFormField(
              controller: _picController,
              decoration: InputDecoration(
                labelText: 'PIC',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'PIC wajib diisi';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            if (widget.isTechnical)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Common', 'Boiler', 'Turbin'].map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              )
            else
              TextFormField(
                initialValue: 'Administrative',
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'wo': _woController.text,
                'desc': _descController.text,
                'typeWO': widget.isTechnical ? _selectedTypeWO : 'Administrative',
                'pic': _picController.text,
                'category': widget.isTechnical ? _selectedCategory : 'Administrative',
              });
            }
          },
          child: Text('Tambah'),
        ),
      ],
    );
  }
}