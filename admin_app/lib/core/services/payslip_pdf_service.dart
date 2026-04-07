import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:admin_app/core/services/supabase_service.dart';

class PayslipPdfService {
  Future<File> generatePayslip({
    required Map<String, dynamic> entry,
    required Map<String, dynamic> staffMap,
    Map<String, dynamic>? businessSettings,
    Map<String, dynamic>? leaveBalances,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final fetchedBusiness = await _fetchBusinessSettings();
    final biz = <String, dynamic>{
      ...fetchedBusiness,
      ...?businessSettings,
    };

    final annualLeave = (leaveBalances?['annual_leave_balance'] as num?)?.toDouble() ?? 0;
    final sickLeave = (leaveBalances?['sick_leave_balance'] as num?)?.toDouble() ?? 0;
    final familyLeave = (leaveBalances?['family_leave_balance'] as num?)?.toDouble() ?? 0;

    final fullName = _string(staffMap['full_name'], fallback: 'Unknown Employee');
    final idNumber = _string(staffMap['id_number']);
    final role = _string(staffMap['role']);
    final phone = _string(staffMap['phone']);
    final employmentType = _string(staffMap['employment_type']);
    final payFrequency = _string(entry['pay_frequency'], fallback: _string(staffMap['pay_frequency']));
    final hireDate = _dateString(staffMap['hire_date']);
    final bankName = _string(staffMap['bank_name']);
    final bankAccount = _maskBankAccount(_string(staffMap['bank_account']));

    final hourlyRate = _num(staffMap['hourly_rate']);
    final monthlySalary = _num(staffMap['monthly_salary']);
    final isSalaried = employmentType == 'monthly_salary';

    final regularHours = _num(entry['regular_hours']);
    final overtimeHours = _num(entry['overtime_hours']);
    final sundayHours = _num(entry['sunday_hours']);
    final publicHolidayHours = _num(entry['public_holiday_hours']);

    final regularPay = _num(entry['regular_pay']);
    final overtimePay = _num(entry['overtime_pay']);
    final sundayPay = _num(entry['sunday_pay']);
    final publicHolidayPay = _num(entry['public_holiday_pay']);
    final grossPay = _num(entry['gross_pay']);

    final uifEmployee = _num(entry['uif_employee']);
    final uifEmployer = _num(entry['uif_employer']);
    final meatDeduction = _num(entry['meat_purchase_deduction']);
    final advanceDeduction = _num(entry['advance_deduction']);
    final otherDeductions = _num(entry['other_deductions']);
    final totalDeductions = uifEmployee + meatDeduction + advanceDeduction + otherDeductions;
    final netPay = _num(entry['net_pay']);

    final status = _string(entry['status'], fallback: 'draft');
    final payDate = _dateString(entry['paid_at'], fallback: _fmtDate(periodEnd));
    final payPeriod = '${_fmtDate(periodStart)} to ${_fmtDate(periodEnd)}';

    final earningsRows = isSalaried
        ? <_EarningRow>[
            _EarningRow(
              description: 'Monthly Salary',
              hours: 0,
              rate: 0,
              amount: monthlySalary > 0 ? monthlySalary : grossPay,
            ),
          ]
        : <_EarningRow>[
            _EarningRow(
              description: 'Regular Pay',
              hours: regularHours,
              rate: hourlyRate,
              amount: regularPay,
            ),
            _EarningRow(
              description: 'Overtime (x1.5)',
              hours: overtimeHours,
              rate: hourlyRate * 1.5,
              amount: overtimePay,
            ),
            _EarningRow(
              description: 'Sunday (x2.0)',
              hours: sundayHours,
              rate: hourlyRate * 2.0,
              amount: sundayPay,
            ),
            _EarningRow(
              description: 'Public Holiday',
              hours: publicHolidayHours,
              rate: hourlyRate * 1.5,
              amount: publicHolidayPay,
            ),
          ].where((r) => r.hours > 0 || r.amount > 0).toList();

    final deductionRows = <_DeductionRow>[
      _DeductionRow(description: 'UIF (Employee 1%)', amount: uifEmployee),
      _DeductionRow(description: 'Meat Purchases', amount: meatDeduction),
      _DeductionRow(description: 'Salary Advance', amount: advanceDeduction),
      _DeductionRow(description: 'PAYE Income Tax', amount: otherDeductions),
    ].where((r) => r.amount > 0).toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _header(
            businessName: _string(biz['business_name'], fallback: 'Business'),
            address: _string(biz['address']),
            phone: _string(biz['phone']),
            email: _string(biz['email']),
            vatNumber: _string(biz['vat_number']),
            payPeriod: payPeriod,
            payDate: payDate,
            status: status,
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Employee Details'),
          _employeeDetails(
            fullName: fullName,
            idNumber: idNumber,
            role: role,
            phone: phone,
            employmentType: employmentType,
            payFrequency: payFrequency,
            hireDate: hireDate,
            bankName: bankName,
            bankAccount: bankAccount,
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Earnings'),
          _earningsTable(earningsRows, grossPay, isSalaried: isSalaried),
          pw.SizedBox(height: 14),
          _sectionTitle('Deductions'),
          _deductionsTable(deductionRows, totalDeductions),
          pw.SizedBox(height: 14),
          _netPayBox(netPay),
          pw.SizedBox(height: 14),
          _sectionTitle('Employer Contributions'),
          _employerContrib(uifEmployer),
          pw.SizedBox(height: 14),
          _sectionTitle('Leave Balances'),
          _leaveTable(annualLeave, sickLeave, familyLeave),
          pw.SizedBox(height: 14),
          _legalFooter(),
        ],
      ),
    );

    final fileName = 'payslip_${_safeFileSegment(fullName)}_${_fmtFileDate(periodStart)}_${_fmtFileDate(periodEnd)}.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<Map<String, dynamic>> _fetchBusinessSettings() async {
    try {
      final row = await SupabaseService.client
          .from('business_settings')
          .select('business_name, address, phone, email, vat_number')
          .order('created_at', ascending: true)
          .limit(1)
          .single();
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  pw.Widget _header({
    required String businessName,
    required String address,
    required String phone,
    required String email,
    required String vatNumber,
    required String payPeriod,
    required String payDate,
    required String status,
  }) {
    final badgeColor = _statusColor(status);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(businessName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
              if (phone.isNotEmpty) pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10)),
              if (email.isNotEmpty) pw.Text('Email: $email', style: const pw.TextStyle(fontSize: 10)),
              if (vatNumber.isNotEmpty) pw.Text('VAT: $vatNumber', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('PAYSLIP', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Pay Period: $payPeriod', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Pay Date: $payDate', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(color: badgeColor, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Text(
                status.toUpperCase(),
                style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: PdfColors.grey200,
      child: pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _employeeDetails({
    required String fullName,
    required String idNumber,
    required String role,
    required String phone,
    required String employmentType,
    required String payFrequency,
    required String hireDate,
    required String bankName,
    required String bankAccount,
  }) {
    pw.Widget row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 78,
                child: pw.Text('$label:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 9))),
            ],
          ),
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                row('Employee Name', fullName),
                row('ID Number', idNumber),
                row('Job Title', role),
                row('Phone', phone),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                row('Employment Type', employmentType),
                row('Pay Frequency', payFrequency),
                row('Hire Date', hireDate),
                row('Bank', [bankName, bankAccount].where((e) => e.isNotEmpty).join(' | ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _earningsTable(List<_EarningRow> rows, double grossPay, {bool isSalaried = false}) {
    final headers = isSalaried
        ? ['Description', 'Amount (R)']
        : ['Description', 'Hours', 'Rate (R/hr)', 'Amount (R)'];

    final body = rows.map((r) {
      if (isSalaried) {
        return <pw.Widget>[
          _tableCell(r.description),
          _tableCell(_fmtMoney(r.amount), right: true),
        ];
      }
      return <pw.Widget>[
        _tableCell(r.description),
        _tableCell(r.hours > 0 ? _fmtHours(r.hours) : '', right: true),
        _tableCell(r.rate > 0 ? _fmtMoney(r.rate) : '', right: true),
        _tableCell(_fmtMoney(r.amount), right: true),
      ];
    }).toList();

    if (isSalaried) {
      body.add([
        _tableCell('GROSS PAY', bold: true),
        _tableCell(_fmtMoney(grossPay), right: true, bold: true),
      ]);
    } else {
      body.add([
        _tableCell('GROSS PAY', bold: true),
        _tableCell('', right: true),
        _tableCell('', right: true),
        _tableCell(_fmtMoney(grossPay), right: true, bold: true),
      ]);
    }

    return _table(
      headers: headers,
      rows: body,
      highlightLast: true,
    );
  }

  pw.Widget _deductionsTable(List<_DeductionRow> rows, double totalDeductions) {
    final body = rows.map((r) {
      return <pw.Widget>[
        _tableCell(r.description),
        _tableCell(_fmtMoney(r.amount), right: true),
      ];
    }).toList();

    body.add([
      _tableCell('TOTAL DEDUCTIONS', bold: true, color: PdfColors.red800),
      _tableCell(_fmtMoney(totalDeductions), right: true, bold: true, color: PdfColors.red800),
    ]);

    return _table(
      headers: const ['Description', 'Amount (R)'],
      rows: body,
      highlightLast: true,
    );
  }

  pw.Widget _netPayBox(double netPay) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: PdfColors.blueGrey900,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('NET PAY', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(_fmtMoney(netPay), style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _employerContrib(double uifEmployer) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('UIF Employer Contribution (1%): ${_fmtMoney(uifEmployer)}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 3),
          pw.Text(
            'This amount is paid by the employer and not deducted from your pay',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _leaveTable(double annual, double sick, double family) {
    final rows = [
      ['Annual Leave', '${annual.toStringAsFixed(1)} days'],
      ['Sick Leave', '${sick.toStringAsFixed(1)} days'],
      ['Family Responsibility Leave', '${family.toStringAsFixed(1)} days'],
    ];

    final body = rows.map((r) => <pw.Widget>[
      _tableCell(r[0]),
      _tableCell(r[1], right: true),
    ]).toList();

    return _table(
      headers: const ['Leave Type', 'Balance (Days)'],
      rows: body,
    );
  }

  pw.Widget _legalFooter() {
    return pw.Text(
      'This payslip is issued in accordance with the Basic Conditions of Employment Act (BCEA) '
      'No. 75 of 1997 and the Unemployment Insurance Act No. 63 of 2001. '
      'UIF contributions are submitted to the Department of Labour.',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<pw.Widget>> rows,
    bool highlightLast = false,
  }) {
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: headers.map((h) => _tableCell(h, bold: true)).toList(),
      ),
    ];

    for (var i = 0; i < rows.length; i++) {
      final isLast = highlightLast && i == rows.length - 1;
      tableRows.add(
        pw.TableRow(
          decoration: isLast ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
          children: rows[i],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: tableRows,
    );
  }

  pw.Widget _tableCell(
    String value, {
    bool right = false,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        value,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  String _string(dynamic value, {String fallback = ''}) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _dateString(dynamic raw, {String fallback = '—'}) {
    if (raw == null) return fallback;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return _fmtDate(parsed);
  }

  String _fmtMoney(double amount) => 'R ${amount.toStringAsFixed(2)}';
  String _fmtHours(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

  String _fmtFileDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  String _safeFileSegment(String s) =>
      s.replaceAll(RegExp(r'[^\w\-\s]'), '').trim().replaceAll(RegExp(r'\s+'), '_');

  String _maskBankAccount(String account) {
    if (account.isEmpty) return '';
    final digits = account.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 4) return '****$digits';
    return '****${digits.substring(digits.length - 4)}';
  }

  PdfColor _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'paid') return PdfColors.blue700;
    if (s == 'approved') return PdfColors.green700;
    if (s == 'draft') return PdfColors.grey700;
    return PdfColors.grey700;
  }
}

class _EarningRow {
  final String description;
  final double hours;
  final double rate;
  final double amount;

  const _EarningRow({
    required this.description,
    required this.hours,
    required this.rate,
    required this.amount,
  });
}

class _DeductionRow {
  final String description;
  final double amount;

  const _DeductionRow({
    required this.description,
    required this.amount,
  });
}
