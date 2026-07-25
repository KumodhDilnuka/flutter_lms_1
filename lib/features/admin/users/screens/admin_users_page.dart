import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/widgets/app_button.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers({String? search}) {
    setState(() => _isLoading = true);
    context.read<AdminProvider>().fetchUsers(search: search).then((_) {
      if (mounted) {
        final error = context.read<AdminProvider>().errorMessage;
        if (error != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('API Error'),
              content: SingleChildScrollView(child: Text(error)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    });
  }

  void _toggleUserStatus(User user) async {
    final provider = context.read<AdminProvider>();
    bool success;
    if (user.status == 'ACTIVE') {
      success = await provider.suspendUser(user.id);
    } else {
      success = await provider.reactivateUser(user.id);
    }

    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<AdminProvider>().users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Users',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _loadUsers(search: value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isActive = user.status == 'ACTIVE';
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                                child: user.profileImageUrl == null ? Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?') : null,
                              ),
                              title: Text('${user.firstName} ${user.lastName}'),
                              subtitle: Text('${user.role} • ${user.email}'),
                              trailing: SizedBox(
                                width: 120,
                                child: AppButton(
                                  label: isActive ? 'Suspend' : 'Reactivate',
                                  isOutlined: isActive,
                                  onPressed: () => _toggleUserStatus(user),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
