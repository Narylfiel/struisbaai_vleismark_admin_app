import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

/// Gemini AI service — reusable for OCR, analysis, forecasting, recommendations.
/// API key stored in flutter_secure_storage, never in code or database.
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyApiKey = 'gemini_api_key';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-001:generateContent';

  final _dio = Dio();

  // ── Key management ────────────────────────────────────────────

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _keyApiKey, value: key.trim());
  }

  Future<String?> loadApiKey() async {
    return _storage.read(key: _keyApiKey);
  }

  Future<bool> isConfigured() async {
    final key = await loadApiKey();
    return key != null && key.isNotEmpty;
  }

  // ── Core request ─────────────────────────────────────────────

  /// Send a text prompt to Gemini. Returns the response text.
  Future<String> prompt(String text) async {
    final apiKey = await loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not configured — go to Settings → AI');
    }

    final response = await _dio.post(
      '$_baseUrl?key=$apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'contents': [
          {
            'parts': [
              {'text': text}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
        },
      },
    );

    if (response.statusCode == 200) {
      return _extractText(response.data);
    }
    throw Exception('Gemini error ${response.statusCode}: ${response.data}');
  }

  /// Send an image + prompt to Gemini Vision.
  /// [imageFile] is the image file to analyse.
  /// [promptText] is the instruction.
  Future<String> promptWithImage({
    required File imageFile,
    required String promptText,
  }) async {
    final apiKey = await loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not configured — go to Settings → AI');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _mimeType(imageFile.path);

    final response = await _dio.post(
      '$_baseUrl?key=$apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'contents': [
          {
            'parts': [
              {'text': promptText},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
        },
      },
    );

    if (response.statusCode == 200) {
      return _extractText(response.data);
    }
    throw Exception('Gemini error ${response.statusCode}: ${response.data}');
  }

  /// Send bytes + prompt (for in-memory images or converted PDFs).
  Future<String> promptWithBytes({
    required Uint8List bytes,
    required String mimeType,
    required String promptText,
  }) async {
    final apiKey = await loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not configured — go to Settings → AI');
    }

    final base64Data = base64Encode(bytes);

    final response = await _dio.post(
      '$_baseUrl?key=$apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'contents': [
          {
            'parts': [
              {'text': promptText},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Data,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
        },
      },
    );

    if (response.statusCode == 200) {
      return _extractText(response.data);
    }
    throw Exception('Gemini error ${response.statusCode}: ${response.data}');
  }

  // ── Supplier invoice OCR ──────────────────────────────────────

  /// Extract supplier invoice data from an image or PDF page.
  /// Returns structured JSON with supplier, invoice number, date,
  /// line items, subtotal, tax, total.
  Future<Map<String, dynamic>> extractInvoiceData({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    const invoicePrompt = '''
You are an invoice data extraction assistant for a South African butchery.
Extract all data from this supplier invoice image and return ONLY a JSON object.
No explanation, no markdown, no code blocks — raw JSON only.

Required JSON structure:
{
  "supplier_name": "string or null",
  "invoice_number": "string or null",
  "invoice_date": "YYYY-MM-DD or null",
  "due_date": "YYYY-MM-DD or null",
  "line_items": [
    {
      "description": "string",
      "supplier_code": "string or null",
      "quantity": number,
      "unit": "string or null",
      "unit_price": number,
      "line_total": number
    }
  ],
  "subtotal": number or null,
  "tax_rate": number or null,
  "tax_amount": number or null,
  "total": number or null,
  "currency": "ZAR",
  "confidence": "high|medium|low"
}

Rules:
- All amounts in numeric format, no currency symbols
- Dates in YYYY-MM-DD format
- If a field is not found, use null
- confidence: high = all fields found clearly, medium = some fields unclear, low = poor quality image
- South African VAT is 15% — if you see VAT use 15 as tax_rate
- supplier_code is the supplier's own product/item code if visible
''';

    final result = await promptWithBytes(
      bytes: imageBytes,
      mimeType: mimeType,
      promptText: invoicePrompt,
    );

    return _parseJsonResponse(result);
  }

  // ── Smart analysis ────────────────────────────────────────────

  /// Ask Gemini to analyse stock and suggest reorder quantities.
  Future<String> analyseReorderNeeds({
    required List<Map<String, dynamic>> stockData,
    String? upcomingEvent,
  }) async {
    final context = upcomingEvent != null
        ? 'There is an upcoming event: $upcomingEvent. '
        : '';
    final stockJson = jsonEncode(stockData);
    return prompt(
      '${context}You are a stock management assistant for a South African butchery. '
      'Based on this current stock data, suggest reorder quantities and flag any urgent items. '
      'Be concise and practical. Stock data: $stockJson',
    );
  }

  /// Ask Gemini to suggest sell prices based on cost prices and target margin.
  Future<String> suggestPricing({
    required List<Map<String, dynamic>> products,
    required double targetMarginPct,
  }) async {
    final json = jsonEncode(products);
    return prompt(
      'You are a pricing assistant for a South African butchery. '
      'Target gross margin is $targetMarginPct%. '
      'Suggest sell prices for these products, considering the local market. '
      'Return a concise table with product name, cost, suggested price, margin%. '
      'Products: $json',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _extractText(dynamic data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';
      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';
      return parts[0]['text']?.toString() ?? '';
    } catch (e) {
      debugPrint('Gemini response parse error: $e');
      return '';
    }
  }

  Map<String, dynamic> _parseJsonResponse(String raw) {
    try {
      String cleaned = raw.trim();
      // Strip markdown code blocks (```json ... ``` or ``` ... ```)
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('```');
        final afterStart = cleaned.substring(start + 3).trimLeft();
        final langEnd = afterStart.startsWith('json')
            ? 4
            : afterStart.startsWith('JSON')
                ? 4
                : 0;
        cleaned = (langEnd > 0 ? afterStart.substring(langEnd) : afterStart)
            .trimLeft();
        final endBlock = cleaned.indexOf('```');
        if (endBlock >= 0) cleaned = cleaned.substring(0, endBlock).trim();
      }
      // Remove leading/trailing whitespace and newlines
      cleaned = cleaned.trim();
      // If response has text before/after JSON, try to extract first { ... }
      if (!cleaned.startsWith('{')) {
        final start = cleaned.indexOf('{');
        if (start >= 0) {
          int depth = 0;
          int end = -1;
          for (int i = start; i < cleaned.length; i++) {
            if (cleaned[i] == '{') depth++;
            if (cleaned[i] == '}') {
              depth--;
              if (depth == 0) {
                end = i;
                break;
              }
            }
          }
          if (end >= 0) cleaned = cleaned.substring(start, end + 1);
        }
      }
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON parse error: $e\nRaw: $raw');
      return {'error': 'Could not parse response', 'raw': raw};
    }
  }

  String _mimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
