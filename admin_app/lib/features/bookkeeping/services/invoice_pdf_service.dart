import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Generates SA-legal VAT invoices as PDF bytes.
/// Complies with SARS VAT Act requirements:
/// - Supplier name, address, VAT number
/// - Customer name, address, VAT number (if VAT vendor)
/// - Unique invoice number
/// - Invoice date
/// - Description, quantity, unit price per line
/// - VAT rate, VAT amount, subtotal, total
class InvoicePdfService {
  static final InvoicePdfService _instance = InvoicePdfService._internal();
  factory InvoicePdfService() => _instance;
  InvoicePdfService._internal();

  final SupabaseClient _client = SupabaseService.client;

  static final PdfColor _primary   = PdfColor.fromHex('#1E3A5F');
  static final PdfColor _lightGrey = PdfColor.fromHex('#F5F5F5');
  static final PdfColor _border    = PdfColor.fromHex('#DDDDDD');
  static final PdfColor _textDark  = PdfColor.fromHex('#222222');
  static final PdfColor _textGrey  = PdfColor.fromHex('#666666');

  /// Generates PDF bytes for a customer invoice.
  /// Fetches business settings and account details from Supabase.
  Future<Uint8List> generateCustomerInvoice(
      Map<String, dynamic> invoice) async {
    // Load business settings
    Map<String, dynamic> biz = {};
    try {
      final row = await _client
          .from('business_settings')
          .select()
          .limit(1)
          .single();
      biz = Map<String, dynamic>.from(row);
    } catch (_) {}

    // Load account details
    Map<String, dynamic> account = {};
    final accountId = invoice['account_id']?.toString();
    if (accountId != null && accountId.isNotEmpty) {
      try {
        final row = await _client
            .from('business_accounts')
            .select()
            .eq('id', accountId)
            .maybeSingle();
        if (row != null) account = Map<String, dynamic>.from(row);
      } catch (_) {}
    }

    return _buildPdf(invoice, biz, account);
  }

