import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/admin_config.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String _message = '';
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isLocked = false;

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

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    try {
      final bytes = utf8.encode(_enteredPin);
      final hashedPin = sha256.convert(bytes).toString();
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('id, full_name, role, active')
          .eq('pin_hash', hashedPin)
          .eq('active', true)
          .maybeSingle();
      if (response == null) {
        _handleFailedAttempt();
        return;
      }
      final role = response['role'] as String;
      if (!AdminConfig.allowedRoles.contains(role)) {
        setState(() {
          _message = 'Access restricted to Admin staff.';
          _enteredPin = '';
          _isLoading = false;
        });
        return;
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainShell(
              staffId: response['id'],
              staffName: response['full_name'],
              role: role,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _message = 'Connection error. Check internet.';
        _enteredPin = '';
        _isLoading = false;
      });
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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                AdminConfig.appName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AdminConfig.appSubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AdminConfig.pinLength, (i) {
                  final filled = i < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppColors.primary : AppColors.borderDark,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 20,
                child: Text(
                  _message,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isLocked ? AppColors.error : AppColors.warning,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
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
    return Column(
      children: [
        _buildNumRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildNumRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildNumRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _numButton('C', onTap: _onClear, isAction: true),
            const SizedBox(width: 12),
            _numButton('0', onTap: () => _onKeyTap('0')),
            const SizedBox(width: 12),
            _numButton('⌫', onTap: _onDelete, isAction: true),
          ],
        ),
      ],
    );
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
        width: 72,
        height: 56,
        decoration: BoxDecoration(
          color: isAction ? AppColors.surfaceBg : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isAction ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  final String staffId;
  final String staffName;
  final String role;

  const MainShell({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'Welcome, $staffName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Dashboard coming next...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
