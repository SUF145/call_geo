import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'add_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final String adminId;
  
  const UserManagementScreen({
    Key? key,
    required this.adminId,
  }) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    final users = await _supabaseService.getUsersByAdmin(widget.adminId);
    
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }
  
  Future<void> _editUser(UserModel user) async {
    // Show dialog to edit user details
    final TextEditingController nameController = TextEditingController(text: user.fullName);
    final TextEditingController emailController = TextEditingController(text: user.email);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await _supabaseService.updateUser(
        userId: user.id,
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
      );
      
      if (success) {
        _loadUsers(); // Refresh the list
      }
    }
    
    nameController.dispose();
    emailController.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No users found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddUserScreen(adminId: widget.adminId),
                            ),
                          );
                          
                          if (result == true) {
                            _loadUsers();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(user.fullName),
                              subtitle: Text(user.email),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editUser(user),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddUserScreen(adminId: widget.adminId),
                            ),
                          );
                          
                          if (result == true) {
                            _loadUsers();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
