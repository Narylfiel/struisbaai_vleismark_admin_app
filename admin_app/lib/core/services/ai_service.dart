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
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

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

    try {
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
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? '';
      throw Exception('Gemini $status: $body');
    } catch (e) {
      throw Exception('Gemini error: $e');
    }
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
          'maxOutputTokens': 8192,
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
          'maxOutputTokens': 8192,
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
  /// Returns a list — normally one invoice, but may return multiple
  /// if the PDF contained more than one invoice on the same page.
  Future<List<Map<String, dynamic>>> extractInvoiceData({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    const invoicePrompt = '''
You are an invoice data extraction assistant for a South African butchery.
Extract all invoice data from this document and return ONLY valid JSON.
No explanation, no markdown, no code blocks — raw JSON only.

IMPORTANT: If the document contains MORE THAN ONE invoice, return a JSON ARRAY
of invoice objects. If it contains exactly one invoice, you may return either
a single JSON object or a single-element array — both are accepted.

Each invoice object must have this structure:
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

    return _parseInvoiceResponse(result);
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

  /// Parse Gemini invoice response — handles single object, array,
  /// or concatenated JSON objects (multiple invoices in one PDF).
  /// Always returns a list; never throws.
  List<Map<String, dynamic>> _parseInvoiceResponse(String raw) {
    try {
      String cleaned = raw.trim();
      // Strip markdown fences
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```json?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      // Try parsing as-is first
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (decoded is Map<String, dynamic>) {
        return [decoded];
      }
    } catch (_) {
      // Fall through to multi-object split attempt
    }

    // Gemini may return two JSON objects concatenated: {...}{...}
    // Split by finding top-level object boundaries
    final objects = _splitTopLevelObjects(raw);
    if (objects.isNotEmpty) {
      debugPrint('_parseInvoiceResponse: split into '
          '${objects.length} JSON object(s)');
      return objects;
    }

    debugPrint('_parseInvoiceResponse: all parsing failed\nRaw: $raw');
    return [
      {'error': 'Could not parse response', 'raw': raw}
    ];
  }

  /// Split a string that may contain multiple concatenated top-level
  /// JSON objects (e.g. "{...}{...}") into individual parsed maps.
  List<Map<String, dynamic>> _splitTopLevelObjects(String raw) {
    final results = <Map<String, dynamic>>[];
    int depth = 0;
    int start = -1;
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (escape) { escape = false; continue; }
      if (c == '\\') { escape = true; continue; }
      if (c == '"') { inString = !inString; continue; }
      if (inString) continue;

      if (c == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0 && start >= 0) {
          final fragment = raw.substring(start, i + 1);
          try {
            final obj = jsonDecode(fragment) as Map<String, dynamic>;
            results.add(obj);
          } catch (_) {
            // Skip malformed fragment
          }
          start = -1;
        }
      }
    }
    return results;
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
