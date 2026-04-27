import 'dart:convert';
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
  static const _keyProcessedFiles = 'drive_processed_file_ids';
  static const _keyImportSource = 'invoice_import_source';
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

  /// Load set of already-processed Drive file IDs.
  Future<Set<String>> _loadProcessedIds() async {
    final raw = await _storage.read(key: _keyProcessedFiles);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  /// Save a file ID as processed so it's never imported again.
  Future<void> _markFileProcessed(String fileId) async {
    final existing = await _loadProcessedIds();
    existing.add(fileId);
    // Keep only last 500 IDs to prevent unbounded growth
    final trimmed = existing.length > 500
        ? existing.skip(existing.length - 500).toSet()
        : existing;
    await _storage.write(key: _keyProcessedFiles, value: trimmed.join(','));
  }

  /// Check if a file has already been processed.
  Future<bool> _isProcessed(String fileId) async {
    final existing = await _loadProcessedIds();
    return existing.contains(fileId);
  }

  /// Mark a file as processed (e.g. after successful invoice creation).
  Future<void> markFileAsProcessed(String fileId) async {
    await _markFileProcessed(fileId);
  }

  /// Clear processed file IDs so the next scan re-processes all files.
  Future<void> clearProcessedIds() async {
    await _storage.delete(key: _keyProcessedFiles);
    await _storage.delete(key: _keyLastScan);
    // Reset in-memory cache too
    debugPrint('DRIVE: Cleared all processed IDs and last scan timestamp');
  }

  /// Clear processed file IDs so previously processed invoices can be re-imported.
  Future<void> clearProcessedFileIds() async {
    await _storage.delete(key: _keyProcessedFiles);
    debugPrint('[DRIVE] Cleared all processed file IDs');
  }

  Future<String> getImportSource() async {
    final val = await _storage.read(key: _keyImportSource);
    return val ?? 'drive';
  }

  Future<void> setImportSource(String source) async {
    await _storage.write(key: _keyImportSource, value: source);
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
    debugPrint('DRIVE: Raw lastScan from storage: $lastScanStr');
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

    // Only apply date filter if last scan was more than 60 seconds ago
    // This prevents filtering out files when doing a fresh/reset scan
    if (lastScan != null) {
      final age = DateTime.now().toUtc().difference(lastScan);
      if (age.inSeconds > 60) {
        final iso = lastScan.toUtc().toIso8601String();
        query += " and createdTime > '$iso'";
      } else {
        debugPrint('DRIVE: Skipping date filter — recent scan reset');
      }
    }

    try {
      debugPrint('DRIVE: Scanning folder ID: $folderId');
      debugPrint('DRIVE: Last scan was: $lastScanStr');
      debugPrint('DRIVE: Query: $query');
      final result = await api.files.list(
        q: query,
        $fields: 'files(id,name,mimeType,createdTime,size)',
        orderBy: 'createdTime asc',
        pageSize: 50,
      );
      final files = result.files ?? [];
      debugPrint('DRIVE: Raw file count: ${files.length}');
      for (final f in files) {
        debugPrint('DRIVE: Found file: ${f.name} (${f.id})');
      }
      return files;
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
      // Skip already-processed files
      if (await _isProcessed(file.id!)) continue;
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

    // NOTE: Do NOT mark files as processed here.
    // markFileAsProcessed is called by _scanDriveFolder only
    // after each invoice is successfully created in the database.
    // This prevents files being marked processed if OCR or DB insert fails.
    if (results.isNotEmpty) {
      await markScanned();
    }
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
