import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate dummy data for the last 2 months for both Technical and Non-Technical
  Future<void> generateDummyData() async {
    try {
      final now = DateTime.now();
      final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);
      
      // List of PIC names for dummy data
      final List<String> picNames = [
        'Didian', 'Budi', 'Sari', 'Ahmad', 'Rina', 'Joko', 'Maya', 'Andi'
      ];
      
      final List<String> categories = ['Common', 'Boiler', 'Turbin'];
      final List<String> statuses = ['Close', 'InProgress', 'Reschedule', 'WMatt', 'WShutt'];
      final List<String> typeWOs = ['PM', 'CM', 'PAM'];
      
      final random = Random();
      
      // Generate data for each day in the last 2 months
      for (DateTime date = twoMonthsAgo; date.isBefore(now); date = date.add(Duration(days: 1))) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        // Generate Technical Tasks (3-8 tasks per day)
        final technicalTasksPerDay = 3 + random.nextInt(6);
        Map<String, dynamic> technicalTasks = {};
        
        for (int i = 1; i <= technicalTasksPerDay; i++) {
          final pic = picNames[random.nextInt(picNames.length)];
          final category = categories[random.nextInt(categories.length)];
          final status = statuses[random.nextInt(statuses.length)];
          final typeWO = typeWOs[random.nextInt(typeWOs.length)];
          
          // Higher chance of Close status for better performance tracking
          final finalStatus = random.nextDouble() < 0.65 ? 'Close' : status;
          
          technicalTasks['task_$i'] = {
            'no': i,
            'wo': 'TECH-${dateStr.replaceAll('-', '')}-${i.toString().padLeft(3, '0')}',
            'desc': 'Technical Task $typeWO untuk $category - ${_generateTechnicalTaskDescription()}',
            'typeWO': typeWO,
            'pic': pic,
            'status': finalStatus,
            'category': category,
            'jenis_wo': 'Technical',
            'photo': finalStatus == 'Close' ? true : false,
            'photoData': finalStatus == 'Close' ? 'dummy_photo_data' : null,
            'timestamp': date.toIso8601String(),
            'date': dateStr,
            'assignedTo': pic,
            'createdAt': date.toIso8601String(),
          };
        }
        
        // Generate Non-Technical Tasks (2-5 tasks per day)
        final nonTechnicalTasksPerDay = 2 + random.nextInt(4);
        Map<String, dynamic> nonTechnicalTasks = {};
        
        for (int i = 1; i <= nonTechnicalTasksPerDay; i++) {
          final pic = picNames[random.nextInt(picNames.length)];
          final status = statuses[random.nextInt(statuses.length)];
          
          // Higher chance of Close status for better performance tracking
          final finalStatus = random.nextDouble() < 0.70 ? 'Close' : status;
          
          nonTechnicalTasks['task_$i'] = {
            'no': i,
            'wo': 'NONTECH-${dateStr.replaceAll('-', '')}-${i.toString().padLeft(3, '0')}',
            'desc': 'Non-Technical Task - ${_generateNonTechnicalTaskDescription()}',
            'typeWO': 'Administrative',
            'pic': pic,
            'status': finalStatus,
            'category': 'Administrative',
            'jenis_wo': 'Non-Technical',
            'photo': finalStatus == 'Close' ? true : false,
            'photoData': finalStatus == 'Close' ? 'dummy_photo_data' : null,
            'timestamp': date.toIso8601String(),
            'date': dateStr,
            'assignedTo': pic,
            'createdAt': date.toIso8601String(),
          };
        }
        
        // Save to Firestore
        await _firestore
            .collection('technical_tasks')
            .doc(dateStr)
            .set(technicalTasks);
            
        await _firestore
            .collection('nontechnical_tasks')
            .doc(dateStr)
            .set(nonTechnicalTasks);
        
        print('Generated ${technicalTasksPerDay} technical + ${nonTechnicalTasksPerDay} non-technical tasks for ${dateStr}');
      }
      
      print('✅ Dummy data generation completed for last 2 months');
      
    } catch (e) {
      print('❌ Error generating dummy data: $e');
      throw e;
    }
  }
  
  String _generateTechnicalTaskDescription() {
    final descriptions = [
      'Pemeliharaan rutin sistem boiler',
      'Inspeksi peralatan turbin',
      'Perbaikan komponen generator',
      'Kalibrasi instrumen kontrol',
      'Penggantian spare part pompa',
      'Cleaning dan maintenance heat exchanger',
      'Troubleshooting sistem elektrik',
      'Upgrade peralatan monitoring',
      'Overhaul komponen mekanik',
      'Testing sistem proteksi',
    ];
    
    return descriptions[Random().nextInt(descriptions.length)];
  }
  
  String _generateNonTechnicalTaskDescription() {
    final descriptions = [
      'Pembuatan laporan harian',
      'Meeting koordinasi tim',
      'Training safety procedure',
      'Audit dokumentasi',
      'Persiapan material',
      'Koordinasi dengan vendor',
      'Update database sistem',
      'Briefing shift handover',
      'Inventory check',
      'Administrative tasks',
    ];
    
    return descriptions[Random().nextInt(descriptions.length)];
  }
  
  // Get technical tasks for specific date
  Future<Map<String, dynamic>> getTechnicalTasksForDate(String date) async {
    try {
      final doc = await _firestore
          .collection('technical_tasks')
          .doc(date)
          .get();
      
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error getting technical tasks for date $date: $e');
      return {};
    }
  }
  
  // Get non-technical tasks for specific date
  Future<Map<String, dynamic>> getNonTechnicalTasksForDate(String date) async {
    try {
      final doc = await _firestore
          .collection('nontechnical_tasks')
          .doc(date)
          .get();
      
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error getting non-technical tasks for date $date: $e');
      return {};
    }
  }
  
  // Get all tasks (both technical and non-technical) for specific date
  Future<Map<String, Map<String, dynamic>>> getAllTasksForDate(String date) async {
    try {
      final technicalTasks = await getTechnicalTasksForDate(date);
      final nonTechnicalTasks = await getNonTechnicalTasksForDate(date);
      
      return {
        'technical': technicalTasks,
        'nontechnical': nonTechnicalTasks,
      };
    } catch (e) {
      print('Error getting all tasks for date $date: $e');
      return {'technical': {}, 'nontechnical': {}};
    }
  }
  
  // Get tasks for date range (both technical and non-technical)
  Future<Map<String, Map<String, Map<String, dynamic>>>> getTasksForDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      Map<String, Map<String, Map<String, dynamic>>> allTasks = {};
      
      for (DateTime date = startDate; 
           date.isBefore(endDate.add(Duration(days: 1))); 
           date = date.add(Duration(days: 1))) {
        
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final tasks = await getAllTasksForDate(dateStr);
        
        if (tasks['technical']!.isNotEmpty || tasks['nontechnical']!.isNotEmpty) {
          allTasks[dateStr] = tasks;
        }
      }
      
      return allTasks;
    } catch (e) {
      print('Error getting tasks for date range: $e');
      return {};
    }
  }
  
  // Calculate PIC performance for date range (combining technical and non-technical)
  Future<Map<String, Map<String, dynamic>>> calculatePICPerformance(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final allTasks = await getTasksForDateRange(startDate, endDate);
      Map<String, Map<String, dynamic>> picPerformance = {};
      
      // Process all tasks (both technical and non-technical)
      allTasks.forEach((date, dayTasks) {
        // Process technical tasks
        dayTasks['technical']!.forEach((taskKey, taskData) {
          if (taskData is Map<String, dynamic>) {
            _processPICTask(picPerformance, taskData, date, 'Technical');
          }
        });
        
        // Process non-technical tasks
        dayTasks['nontechnical']!.forEach((taskKey, taskData) {
          if (taskData is Map<String, dynamic>) {
            _processPICTask(picPerformance, taskData, date, 'Non-Technical');
          }
        });
      });
      
      // Calculate percentages
      picPerformance.forEach((pic, data) {
        final totalTasks = data['totalTasks'] as int;
        final completedTasks = data['completedTasks'] as int;
        
        if (totalTasks > 0) {
          data['percentage'] = (completedTasks / totalTasks * 100);
        }
      });
      
      return picPerformance;
    } catch (e) {
      print('Error calculating PIC performance: $e');
      return {};
    }
  }
  
  void _processPICTask(
    Map<String, Map<String, dynamic>> picPerformance,
    Map<String, dynamic> taskData,
    String date,
    String taskType
  ) {
    final pic = taskData['pic']?.toString() ?? '';
    final status = taskData['status']?.toString() ?? '';
    
    if (pic.isNotEmpty && pic.toLowerCase() != 'admin') {
      // Initialize PIC data if not exists
      if (!picPerformance.containsKey(pic)) {
        picPerformance[pic] = {
          'totalTasks': 0,
          'completedTasks': 0,
          'percentage': 0.0,
          'incompleteTasks': <Map<String, dynamic>>[],
          'dailyTasks': <String, int>{},
          'dailyCompleted': <String, int>{},
          'technicalTasks': 0,
          'nonTechnicalTasks': 0,
          'technicalCompleted': 0,
          'nonTechnicalCompleted': 0,
        };
      }
      
      // Count total tasks
      picPerformance[pic]!['totalTasks'] = 
          (picPerformance[pic]!['totalTasks'] as int) + 1;
      
      // Count by task type
      if (taskType == 'Technical') {
        picPerformance[pic]!['technicalTasks'] = 
            (picPerformance[pic]!['technicalTasks'] as int) + 1;
      } else {
        picPerformance[pic]!['nonTechnicalTasks'] = 
            (picPerformance[pic]!['nonTechnicalTasks'] as int) + 1;
      }
      
      // Count daily tasks
      final dailyTasks = picPerformance[pic]!['dailyTasks'] as Map<String, int>;
      dailyTasks[date] = (dailyTasks[date] ?? 0) + 1;
      
      // Count completed tasks
      if (status == 'Close') {
        picPerformance[pic]!['completedTasks'] = 
            (picPerformance[pic]!['completedTasks'] as int) + 1;
        
        // Count by task type
        if (taskType == 'Technical') {
          picPerformance[pic]!['technicalCompleted'] = 
              (picPerformance[pic]!['technicalCompleted'] as int) + 1;
        } else {
          picPerformance[pic]!['nonTechnicalCompleted'] = 
              (picPerformance[pic]!['nonTechnicalCompleted'] as int) + 1;
        }
        
        // Count daily completed
        final dailyCompleted = picPerformance[pic]!['dailyCompleted'] as Map<String, int>;
        dailyCompleted[date] = (dailyCompleted[date] ?? 0) + 1;
      } else {
        // Add to incomplete tasks
        final incompleteTasks = picPerformance[pic]!['incompleteTasks'] as List<Map<String, dynamic>>;
        incompleteTasks.add({
          'wo': taskData['wo'],
          'desc': taskData['desc'],
          'status': status,
          'date': date,
          'category': taskData['category'],
          'type': taskType,
        });
      }
    }
  }
  
  // Get weekly performance data
  Future<Map<String, Map<String, dynamic>>> getWeeklyPerformance() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    return await calculatePICPerformance(startOfWeek, endOfWeek);
  }
  
  // Get monthly performance data
  Future<Map<String, Map<String, dynamic>>> getMonthlyPerformance() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return await calculatePICPerformance(startOfMonth, endOfMonth);
  }
  
  // Add new technical task (Admin only)
  Future<void> addTechnicalTask(String date, Map<String, dynamic> taskData) async {
    try {
      final docRef = _firestore.collection('technical_tasks').doc(date);
      final doc = await docRef.get();
      
      Map<String, dynamic> existingTasks = {};
      if (doc.exists) {
        existingTasks = doc.data() ?? {};
      }
      
      // Find next task number
      int nextTaskNumber = 1;
      existingTasks.forEach((key, value) {
        if (key.startsWith('task_')) {
          final taskNum = int.tryParse(key.split('_')[1]) ?? 0;
          if (taskNum >= nextTaskNumber) {
            nextTaskNumber = taskNum + 1;
          }
        }
      });
      
      // Add new task
      existingTasks['task_$nextTaskNumber'] = {
        ...taskData,
        'no': nextTaskNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'date': date,
        'jenis_wo': 'Technical',
      };
      
      await docRef.set(existingTasks);
      print('✅ Technical task added successfully for date: $date');
      
    } catch (e) {
      print('❌ Error adding technical task: $e');
      throw e;
    }
  }
  
  // Add new non-technical task (Admin only)
  Future<void> addNonTechnicalTask(String date, Map<String, dynamic> taskData) async {
    try {
      final docRef = _firestore.collection('nontechnical_tasks').doc(date);
      final doc = await docRef.get();
      
      Map<String, dynamic> existingTasks = {};
      if (doc.exists) {
        existingTasks = doc.data() ?? {};
      }
      
      // Find next task number
      int nextTaskNumber = 1;
      existingTasks.forEach((key, value) {
        if (key.startsWith('task_')) {
          final taskNum = int.tryParse(key.split('_')[1]) ?? 0;
          if (taskNum >= nextTaskNumber) {
            nextTaskNumber = taskNum + 1;
          }
        }
      });
      
      // Add new task
      existingTasks['task_$nextTaskNumber'] = {
        ...taskData,
        'no': nextTaskNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'date': date,
        'jenis_wo': 'Non-Technical',
      };
      
      await docRef.set(existingTasks);
      print('✅ Non-technical task added successfully for date: $date');
      
    } catch (e) {
      print('❌ Error adding non-technical task: $e');
      throw e;
    }
  }
  
  // Update task status (only allowed on task date and by assigned PIC)
  Future<void> updateTaskStatus(
    String date, 
    String taskKey, 
    String newStatus,
    String currentUserPIC,
    bool isTechnical
  ) async {
    try {
      final today = DateTime.now();
      final taskDate = DateTime.parse(date);
      
      // Check if it's the same date
      if (taskDate.year != today.year || 
          taskDate.month != today.month || 
          taskDate.day != today.day) {
        throw Exception('Status task hanya dapat diubah pada tanggal task tersebut');
      }
      
      final collection = isTechnical ? 'technical_tasks' : 'nontechnical_tasks';
      final docRef = _firestore.collection(collection).doc(date);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Task tidak ditemukan');
      }
      
      final tasks = doc.data() ?? {};
      if (!tasks.containsKey(taskKey)) {
        throw Exception('Task tidak ditemukan');
      }
      
      final task = tasks[taskKey] as Map<String, dynamic>;
      final taskPIC = task['pic']?.toString().toLowerCase() ?? '';
      
      // Check if user is the PIC of this task
      if (taskPIC != currentUserPIC.toLowerCase()) {
        throw Exception('Anda hanya dapat mengubah status task yang ditugaskan kepada Anda');
      }
      
      // Update status
      task['status'] = newStatus;
      task['lastUpdated'] = DateTime.now().toIso8601String();
      
      // If status is Close, require photo
      if (newStatus == 'Close' && task['photo'] != true) {
        throw Exception('Upload foto terlebih dahulu sebelum memilih status Close');
      }
      
      await docRef.set(tasks);
      print('✅ Task status updated successfully');
      
    } catch (e) {
      print('❌ Error updating task status: $e');
      throw e;
    }
  }
  
  // Update task photo
  Future<void> updateTaskPhoto(
    String date,
    String taskKey,
    String photoData,
    String currentUserPIC,
    bool isTechnical
  ) async {
    try {
      final collection = isTechnical ? 'technical_tasks' : 'nontechnical_tasks';
      final docRef = _firestore.collection(collection).doc(date);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Task tidak ditemukan');
      }
      
      final tasks = doc.data() ?? {};
      if (!tasks.containsKey(taskKey)) {
        throw Exception('Task tidak ditemukan');
      }
      
      final task = tasks[taskKey] as Map<String, dynamic>;
      final taskPIC = task['pic']?.toString().toLowerCase() ?? '';
      
      // Check if user is the PIC of this task
      if (taskPIC != currentUserPIC.toLowerCase()) {
        throw Exception('Anda hanya dapat mengupload foto untuk task yang ditugaskan kepada Anda');
      }
      
      // Update photo
      task['photo'] = true;
      task['photoData'] = photoData;
      task['photoUpdated'] = DateTime.now().toIso8601String();
      
      await docRef.set(tasks);
      print('✅ Task photo updated successfully');
      
    } catch (e) {
      print('❌ Error updating task photo: $e');
      throw e;
    }
  }
  
  // Process Excel data for technical tasks (Admin only)
  Future<void> processTechnicalExcelData(
    List<List<dynamic>> excelRows, 
    String targetDate
  ) async {
    try {
      print('🔄 Processing Technical Excel data for date: $targetDate');
      
      if (excelRows.isEmpty) {
        throw Exception('No data to process');
      }
      
      Map<String, dynamic> processedTasks = {};
      Map<String, Map<String, int>> picStats = {}; // PIC -> {total, completed}
      
      // Skip header row and process data
      for (int i = 1; i < excelRows.length; i++) {
        final row = excelRows[i];
        
        if (row.length >= 5) {
          final no = row[0]?.toString().trim() ?? '';
          final wo = row[1]?.toString().trim() ?? '';
          final desc = row[2]?.toString().trim() ?? '';
          final typeWO = row[3]?.toString().trim() ?? '';
          final pic = row[4]?.toString().trim() ?? '';
          final status = row.length > 5 ? row[5]?.toString().trim() ?? '' : '';
          
          if (wo.isNotEmpty && pic.isNotEmpty && pic.toLowerCase() != 'admin') {
            // Initialize PIC stats
            if (!picStats.containsKey(pic)) {
              picStats[pic] = {'total': 0, 'completed': 0};
            }
            
            // Count total tasks for PIC
            picStats[pic]!['total'] = picStats[pic]!['total']! + 1;
            
            // Count completed tasks for PIC
            if (status.toLowerCase() == 'close') {
              picStats[pic]!['completed'] = picStats[pic]!['completed']! + 1;
            }
            
            // Create task data
            final taskData = {
              'no': int.tryParse(no) ?? i,
              'wo': wo,
              'desc': desc.isNotEmpty ? desc : 'Deskripsi tidak tersedia',
              'typeWO': typeWO.isNotEmpty ? typeWO : 'Other',
              'pic': pic,
              'status': _normalizeStatus(status),
              'category': _determineCategory(desc),
              'jenis_wo': 'Technical',
              'photo': status.toLowerCase() == 'close',
              'photoData': status.toLowerCase() == 'close' ? 'excel_import_photo' : null,
              'timestamp': DateTime.now().toIso8601String(),
              'date': targetDate,
              'assignedTo': pic,
              'createdAt': DateTime.now().toIso8601String(),
            };
            
            processedTasks['task_$i'] = taskData;
          }
        }
      }
      
      // Save tasks to Firestore
      if (processedTasks.isNotEmpty) {
        await _firestore
            .collection('technical_tasks')
            .doc(targetDate)
            .set(processedTasks);
        
        print('✅ Technical Excel data processed and saved: ${processedTasks.length} tasks');
        
        // Log PIC performance summary
        print('📊 PIC Performance Summary (Technical):');
        picStats.forEach((pic, stats) {
          final total = stats['total']!;
          final completed = stats['completed']!;
          final percentage = total > 0 ? (completed / total * 100) : 0.0;
          print('   $pic: $completed/$total (${percentage.toStringAsFixed(1)}%)');
        });
      }
      
    } catch (e) {
      print('❌ Error processing Technical Excel data: $e');
      throw e;
    }
  }
  
  // Process Excel data for non-technical tasks (Admin only)
  Future<void> processNonTechnicalExcelData(
    List<List<dynamic>> excelRows, 
    String targetDate
  ) async {
    try {
      print('🔄 Processing Non-Technical Excel data for date: $targetDate');
      
      if (excelRows.isEmpty) {
        throw Exception('No data to process');
      }
      
      Map<String, dynamic> processedTasks = {};
      Map<String, Map<String, int>> picStats = {}; // PIC -> {total, completed}
      
      // Skip header row and process data
      for (int i = 1; i < excelRows.length; i++) {
        final row = excelRows[i];
        
        if (row.length >= 4) { // Non-technical might have fewer columns
          final no = row[0]?.toString().trim() ?? '';
          final wo = row[1]?.toString().trim() ?? '';
          final desc = row[2]?.toString().trim() ?? '';
          final pic = row[3]?.toString().trim() ?? '';
          final status = row.length > 4 ? row[4]?.toString().trim() ?? '' : '';
          
          if (wo.isNotEmpty && pic.isNotEmpty && pic.toLowerCase() != 'admin') {
            // Initialize PIC stats
            if (!picStats.containsKey(pic)) {
              picStats[pic] = {'total': 0, 'completed': 0};
            }
            
            // Count total tasks for PIC
            picStats[pic]!['total'] = picStats[pic]!['total']! + 1;
            
            // Count completed tasks for PIC
            if (status.toLowerCase() == 'close') {
              picStats[pic]!['completed'] = picStats[pic]!['completed']! + 1;
            }
            
            // Create task data
            final taskData = {
              'no': int.tryParse(no) ?? i,
              'wo': wo,
              'desc': desc.isNotEmpty ? desc : 'Deskripsi tidak tersedia',
              'typeWO': 'Administrative',
              'pic': pic,
              'status': _normalizeStatus(status),
              'category': 'Administrative',
              'jenis_wo': 'Non-Technical',
              'photo': status.toLowerCase() == 'close',
              'photoData': status.toLowerCase() == 'close' ? 'excel_import_photo' : null,
              'timestamp': DateTime.now().toIso8601String(),
              'date': targetDate,
              'assignedTo': pic,
              'createdAt': DateTime.now().toIso8601String(),
            };
            
            processedTasks['task_$i'] = taskData;
          }
        }
      }
      
      // Save tasks to Firestore
      if (processedTasks.isNotEmpty) {
        await _firestore
            .collection('nontechnical_tasks')
            .doc(targetDate)
            .set(processedTasks);
        
        print('✅ Non-Technical Excel data processed and saved: ${processedTasks.length} tasks');
        
        // Log PIC performance summary
        print('📊 PIC Performance Summary (Non-Technical):');
        picStats.forEach((pic, stats) {
          final total = stats['total']!;
          final completed = stats['completed']!;
          final percentage = total > 0 ? (completed / total * 100) : 0.0;
          print('   $pic: $completed/$total (${percentage.toStringAsFixed(1)}%)');
        });
      }
      
    } catch (e) {
      print('❌ Error processing Non-Technical Excel data: $e');
      throw e;
    }
  }
  
  String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'close':
        return 'Close';
      case 'inprogress':
      case 'in progress':
        return 'InProgress';
      case 'reschedule':
        return 'Reschedule';
      case 'wmatt':
        return 'WMatt';
      case 'wshutt':
      case 'wshut':
        return 'WShutt';
      default:
        return status.isNotEmpty ? status : 'InProgress';
    }
  }
  
  String _determineCategory(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('boiler')) return 'Boiler';
    if (desc.contains('turbin')) return 'Turbin';
    if (desc.contains('administrative') || desc.contains('admin')) return 'Administrative';
    return 'Common';
  }
  
  // Check if user can edit tasks for specific date
  bool canEditTasksForDate(String date, bool isAdmin) {
    // Only today's tasks can be edited
    final today = DateTime.now();
    final taskDate = DateTime.parse(date);
    return taskDate.year == today.year && 
           taskDate.month == today.month && 
           taskDate.day == today.day;
  }
  
  // Get available dates for task viewing (last 7 days for members, last 30 for admin)
  List<String> getAvailableDates(bool isAdmin) {
    final now = DateTime.now();
    List<String> dates = [];
    
    if (isAdmin) {
      // Admin can see last 30 days
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        dates.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
      }
    } else {
      // Members can see last 7 days but only edit today
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        dates.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
      }
    }
    
    return dates;
  }
  
  // Get combined status count for dashboard
  Future<Map<String, int>> getStatusCountForDate(String date) async {
    try {
      final technicalTasks = await getTechnicalTasksForDate(date);
      final nonTechnicalTasks = await getNonTechnicalTasksForDate(date);
      
      Map<String, int> statusCount = {
        'Close': 0,
        'WShutt': 0,
        'WMatt': 0,
        'InProgress': 0,
        'Reschedule': 0,
      };
      
      // Count technical tasks
      technicalTasks.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final status = value['status']?.toString() ?? 'InProgress';
          if (statusCount.containsKey(status)) {
            statusCount[status] = statusCount[status]! + 1;
          }
        }
      });
      
      // Count non-technical tasks
      nonTechnicalTasks.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final status = value['status']?.toString() ?? 'InProgress';
          if (statusCount.containsKey(status)) {
            statusCount[status] = statusCount[status]! + 1;
          }
        }
      });
      
      return statusCount;
    } catch (e) {
      print('Error getting status count: $e');
      return {
        'Close': 0,
        'WShutt': 0,
        'WMatt': 0,
        'InProgress': 0,
        'Reschedule': 0,
      };
    }
  }
}