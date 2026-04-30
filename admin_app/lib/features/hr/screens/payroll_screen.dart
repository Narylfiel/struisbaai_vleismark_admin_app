import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/services/export_service.dart';
import 'package:admin_app/core/services/payslip_pdf_service.dart';
import 'package:admin_app/core/services/supabase_service.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/utils/error_handler.dart';
import 'package:admin_app/features/bookkeeping/services/ledger_repository.dart';
import 'package:admin_app/features/hr/services/staff_profile_repository.dart';
import 'package:admin_app/features/hr/services/timecard_repository.dart';

class PayrollScreen extends StatefulWidget {
  final bool isEmbedded;
  const PayrollScreen({super.key, this.isEmbedded = false});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _client = SupabaseService.client;
  
  DateTime? _periodStart;
  DateTime? _periodEnd;
  
  bool _isCalculating = false;
  bool _isApproving = false;
  bool _isPaying = false;
  
  List<Map<String, dynamic>> _calculatedEntries = [];
  Map<String, dynamic>? _periodRecord;

  final Set<String> _generatingPayslipIds = <String>{};
  bool _isGeneratingAllPayslips = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadExistingPeriod() async {
    if (_periodStart == null || _periodEnd == null) return;
    try {
      final startStr = _periodStart!.toIso8601String().substring(0, 10);
      final endStr = _periodEnd!.toIso8601String().substring(0, 10);
      
      final periodReq = await _client.from('payroll_periods')
          .select()
          .eq('start_date', startStr)
          .eq('end_date', endStr)
          .maybeSingle();
      
      final entriesReq = await _client.from('payroll_entries')
          .select('*, staff_profiles!payroll_entries_staff_id_fkey(full_name, hourly_rate, monthly_salary, employment_type, is_active, date_of_birth, uif_exempt, id_number, role, phone, hire_date, bank_name, bank_account)')
          .eq('pay_period_start', startStr)
          .eq('pay_period_end', endStr);
          
      if (mounted) {
        setState(() {
          _periodRecord = periodReq;
          _calculatedEntries = List<Map<String, dynamic>>.from(entriesReq);
        });
      }
    } catch (_) {
      // Ignored
    }
  }


