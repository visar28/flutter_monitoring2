import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'drawer.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_chart_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../models/user_model.dart';
import 'task_management_screen.dart';

class TacticalWOPage extends StatefulWidget {
  const TacticalWOPage({super.key});

  @override
  _TacticalWOPageState createState() => _TacticalWOPageState();
}

class _TacticalWOPageState extends State<TacticalWOPage> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  Map<String, int> statusCount = {
    'Close': 0,
    'WShutt': 0,
    'WMatt': 0,
    'InProgress': 0,
    'Reschedule': 0,
  };
  
  Map<String, Map<String, dynamic>> _weeklyPerformance = {};
  Map<String, Map<String, dynamic>> _monthlyPerformance = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUser = await _authService.getCurrentUserData();
      
      if (_currentUser != null) {
        await _loadDashboardData();
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load today's tasks for status count
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayTasks = await _taskService.getTasksForDate(todayStr);
      
      // Calculate status count
      Map<String, int> newStatusCount = {
        'Close': 0,
        'WShutt': 0,
        'WMatt': 0,
        'InProgress': 0,
        'Reschedule': 0,
      };
      
      todayTasks.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final status = value['status']?.toString() ?? 'InProgress';
          if (newStatusCount.containsKey(status)) {
            newStatusCount[status] = newStatusCount[status]! + 1;
          }
        }
      });
      
      // Load performance data
      final weeklyData = await _taskService.getWeeklyPerformance();
      final monthlyData = await _taskService.getMonthlyPerformance();
      
      setState(() {
        statusCount = newStatusCount;
        _weeklyPerformance = weeklyData;
        _monthlyPerformance = monthlyData;
      });
      
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  Widget _buildPieChart() {
    final colors = {
      'Close': Colors.green,
      'WShutt': Colors.orange,
      'WMatt': Colors.yellow.shade700,
      'InProgress': Colors.blue,
      'Reschedule': Colors.red,
    };

    final validEntries = statusCount.entries.where((entry) => entry.value > 0).toList();

    if (validEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'Belum ada data hari ini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: validEntries.map((entry) {
                final double value = entry.value.toDouble();
                return PieChartSectionData(
                  color: colors[entry.key] ?? Colors.grey,
                  value: value,
                  title: '${entry.value}',
                  radius: 60,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: validEntries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final totalTasks = statusCount.values.fold(0, (sum, count) => sum + count);
    final completedTasks = statusCount['Close'] ?? 0;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Icon(Icons.task_alt, size: 32, color: Colors.blue),
                SizedBox(height: 8),
                Text(
                  '$totalTasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Total Tasks Hari Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 32, color: Colors.green),
                SizedBox(height: 8),
                Text(
                  '$completedTasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Tasks Selesai',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Icon(Icons.trending_up, size: 32, color: Colors.orange),
                SizedBox(height: 8),
                Text(
                  '${completionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformers() {
    if (_weeklyPerformance.isEmpty) {
      return ModernCard(
        child: Center(
          child: Text(
            'Belum ada data performance',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final sortedPerformers = _weeklyPerformance.entries.toList()
      ..sort((a, b) => (b.value['percentage'] as double).compareTo(a.value['percentage'] as double));

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performers Minggu Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          ...sortedPerformers.take(3).map((entry) {
            final index = sortedPerformers.indexOf(entry);
            final pic = entry.key;
            final data = entry.value;
            final percentage = data['percentage'] as double;
            final completed = data['completedTasks'] as int;
            final total = data['totalTasks'] as int;

            Color rankColor;
            switch (index) {
              case 0:
                rankColor = Colors.amber;
                break;
              case 1:
                rankColor = Colors.grey.shade400;
                break;
              case 2:
                rankColor = Colors.orange.shade300;
                break;
              default:
                rankColor = Colors.grey.shade300;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rankColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: rankColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pic,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$completed/$total tasks (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dashboard - ${_currentUser!.role.toUpperCase()}',
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
      ),
      endDrawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Welcome Section
                  ModernCard(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.waving_hand,
                            size: 32,
                            color: Colors.green.shade700,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang, ${_currentUser!.username}!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Role: ${_currentUser!.role.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskManagementScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Kelola Tasks'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Quick Stats
                  _buildQuickStats(),

                  SizedBox(height: 16),

                  // Charts Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: ModernChartCard(
                          title: 'Status Tasks Hari Ini',
                          subtitle: 'Distribusi status pekerjaan',
                          height: 300,
                          chart: _buildPieChart(),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildTopPerformers(),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Quick Actions
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskManagementScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.task),
                                label: Text('Kelola Tasks'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to history
                                },
                                icon: Icon(Icons.history),
                                label: Text('Lihat History'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}