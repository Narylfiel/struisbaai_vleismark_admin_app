import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/constants/permissions.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/audit_service.dart';

/// User Management — OWNER ONLY screen for managing admin users and roles.
///
/// Two tabs:
/// - Users: View, add, edit, deactivate admin users
/// - Roles: Manage role definitions, colors, permissions
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.client;
  final _auth = AuthService();
  late TabController _tabController;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
    });

    // Check access and load data
    if (_auth.currentRole == 'owner') {
      _loadRoles().then((_) => _loadUsers());
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final data = await _client.from('admin_roles').select().order('sort_order');
      if (mounted) {
        setState(() => _roles = List<Map<String, dynamic>>.from(data as List));
      }
    } catch (e) {
      debugPrint('Load roles error: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, full_name, role, phone, email, active, is_active, created_at');

      final sortMap = {
        for (var r in _roles) r['role_name'] as String: r['sort_order'] as int? ?? 99
      };

      final list = List<Map<String, dynamic>>.from(data as List);
      list.sort((a, b) {
        final sA = sortMap[a['role']] ?? 99;
        final sB = sortMap[b['role']] ?? 99;
        if (sA != sB) return sA.compareTo(sB);
        return (a['full_name'] as String).compareTo(b['full_name'] as String);
      });

      if (mounted) {
        setState(() => _users = list);
      }
    } catch (e) {
      debugPrint('Load users error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _roleDisplayName(String roleName) {
    final role = _roles.firstWhere(
      (r) => r['role_name'] == roleName,
      orElse: () => <String, dynamic>{'display_name': roleName},
    );
    return role['display_name'] as String? ?? roleName;
  }

  Color _roleColor(String roleName) {
    final role = _roles.firstWhere(
      (r) => r['role_name'] == roleName,
      orElse: () => <String, dynamic>{'color_hex': '#607D8B'},
    );
    final hex = (role['color_hex'] as String? ?? '#607D8B').replaceAll('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  int get _activeOwnerCount =>
      _users.where((u) => u['role'] == 'owner' && u['active'] == true).length;

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'reset_pin':
        _showResetPinDialog(user);
        break;
      case 'change_role':
        _showChangeRoleDialog(user);
        break;
      case 'deactivate':
        _showDeactivateDialog(user);
        break;
      case 'reactivate':
        _reactivateUser(user);
        break;
    }
  }

  void _handleRoleAction(String action, Map<String, dynamic> role) {
    switch (action) {
      case 'edit':
        _showEditRoleDialog(role);
        break;
      case 'deactivate':
        _showDeactivateRoleDialog(role);
        break;
      case 'reactivate':
        _reactivateRole(role);
        break;
    }
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final pinController = TextEditingController();
    String? selectedRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Add Admin User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles
                      .where((r) => r['is_active'] == true)
                      .map((r) => DropdownMenuItem<String>(
                            value: r['role_name'] as String,
                            child: Text(r['display_name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => selectedRole = v,
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: 'Initial PIN *',
                    border: OutlineInputBorder(),
                    helperText: 'User must change PIN after first login',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length != 4) return 'Must be exactly 4 digits';
                    if (!RegExp(r'^\d{4}$').hasMatch(v)) return 'Must be 4 digits only';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate() || selectedRole == null) {
                if (selectedRole == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a role'), backgroundColor: AppColors.warning),
                  );
                }
                return;
              }

              try {
                final result = await _client.from('profiles').insert({
                  'full_name': nameController.text.trim(),
                  'role': selectedRole,
                  'pin_hash': pinController.text,
                  'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  'active': true,
                  'is_active': true,
                }).select('id').single();

                await AuditService.log(
                  action: 'CREATE',
                  module: 'Settings',
                  description: 'New admin user: ${nameController.text.trim()} (${_roleDisplayName(selectedRole!)})',
                  entityType: 'Profile',
                  entityId: result['id'],
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${nameController.text.trim()} added successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user['full_name']);
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final isOwner = user['role'] == 'owner';
    
    // Load current permission overrides for this user
    Map<String, bool> tempOverrides = {};
    Map<String, bool> oldOverrides = {};
    if (!isOwner) {
      try {
        final data = await _client
            .from('profiles')
            .select('permissions')
            .eq('id', user['id'])
            .maybeSingle();
        final currentOverrides = (data?['permissions'] as Map<String, dynamic>?) ?? {};
        if (currentOverrides.isNotEmpty) {
          tempOverrides = currentOverrides.map((k, v) => MapEntry(k, v == true));
          oldOverrides = Map<String, bool>.from(tempOverrides);
        }
      } catch (e) {
        debugPrint('Error loading user permission overrides: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text('Edit — ${user['full_name']}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To change role or PIN, use the card menu options',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!isOwner) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Permission Overrides',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Overrides are additive — only enabled overrides apply. Leave all off to use role defaults.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    ..._buildPermissionToggles(tempOverrides, setDialogState),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  await _client.from('profiles').update({
                    'full_name': nameController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                    'permissions': isOwner ? null : tempOverrides,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', user['id']);

                  await AuditService.log(
                    action: 'UPDATE',
                    module: 'Settings',
                    description: 'Admin user updated: ${nameController.text.trim()}',
                    entityType: 'Profile',
                    entityId: user['id'],
                  );

                  if (!isOwner && (tempOverrides.isNotEmpty || oldOverrides.isNotEmpty)) {
                    await AuditService.log(
                      action: 'UPDATE',
                      module: 'Settings',
                      description: 'Permission overrides updated for: ${nameController.text.trim()}',
                      entityType: 'Profile',
                      entityId: user['id'],
                      oldValues: {'permissions': oldOverrides},
                      newValues: {'permissions': tempOverrides},
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPinDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Reset PIN — ${user['full_name']}'),
        content: const Text(
          'This will reset their PIN to 0000.\n\n'
          'You must tell them their new PIN manually.\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _client.from('profiles').update({
                  'pin_hash': '0000',
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', user['id']);

                await AuditService.log(
                  action: 'UPDATE',
                  module: 'Settings',
                  description: 'PIN reset to 0000 for: ${user['full_name']}',
                  entityType: 'Profile',
                  entityId: user['id'],
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${user['full_name']}'s PIN reset to 0000 — inform them manually"),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    // Protection checks
    if (user['id'] == _auth.currentStaffId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot change your own role'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (user['role'] == 'owner' && _activeOwnerCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot change role of the last active owner'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Change Role — ${user['full_name']}'),
        children: _roles
            .where((r) => r['is_active'] == true)
            .map((r) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _roleColor(r['role_name']),
                    child: Text(
                      (r['display_name'] as String).substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(r['display_name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r['description'] ?? ''),
                  trailing: user['role'] == r['role_name']
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => _changeRole(user, r['role_name']),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _changeRole(Map<String, dynamic> user, String newRoleName) async {
    if (newRoleName == user['role']) {
      Navigator.pop(context);
      return;
    }

    final oldRole = user['role'];
    try {
      await _client.from('profiles').update({
        'role': newRoleName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user['id']);

      await AuditService.log(
        action: 'UPDATE',
        module: 'Settings',
        description: 'Role changed: ${user['full_name']} → ${_roleDisplayName(newRoleName)} (was ${_roleDisplayName(oldRole)})',
        entityType: 'Profile',
        entityId: user['id'],
        oldValues: {'role': oldRole},
        newValues: {'role': newRoleName},
      );

      if (mounted) {
        Navigator.pop(context);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${user['full_name']} is now ${_roleDisplayName(newRoleName)}"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showDeactivateDialog(Map<String, dynamic> user) {
    // Protection checks
    if (user['id'] == _auth.currentStaffId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot deactivate yourself'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (user['role'] == 'owner' && _activeOwnerCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot deactivate the last active owner'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Deactivate ${user['full_name']}?'),
        content: const Text(
          'They will no longer be able to log into the Admin App.\n\nThis does not delete their record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _client.from('profiles').update({
                  'active': false,
                  'is_active': false,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', user['id']);

                await AuditService.log(
                  action: 'UPDATE',
                  module: 'Settings',
                  description: 'Admin user deactivated: ${user['full_name']}',
                  entityType: 'Profile',
                  entityId: user['id'],
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${user['full_name']} deactivated"), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivateUser(Map<String, dynamic> user) async {
    try {
      await _client.from('profiles').update({
        'active': true,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user['id']);

      await AuditService.log(
        action: 'UPDATE',
        module: 'Settings',
        description: 'Admin user reactivated: ${user['full_name']}',
        entityType: 'Profile',
        entityId: user['id'],
      );

      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user['full_name']} reactivated"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddRoleDialog() {
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController();
    final roleNameController = TextEditingController();
    final descriptionController = TextEditingController();
    final sortOrderController = TextEditingController(
      text: (_roles.isEmpty ? 0 : (_roles.map((r) => r['sort_order'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1)).toString(),
    );
    String selectedColorHex = '#607D8B';

    final colorOptions = [
      '#C62828', // Red
      '#E65100', // Orange
      '#F9A825', // Yellow
      '#2E7D32', // Green
      '#1565C0', // Blue
      '#4527A0', // Purple
      '#00695C', // Teal
      '#607D8B', // Grey
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('Add New Role'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final autoName = v.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
                      roleNameController.text = autoName;
                    },
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: roleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Role Name *',
                      border: OutlineInputBorder(),
                      helperText: 'Stored in database — no spaces or special characters',
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) return 'Only lowercase, numbers, and underscores';
                      if (_roles.any((r) => r['role_name'] == v)) return 'Role name already exists';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  const Text('Color *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: colorOptions.map((hex) {
                      final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                      final isSelected = selectedColorHex == hex;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColorHex = hex),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: isSelected ? 3 : 0,
                              color: Colors.black,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sortOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final result = await _client.from('admin_roles').insert({
                    'role_name': roleNameController.text.trim(),
                    'display_name': displayNameController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    'color_hex': selectedColorHex,
                    'sort_order': int.tryParse(sortOrderController.text) ?? 99,
                    'is_active': true,
                  }).select('id').single();

                  await AuditService.log(
                    action: 'CREATE',
                    module: 'Settings',
                    description: 'New role created: ${displayNameController.text.trim()} (${roleNameController.text.trim()})',
                    entityType: 'AdminRole',
                    entityId: result['id'],
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadRoles();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Role '${displayNameController.text.trim()}' created"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(Map<String, dynamic> role) async {
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController(text: role['display_name']);
    final descriptionController = TextEditingController(text: role['description'] ?? '');
    final sortOrderController = TextEditingController(text: (role['sort_order'] ?? 0).toString());
    String selectedColorHex = role['color_hex'] as String? ?? '#607D8B';
    
    // Load current permissions for this role
    Map<String, bool> tempPerms = {};
    Map<String, bool> oldPerms = {};
    try {
      final data = await _client
          .from('role_permissions')
          .select('permissions')
          .eq('role_name', role['role_name'])
          .maybeSingle();
      final currentPerms = (data?['permissions'] as Map<String, dynamic>?) ?? {};
      tempPerms = currentPerms.map((k, v) => MapEntry(k, v == true));
      oldPerms = Map<String, bool>.from(tempPerms);
    } catch (e) {
      debugPrint('Error loading role permissions: $e');
    }

    final colorOptions = [
      '#C62828', '#E65100', '#F9A825', '#2E7D32',
      '#1565C0', '#4527A0', '#00695C', '#607D8B',
    ];

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text('Edit Role — ${role['display_name']}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.info),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Role name (${role['role_name']}) cannot be changed — it is stored against existing users',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  const Text('Color *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: colorOptions.map((hex) {
                      final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                      final isSelected = selectedColorHex == hex;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColorHex = hex),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: isSelected ? 3 : 0,
                              color: Colors.black,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sortOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Default Permissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These permissions apply to all users with this role (unless overridden per user)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                  ..._buildPermissionToggles(tempPerms, setDialogState),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  // Update admin_roles
                  await _client.from('admin_roles').update({
                    'display_name': displayNameController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    'color_hex': selectedColorHex,
                    'sort_order': int.tryParse(sortOrderController.text) ?? 0,
                  }).eq('id', role['id']);

                  // Upsert role_permissions
                  await _client.from('role_permissions').upsert({
                    'role_name': role['role_name'],
                    'permissions': tempPerms,
                  });

                  await AuditService.log(
                    action: 'UPDATE',
                    module: 'Settings',
                    description: 'Role updated: ${displayNameController.text.trim()} (${role['role_name']})',
                    entityType: 'AdminRole',
                    entityId: role['id'],
                  );

                  await AuditService.log(
                    action: 'UPDATE',
                    module: 'Settings',
                    description: 'Role permissions updated: ${role['display_name']}',
                    entityType: 'RolePermissions',
                    entityId: role['role_name'],
                    oldValues: {'permissions': oldPerms},
                    newValues: {'permissions': tempPerms},
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadRoles().then((_) => _loadUsers());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateRoleDialog(Map<String, dynamic> role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Deactivate Role — ${role['display_name']}?'),
        content: const Text(
          'Users with this role will still exist but this role will not appear in dropdowns for new assignments.\n\n'
          'Existing users keep their current role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _client.from('admin_roles').update({
                  'is_active': false,
                }).eq('id', role['id']);

                await AuditService.log(
                  action: 'UPDATE',
                  module: 'Settings',
                  description: 'Role deactivated: ${role['display_name']} (${role['role_name']})',
                  entityType: 'AdminRole',
                  entityId: role['id'],
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadRoles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Role '${role['display_name']}' deactivated"), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivateRole(Map<String, dynamic> role) async {
    try {
      await _client.from('admin_roles').update({
        'is_active': true,
      }).eq('id', role['id']);

      await AuditService.log(
        action: 'UPDATE',
        module: 'Settings',
        description: 'Role reactivated: ${role['display_name']} (${role['role_name']})',
        entityType: 'AdminRole',
        entityId: role['id'],
      );

      _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Role '${role['display_name']}' reactivated"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Build permission toggle list for role or user permission editing
  List<Widget> _buildPermissionToggles(Map<String, bool> perms, StateSetter setState) {
    return Permissions.allKeys.map((key) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Permissions.getName(key),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Permissions.getDescription(key),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: perms[key] ?? false,
              onChanged: (val) => setState(() => perms[key] = val),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Access control
    if (_auth.currentRole != 'owner') {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              const Text(
                'Access Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'User Management is only available to Owners',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppColors.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
                Tab(icon: Icon(Icons.badge, size: 18), text: 'Roles'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersTab(),
                      _buildRolesTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddRoleDialog,
              backgroundColor: AppColors.primary,
              tooltip: 'Add Role',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Add user button at top
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.cardBg,
          child: Row(
            children: [
              const Text(
                'Admin Users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _users.isEmpty
              ? const Center(
                  child: Text('No users found', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (context, index) => _buildUserCard(_users[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isCurrentUser = user['id'] == _auth.currentStaffId;
    final isInactive = user['active'] == false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(user['role']),
          child: Text(
            _initials(user['full_name']),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              user['full_name'],
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            if (isCurrentUser)
              Chip(
                label: const Text('You', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.teal[100],
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            if (isInactive)
              Chip(
                label: Text('INACTIVE', style: TextStyle(fontSize: 11, color: Colors.red[800])),
                backgroundColor: Colors.red[100],
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Chip(
              label: Text(_roleDisplayName(user['role'])),
              backgroundColor: _roleColor(user['role']).withOpacity(0.15),
              labelStyle: TextStyle(color: _roleColor(user['role']), fontSize: 11),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            if (user['phone'] != null)
              Text(
                user['phone'],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            if (user['email'] != null)
              Text(
                user['email'],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
            const PopupMenuItem(value: 'reset_pin', child: Text('Reset PIN')),
            const PopupMenuItem(value: 'change_role', child: Text('Change Role')),
            if (user['active'] == true)
              const PopupMenuItem(
                value: 'deactivate',
                child: Text('Deactivate', style: TextStyle(color: Colors.red)),
              ),
            if (user['active'] == false)
              const PopupMenuItem(
                value: 'reactivate',
                child: Text('Reactivate', style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _roles.length,
      itemBuilder: (context, index) => _buildRoleCard(_roles[index]),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final isOwner = role['role_name'] == 'owner';
    final isInactive = role['is_active'] == false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBg,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(role['role_name']),
          child: Text(
            (role['display_name'] as String).substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Text(
              role['display_name'],
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              role['role_name'],
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (isInactive)
              Chip(
                label: Text('INACTIVE', style: TextStyle(fontSize: 11, color: Colors.red[800])),
                backgroundColor: Colors.red[100],
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        subtitle: Text(
          role['description'] ?? '',
          style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _handleRoleAction(v, role),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Role')),
            if (!isOwner) ...[
              if (role['is_active'] == true)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Deactivate Role', style: TextStyle(color: Colors.red)),
                ),
              if (role['is_active'] == false)
                const PopupMenuItem(
                  value: 'reactivate',
                  child: Text('Reactivate Role', style: TextStyle(color: Colors.green)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