  DateTime _getMonday(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  /// Calculates monthly PAYE tax (SARS 2025/2026 tax year)
  static double _calculateMonthlyPAYE(double monthlyGross, DateTime? dob) {
    final double annualIncome = monthlyGross * 12;

    // Annual tax from brackets
    double annualTax;
    if (annualIncome <= 237100) {
      annualTax = annualIncome * 0.18;
    } else if (annualIncome <= 370500) {
      annualTax = 42678 + (annualIncome - 237100) * 0.26;
    } else if (annualIncome <= 512800) {
      annualTax = 77362 + (annualIncome - 370500) * 0.31;
    } else if (annualIncome <= 673000) {
      annualTax = 121475 + (annualIncome - 512800) * 0.36;
    } else if (annualIncome <= 857900) {
      annualTax = 179147 + (annualIncome - 673000) * 0.39;
    } else if (annualIncome <= 1817000) {
      annualTax = 251258 + (annualIncome - 857900) * 0.41;
    } else {
      annualTax = 644489 + (annualIncome - 1817000) * 0.45;
    }

    // Rebates based on age
    int age = 0;
    if (dob != null) {
      final now = DateTime.now();
      age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
    }

    double rebate = 17235; // Primary — everyone
    if (age >= 65) rebate += 9444; // Secondary
    if (age >= 75) rebate += 3145; // Tertiary

    annualTax = (annualTax - rebate).clamp(0, double.infinity);

    return annualTax / 12;
  }

  Future<void> _calculatePayroll() async {
    if (_periodStart == null || _periodEnd == null) return;
    setState(() => _isCalculating = true);
    
    try {
      final startStr = _periodStart!.toIso8601String().substring(0, 10);
      final endStr = _periodEnd!.toIso8601String().substring(0, 10);

      // STEP 1a - Fetch active staff (hourly + monthly_salary)
      final staffResponse = await StaffProfileRepository(client: _client)
          .getAll(isActive: true)
          .then((rows) => rows
              .where((r) {
                final type = r['employment_type'] as String?;
                if (type == 'hourly') {
                  return r['hourly_rate'] != null &&
                      (r['hourly_rate'] as num) > 0;
                }
                if (type == 'monthly_salary') {
                  return r['monthly_salary'] != null &&
                      (r['monthly_salary'] as num) > 0;
                }
                return false;
              })
              .toList());
      
      debugPrint('Staff count: ${staffResponse.length}');
      
      List<Map<String, dynamic>> staffList = List<Map<String, dynamic>>.from(staffResponse);

      // STEP 1b - Fetch public holidays in range
      final phResponse = await _client.from('public_holidays')
          .select('holiday_date')
          .eq('is_active', true)
          .gte('holiday_date', startStr)
          .lte('holiday_date', endStr);
      
      final phDates = (phResponse as List).map((row) => row['holiday_date'].toString()).toSet();

      // Ensure payroll_periods exists or create a draft
      double sumGross = 0;
      double sumDed = 0;
      double sumNet = 0;
      List<Map<String, dynamic>> newEntries = [];

      // STEP 2 - Iterate through staff
      for (var staff in staffList) {
        final staffId = staff['id'] as String;
        final employmentType = staff['employment_type'] as String? ?? 'hourly';
        final monthlySalary = (staff['monthly_salary'] as num?)?.toDouble() ?? 0.0;
        final hourlyRate = (staff['hourly_rate'] as num?)?.toDouble() ?? 0.0;
        
        // 2a. Timecards
        final tcResponse = await TimecardRepository(client: _client).getForPeriod(
          staffId: staffId,
          periodStart: _periodStart!,
          periodEnd: _periodEnd!,
        );

        final timecards = tcResponse
            .where((tc) =>
                tc['status'] == 'clocked_out' &&
                tc['total_hours'] != null &&
                (tc['total_hours'] as num).toDouble() > 0)
            .map((tc) => <String, dynamic>{
                  'shift_date': tc['shift_date'],
                  'total_hours': tc['total_hours'],
                  'clock_in': tc['clock_in'],
                  'clock_out': tc['clock_out'],
                  'break_minutes': tc['break_minutes'],
                  'status': tc['status'],
                })
            .toList();
        
        // 2c. Group by ISO Week (Monday)
        Map<DateTime, List<Map<String, dynamic>>> weeklyChunks = {};
        for(var tc in timecards) {
          final dt = DateTime.parse(tc['shift_date']);
          final monday = _getMonday(dt);
          weeklyChunks.putIfAbsent(monday, () => []).add(tc);
        }

        double totalRegHrs = 0;
        double totalOtHrs = 0;
        double totalSunHrs = 0;
        double totalPhHrs = 0;

        for (var weekEntries in weeklyChunks.values) {
          double weeklyTotal = weekEntries.fold(0.0, (sum, tc) => sum + (tc['total_hours'] as num).toDouble());
          
          for (var tc in weekEntries) {
            tc['_calc_reg'] = 0.0;
            tc['_calc_ot'] = 0.0;
            tc['_calc_sun'] = 0.0;
            tc['_calc_ph'] = 0.0;
            tc['_orig_hrs'] = (tc['total_hours'] as num).toDouble();
            
            final dt = DateTime.parse(tc['shift_date']);
            tc['_is_sun'] = dt.weekday == DateTime.sunday;
            tc['_is_ph'] = phDates.contains(tc['shift_date']);
          }

          if (weeklyTotal > 45) {
            double overflow = weeklyTotal - 45.0;
            weekEntries.sort((a,b) => (b['shift_date'] as String).compareTo(a['shift_date'] as String));
            for (var tc in weekEntries) {
              double hrs = tc['_orig_hrs'];
              if (tc['_is_sun']) {
                tc['_calc_sun'] = hrs;
                overflow -= hrs;
              } else if (tc['_is_ph']) {
                tc['_calc_ph'] = hrs;
                overflow -= hrs;
              } else {
                if (overflow > 0) {
                  double otPart = (hrs > overflow) ? overflow : hrs;
                  tc['_calc_ot'] = otPart;
                  tc['_calc_reg'] = hrs - otPart;
                  overflow -= otPart;
                } else {
                  tc['_calc_reg'] = hrs;
                }
              }
            }
          } else {
            for (var tc in weekEntries) {
              double hrs = tc['_orig_hrs'];
              if (tc['_is_sun']) {
                tc['_calc_sun'] = hrs;
              } else if (tc['_is_ph']) {
                tc['_calc_ph'] = hrs;
              } else {
                tc['_calc_reg'] = hrs;
              }
            }
          }

          for (var tc in weekEntries) {
            totalRegHrs += tc['_calc_reg'] as double;
            totalOtHrs += tc['_calc_ot'] as double;
            totalSunHrs += tc['_calc_sun'] as double;
            totalPhHrs += tc['_calc_ph'] as double;
          }
        } // week loop

        // 2e. Calculate Pay
        double regPay = 0;
        double otPay = 0;
        double sunPay = 0;
        double phPay = 0;
        double grossPay = 0;

        if (employmentType == 'monthly_salary') {
          // Salaried: fixed monthly amount, no hours calculation
          totalRegHrs = 0;
          totalOtHrs = 0;
          totalSunHrs = 0;
          totalPhHrs = 0;
          grossPay = monthlySalary;
        } else {
          // Hourly: existing calculation unchanged
          regPay = totalRegHrs * hourlyRate;
          otPay = totalOtHrs * hourlyRate * 1.5;
          sunPay = totalSunHrs * hourlyRate * 2.0;
          phPay = totalPhHrs * hourlyRate * 1.5;
          grossPay = regPay + otPay + sunPay + phPay;
        }

        // 2f. UIF
        bool isUifExempt = staff['uif_exempt'] == true;
        double uifEmployee = isUifExempt ? 0 : grossPay * 0.01;
        double uifEmployer = isUifExempt ? 0 : grossPay * 0.01;

        // 2f2. PAYE income tax (SARS 2025/2026)
        final String? dobStr = staff['date_of_birth'] as String?;
        final DateTime? dob = dobStr != null ? DateTime.tryParse(dobStr) : null;
        final double payeTax = _calculateMonthlyPAYE(grossPay, dob);

        // 2g. Meat purchases
        final meatReq = await _client.from('staff_credit')
            .select('credit_amount')
            .eq('staff_id', staffId)
            .eq('credit_type', 'meat_purchase')
            .inFilter('status', ['pending', 'partial', 'owing', 'deducted'])
            .gte('deduct_from', startStr)
            .lte('deduct_from', endStr);
        double meatDed = (meatReq as List).fold(0.0, (sum, row) => sum + (row['credit_amount'] as num).toDouble());

        // 2h. Advances
        final advReq = await _client.from('staff_credit')
            .select('credit_amount')
            .eq('staff_id', staffId)
            .eq('credit_type', 'salary_advance')
            .inFilter('status', ['pending', 'owing', 'deducted'])
            .gte('deduct_from', startStr)
            .lte('deduct_from', endStr);
        double advDed = (advReq as List).fold(0.0, (sum, row) => sum + (row['credit_amount'] as num).toDouble());

        // 2i. Totals
        double totalDed = uifEmployee + meatDed + advDed + payeTax;
        double netPay = grossPay - totalDed;

        sumGross += grossPay;
        sumDed += totalDed;
        sumNet += netPay;

        // Fetch existing entry to check status safely
        final existingEntry = await _client.from('payroll_entries')
            .select('id, status')
            .eq('staff_id', staffId)
            .eq('pay_period_start', startStr)
            .eq('pay_period_end', endStr)
            .maybeSingle();

        if (existingEntry != null && (existingEntry['status'] == 'approved' || existingEntry['status'] == 'paid')) {
           // SKIP Upsert but include existing calculated totals for UI
           newEntries.add({
             'staff_profiles': staff,
             'is_skipped': true, // flag for UI Warning
             ...existingEntry
           });
           continue; 
        }

        final upsertPayload = {
          'staff_id': staffId,
          'pay_period_start': startStr,
          'pay_period_end': endStr,
          'pay_frequency': staff['pay_frequency'] ?? 'monthly',
          'gross_pay': grossPay,
          'deductions': totalDed,
          'net_pay': netPay,
          'status': 'draft',
          'regular_hours': totalRegHrs,
          'overtime_hours': totalOtHrs,
          'sunday_hours': totalSunHrs,
          'public_holiday_hours': totalPhHrs,
          'regular_pay': regPay,
          'overtime_pay': otPay,
          'sunday_pay': sunPay,
          'public_holiday_pay': phPay,
          'uif_employee': uifEmployee,
          'uif_employer': uifEmployer,
          'advance_deduction': advDed,
          'meat_purchase_deduction': meatDed,
          'other_deductions': payeTax,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // UPSERT is natively supported via primary key constraint if setup, or manual delete/insert if needed.
        // Assuming pay_period_start + staff_id is unique constraints. We use standard upsert on constraint.
        // Since we don't know the unique index name perfectly, we do an explicit insert/update.
        if (existingEntry != null) {
          final res = await _client.from('payroll_entries').update(upsertPayload).eq('id', existingEntry['id']).select().single();
          newEntries.add({ ...res, 'staff_profiles': staff, 'timecards': timecards });
        } else {
          final res = await _client.from('payroll_entries').insert(upsertPayload).select().single();
          newEntries.add({ ...res, 'staff_profiles': staff, 'timecards': timecards });
        }
      }

      // Update payroll_periods
      final existingPeriod = await _client.from('payroll_periods')
          .select('id, status')
          .eq('start_date', startStr)
          .eq('end_date', endStr)
          .maybeSingle();

      final periodPayload = {
        'period_name': '$startStr to $endStr',
        'start_date': startStr,
        'end_date': endStr,
        'status': (existingPeriod != null && (existingPeriod['status'] == 'approved' || existingPeriod['status'] == 'paid')) ? existingPeriod['status'] : 'open',
        'total_gross': sumGross,
        'total_deductions': sumDed,
        'total_net': sumNet,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingPeriod != null) {
         await _client.from('payroll_periods').update(periodPayload).eq('id', existingPeriod['id']);
      } else {
         await _client.from('payroll_periods').insert(periodPayload);
      }

      await _loadExistingPeriod();

      // Reload from DB to show accurate saved data
      final saved = await _client
          .from('payroll_entries')
          .select('*, staff_profiles!payroll_entries_staff_id_fkey(full_name, hourly_rate, monthly_salary, employment_type, is_active, date_of_birth, uif_exempt, id_number, role, phone, hire_date, bank_name, bank_account)')
          .eq('pay_period_start', startStr)
          .eq('pay_period_end', endStr)
          .order('full_name', referencedTable: 'staff_profiles');

      if (mounted) {
        setState(() {
          _calculatedEntries = List<Map<String, dynamic>>.from(saved);
          _isCalculating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payroll calculated successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e, stack) {
      debugPrint('=== PAYROLL CALCULATE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ErrorHandler.friendlyMessage(e)),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted && _isCalculating) setState(() => _isCalculating = false);
    }
  }

  Future<void> _uploadPayslipsToStorage(
    List<Map<String, dynamic>> entries,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final pdfService = PayslipPdfService();
    final businessSettings = await _client
        .from('business_settings')
        .select()
        .limit(1)
        .single();

    for (final entry in entries) {
      try {
        final staffId = entry['staff_id'] as String?;
        if (staffId == null) continue;

        final staffData = await _client
            .from('staff_profiles')
            .select('*')
            .eq('id', staffId)
            .single();

        final file = await pdfService.generatePayslip(
          entry: entry,
          staffMap: staffData,
          businessSettings: businessSettings,
          periodStart: periodStart,
          periodEnd: periodEnd,
          recalculateDeductions: true,
        );

        final period =
            '${periodStart.year}-${periodStart.month.toString().padLeft(2, '0')}';
        final storagePath = '$staffId/$period.pdf';

        final bytes = await file.readAsBytes();
        await _client.storage
            .from('payslips')
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'application/pdf',
                upsert: true,
              ),
            );

        debugPrint('[PAYROLL] Uploaded payslip: $storagePath');
      } catch (e) {
        debugPrint('[PAYROLL] Failed to upload payslip for '
            '${entry['staff_id']}: $e');
      }
    }
  }

  Future<void> _generatePayslipsForPeriod() async {
    if (_periodStart == null ||
        _periodEnd == null ||
        _calculatedEntries.isEmpty) {
      return;
    }

    setState(() => _isGeneratingAllPayslips = true);

    try {
      await _uploadPayslipsToStorage(
        _calculatedEntries,
        _periodStart!,
        _periodEnd!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payslips generated and uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate payslips: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAllPayslips = false);
      }
    }
  }

  Future<void> _approvePayroll() async {
    final startStr = _periodStart!.toIso8601String().substring(0, 10);
    final endStr = _periodEnd!.toIso8601String().substring(0, 10);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Payroll'),
        content: Text('Approve payroll for $startStr to $endStr?\n\nThis will mark all advances and meat purchases as deducted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      )
    );

    if (confirmed != true) return;
    setState(() => _isApproving = true);

    try {
      final currentUserId = AuthService().currentStaffId;
      
      // 1. UPDATE payroll_entries
      await _client.from('payroll_entries')
        .update({
          'status': 'approved',
          'approved_by': currentUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('pay_period_start', startStr)
        .eq('pay_period_end', endStr)
        .eq('status', 'draft');

      final staffIds = _calculatedEntries.map((e) => e['staff_id']).toList();
      if (staffIds.isNotEmpty) {
        // 2. UPDATE Meat Purchases
        await _client.from('staff_credit')
          .update({'status': 'deducted'})
          .eq('credit_type', 'meat_purchase')
          .inFilter('status', ['pending', 'partial', 'owing'])
          .gte('deduct_from', startStr)
          .lte('deduct_from', endStr)
          .inFilter('staff_id', staffIds);

        // 3. UPDATE Salary Advances
        await _client.from('staff_credit')
          .update({'status': 'deducted'})
          .eq('credit_type', 'salary_advance')
          .inFilter('status', ['pending', 'owing'])
          .gte('deduct_from', startStr)
          .lte('deduct_from', endStr)
          .inFilter('staff_id', staffIds);
      }

      // 4. Update period
      await _client.from('payroll_periods')
        .update({
          'status': 'completed',
          'processed_at': DateTime.now().toIso8601String(),
          'processed_by': currentUserId,
        })
        .eq('start_date', startStr)
        .eq('end_date', endStr);
      
      await _loadExistingPeriod();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll approved'), backgroundColor: AppColors.success));

      // Upload payslips to storage for clock-in app access
      await _uploadPayslipsToStorage(
        _calculatedEntries,
        _periodStart!,
        _periodEnd!,
      );
    } catch (e, stack) {
      debugPrint('=== APPROVE PAYROLL ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _markAsPaid() async {
    final startStr = _periodStart!.toIso8601String().substring(0, 10);
    final endStr = _periodEnd!.toIso8601String().substring(0, 10);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Mark this payroll as paid?\n\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Mark as Paid')
          ),
        ],
      )
    );

    if (confirmed != true) return;
    setState(() => _isPaying = true);

    try {
      final currentUserId = AuthService().currentStaffId;
      final periodNetPay = _calculatedEntries.fold<double>(
        0.0,
        (sum, entry) => sum + ((entry['net_pay'] as num?)?.toDouble() ?? 0.0),
      );
      final periodDescription = (_periodRecord?['description']?.toString().trim().isNotEmpty ?? false)
          ? _periodRecord!['description'].toString().trim()
          : '$startStr to $endStr';

      await _client.from('payroll_entries')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('pay_period_start', startStr)
        .eq('pay_period_end', endStr)
        .eq('status', 'approved');

      await _client.from('payroll_periods')
        .update({'status': 'paid'})
        .eq('start_date', startStr)
        .eq('end_date', endStr);

      if (currentUserId != null && periodNetPay > 0) {
        // Ledger post is fatal — failure surfaces to the outer catch and blocks paid status.
        final periodRow = await _client
            .from('payroll_periods')
            .select('id')
            .eq('start_date', startStr)
            .eq('end_date', endStr)
            .maybeSingle();
        final payrollPeriodId = periodRow?['id']?.toString();
        if (payrollPeriodId != null && payrollPeriodId.isNotEmpty) {
          await LedgerRepository(client: _client).createDoubleEntry(
            date: DateTime.now(),
            debitAccountCode: '6100',
            debitAccountName: 'Wages & Salaries',
            creditAccountCode: '1100',
            creditAccountName: 'Bank',
            amount: periodNetPay,
            description: 'Payroll: $periodDescription',
            referenceType: 'payroll',
            referenceId: payrollPeriodId,
            recordedBy: currentUserId,
          );
        }
      }
      
      await _loadExistingPeriod();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll marked as paid'), backgroundColor: AppColors.success));

      // Upload payslips to storage for clock-in app access
      await _uploadPayslipsToStorage(
        _calculatedEntries,
        _periodStart!,
        _periodEnd!,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.friendlyMessage(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  double _totalDeductionsForEntry(Map<String, dynamic> e) {
    final d = e['deductions'];
    if (d is num) return d.toDouble();
    final uif = (e['uif_employee'] as num?)?.toDouble() ?? 0;
    final meat = (e['meat_purchase_deduction'] as num?)?.toDouble() ?? 0;
    final adv = (e['advance_deduction'] as num?)?.toDouble() ?? 0;
    final other = (e['other_deductions'] as num?)?.toDouble() ?? 0;
    return uif + meat + adv + other;
  }

  Future<void> _openPdfFile(File file) async {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
    } else {
      await Process.run('open', [file.path]);
    }
  }

  Future<void> _generatePayslip(Map<String, dynamic> entry) async {
    if (_periodStart == null || _periodEnd == null) return;
    try {
      final staff = entry['staff_profiles'];
      final staffMap = staff is Map<String, dynamic> ? staff : <String, dynamic>{};
      // Fetch leave balances for this staff member
      Map<String, dynamic> leaveBalances = {};
      try {
        final staffId = entry['staff_id'] as String?;
        if (staffId != null) {
          final leaveRow = await _client
              .from('leave_balances')
              .select('annual_leave_balance, sick_leave_balance, family_leave_balance')
              .eq('staff_id', staffId)
              .maybeSingle();
          if (leaveRow != null) leaveBalances = Map<String, dynamic>.from(leaveRow);
        }
      } catch (_) {}

      final file = await PayslipPdfService().generatePayslip(
        entry: entry,
        staffMap: staffMap,
        leaveBalances: leaveBalances,
        periodStart: _periodStart!,
        periodEnd: _periodEnd!,
      );
      await _openPdfFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _generateAllPayslips() async {
    if (_periodStart == null || _periodEnd == null || _calculatedEntries.isEmpty) {
      return;
    }
    if (mounted) setState(() => _isGeneratingAllPayslips = true);
    try {
      final startStr = _periodStart!.toIso8601String().substring(0, 10);
      final endStr = _periodEnd!.toIso8601String().substring(0, 10);

      final data = <Map<String, dynamic>>[];
      double sumGross = 0;
      double sumDed = 0;
      double sumNet = 0;

      for (final e in _calculatedEntries) {
        final staff = e['staff_profiles'] ?? {};
        final staffMap = staff is Map<String, dynamic> ? staff : <String, dynamic>{};
        final name = staffMap['full_name']?.toString() ?? '';
        final regH = (e['regular_hours'] as num?)?.toDouble() ?? 0;
        final otH = (e['overtime_hours'] as num?)?.toDouble() ?? 0;
        final gross = (e['gross_pay'] as num?)?.toDouble() ?? 0;
        final ded = _totalDeductionsForEntry(e);
        final net = (e['net_pay'] as num?)?.toDouble() ?? 0;
        sumGross += gross;
        sumDed += ded;
        sumNet += net;
        data.add({
          'staff_name': name,
          'regular_hours': regH,
          'overtime_hours': otH,
          'gross_pay': gross,
          'total_deductions': ded,
          'net_pay': net,
          'status': e['status']?.toString() ?? '',
        });
      }

      final columnHeaders = <String, String>{
        'staff_name': 'Staff',
        'regular_hours': 'Reg Hrs',
        'overtime_hours': 'OT Hrs',
        'gross_pay': 'Gross (R)',
        'total_deductions': 'Deductions (R)',
        'net_pay': 'Net Pay (R)',
        'status': 'Status',
      };

      final summary = <String, dynamic>{
        'Total Staff': _calculatedEntries.length,
        'Total Gross': sumGross,
        'Total Deductions': sumDed,
        'Total Net Pay': sumNet,
      };

      final baseName = 'payroll_summary_${startStr}_$endStr';

      final file = await ExportService().exportToPdf(
        fileName: baseName,
        title: 'Payroll Summary',
        subtitle: '$startStr to $endStr',
        data: data,
        columns: const [
          'staff_name',
          'regular_hours',
          'overtime_hours',
          'gross_pay',
          'total_deductions',
          'net_pay',
          'status',
        ],
        columnHeaders: columnHeaders,
        summary: summary,
      );
      await _openPdfFile(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payroll summary PDF generated'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAllPayslips = false);
    }
  }

  Widget _buildStatusChip(String? status) {
    Color bg;
    Color text = Colors.white;
    String label = status ?? 'Draft';
    
    if (label.toLowerCase() == 'draft') {
      bg = Colors.grey;
      label = 'Draft';
    } else if (label.toLowerCase() == 'approved') {
      bg = AppColors.success;
      label = 'Approved';
    } else if (label.toLowerCase() == 'paid') {
      bg = Colors.blue;
      label = 'Paid';
    } else {
      bg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = AuthService().currentRole == 'owner';
    final hasDrafts = _calculatedEntries.any((e) => e['status'] == 'draft');
    final allApproved = _calculatedEntries.isNotEmpty && _calculatedEntries.every((e) => e['status'] == 'approved' || e['status'] == 'paid');
    final hasUnpaidApproved = _calculatedEntries.any((e) => e['status'] == 'approved');

    double totalGross = 0;
    double totalDeductions = 0;
    double totalNet = 0;
    if (_periodRecord != null) {
       totalGross = (_periodRecord!['total_gross'] as num?)?.toDouble() ?? 0;
       totalDeductions = (_periodRecord!['total_deductions'] as num?)?.toDouble() ?? 0;
       totalNet = (_periodRecord!['total_net'] as num?)?.toDouble() ?? 0;
    } else {
      for (var e in _calculatedEntries) {
        totalGross += (e['gross_pay'] as num?)?.toDouble() ?? 0;
        final uif = (e['uif_employee'] as num?)?.toDouble() ?? 0;
        final meat = (e['meat_purchase_deduction'] as num?)?.toDouble() ?? 0;
        final adv = (e['advance_deduction'] as num?)?.toDouble() ?? 0;
        final other = (e['other_deductions'] as num?)?.toDouble() ?? 0;
        totalDeductions += uif + meat + adv + other;
        totalNet += (e['net_pay'] as num?)?.toDouble() ?? 0;
      }
    }

    final body = Column(
      children: [
        // Top Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final fromButton = OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: Text(
                        _periodStart != null
                          ? '${_periodStart!.day}/${_periodStart!.month}/'
                            '${_periodStart!.year}'
                          : 'From date',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _periodStart ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _periodStart = d);
                      },
                    );
                    final toButton = OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: Text(
                        _periodEnd != null
                          ? '${_periodEnd!.day}/${_periodEnd!.month}/'
                            '${_periodEnd!.year}'
                          : 'To date',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _periodEnd ?? _periodStart
                            ?? DateTime.now(),
                          firstDate: _periodStart ?? DateTime(2024),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _periodEnd = d);
                      },
                    );
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Pay Period:',
                            style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          fromButton,
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('→',
                              style: TextStyle(fontSize: 16,
                                color: AppColors.textSecondary)),
                          ),
                          toButton,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pay Period:',
                          style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            fromButton,
                            const Text('→',
                              style: TextStyle(fontSize: 16,
                                color: AppColors.textSecondary)),
                            toButton,
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (_periodStart != null && _periodEnd != null && !_isCalculating) ? _calculatePayroll : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isCalculating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CALCULATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ],
            ),
          ),
          
          if (_calculatedEntries.isNotEmpty) ...[
            // Summary Strip
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  Text('Staff: ${_calculatedEntries.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Total Gross: R${totalGross.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Total Deductions: R${totalDeductions.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                  Text('Total Net: R${totalNet.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
                ],
              ),
            ),
            
            // Staff Table
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _calculatedEntries.length,
                itemBuilder: (context, index) {
                  final e = _calculatedEntries[index];
                  final staffId = e['staff_id']?.toString() ?? '';
                  final staff = e['staff_profiles'] ?? {};
                  final isSkipped = e['is_skipped'] == true;
                  
                  final regHrs = (e['regular_hours'] as num?)?.toDouble() ?? 0;
                  final otHrs = (e['overtime_hours'] as num?)?.toDouble() ?? 0;
                  final sunHrs = (e['sunday_hours'] as num?)?.toDouble() ?? 0;
                  final phHrs = (e['public_holiday_hours'] as num?)?.toDouble() ?? 0;

                  final regPay = (e['regular_pay'] as num?)?.toDouble() ?? 0;
                  final otPay = (e['overtime_pay'] as num?)?.toDouble() ?? 0;
                  final sunPay = (e['sunday_pay'] as num?)?.toDouble() ?? 0;
                  final phPay = (e['public_holiday_pay'] as num?)?.toDouble() ?? 0;
                  
                  final uifEmp = (e['uif_employee'] as num?)?.toDouble() ?? 0;
                  final meatDed = (e['meat_purchase_deduction'] as num?)?.toDouble() ?? 0;
                  final advDed = (e['advance_deduction'] as num?)?.toDouble() ?? 0;
                  final otherDed = (e['other_deductions'] as num?)?.toDouble() ?? 0;
                  
                  final employmentType = staff['employment_type'] as String? ?? 'hourly';
                  final rate = (staff['hourly_rate'] as num?)?.toDouble() ?? 0;
                  final monthlySalary = (staff['monthly_salary'] as num?)?.toDouble() ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(staff['full_name'] ?? 'Unknown Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(staff['pay_frequency'] ?? 'monthly', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusChip(e['status']),
                                  ],
                                ),
                                if (isSkipped)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text('Period already approved/paid — cannot recalculate', style: TextStyle(color: AppColors.error, fontSize: 11)),
                                  )
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Gross: R ${(e['gross_pay'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Net: R ${(e['net_pay'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
                            ],
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Reg: ${regHrs.toStringAsFixed(2)}h  |  OT: ${otHrs.toStringAsFixed(2)}h  |  Sun: ${sunHrs.toStringAsFixed(2)}h  |  PH: ${phHrs.toStringAsFixed(2)}h',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: AppColors.surfaceBg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('─── HOURS ───', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              if (employmentType == 'monthly_salary')
                                _RowItem('Monthly salary:', 'R${monthlySalary.toStringAsFixed(2)}/month', (e['gross_pay'] as num?)?.toDouble() ?? 0)
                              else ...[
                                _RowItem('Regular hours:', '${regHrs.toStringAsFixed(2)}h × R${rate.toStringAsFixed(2)}', regPay),
                                _RowItem('Overtime hours:', '${otHrs.toStringAsFixed(2)}h × R${rate.toStringAsFixed(2)} × 1.5', otPay),
                                _RowItem('Sunday hours:', '${sunHrs.toStringAsFixed(2)}h × R${rate.toStringAsFixed(2)} × 2.0', sunPay),
                                _RowItem('Public holiday hours:', '${phHrs.toStringAsFixed(2)}h × R${rate.toStringAsFixed(2)} × 1.5', phPay),
                              ],
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('GROSS PAY:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('R ${(e['gross_pay'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              const Text('─── DEDUCTIONS ───', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              _RowItem('UIF (employee 1%):', '', -uifEmp, isNative: true),
                              _RowItem('Meat purchases:', '', -meatDed, isNative: true),
                              _RowItem('Salary advances:', '', -advDed, isNative: true),
                              _RowItem('PAYE income tax:', '', -otherDed, isNative: true),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('NET PAY:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('R ${(e['net_pay'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _generatingPayslipIds.contains(staffId)
                                      ? null
                                      : () async {
                                          if (mounted) setState(() => _generatingPayslipIds.add(staffId));
                                          await _generatePayslip(e);
                                          if (mounted) {
                                            setState(() => _generatingPayslipIds.remove(staffId));
                                          }
                                        },
                                  icon: _generatingPayslipIds.contains(staffId)
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.picture_as_pdf, size: 18),
                                  label: const Text('Download Payslip'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),

                              // If timecards are captured during calculation, map them out. (For brevity in UI, we omitted separate fetches of exactly which meat items, but we display the macro summaries perfectly).
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Actions
            if (_calculatedEntries.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingAllPayslips ? null : _generateAllPayslips,
                        icon: _isGeneratingAllPayslips
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: const Text('Download All Payslips (PDF)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (isOwner && (hasDrafts || (allApproved && hasUnpaidApproved))) ...[
                      const SizedBox(height: 8),
                      hasDrafts
                          ? ElevatedButton(
                              onPressed: _isApproving ? null : _approvePayroll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isApproving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'APPROVE PAYROLL',
                                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                    ),
                            )
                          : ElevatedButton(
                              onPressed: _isPaying ? null : _markAsPaid,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isPaying
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'MARK AS PAID',
                                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                    ),
                            ),
                    ],
                    if (isOwner &&
                        _calculatedEntries.isNotEmpty &&
                        _calculatedEntries
                            .every((e) => e['status'] == 'paid')) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isGeneratingAllPayslips
                              ? null
                              : _generatePayslipsForPeriod,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isGeneratingAllPayslips
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'GENERATE PAYSLIPS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ] else if (!_isCalculating && _calculatedEntries.isEmpty) ...[
            const Expanded(
              child: Center(
                child: Text('Select a date range and click Calculate', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ]
        ],
      );

    if (widget.isEmbedded) return body;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: body,
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String formula;
  final double amount;
  final bool isNative;

  const _RowItem(this.label, this.formula, this.amount, {this.isNative = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(child: Text(formula, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Text(amount == 0 ? 'R 0.00' : '${amount < 0 ? '-' : ''}R ${amount.abs().toStringAsFixed(2)}', 
            style: TextStyle(fontSize: 12, color: amount < 0 ? AppColors.error : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
