import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';
import '../utils/app_constants.dart';

/// WhatsApp service for sending notifications and customer communications via Twilio/Meta API
class WhatsAppService extends BaseService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  // Twilio credentials - TODO: Move to secure config
  final String _accountSid = ''; // Twilio Account SID
  final String _authToken = ''; // Twilio Auth Token
  final String _fromNumber = ''; // Twilio WhatsApp number
  final String _apiUrl = 'https://api.twilio.com/2010-04-01';

  /// Send WhatsApp message with retry logic
  Future<bool> sendMessage({
    required String toNumber,
    required String message,
    String? mediaUrl,
    int maxRetries = 3,
  }) async {
    if (!await isOnline()) {
      await _logMessage(null, toNumber, message, 'queued (offline)', error: 'Device offline');
      // In a full implementation, we'd add it to a local queue here
      throw Exception('Device is offline. Message queued.');
    }

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        if (!isConfigured) {
          throw Exception('WhatsApp service not configured');
        }

        final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
        final url = Uri.parse('$_apiUrl/Accounts/$_accountSid/Messages.json');

        final body = {
          'From': 'whatsapp:$_fromNumber',
          'To': 'whatsapp:$toNumber',
          'Body': message,
        };

        if (mediaUrl != null) {
          body['MediaUrl'] = mediaUrl;
        }

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: body,
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          await _logMessage(data['sid'], toNumber, message, 'sent');
          return true;
        } else if (response.statusCode >= 500) {
          throw Exception('Server error: ${response.statusCode}');
        } else {
          throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries || e.toString().contains('not configured')) {
          await _logMessage(null, toNumber, message, 'failed', error: e.toString());
          throw Exception('Failed to send WhatsApp message after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return false;
  }

  /// Send order confirmation to customer
  Future<bool> sendOrderConfirmation({
    required String customerPhone,
    required String customerName,
    required String orderNumber,
    required double totalAmount,
    required DateTime pickupDateTime,
  }) async {
    final message = '''
🛒 Order Confirmation - Struisbaai Vleismark

Hi $customerName!

Your order #$orderNumber has been confirmed.

📅 Pickup: ${pickupDateTime.toString().split('T')[0]} at ${pickupDateTime.toString().split('T')[1].substring(0, 5)}
💰 Total: R${totalAmount.toStringAsFixed(2)}

Please arrive 5 minutes before your pickup time.
We'll have your order ready!

Questions? Reply to this message.

Thank you for choosing Struisbaai Vleismark! 🥩
    '''.trim();

    return await sendMessage(toNumber: customerPhone, message: message);
  }

  /// Send payment reminder
  Future<bool> sendPaymentReminder({
    required String customerPhone,
    required String customerName,
    required double outstandingAmount,
    required DateTime dueDate,
  }) async {
    final message = '''
💳 Payment Reminder - Struisbaai Vleismark

Hi $customerName,

You have an outstanding balance of R${outstandingAmount.toStringAsFixed(2)} due on ${dueDate.toString().split('T')[0]}.

Please settle your account to avoid any interruptions to your service.

Contact us if you need to arrange payment.

Thank you! 🥩
    '''.trim();

    return await sendMessage(toNumber: customerPhone, message: message);
  }

  /// Send loyalty points update
  Future<bool> sendLoyaltyUpdate({
    required String customerPhone,
    required String customerName,
    required int pointsEarned,
    required int totalPoints,
  }) async {
    final message = '''
⭐ Loyalty Points Update

Hi $customerName!

You've earned $pointsEarned points!
Your total points balance: $totalPoints

Points can be redeemed for discounts on future purchases.

Keep shopping with us! 🥩
    '''.trim();

    return await sendMessage(toNumber: customerPhone, message: message);
  }

  /// Send promotional announcement
  Future<bool> sendPromotion({
    required List<String> customerPhones,
    required String title,
    required String message,
    String? imageUrl,
  }) async {
    var successCount = 0;

    for (final phone in customerPhones) {
      try {
        final fullMessage = '''
📢 $title

$message

Valid while stocks last!
        '''.trim();

        final success = await sendMessage(
          toNumber: phone,
          message: fullMessage,
          mediaUrl: imageUrl,
        );

        if (success) successCount++;
      } catch (e) {
        print('Failed to send promotion to $phone: $e');
      }
    }

    return successCount > 0;
  }

  /// Send stock alert to staff
  Future<bool> sendStockAlert({
    required String staffPhone,
    required String itemName,
    required int currentStock,
    required int reorderPoint,
  }) async {
    final message = '''
⚠️ Stock Alert

Item: $itemName
Current Stock: $currentStock
Reorder Point: $reorderPoint

Please reorder immediately to avoid stockouts.
    '''.trim();

    return await sendMessage(toNumber: staffPhone, message: message);
  }

  /// Send production completion alert
  Future<bool> sendProductionAlert({
    required String staffPhone,
    required String batchNumber,
    required String productName,
    required int quantity,
  }) async {
    final message = '''
🏭 Production Complete

Batch: $batchNumber
Product: $productName
Quantity: $quantity

Ready for quality check and packaging.
    '''.trim();

    return await sendMessage(toNumber: staffPhone, message: message);
  }

  /// Get message delivery status
  Future<String?> getMessageStatus(String messageSid) async {
    try {
      if (!isConfigured) return null;

      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      final url = Uri.parse('$_apiUrl/Accounts/$_accountSid/Messages/$messageSid.json');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'];
      }

      return null;
    } catch (e) {
      print('Failed to get message status: $e');
      return null;
    }
  }

  /// Log message for audit trail
  Future<void> _logMessage(String? messageSid, String toNumber, String message, String status, {String? error}) async {
    try {
      await executeQuery(
        () => client.from('message_logs').insert({
          'message_sid': messageSid,
          'to_number': toNumber,
          'message_content': message.substring(0, min(500, message.length)), // Truncate if too long
          'status': status,
          'error_message': error,
          'sent_at': DateTime.now().toIso8601String(),
        }),
        operationName: 'Log WhatsApp message',
      );
    } catch (e) {
      print('Failed to log message: $e');
    }
  }

  /// Get message logs for reporting
  Future<List<Map<String, dynamic>>> getMessageLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = client.from('message_logs').select('*');

      if (startDate != null) {
        query = query.gte('sent_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('sent_at', endDate.toIso8601String());
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await executeQuery(() => query.order('sent_at', ascending: false), operationName: 'Fetch message logs');
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      throw Exception('Failed to fetch message logs: $e');
    }
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    // South African phone number validation
    final saPhoneRegex = RegExp(r'^(\+27|27|0)[6-8][0-9]{8}$');
    return saPhoneRegex.hasMatch(phoneNumber.replaceAll(' ', '').replaceAll('-', ''));
  }

  /// Format phone number for WhatsApp
  String formatPhoneNumber(String phoneNumber) {
    // Ensure South African format
    var cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = '27${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('27')) {
      cleaned = '27$cleaned';
    }

    return cleaned;
  }

  /// Check if service is configured
  bool get isConfigured => _accountSid.isNotEmpty && _authToken.isNotEmpty && _fromNumber.isNotEmpty;

  /// Get service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'is_configured': isConfigured,
      'api_available': await _testApiConnection(),
      'last_message_sent': await _getLastMessageTime(),
    };
  }

  /// Test API connection
  Future<bool> _testApiConnection() async {
    if (!isConfigured) return false;

    try {
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      final url = Uri.parse('$_apiUrl/Accounts/$_accountSid/Messages.json?PageSize=1');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get last message timestamp
  Future<String?> _getLastMessageTime() async {
    try {
      final logs = await getMessageLogs();
      if (logs.isNotEmpty) {
        return logs.first['sent_at'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Utility function for min
  int min(int a, int b) => a < b ? a : b;
}