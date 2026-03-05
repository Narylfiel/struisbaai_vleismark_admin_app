import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Google Drive service — authenticates with service account,
/// polls a configured folder for new invoice files,
/// downloads and returns file bytes for Gemini OCR processing.
class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyFolderId = 'drive_folder_id';
  static const _keyLastScan = 'drive_last_scan';
  static const _keyEnabled = 'drive_sync_enabled';
  static const _scopes = [drive.DriveApi.driveReadonlyScope];
  static const _serviceAccountAsset =
      'assets/secrets/google_service_account.json';

  drive.DriveApi? _driveApi;

  // ── Settings ──────────────────────────────────────────────────

  Future<void> saveFolderId(String folderId) async {
    String id = folderId.trim();
    // Strip full URL if user pastes it instead of just the ID
    final match = RegExp(r'/folders/([a-zA-Z0-9_-]+)').firstMatch(id);
    if (match != null) id = match.group(1)!;
    // Strip any query string
    if (id.contains('?')) id = id.split('?').first;
    await _storage.write(key: _keyFolderId, value: id);
  }

  Future<String?> loadFolderId() async {
    return _storage.read(key: _keyFolderId);
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(
        key: _keyEnabled, value: enabled ? 'true' : 'false');
  }

  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  Future<bool> isConfigured() async {
    final folderId = await loadFolderId();
    return folderId != null && folderId.isNotEmpty;
  }

  // ── Authentication ────────────────────────────────────────────

  Future<drive.DriveApi> _getApi() async {
    if (_driveApi != null) return _driveApi!;

    try {
      final jsonStr =
          await rootBundle.loadString(_serviceAccountAsset);
      final credentials = ServiceAccountCredentials.fromJson(
          jsonDecode(jsonStr));
      final client =
          await clientViaServiceAccount(credentials, _scopes);
      _driveApi = drive.DriveApi(client);
      return _driveApi!;
    } catch (e) {
      throw Exception(
          'Failed to load Drive credentials: $e\n'
          'Make sure assets/secrets/google_service_account.json exists.');
    }
  }

  // ── Folder scanning ───────────────────────────────────────────

  /// List new files in the configured folder since last scan.
  /// Returns list of DriveFile metadata.
  Future<List<drive.File>> listNewFiles() async {
    final folderId = await loadFolderId();
    if (folderId == null || folderId.isEmpty) return [];

    final api = await _getApi();
    final lastScanStr = await _storage.read(key: _keyLastScan);
    final lastScan = lastScanStr != null
        ? DateTime.tryParse(lastScanStr)
        : null;

    // Build query — PDF and image files in this folder
    String query =
        "'$folderId' in parents and trashed = false and "
        "(mimeType = 'application/pdf' or "
        "mimeType = 'image/jpeg' or "
        "mimeType = 'image/png' or "
        "mimeType = 'image/webp')";

    if (lastScan != null) {
      final iso = lastScan.toUtc().toIso8601String();
      query += " and createdTime > '$iso'";
    }

    try {
      final result = await api.files.list(
        q: query,
        $fields: 'files(id,name,mimeType,createdTime,size)',
        orderBy: 'createdTime asc',
        pageSize: 50,
      );
      return result.files ?? [];
    } catch (e) {
      debugPrint('Drive list error: $e');
      return [];
    }
  }

  /// Download a file by ID and return its bytes.
  Future<Uint8List?> downloadFile(String fileId) async {
    try {
      final api = await _getApi();
      final response = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final chunks = <int>[];
      await for (final chunk in response.stream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    } catch (e) {
      debugPrint('Drive download error: $e');
      return null;
    }
  }

  /// Mark current time as last scan time.
  Future<void> markScanned() async {
    await _storage.write(
      key: _keyLastScan,
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Test connection by listing files in folder (max 1).
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final folderId = await loadFolderId();
      if (folderId == null || folderId.isEmpty) {
        return {
          'success': false,
          'error': 'No folder ID configured'
        };
      }
      final api = await _getApi();
      final result = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id,name)',
        pageSize: 1,
      );
      final count = result.files?.length ?? 0;
      return {
        'success': true,
        'message':
            'Connected — folder accessible. '
            '${count > 0 ? 'Found files.' : 'Folder is empty.'}'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Full scan: list new files, download each, return as
  /// list of {name, bytes, mimeType} maps for OCR processing.
  Future<List<DriveInvoiceFile>> scanForNewInvoices() async {
    final enabled = await isEnabled();
    if (!enabled) return [];

    final files = await listNewFiles();
    if (files.isEmpty) {
      await markScanned();
      return [];
    }

    final results = <DriveInvoiceFile>[];
    for (final file in files) {
      if (file.id == null) continue;
      final bytes = await downloadFile(file.id!);
      if (bytes == null) continue;
      results.add(DriveInvoiceFile(
        fileId: file.id!,
        fileName: file.name ?? 'invoice',
        mimeType: file.mimeType ?? 'application/pdf',
        bytes: bytes,
        createdTime: file.createdTime,
      ));
    }

    await markScanned();
    return results;
  }
}

// ── Data class ────────────────────────────────────────────────────

class DriveInvoiceFile {
  final String fileId;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final DateTime? createdTime;

  const DriveInvoiceFile({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    this.createdTime,
  });
}
