import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'ai_service.dart';

/// OCR service — uses Gemini AI to extract data from supplier invoice
/// photos and PDF files. Replaces the old Google Vision implementation.
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final _aiService = AiService();
  final _imagePicker = ImagePicker();

  // ── Source selection ──────────────────────────────────────────

  /// Pick image from camera and extract invoice data.
  Future<OcrResult> scanFromCamera() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (picked == null) return OcrResult.cancelled();
      final bytes = await picked.readAsBytes();
      final mimeType = _mimeFromPath(picked.path);
      return await _extractFromBytes(bytes, mimeType);
    } catch (e) {
      return OcrResult.error('Camera error: $e');
    }
  }

  /// Pick image or PDF from file system and extract invoice data.
  Future<OcrResult> scanFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return OcrResult.cancelled();
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        // Fallback: read from path
        if (file.path == null) return OcrResult.error('Cannot read file');
        final fileObj = File(file.path!);
        final fileBytes = await fileObj.readAsBytes();
        final mimeType = _mimeFromPath(file.path!);
        return await _extractFromBytes(fileBytes, mimeType);
      }
      final mimeType = _mimeFromExtension(file.extension ?? 'jpg');
      return await _extractFromBytes(bytes, mimeType);
    } catch (e) {
      return OcrResult.error('File error: $e');
    }
  }

  // ── Core extraction ───────────────────────────────────────────

  Future<OcrResult> _extractFromBytes(
      Uint8List bytes, String mimeType) async {
    try {
      final configured = await _aiService.isConfigured();
      if (!configured) {
        return OcrResult.error(
            'Gemini AI not configured — go to Settings → AI to add your API key');
      }

      final list = await _aiService.extractInvoiceData(
        imageBytes: bytes,
        mimeType: mimeType,
      );
      final valid = list.where((e) => !e.containsKey('error')).toList();
      if (valid.isEmpty) {
        final err = list.isNotEmpty ? list.first['error'] : 'no data';
        return OcrResult.error(
            'AI could not read invoice: $err');
      }
      return OcrResult.successMulti(invoices: valid);
    } catch (e) {
      debugPrint('OCR extraction error: $e');
      return OcrResult.error('Extraction failed: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _mimeFromPath(String path) {
    return _mimeFromExtension(path.split('.').last);
  }

  String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

// ── Result types ──────────────────────────────────────────────────

class OcrResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;
  final String? supplierName;
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? dueDate;
  final List<OcrLineItem> lineItems;
  final double? subtotal;
  final double? taxRate;
  final double? taxAmount;
  final double? total;
  final String confidence;
  final Map<String, dynamic> rawData;
  final List<Map<String, dynamic>> invoices;
  final bool isMultiInvoice;

  OcrResult._({
    required this.success,
    required this.cancelled,
    this.errorMessage,
    this.supplierName,
    this.invoiceNumber,
    this.invoiceDate,
    this.dueDate,
    this.lineItems = const [],
    this.subtotal,
    this.taxRate,
    this.taxAmount,
    this.total,
    this.confidence = 'medium',
    this.rawData = const {},
    this.invoices = const [],
    this.isMultiInvoice = false,
  });

  factory OcrResult.success({
    String? supplierName,
    String? invoiceNumber,
    String? invoiceDate,
    String? dueDate,
    List<OcrLineItem> lineItems = const [],
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String confidence = 'medium',
    Map<String, dynamic> rawData = const {},
  }) =>
      OcrResult._(
        success: true,
        cancelled: false,
        supplierName: supplierName,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        lineItems: lineItems,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        total: total,
        confidence: confidence,
        rawData: rawData,
      );

  factory OcrResult.successMulti({
    required List<Map<String, dynamic>> invoices,
  }) {
    final first = invoices.isNotEmpty ? invoices.first : <String, dynamic>{};
    return OcrResult._(
      success: true,
      cancelled: false,
      invoices: invoices,
      isMultiInvoice: invoices.length > 1,
      supplierName: first['supplier_name']?.toString(),
      invoiceNumber: first['invoice_number']?.toString(),
      invoiceDate: first['invoice_date']?.toString(),
      total: (first['grand_total'] as num?)?.toDouble() ?? 0,
      lineItems: (first['line_items'] as List<dynamic>? ?? [])
          .map((e) => OcrLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory OcrResult.cancelled() =>
      OcrResult._(success: false, cancelled: true);

  factory OcrResult.error(String message) =>
      OcrResult._(success: false, cancelled: false, errorMessage: message);

  /// Confidence color: green = high, orange = medium, red = low
  bool get isHighConfidence => confidence == 'high';
  bool get isLowConfidence => confidence == 'low';
}

class OcrLineItem {
  final String description;
  final String? supplierCode;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double lineTotal;
  final double? vatAmount;

  const OcrLineItem({
    required this.description,
    this.supplierCode,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.lineTotal,
    this.vatAmount,
  });

  factory OcrLineItem.fromJson(Map<String, dynamic> json) {
    return OcrLineItem(
      description: json['description']?.toString() ?? '',
      supplierCode: json['supplier_code']?.toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit']?.toString(),
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble(),
    );
  }
}
