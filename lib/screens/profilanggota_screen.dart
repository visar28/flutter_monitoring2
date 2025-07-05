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
      
      // Load all users except admin
      List<UserModel> allUsers = await _authService.getAllUsers();
      users = allUsers.where((user) => user.role.toLowerCase() != 'admin').toList();
      
      // Calculate performance for each user based on PIC
      for (var user in users) {
        await _calculateUserPerformanceByPIC(user.username);
      }
      
      // Sort users by performance
      users.sort((a, b) {
        double perfA = userPerformance[a.username]?['percentage'] ?? 0.0;
        double perfB = userPerformance[b.username]?['percentage'] ?? 0.0;
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

  Future<void> _calculateUserPerformanceByPIC(String username) async {
    try {
      int totalTasks = 0;
      int completedTasks = 0;
      List<Map<String, dynamic>> incompleteTasks = [];

      // Check tactical work orders by PIC
      final tacticalSnapshot = await _firestore
          .collection('tactical_work_orders')
          .doc('tactical')
          .get();

      if (tacticalSnapshot.exists) {
        final data = tacticalSnapshot.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final picName = value['pic']?.toString().toLowerCase() ?? '';
            final taskUsername = username.toLowerCase();
            
            if (picName == taskUsername && 
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
          }
        });
      }

      // Check non-tactical work orders by PIC
      final nonTacticalSnapshot = await _firestore
          .collection('nontactical_work_order')
          .doc('nontactical')
          .get();

      if (nonTacticalSnapshot.exists) {
        final data = nonTacticalSnapshot.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final picName = value['pic']?.toString().toLowerCase() ?? '';
            final taskUsername = username.toLowerCase();
            
            if (picName == taskUsername && 
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
          }
        });
      }

      double percentage = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

      userPerformance[username] = {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'percentage': percentage,
        'incompleteTasks': incompleteTasks,
      };

      print('Performance for $username: $completedTasks/$totalTasks (${percentage.toStringAsFixed(1)}%)');

    } catch (e) {
      print('Error calculating performance for user $username: $e');
      userPerformance[username] = {
        'totalTasks': 0,
        'completedTasks': 0,
        'percentage': 0.0,
        'incompleteTasks': <Map<String, dynamic>>[],
      };
    }
  }

  void _showIncompleteTasksModal(UserModel user) {
    final incompleteTasks = userPerformance[user.username]?['incompleteTasks'] as List<Map<String, dynamic>>? ?? [];
    
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
      case 'Inprogress':
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
    final performance = userPerformance[user.username];
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
                      'Kinerja (berdasarkan PIC)',
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

  // User Management Functions
  Future<void> _showAddUserDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();
    String _selectedRole = 'karyawan';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah Anggota Baru'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username wajib diisi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
                        DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await _authService.createUserWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          username: _usernameController.text.trim(),
                          role: _selectedRole,
                        );
                        Navigator.pop(context);
                        _loadUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Anggota berhasil ditambahkan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetPassword(UserModel user) async {
    try {
      await _authService.sendPasswordResetEmail(user.email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email reset password telah dikirim ke ${user.email}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Anggota'),
          content: Text('Apakah Anda yakin ingin menghapus ${user.username}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _authService.deleteUser(user.uid);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anggota berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          // Only admin can add users
          if (currentUser?.isAdmin == true)
            IconButton(
              onPressed: _showAddUserDialog,
              icon: Icon(Icons.person_add, color: Colors.green.shade700),
              tooltip: 'Tambah Anggota',
            ),
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
                          if (currentUser?.isAdmin == true) ...[
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddUserDialog,
                              icon: Icon(Icons.person_add),
                              label: Text('Tambah Anggota'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
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
                                    'Ranking Kinerja Anggota',
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
                                'Kinerja berdasarkan PIC (nama di kolom PIC = username member)\nKlik pada kartu anggota untuk melihat task yang belum selesai',
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
                                          '${users.where((u) => (userPerformance[u.username]?['percentage'] ?? 0.0) >= 80).length}',
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
                          return Column(
                            children: [
                              _buildPerformanceCard(user, index + 1),
                              // Action buttons for each user (Admin only)
                              if (currentUser?.isAdmin == true)
                                Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _resetPassword(user),
                                          icon: Icon(Icons.lock_reset, size: 16),
                                          label: Text('Reset Password'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange.shade700,
                                            side: BorderSide(color: Colors.orange.shade700),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _deleteUser(user),
                                          icon: Icon(Icons.delete, size: 16),
                                          label: Text('Hapus'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade700,
                                            side: BorderSide(color: Colors.red.shade700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
            ),
    );
  }
}