import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// SMTP email service using cPanel credentials stored in flutter_secure_storage.
/// Credentials never touch the database — password lives on device only.
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const _storage = FlutterSecureStorage();

  // Secure storage keys
  static const _keyHost     = 'smtp_host';
  static const _keyPort     = 'smtp_port';
  static const _keyUsername = 'smtp_username';
  static const _keyPassword = 'smtp_password';
  static const _keyFromName = 'smtp_from_name';

  final SupabaseClient _client = SupabaseService.client;

  // ── Credential management ─────────────────────────────────────

  Future<void> saveCredentials({
    required String host,
    required int port,
    required String username,
    required String password,
    required String fromName,
  }) async {
    await _storage.write(key: _keyHost,     value: host);
    await _storage.write(key: _keyPort,     value: port.toString());
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyFromName, value: fromName);

    // Save non-sensitive settings to DB for display purposes
    final existing = await _client
        .from('smtp_settings')
        .select('id')
        .limit(1);
    final row = {
      'host': host,
      'port': port,
      'username': username,
      'from_name': fromName,
      'from_email': username,
      'is_active': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if ((existing as List).isEmpty) {
      await _client.from('smtp_settings').insert(row);
    } else {
      final id = existing.first['id'];
      await _client.from('smtp_settings').update(row).eq('id', id as String);
    }
  }

  Future<Map<String, String?>> loadCredentials() async {
    return {
      'host':      await _storage.read(key: _keyHost),
      'port':      await _storage.read(key: _keyPort),
      'username':  await _storage.read(key: _keyUsername),
      'password':  await _storage.read(key: _keyPassword),
      'from_name': await _storage.read(key: _keyFromName),
    };
  }

  Future<bool> isConfigured() async {
    final creds = await loadCredentials();
    return (creds['host']?.isNotEmpty ?? false) &&
           (creds['password']?.isNotEmpty ?? false);
  }

  // ── Send invoice email ────────────────────────────────────────

  /// Sends a customer invoice PDF by email.
  /// Returns true on success, false on failure.
  /// Always writes a row to email_log.
  Future<bool> sendInvoiceEmail({
    required String invoiceId,
    required String invoiceNumber,
    required String recipientEmail,
    required String recipientName,
    required Uint8List pdfBytes,
    String? ccEmail,
  }) async {
    final creds = await loadCredentials();
    final host     = creds['host'];
    final portStr  = creds['port'];
    final username = creds['username'];
    final password = creds['password'];
    final fromName = creds['from_name'] ?? 'Struisbaai Vleismark';

    if (host == null || password == null || username == null) {
      await _logEmail(
        invoiceId: invoiceId,
        recipient: recipientEmail,
        subject: 'Invoice $invoiceNumber',
        status: 'failed',
        error: 'SMTP not configured — go to Settings → Email to set up.',
      );
      return false;
    }

    final port = int.tryParse(portStr ?? '465') ?? 465;
    final subject = 'Invoice $invoiceNumber — Struisbaai Vleismark';

    final smtpServer = SmtpServer(
      host,
      port: port,
      ssl: port == 465,
      username: username,
      password: password,
    );

    final message = Message()
      ..from = Address(username, fromName)
      ..recipients.add(Address(recipientEmail, recipientName))
      ..subject = subject
      ..html = _buildEmailHtml(invoiceNumber, recipientName)
      ..attachments.add(
          StreamAttachment(
            Stream.fromIterable([pdfBytes]),
            'application/pdf',
            fileName: 'Invoice-$invoiceNumber.pdf',
          ),
        );

    if (ccEmail != null && ccEmail.isNotEmpty) {
      message.ccRecipients.add(Address(ccEmail));
    }

    try {
      await send(message, smtpServer);
      await _logEmail(
        invoiceId: invoiceId,
        recipient: recipientEmail,
        subject: subject,
        status: 'sent',
      );
      await _client.from('customer_invoices').update({
        'email_delivery_status': 'sent',
        'email_sent_at': DateTime.now().toUtc().toIso8601String(),
        'email_sent_to': recipientEmail,
        'status': 'sent',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', invoiceId);
      return true;
    } catch (e) {
      debugPrint('Email send failed: $e');
      await _logEmail(
        invoiceId: invoiceId,
        recipient: recipientEmail,
        subject: subject,
        status: 'failed',
        error: e.toString(),
      );
      await _client.from('customer_invoices').update({
        'email_delivery_status': 'failed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', invoiceId);
      return false;
    }
  }

  /// Send all pending_email invoices — call on app startup and
  /// when bookkeeping screen opens.
  Future<int> sendPendingInvoices({
    required Future<Uint8List> Function(Map<String, dynamic> invoice) pdfGenerator,
  }) async {
    if (!await isConfigured()) return 0;
    int sent = 0;
    try {
      final pending = await _client
          .from('customer_invoices')
          .select('*, business_accounts(id, name, email)')
          .eq('email_delivery_status', 'pending_email')
          .order('created_at');

      for (final inv in pending as List) {
        final account = inv['business_accounts'] as Map<String, dynamic>?;
        final email = account?['email'] as String?;
        if (email == null || email.isEmpty) continue;

        try {
          final pdfBytes = await pdfGenerator(Map<String, dynamic>.from(inv));
          final success = await sendInvoiceEmail(
            invoiceId: inv['id'] as String,
            invoiceNumber: inv['invoice_number'] as String? ?? '',
            recipientEmail: email,
            recipientName: account?['name'] as String? ?? '',
            pdfBytes: pdfBytes,
          );
          if (success) sent++;
        } catch (e) {
          debugPrint('Failed to send pending invoice ${inv['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('sendPendingInvoices error: $e');
    }
    return sent;
  }

  // ── Test connection ───────────────────────────────────────────

  Future<Map<String, dynamic>> testConnection() async {
    final creds = await loadCredentials();
    final host     = creds['host'];
    final portStr  = creds['port'];
    final username = creds['username'];
    final secret   = creds['password'];

    if (host == null || secret == null || username == null ||
        host.isEmpty || secret.isEmpty || username.isEmpty) {
      return {'success': false, 'error': 'Credentials not configured'};
    }

    final port = int.tryParse(portStr ?? '465') ?? 465;
    final smtpServer = SmtpServer(
      host,
      port: port,
      ssl: port == 465,
      username: username,
      password: secret,
    );

    try {
      final testMessage = Message()
        ..from = Address(username, 'Test')
        ..recipients.add(Address(username))
        ..subject = 'SMTP Connection Test'
        ..text = 'Connection test from Admin App.';

      await send(testMessage, smtpServer);
      return {'success': true};
    } on SmtpClientAuthenticationException catch (e) {
      return {'success': false, 'error': 'Login rejected — ${e.message}'};
    } on SocketException catch (e) {
      return {'success': false, 'error': 'Cannot reach mail server — ${e.message}'};
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('535') ||
          msg.contains('Authentication') ||
          msg.contains('auth')) {
        return {'success': false, 'error': 'Login rejected — check credentials'};
      }
      return {'success': false, 'error': msg};
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<void> _logEmail({
    required String invoiceId,
    required String recipient,
    required String subject,
    required String status,
    String? error,
  }) async {
    try {
      await _client.from('email_log').insert({
        'invoice_id': invoiceId,
        'recipient_email': recipient,
        'subject': subject,
        'status': status,
        'error_message': error,
        'sent_at': status == 'sent'
            ? DateTime.now().toUtc().toIso8601String()
            : null,
      });
    } catch (e) {
      debugPrint('email_log insert failed: $e');
    }
  }

  String _buildEmailHtml(String invoiceNumber, String recipientName) {
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto;">
  <div style="background: #1E3A5F; padding: 24px; text-align: center;">
    <h1 style="color: white; margin: 0; font-size: 22px;">Struisbaai Vleismark</h1>
    <p style="color: #ccc; margin: 4px 0 0 0; font-size: 13px;">struisbaai-slaghuis.co.za</p>
  </div>
  <div style="padding: 32px 24px;">
    <p>Dear $recipientName,</p>
    <p>Please find your invoice <strong>$invoiceNumber</strong> attached to this email.</p>
    <p>If you have any queries regarding this invoice, please contact us directly.</p>
    <br>
    <p style="color: #666; font-size: 13px;">
      Struisbaai Vleismark<br>
      Unit 6b Struisbaai Business Centre, Malvern Drive<br>
      Tel: 082 696 2940
    </p>
  </div>
  <div style="background: #f5f5f5; padding: 16px 24px; font-size: 11px; color: #999; text-align: center;">
    This is an automated invoice from Struisbaai Vleismark Admin System.
  </div>
</body>
</html>
''';
  }
}