  Future<Uint8List> _buildPdf(
    Map<String, dynamic> invoice,
    Map<String, dynamic> biz,
    Map<String, dynamic> account,
  ) async {
    final pdf = pw.Document();

    // Invoice data
    final invoiceNumber = invoice['invoice_number']?.toString() ?? '—';
    final invoiceDate   = _formatDate(invoice['invoice_date']?.toString());
    final dueDate       = _formatDate(invoice['due_date']?.toString());
    final subtotal      = (invoice['subtotal'] as num?)?.toDouble() ?? 0;
    final taxAmount     = (invoice['tax_amount'] as num?)?.toDouble() ?? 0;
    final total         = (invoice['total'] as num?)?.toDouble() ?? 0;
    final taxRate       = (invoice['tax_rate'] as num?)?.toDouble() ?? 15.0;
    final notes         = invoice['notes']?.toString();

    // Line items
    final rawItems = invoice['line_items'];
    final lineItems = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) lineItems.add(Map<String, dynamic>.from(e));
      }
    }

    // Business details
    final bizName    = biz['business_name']?.toString() ?? 'Struisbaai Vleismark';
    final bizAddress = biz['address']?.toString() ?? 'Unit 6b Struisbaai Business Centre, Malvern Drive';
    final bizVat     = biz['vat_number']?.toString() ?? '';
    final bizPhone   = biz['phone']?.toString() ?? '082 696 2940';
    const bizEmail   = 'leon@struisbaai-slaghuis.co.za';

    // Account details
    final accName    = account['name']?.toString() ?? invoice['account_name']?.toString() ?? '—';
    final accAddress = account['address']?.toString() ?? '';
    final accVat     = account['vat_number']?.toString() ?? '';
    final accEmail   = account['email']?.toString() ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // ── Header ─────────────────────────────────────────────
          pw.Container(
            color: _primary,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(bizName,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(bizAddress,
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 10)),
                    if (bizPhone.isNotEmpty)
                      pw.Text('Tel: $bizPhone',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    if (bizEmail.isNotEmpty)
                      pw.Text(bizEmail,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    if (bizVat.isNotEmpty)
                      pw.Text('VAT Reg: $bizVat',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice #: $invoiceNumber',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 11)),
                    pw.Text('Date: $invoiceDate',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 10)),
                    pw.Text('Due: $dueDate',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Bill To ─────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _lightGrey,
                    border: pw.Border.all(color: _border),
                    borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _textGrey,
                              letterSpacing: 1)),
                      pw.SizedBox(height: 6),
                      pw.Text(accName,
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _textDark)),
                      if (accAddress.isNotEmpty)
                        pw.Text(accAddress,
                            style: pw.TextStyle(
                                fontSize: 10, color: _textGrey)),
                      if (accEmail.isNotEmpty)
                        pw.Text(accEmail,
                            style: pw.TextStyle(
                                fontSize: 10, color: _textGrey)),
                      if (accVat.isNotEmpty)
                        pw.Text('VAT Reg: $accVat',
                            style: pw.TextStyle(
                                fontSize: 10, color: _textGrey)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── Line items table ────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: _border, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FixedColumnWidth(60),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(80),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _primary),
                children: [
                  _tableHeader('DESCRIPTION'),
                  _tableHeader('QTY', align: pw.TextAlign.center),
                  _tableHeader('UNIT PRICE', align: pw.TextAlign.right),
                  _tableHeader('AMOUNT', align: pw.TextAlign.right),
                ],
              ),
              // Data rows
              ...lineItems.map((item) {
                final desc     = item['description']?.toString() ?? '—';
                final qty      = (item['quantity'] as num?)?.toDouble() ?? 0;
                final price    = (item['unit_price'] as num?)?.toDouble() ?? 0;
                final lineTotal = (item['line_total'] as num?)?.toDouble() ??
                    (qty * price);
                return pw.TableRow(
                  children: [
                    _tableCell(desc),
                    _tableCell(_fmt(qty, decimals: 3),
                        align: pw.TextAlign.center),
                    _tableCell('R ${_fmt(price)}',
                        align: pw.TextAlign.right),
                    _tableCell('R ${_fmt(lineTotal)}',
                        align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── Totals ──────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 240,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal (excl. VAT)',
                        'R ${_fmt(subtotal)}'),
                    _totalRow(
                        'VAT (${taxRate.toStringAsFixed(0)}%)',
                        'R ${_fmt(taxAmount)}'),
                    pw.Container(
                      color: _primary,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL DUE',
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13)),
                          pw.Text('R ${_fmt(total)}',
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (notes != null && notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _lightGrey,
                border: pw.Border.all(color: _border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Notes',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: _textGrey)),
                  pw.SizedBox(height: 4),
                  pw.Text(notes,
                      style:
                          pw.TextStyle(fontSize: 10, color: _textDark)),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 24),

          // ── Footer ──────────────────────────────────────────────
          pw.Divider(color: _border),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'This is a valid tax invoice in terms of the Value-Added Tax Act 89 of 1991.',
                  style: pw.TextStyle(
                      fontSize: 9, color: _textGrey),
                  textAlign: pw.TextAlign.center,
                ),
                if (bizVat.isNotEmpty)
                  pw.Text(
                    'VAT Registration Number: $bizVat',
                    style: pw.TextStyle(
                        fontSize: 9, color: _textGrey),
                    textAlign: pw.TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ─────────────────────────────────────────────────────

  pw.Widget _tableHeader(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            letterSpacing: 0.5),
        textAlign: align,
      ),
    );
  }

  pw.Widget _tableCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, color: _textDark),
        textAlign: align,
      ),
    );
  }

  pw.Widget _totalRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: _textGrey)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, color: _textDark)),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return raw;
    }
  }

  String _fmt(double v, {int decimals = 2}) =>
      v.toStringAsFixed(decimals);
}
