import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'base_service.dart';
import '../utils/app_constants.dart';

/// OCR service for processing receipts and invoices using Google Cloud Vision API
class OcrService extends BaseService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final String _apiKey = ''; // TODO: Add Google Cloud Vision API key
  final String _apiUrl = 'https://vision.googleapis.com/v1/images:annotate';

  /// Process image for OCR with retry logic
  Future<String> processImageForText(File imageFile) async {
    if (!await isOnline()) {
      throw Exception('OCR requires an active internet connection. Please try again later.');
    }

    int attempts = 0;
    while (attempts < 3) {
      try {
        // Convert image to base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Prepare request
        final request = {
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION', 'maxResults': 1}
              ],
            }
          ]
        };

        // Make API call
        final response = await http.post(
          Uri.parse('$_apiUrl?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return _extractTextFromResponse(data);
        } else {
          throw Exception('OCR API error: ${response.statusCode}');
        }
      } catch (e) {
        attempts++;
        print('⚠️ OCR attempt $attempts failed: $e');
        if (attempts >= 3) {
          throw Exception('Failed to process image after 3 attempts: $e');
        }
        await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
      }
    }
    throw Exception('Failed to process image');
  }

  /// Process receipt/invoice from camera
  Future<Map<String, dynamic>?> processReceiptFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) return null;

      final file = File(image.path);
      final extractedText = await processImageForText(file);

      return await _parseReceiptText(extractedText);
    } catch (e) {
      throw Exception('Failed to process receipt: $e');
    }
  }

  /// Process receipt/invoice from gallery
  Future<Map<String, dynamic>?> processReceiptFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      final file = File(image.path);
      final extractedText = await processImageForText(file);

      return await _parseReceiptText(extractedText);
    } catch (e) {
      throw Exception('Failed to process receipt: $e');
    }
  }

  /// Parse extracted text to extract receipt data
  Future<Map<String, dynamic>?> _parseReceiptText(String text) async {
    try {
      // Basic text parsing - in production, this would use more sophisticated NLP
      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

      // Extract vendor name (usually first line or prominent text)
      String vendorName = _extractVendorName(lines);

      // Extract total amount
      double? totalAmount = _extractTotalAmount(lines);

      // Extract date
      DateTime? date = _extractDate(lines);

      // Extract items (basic implementation)
      List<Map<String, dynamic>> items = _extractItems(lines);

      if (vendorName.isEmpty && totalAmount == null) {
        return null; // Not enough data extracted
      }

      return {
        'vendor_name': vendorName,
        'total_amount': totalAmount,
        'date': date?.toIso8601String(),
        'items': items,
        'raw_text': text,
        'confidence': _calculateConfidence(vendorName, totalAmount, items),
      };
    } catch (e) {
      print('Error parsing receipt text: $e');
      return null;
    }
  }

  /// Extract vendor/supplier name from text
  String _extractVendorName(List<String> lines) {
    // Look for common vendor patterns
    final vendorPatterns = [
      RegExp(r'^(.*?(MARKET|STORE|SUPER|WHOLESALE|MEAT|FRESH|BUTCHERY).*)', caseSensitive: false),
      RegExp(r'^(.*?(PTY|LTD|INC|CO).*)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in vendorPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1)?.trim() ?? '';
        }
      }
    }

    // Fallback: first non-empty line that's not a date or total
    for (final line in lines) {
      if (!_isDateLine(line) && !_isTotalLine(line) && line.length > 3) {
        return line;
      }
    }

    return '';
  }

  /// Extract total amount from text
  double? _extractTotalAmount(List<String> lines) {
    final totalPatterns = [
      RegExp(r'TOTAL[:\s]*R?(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'AMOUNT[:\s]*R?(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'R?\s*(\d+[.,]\d{2})\s*$'), // Amount at end of line
    ];

    for (final line in lines) {
      for (final pattern in totalPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '.') ?? '0';
          return double.tryParse(amountStr);
        }
      }
    }

    return null;
  }

  /// Extract date from text
  DateTime? _extractDate(List<String> lines) {
    final datePatterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'), // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (match.groupCount == 3) {
              final part1 = int.parse(match.group(1)!);
              final part2 = int.parse(match.group(2)!);
              final part3 = int.parse(match.group(3)!);

              // Assume DD/MM/YYYY format
              if (part1 <= 31 && part2 <= 12 && part3 >= 2000) {
                return DateTime(part3, part2, part1);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    return null;
  }

  /// Extract items from receipt (basic implementation)
  List<Map<String, dynamic>> _extractItems(List<String> lines) {
    final items = <Map<String, dynamic>>[];

    // Look for lines that might be items (contain quantity and price)
    final itemPattern = RegExp(r'(.+?)\s+(\d+(?:\.\d+)?)\s*[xX]\s*R?(\d+(?:[.,]\d{2})?)');

    for (final line in lines) {
      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final quantity = double.tryParse(match.group(2) ?? '0') ?? 0;
        final priceStr = match.group(3)?.replaceAll(',', '.') ?? '0';
        final unitPrice = double.tryParse(priceStr) ?? 0;

        if (name.isNotEmpty && quantity > 0 && unitPrice > 0) {
          items.add({
            'name': name,
            'quantity': quantity,
            'unit_price': unitPrice,
            'line_total': quantity * unitPrice,
          });
        }
      }
    }

    return items;
  }

  /// Extract text from Google Vision API response
  String _extractTextFromResponse(Map<String, dynamic> response) {
    try {
      final responses = response['responses'] as List?;
      if (responses != null && responses.isNotEmpty) {
        final textAnnotations = responses[0]['textAnnotations'] as List?;
        if (textAnnotations != null && textAnnotations.isNotEmpty) {
          return textAnnotations[0]['description'] ?? '';
        }
      }
      return '';
    } catch (e) {
      throw Exception('Failed to extract text from API response: $e');
    }
  }

  /// Calculate confidence score for extracted data
  double _calculateConfidence(String vendorName, double? totalAmount, List<Map<String, dynamic>> items) {
    double confidence = 0;

    if (vendorName.isNotEmpty) confidence += 0.4;
    if (totalAmount != null) confidence += 0.4;
    if (items.isNotEmpty) confidence += 0.2;

    return confidence;
  }

  /// Check if line appears to be a date
  bool _isDateLine(String line) {
    return RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{4}').hasMatch(line) ||
           RegExp(r'\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)', caseSensitive: false).hasMatch(line);
  }

  /// Check if line appears to contain a total
  bool _isTotalLine(String line) {
    return RegExp(r'TOTAL|AMOUNT|SUM', caseSensitive: false).hasMatch(line);
  }

  /// Validate API key is configured
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Get OCR processing status
  Future<Map<String, dynamic>> getProcessingStatus() async {
    return {
      'is_configured': isConfigured,
      'api_available': await _testApiConnection(),
      'last_used': DateTime.now().toIso8601String(), // Would track actual usage
    };
  }

  /// Test API connection
  Future<bool> _testApiConnection() async {
    if (!isConfigured) return false;

    try {
      // Simple test request
      final response = await http.get(Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_apiKey'));
      return response.statusCode == 400; // 400 is expected for missing image
    } catch (e) {
      return false;
    }
  }
}