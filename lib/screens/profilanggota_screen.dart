import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'drawer.dart';

class AturProfilAnggotaPage extends StatefulWidget {
  const AturProfilAnggotaPage({super.key});

  @override
  State<AturProfilAnggotaPage> createState() => _AturProfilAnggotaPageState();
}

class _AturProfilAnggotaPageState extends State<AturProfilAnggotaPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<UserModel> users = [];
  Map<String, Map<String, dynamic>> userPerformance = {};
  bool isLoading = true;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await _authService.getCurrentUserData();
    setState(() {});
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => isLoading = true);
      
      // Load all users
      users = await _authService.getAllUsers();
      
      // Calculate performance for each user
      for (var user in users) {
        await _calculateUserPerformance(user.uid);
      }
      
      // Sort users by performance
      users.sort((a, b) {
        double perfA = userPerformance[a.uid]?['percentage'] ?? 0.0;
        double perfB = userPerformance[b.uid]?['percentage'] ?? 0.0;
        return perfB.compareTo(perfA);
      });
      
    } catch (e) {
      print('Error loading users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _calculateUserPerformance(String userId) async {
    try {
      int totalTasks = 0;
      int completedTasks = 0;
      List<Map<String, dynamic>> incompleteTasks = [];

      // Check tactical work orders
      final tacticalSnapshot = await _firestore
          .collection('tactical_work_orders')
          .doc('tactical')
          .get();

      if (tacticalSnapshot.exists) {
        final data = tacticalSnapshot.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          if (value is Map<String, dynamic> && 
              value['userId'] == userId && 
              value['wo']?.toString().trim().isNotEmpty == true) {
            totalTasks++;
            if (value['status'] == 'Close') {
              completedTasks++;
            } else {
              incompleteTasks.add({
                'wo': value['wo'],
                'desc': value['desc'],
                'status': value['status'],
                'type': 'Tactical',
                'category': value['category'],
              });
            }
          }
        });
      }

      // Check non-tactical work orders
      final nonTacticalSnapshot = await _firestore
          .collection('nontactical_work_order')
          .doc('nontactical')
          .get();

      if (nonTacticalSnapshot.exists) {
        final data = nonTacticalSnapshot.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          if (value is Map<String, dynamic> && 
              value['userId'] == userId && 
              value['wo']?.toString().trim().isNotEmpty == true) {
            totalTasks++;
            if (value['status'] == 'Close') {
              completedTasks++;
            } else {
              incompleteTasks.add({
                'wo': value['wo'],
                'desc': value['desc'],
                'status': value['status'],
                'type': 'Non-Tactical',
                'category': value['category'],
              });
            }
          }
        });
      }

      double percentage = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

      userPerformance[userId] = {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'percentage': percentage,
        'incompleteTasks': incompleteTasks,
      };

    } catch (e) {
      print('Error calculating performance for user $userId: $e');
      userPerformance[userId] = {
        'totalTasks': 0,
        'completedTasks': 0,
        'percentage': 0.0,
        'incompleteTasks': <Map<String, dynamic>>[],
      };
    }
  }

  void _showIncompleteTasksModal(UserModel user) {
    final incompleteTasks = userPerformance[user.uid]?['incompleteTasks'] as List<Map<String, dynamic>>? ?? [];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.pending_actions, color: Colors.orange.shade700),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Belum Selesai',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                if (incompleteTasks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'Semua Task Sudah Selesai!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: incompleteTasks.length,
                      itemBuilder: (context, index) {
                        final task = incompleteTasks[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: task['type'] == 'Tactical' 
                                          ? Colors.blue.shade100 
                                          : Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task['type'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: task['type'] == 'Tactical' 
                                            ? Colors.blue.shade700 
                                            : Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(task['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task['status'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(task['status']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                task['wo'] ?? 'No WO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                task['desc'] ?? 'No description',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildPerformanceCard(UserModel user, int rank) {
    final performance = userPerformance[user.uid];
    final percentage = performance?['percentage'] ?? 0.0;
    final completedTasks = performance?['completedTasks'] ?? 0;
    final totalTasks = performance?['totalTasks'] ?? 0;

    Color rankColor;
    IconData rankIcon;
    
    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey.shade400;
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.orange.shade300;
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.grey.shade300;
        rankIcon = Icons.person;
    }

    return GestureDetector(
      onTap: () => _showIncompleteTasksModal(user),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: rank <= 3 ? Border.all(color: rankColor, width: 2) : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Rank Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(rankIcon, color: Colors.white, size: 16),
                      Text(
                        '#$rank',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Performance Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(percentage),
                      ),
                    ),
                    Text(
                      '$completedTasks/$totalTasks tasks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kinerja',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(percentage),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getPerformanceColor(percentage),
                            _getPerformanceColor(percentage).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'supervisor':
        return Colors.orange;
      case 'karyawan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Manajemen Anggota',
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
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green.shade700),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data anggota...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada anggota',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        // Header Stats
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade700, Colors.green.shade500],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.leaderboard, color: Colors.white, size: 32),
                                  SizedBox(width: 12),
                                  Text(
                                    'Ranking Kinerja',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Klik pada kartu anggota untuk melihat task yang belum selesai',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${users.length}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Total Anggota',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${users.where((u) => (userPerformance[u.uid]?['percentage'] ?? 0.0) >= 80).length}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Kinerja Tinggi',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Members List
                        ...users.asMap().entries.map((entry) {
                          int index = entry.key;
                          UserModel user = entry.value;
                          return _buildPerformanceCard(user, index + 1);
                        }).toList(),
                      ],
                    ),
            ),
    );
  }
}