import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';
import 'package:admin_app/features/dashboard/screens/main_shell.dart';

// ─────────────────────────────────────────────────────────────────
// SIMPLE JSON FILE CACHE
// Uses path_provider (already in pubspec) to store staff profiles
// as a JSON file on disk. Works offline. No new dependency needed.
// Blueprint: "Profile data (name, role, pin_hash) cached locally.
//             PIN validation works without internet."
// ─────────────────────────────────────────────────────────────────
class _StaffCache {
  static Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/staff_cache.json');
  }

  /// Save all active staff to local JSON file
  static Future<void> save(List<Map<String, dynamic>> profiles) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(profiles));
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }

  /// Load cached staff list from disk
  static Future<List<Map<String, dynamic>>> load() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Cache load error: $e');
      return [];
    }
  }

  /// Find staff member by PIN hash in local cache
  static Future<Map<String, dynamic>?> findByPin(String pinHash) async {
    final profiles = await load();
    try {
      return profiles.firstWhere(
        (p) {
          if (p['pin_hash'] != pinHash) return false;
          if (p['is_active'] != true && p['is_active'] != 'true') return false;
          final r = p['role'] as String? ?? '';
          return AdminConfig.allowedRoles.contains(r.toLowerCase());
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if any cache exists at all
  static Future<bool> exists() async {
    final profiles = await load();
    return profiles.isNotEmpty;
  }
}

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
  int _failedAttempts = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    // Silently refresh cache in background on startup
    _refreshCacheIfOnline();
  }

  /// Try to pull fresh staff data from Supabase and cache it.
  /// Runs silently — does not block the UI.
  Future<void> _refreshCacheIfOnline() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('staff_profiles')
          .select('id, full_name, role, pin_hash, is_active')
          .eq('is_active', true)
          .timeout(const Duration(seconds: 6));
      final profiles = List<Map<String, dynamic>>.from(data);
      await _StaffCache.save(profiles);
      if (mounted) setState(() => _isOffline = false);
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
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('staff_profiles')
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
      // 2. Offline fallback — check local JSON cache
      if (mounted) setState(() => _isOffline = true);

      final hasCache = await _StaffCache.exists();
      if (!hasCache) {
        setState(() {
          _message =
              'No internet & no local data.\nLog in online once to enable offline access.';
          _enteredPin = '';
          _isLoading = false;
        });
        return;
      }

      staff = await _StaffCache.findByPin(pinHash);
      if (staff == null) {
        _handleFailedAttempt();
        return;
      }
    }

    if (staff == null) {
      _handleFailedAttempt();
      return;
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
      Future.delayed(Duration(minutes: AdminConfig.pinLockoutMinutes), () {
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
              Text(AdminConfig.appName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              Text(AdminConfig.appSubtitle,
                  style: const TextStyle(
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