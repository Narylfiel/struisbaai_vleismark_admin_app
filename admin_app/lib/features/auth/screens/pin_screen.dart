import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/db/cached_staff_profile.dart';
import 'package:admin_app/core/db/isar_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/permission_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';
import 'package:admin_app/features/dashboard/screens/main_shell.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String _message = '';
  bool _isLoading = false;
  bool _isOffline = false;
  bool _cacheStale = false;
  int _failedAttempts = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    // Do not auto-restore session on launch — PIN is required every time.
    // Silently refresh cache in background on startup.
    _refreshCacheIfOnline();
  }

  /// Try to pull fresh staff data from Supabase and write to Isar.
  /// Runs silently — does not block the UI.
  Future<void> _refreshCacheIfOnline() async {
    try {
      final supabase = SupabaseService.client;
      final data = await supabase
          .from('profiles')
          .select('id, full_name, role, pin_hash, is_active')
          .eq('is_active', true)
          .timeout(const Duration(seconds: 6));
      final rows = List<Map<String, dynamic>>.from(data);
      final profiles = rows.map((r) => CachedStaffProfile.fromSupabase(r)).toList();
      await IsarService.saveStaffProfiles(profiles);
      if (mounted) setState(() { _isOffline = false; _cacheStale = false; });
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    }
  }

  void _onKeyTap(String value) {
    if (_isLocked || _isLoading) return;
    if (_enteredPin.length < AdminConfig.pinLength) {
      setState(() {
        _enteredPin += value;
        _message = '';
      });
      if (_enteredPin.length == AdminConfig.pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _message = '';
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _message = '';
    });
  }

  // ── PIN verification: online first, cache fallback ────────────
  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final pinHash = sha256.convert(utf8.encode(_enteredPin)).toString();
    Map<String, dynamic>? staff;

    // 1. Try Supabase (online path)
    try {
      final supabase = SupabaseService.client;
      final response = await supabase
          .from('profiles')
          .select('id, full_name, role, pin_hash, is_active')
          .eq('pin_hash', pinHash)
          .inFilter('role', AdminConfig.allowedRoles)
          .eq('is_active', true)
          .limit(1)
          .timeout(const Duration(seconds: 6));

      final rows = List<Map<String, dynamic>>.from(response);
      if (rows.isNotEmpty) {
        staff = rows.first;
        // We're online — refresh cache in background
        _refreshCacheIfOnline();
        if (mounted) setState(() => _isOffline = false);
      } else {
        // Online but PIN not found in database
        _handleFailedAttempt();
        return;
      }
    } catch (_) {
      // 2. Offline fallback — read from Isar
      if (mounted) setState(() => _isOffline = true);

      final hasCache = await IsarService.hasCachedStaff();
      if (!hasCache) {
        if (mounted) setState(() {
          _message =
              'No internet & no local data.\nLog in online once to enable offline access.';
          _enteredPin = '';
          _isLoading = false;
        });
        return;
      }

      final cached = await IsarService.getStaffProfileByPinHash(pinHash);
      if (cached == null) {
        _handleFailedAttempt();
        return;
      }
      staff = cached.toAuthMap();
      final stale = await IsarService.isStaffCacheStale();
      if (mounted) setState(() => _cacheStale = stale);
    }

    // ── Role check — Admin app: Owner + Manager only ──────────
    final role = staff['role'] as String? ?? '';
    if (!AdminConfig.allowedRoles.contains(role.toLowerCase())) {
      setState(() {
        _message = 'Access restricted to Admin staff.';
        _enteredPin = '';
        _isLoading = false;
      });
      return;
    }

    // ── Success ───────────────────────────────────────────────
    AuthService().setSession(
      staff!['id'] as String,
      staff['full_name'] as String,
      role,
    );

    // Load permissions BEFORE navigating to MainShell
    // This ensures PermissionService._isOwner is set correctly
    // before MainShell builds the sidebar
    await PermissionService().loadPermissions(
      role: role,
      staffId: staff!['id'] as String,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(
            staffId: staff!['id'] as String,
            staffName: staff['full_name'] as String,
            role: role,
          ),
        ),
      );
    }
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= AdminConfig.maxPinAttempts) {
      setState(() {
        _isLocked = true;
        _message =
            'Too many attempts. Locked for ${AdminConfig.pinLockoutMinutes} minutes.';
        _enteredPin = '';
        _isLoading = false;
      });
      Future.delayed(const Duration(minutes: AdminConfig.pinLockoutMinutes), () {
        if (mounted) {
          setState(() {
            _isLocked = false;
            _failedAttempts = 0;
            _message = '';
          });
        }
      });
    } else {
      setState(() {
        _message =
            'Incorrect PIN. ${AdminConfig.maxPinAttempts - _failedAttempts} attempts remaining.';
        _enteredPin = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(AdminConfig.appName,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Text(AdminConfig.appSubtitle,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),

              // Offline indicator — only shows when no internet
              if (_isOffline) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 14, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text('Offline Mode — using cached data',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AdminConfig.pinLength, (i) {
                  final filled = i < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? AppColors.primary
                            : AppColors.borderDark,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_isOffline && _cacheStale) ...[
                const SizedBox(height: 6),
                Text(
                  'Cached data may be outdated.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Message area
              SizedBox(
                height: 34,
                child: Text(
                  _message,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          _isLocked ? AppColors.error : AppColors.warning),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Numpad or loading spinner
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                _buildNumpad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(children: [
      _buildNumRow(['1', '2', '3']),
      const SizedBox(height: 12),
      _buildNumRow(['4', '5', '6']),
      const SizedBox(height: 12),
      _buildNumRow(['7', '8', '9']),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _numButton('C', onTap: _onClear, isAction: true),
        const SizedBox(width: 12),
        _numButton('0', onTap: () => _onKeyTap('0')),
        const SizedBox(width: 12),
        _numButton('⌫', onTap: _onDelete, isAction: true),
      ]),
    ]);
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys
          .map((k) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _numButton(k, onTap: () => _onKeyTap(k)),
              ))
          .toList(),
    );
  }

  Widget _numButton(String label,
      {required VoidCallback onTap, bool isAction = false}) {
    return InkWell(
      onTap: _isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 72, height: 56,
        decoration: BoxDecoration(
          color: isAction
              ? AppColors.surfaceBg
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isAction
                      ? AppColors.textSecondary
                      : AppColors.primary)),
        ),
      ),
    );
  }
}